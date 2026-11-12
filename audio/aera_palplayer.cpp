/*
 * Copyright (C) 2026 AERA Recovery Project contributors
 * SPDX-License-Identifier: Apache-2.0
 *
 * aera-palplayer — dedicated recovery-side PAL consumer (A17 stock runtime).
 *
 * T11: the stream type is configurable because PAL's NON_TUNNEL stream (type 1)
 * goes through tinyalsa's PCM plugin (pcm_plug_open -> libagm_pcm_plugin.so),
 * which currently fails on this recovery configuration. Tunnel PCM stream
 * types (e.g. PAL_STREAM_DEEP_BUFFER / LOW_LATENCY / GENERIC) use the AGM graph
 * shared buffer and do not need that tinyalsa plugin, so they can bypass the
 * stuck path without touching stock libraries.
 *
 * Selection order for the stream type:
 *   --stream-type N  >  /tmp/aera-pal-stream-type (file)  >
 *   $AERA_PAL_STREAM_TYPE  >  default 13 (DEEP_BUFFER candidate)
 *
 * Other knobs: --device N (default 3 = SPEAKER), --flags N, --custom-key STR.
 *
 * Process environment (set by caller / init rc):
 *   LD_LIBRARY_PATH=/AERA/audio/abi:/AERA/audio/lib64:/vendor/lib64:/system/lib64
 *
 * Usage:
 *   aera-palplayer --fifo /tmp/aera-browser-audio-<pid> [--stream-type N]
 *   aera-palplayer --stdin [--stream-type N]
 *
 * PAL failures are reported via return codes; the player never calls abort()
 * and skips teardown if pal_stream_start fails (stock PAL can otherwise crash
 * in its teardown path).
 */

#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdarg.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

#include <array>

namespace {

constexpr uint32_t kRate = 48000U;
constexpr uint32_t kChannels = 2U;
constexpr uint32_t kBits = 16U;
constexpr int kSpeakerDeviceId = 3;   /* PAL_DEVICE_OUT_SPEAKER */
constexpr int kDefaultStreamType = 1; /* PAL_STREAM_LOW_LATENCY: verified on TB323FU (T11c) */
constexpr int kStreamDirection = 1;    /* PAL_DIRECTION_OUTPUT */
constexpr char kStreamTypeFile[] = "/tmp/aera-pal-stream-type";

volatile sig_atomic_t g_stop = 0;
bool g_graceful_teardown = false;
void OnSignal(int) { g_stop = 1; }

void Log(const char* fmt, ...) {
  va_list args;
  va_start(args, fmt);
  fprintf(stderr, "AERA palplayer: ");
  vfprintf(stderr, fmt, args);
  fprintf(stderr, "\n");
  va_end(args);
}

using PalStreamHandle = uint64_t;

struct PalChannelInfo {
  uint16_t channels;
  uint8_t channel_map[64];
};

struct PalStreamInfo {
  int64_t version;
  int64_t size;
  int64_t duration_us;
  bool has_video;
  bool is_streaming;
  int32_t loopback_type;
  int32_t tx_proxy_type;
  int32_t rx_proxy_type;
  int32_t haptics_type;
  bool is_bit_perfect;
};

union PalStreamInfoUnion {
  PalStreamInfo optional;
  struct {
    int64_t version;
    int64_t size;
    int32_t direction;
  } voice_record;
  struct {
    uint32_t vsid;
    uint32_t tty_mode;
  } voice_call;
  struct {
    bool local_playback;
    int32_t direction;
  } incall_music;
  int32_t hpcm_stream_type;
};

struct PalMediaConfig {
  uint32_t sample_rate;
  uint32_t bit_width;
  int32_t format;
  PalChannelInfo channel_info;
};

struct PalStreamAttributes {
  int32_t type;
  PalStreamInfoUnion info;
  int32_t flags;
  int32_t direction;
  PalMediaConfig input;
  PalMediaConfig output;
  char* address;
};

struct PalDevice {
  int32_t id;
  PalMediaConfig config;
  int32_t usb_card;
  int32_t usb_device;
  char sound_device_name[128];
  char custom_key[128];
  union {
    char id[128];
    uint32_t ipv6[8];
  } address;
};

struct PalBuffer {
  uint8_t* data;
  size_t size;
  size_t offset;
  timespec* timestamp;
  uint32_t flags;
  size_t metadata_size;
  uint8_t* metadata;
  struct {
    int32_t handle;
    uint32_t size;
    uint32_t offset;
  } allocation;
  uint64_t frame_index;
};

static_assert(sizeof(PalStreamAttributes) == 232, "PAL stream attr layout");
static_assert(offsetof(PalStreamAttributes, input) == 64, "PAL input offset");
static_assert(sizeof(PalDevice) == 476, "PAL device layout");
static_assert(sizeof(PalBuffer) == 80, "PAL buffer layout");

struct PalApi {
  using Init = int32_t (*)();
  using Deinit = void (*)();
  using StreamOpen = int32_t (*)(PalStreamAttributes*, uint32_t, PalDevice*,
                                 uint32_t, void*, void*, uint64_t,
                                 PalStreamHandle**);
  using StreamOperation = int32_t (*)(PalStreamHandle*);
  using StreamWrite = ssize_t (*)(PalStreamHandle*, PalBuffer*);

  void* library = nullptr;
  Init init = nullptr;
  Deinit deinit = nullptr;
  StreamOpen stream_open = nullptr;
  StreamOperation stream_close = nullptr;
  StreamOperation stream_start = nullptr;
  StreamOperation stream_stop = nullptr;
  StreamWrite stream_write = nullptr;

  ~PalApi() {
    if (library) dlclose(library);
  }

  template <typename T>
  bool LoadSymbol(const char* name, T* target) {
    *target = reinterpret_cast<T>(dlsym(library, name));
    if (*target) return true;
    Log("missing stock PAL symbol %s: %s", name, dlerror());
    return false;
  }

  bool Load() {
    library = dlopen("libar-pal.so", RTLD_NOW | RTLD_LOCAL);
    if (!library) {
      Log("could not load stock libar-pal.so: %s", dlerror());
      return false;
    }
    return LoadSymbol("pal_init", &init) &&
           LoadSymbol("pal_deinit", &deinit) &&
           LoadSymbol("pal_stream_open", &stream_open) &&
           LoadSymbol("pal_stream_close", &stream_close) &&
           LoadSymbol("pal_stream_start", &stream_start) &&
           LoadSymbol("pal_stream_stop", &stream_stop) &&
           LoadSymbol("pal_stream_write", &stream_write);
  }
};

struct PlayerConfig {
  int stream_type = kDefaultStreamType;
  int device_id = kSpeakerDeviceId;
  int flags = 0;
  char custom_key[128] = {};
};

int ReadStreamTypeFile(int fallback) {
  const int fd = open(kStreamTypeFile, O_RDONLY | O_CLOEXEC);
  if (fd < 0) return fallback;
  char value[32] = {};
  const ssize_t count = read(fd, value, sizeof(value) - 1);
  close(fd);
  if (count <= 0) return fallback;
  return atoi(value);
}

void SetPcmConfig(PalMediaConfig* config) {
  config->sample_rate = kRate;
  config->bit_width = kBits;
  config->format = 1; /* PAL_AUDIO_FMT_PCM */
  config->channel_info.channels = kChannels;
  config->channel_info.channel_map[0] = 1; /* FL */
  config->channel_info.channel_map[1] = 2; /* FR */
}

int PlayFifo(int input, PalApi& api, const PlayerConfig& player) {
  int result = 0;
  bool initialized = false;
  bool started = false;
  PalStreamHandle* stream = nullptr;

  {
    if (api.init() != 0) {
      Log("pal_init failed");
      return 70;
    }
    initialized = true;

    PalStreamAttributes attributes{};
    PalDevice device{};
    attributes.type = player.stream_type;
    attributes.flags = player.flags;
    attributes.direction = kStreamDirection;
    SetPcmConfig(&attributes.input);
    SetPcmConfig(&attributes.output);
    device.id = player.device_id;
    SetPcmConfig(&device.config);
    if (player.custom_key[0] != '\0') {
      strncpy(device.custom_key, player.custom_key, sizeof(device.custom_key) - 1);
    }
    Log("pal_stream_open(type=%d device=%d flags=0x%x custom_key='%s')",
        player.stream_type, player.device_id, player.flags,
        player.custom_key);
    if (api.stream_open(&attributes, 1, &device, 0, nullptr, nullptr, 0,
                        &stream) != 0 ||
        stream == nullptr) {
      Log("pal_stream_open failed");
      return 70;
    }
    Log("PAL stream opened (speaker, 48k/16b/2ch)");

    if (api.stream_start(stream) != 0) {
      Log("pal_stream_start failed; skipping teardown to avoid stock PAL abort");
      /* PAL's teardown after a failed start currently hits a destroyed mutex
       * and raises SIGABRT; exiting here keeps the probe/return-code clean. */
      _exit(72);
    }
    started = true;
    Log("PAL stream started");

    {
      std::array<uint8_t, 8195> buffer{};
      size_t carry = 0;
      while (!g_stop) {
        const ssize_t count =
            read(input, buffer.data() + carry, buffer.size() - carry);
        if (count < 0 && errno == EINTR) continue;
        if (count == 0) break;
        if (count < 0) {
          Log("FIFO read failed: %s", strerror(errno));
          result = 74;
          break;
        }
        const size_t total = carry + static_cast<size_t>(count);
        const size_t aligned = total & ~static_cast<size_t>(3);
        size_t written = 0;
        while (written < aligned) {
          PalBuffer buffer_info{};
          buffer_info.data = buffer.data() + written;
          buffer_info.size = aligned - written;
          const ssize_t bytes = api.stream_write(stream, &buffer_info);
          if (bytes <= 0) break;
          written += static_cast<size_t>(bytes);
        }
        if (written != aligned) {
          Log("pal_stream_write failed");
          result = 74;
          break;
        }
        carry = total - aligned;
        if (carry) memmove(buffer.data(), buffer.data() + aligned, carry);
      }
    }
  }

  if (!g_graceful_teardown) {
    /* T12: stock PAL's stop/close/deinit path currently aborts with
     * 'FORTIFY: pthread_mutex_lock called on a destroyed mutex' after the
     * graph ends. Exiting here keeps the single-shot exit code clean; the
     * AGM host cleans up the session via binder client-death handling. */
    Log("EOF or signal: fast exit without PAL teardown (stock PAL abort workaround)");
    _exit(result);
  }

  {
    if (started && api.stream_stop(stream) != 0)
      Log("pal_stream_stop failed");
    if (stream != nullptr && api.stream_close(stream) != 0)
      Log("pal_stream_close failed");
    if (initialized) api.deinit();
  }
  return result;
}

void PrintUsage() {
  fprintf(stderr,
          "Usage: aera-palplayer --fifo <path> | --stdin\n"
          "       [--stream-type N] [--device N] [--flags N] [--graceful-teardown]"
          "[--custom-key STR]\n"
          "Stream type selection: CLI > %s > $AERA_PAL_STREAM_TYPE > %d\n"
          "Examples: --stream-type 13 (DEEP_BUFFER), 12 (LOW_LATENCY), "
          "11 (GENERIC), 1 (NON_TUNNEL)\n"
          "Environment: LD_LIBRARY_PATH must put /AERA/audio/abi and "
          "/AERA/audio/lib64 first (also add /vendor/lib64 for stock PAL "
          "plugins).\n",
          kStreamTypeFile, kDefaultStreamType);
}

}  // namespace

int main(int argc, char** argv) {
  signal(SIGPIPE, SIG_IGN);
  signal(SIGTERM, OnSignal);
  signal(SIGINT, OnSignal);

  PlayerConfig player;
  const char* fifo = nullptr;
  int input = -1;
  bool stdin_mode = false;

  for (int index = 1; index < argc; ++index) {
    if (strcmp(argv[index], "--fifo") == 0 && index + 1 < argc) {
      fifo = argv[++index];
    } else if (strcmp(argv[index], "--stdin") == 0) {
      stdin_mode = true;
    } else if (strcmp(argv[index], "--stream-type") == 0 && index + 1 < argc) {
      player.stream_type = atoi(argv[++index]);
    } else if (strcmp(argv[index], "--device") == 0 && index + 1 < argc) {
      player.device_id = atoi(argv[++index]);
    } else if (strcmp(argv[index], "--flags") == 0 && index + 1 < argc) {
      player.flags = static_cast<int>(strtol(argv[++index], nullptr, 0));
    } else if (strcmp(argv[index], "--custom-key") == 0 && index + 1 < argc) {
      strncpy(player.custom_key, argv[++index], sizeof(player.custom_key) - 1);
    } else if (strcmp(argv[index], "--graceful-teardown") == 0) {
      g_graceful_teardown = true;
    } else if (strcmp(argv[index], "--help") == 0 ||
               strcmp(argv[index], "-h") == 0) {
      PrintUsage();
      return 0;
    } else {
      PrintUsage();
      return 64;
    }
  }
  /* precedence: CLI > file > env > default */
  if (player.stream_type == kDefaultStreamType) {
    const char* env_value = getenv("AERA_PAL_STREAM_TYPE");
    int selected = kDefaultStreamType;
    if (env_value != nullptr) selected = atoi(env_value);
    selected = ReadStreamTypeFile(selected);
    player.stream_type = selected;
  }
  if (player.device_id == kSpeakerDeviceId) {
    const char* env_device = getenv("AERA_PAL_DEVICE");
    if (env_device != nullptr) player.device_id = atoi(env_device);
  }
  if (getenv("AERA_PAL_GRACEFUL_TEARDOWN") != nullptr) {
    g_graceful_teardown = true;
  }
  if (player.flags == 0) {
    const char* env_flags = getenv("AERA_PAL_FLAGS");
    if (env_flags != nullptr)
      player.flags = static_cast<int>(strtol(env_flags, nullptr, 0));
  }

  if (fifo == nullptr && !stdin_mode) {
    PrintUsage();
    return 64;
  }
  if (stdin_mode) {
    input = STDIN_FILENO;
  } else {
    struct stat info {};
    if (lstat(fifo, &info) != 0 || !S_ISFIFO(info.st_mode) ||
        info.st_uid != 0) {
      Log("rejected invalid PCM FIFO %s", fifo);
      return 64;
    }
    input = open(fifo, O_RDONLY | O_CLOEXEC);
    if (input < 0) {
      Log("could not open FIFO %s: %s", fifo, strerror(errno));
      return 71;
    }
  }

  Log("selected stream_type=%d device=%d flags=0x%x source=%s",
      player.stream_type, player.device_id, player.flags,
      (argc > 1 ? "argv/env/file" : "default"));

  PalApi api;
  if (!api.Load()) {
    if (input > STDIN_FILENO) close(input);
    return 70;
  }
  const int result = PlayFifo(input, api, player);
  if (input > STDIN_FILENO) close(input);
  Log("exit %d", result);
  return result;
}
