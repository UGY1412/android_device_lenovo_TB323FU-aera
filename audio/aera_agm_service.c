/*
 * Copyright (C) 2026 AERA Recovery Project contributors
 * SPDX-License-Identifier: Apache-2.0
 *
 * Small recovery-side host for Qualcomm's device-matched AGM implementation.
 * The proprietary implementation and its matching runtime are shipped in the
 * TB323FU recovery ramdisk. Plugins never receive /dev/snd or partition access.
 *
 * Round T2: libbinder_ndk is dlopen()ed from the bundled A17 ABI directory so
 * the host and the stock AGM/PAL libraries share one binder implementation
 * (recovery's servicemanager is AOSP 16). Registration failures are logged but
 * do not kill the host: a rejected registration simply means the PCM bridge is
 * unavailable, and the audio stack must not spin in an init restart loop.
 */
#include <android/log.h>
#include <dlfcn.h>
#include <stdbool.h>
#include <unistd.h>

#include <stdio.h>
#include <string.h>

static const char kTag[] = "AERAAudio";
static const char kAgmService[] =
    "/AERA/audio/lib64/libagmipcservice.so";
static const char kPalService[] =
    "/AERA/audio/lib64/libpalipcservice.so";
static const char kBinderNdk[] = "libbinder_ndk.so";

typedef void* AIBinder;

struct BinderApi {
  void (*set_thread_pool_max)(int);
  void (*start_thread_pool)(void);
  int (*join_thread_pool)(void);
  AIBinder* (*check_service)(const char*);
  void (*dec_strong)(AIBinder*);
};

static struct BinderApi gBinder;

static void Log(int priority, const char* message) {
  __android_log_write(priority, kTag, message);
  fprintf(stderr, "%s\n", message);
}

static int LoadBinderApi(void* binder_library) {
  gBinder.set_thread_pool_max = (void (*)(int))dlsym(
      binder_library, "ABinderProcess_setThreadPoolMaxThreadCount");
  gBinder.start_thread_pool = (void (*)(void))dlsym(
      binder_library, "ABinderProcess_startThreadPool");
  gBinder.join_thread_pool = (int (*)(void))dlsym(
      binder_library, "ABinderProcess_joinThreadPool");
  gBinder.check_service = (AIBinder* (*)(const char*))dlsym(
      binder_library, "AServiceManager_checkService");
  gBinder.dec_strong = (void (*)(AIBinder*))dlsym(
      binder_library, "AIBinder_decStrong");
  return gBinder.set_thread_pool_max && gBinder.start_thread_pool &&
         gBinder.join_thread_pool && gBinder.check_service && gBinder.dec_strong;
}

static void* RegisterServiceLibrary(const char* path, const char* descriptor,
                                    const char* label, bool* confirmed) {
  *confirmed = false;
  void* library = dlopen(path, RTLD_NOW | RTLD_LOCAL);
  if (!library) {
    const char* error = dlerror();
    __android_log_print(ANDROID_LOG_ERROR, kTag, "%s load failed: %s", label,
                        error ? error : "unknown dynamic-linker error");
    return NULL;
  }

  dlerror();
  void (*register_service)(void) = dlsym(library, "registerService");
  const char* symbol_error = dlerror();
  if (!register_service || symbol_error) {
    __android_log_print(ANDROID_LOG_ERROR, kTag, "%s symbol failed: %s", label,
                        symbol_error ? symbol_error : "registerService missing");
    dlclose(library);
    return NULL;
  }

  register_service();
  AIBinder* service = gBinder.check_service(descriptor);
  if (service == NULL) {
    __android_log_print(ANDROID_LOG_ERROR, kTag,
                        "%s registration was not confirmed for %s", label,
                        descriptor);
    dlclose(library);
    return NULL;
  }
  gBinder.dec_strong(service);
  *confirmed = true;
  __android_log_print(ANDROID_LOG_INFO, kTag, "%s registered.", label);
  return library;
}

int main(int argc, char** argv) {
  if (argc != 2 || strcmp(argv[1], "--tb323fu-stock-agm") != 0) {
    Log(ANDROID_LOG_ERROR,
        "Refusing to start without the TB323FU stock AGM mode.");
    return 64;
  }
  if (getuid() != 0 || access(kAgmService, R_OK) != 0 ||
      access(kPalService, R_OK) != 0) {
    Log(ANDROID_LOG_ERROR, "The bundled TB323FU audio runtime is unavailable.");
    return 66;
  }

  void* binder_library = dlopen(kBinderNdk, RTLD_NOW | RTLD_LOCAL);
  if (!binder_library || !LoadBinderApi(binder_library)) {
    const char* error = dlerror();
    __android_log_print(ANDROID_LOG_ERROR, kTag,
                        "libbinder_ndk load failed: %s",
                        error ? error : "missing binder symbols");
    return 67;
  }

  gBinder.set_thread_pool_max(8);
  gBinder.start_thread_pool();

  bool agm_confirmed = false;
  void* agm_library = RegisterServiceLibrary(
      kAgmService, "vendor.qti.hardware.agm.IAGM/default",
      "TB323FU stock AGM", &agm_confirmed);
  bool pal_confirmed = false;
  void* pal_library =
      agm_library ? RegisterServiceLibrary(
                        kPalService, "vendor.qti.hardware.pal.IPAL/default",
                        "TB323FU stock PAL", &pal_confirmed)
                  : NULL;

  if (!agm_library || !pal_library) {
    // Keep the process alive only when at least one service was registered;
    // otherwise let init stop us (and log why).
    if (!agm_confirmed && !pal_confirmed) {
      Log(ANDROID_LOG_ERROR,
          "No AGM/PAL service could be registered; audio bridge unavailable.");
      return 70;
    }
  }
  __android_log_print(ANDROID_LOG_INFO, kTag,
                      "TB323FU stock AGM/PAL host ready (AGM=%d PAL=%d)",
                      agm_confirmed, pal_confirmed);
  gBinder.join_thread_pool();
  Log(ANDROID_LOG_ERROR, "Audio Binder thread pool exited unexpectedly.");
  if (pal_library) dlclose(pal_library);
  if (agm_library) dlclose(agm_library);
  return 70;
}
