#!/bin/bash
# =============================================================================
# apply-audio-t12.sh — AERA recovery audio T12 (TB323FU)
#
# T11c 真机已打通出声：palplayer --stream-type 1 -> PAL started ->
# aw882xx_start_pa: start success（双 PA）。T12 收尾：
#   1. palplayer 单次播放 EOF 后快速退出，跳过 stock PAL 的 stop/close/deinit
#      (FORTIFY destroyed-mutex -> SIGABRT / rc=134)；AGM host 通过 binder
#      client-death 清理 binder session；
#   2. bridge 集成：FIFO 名改为 client pid（避免复用 bridge pid 的 stale FIFO），
#      子进程显式 --stream-type 1，默认软件音量 30% -> 60%；
#   3. bootstrap 保持 /tmp/aera-pal-stream-type=1 seed（已有则跳过）。
#
#   bash apply-audio-t12.sh --dry-run
#   bash apply-audio-t12.sh
#   bash apply-audio-t12.sh --revert
# =============================================================================
set -uo pipefail

TREE=/root/aera-worktree
EV=<WORKSPACE>
SRC="${EV}/round7/src"
MODE=apply
for arg in "$@"; do
  case "${arg}" in
    --dry-run) MODE=dry;;
    --revert) MODE=revert;;
    --tree=*) TREE="${arg#--tree=}";;
    -h|--help) sed -n '1,20p' "$0"; exit 0;;
    *) echo "unknown argument: ${arg}" >&2; exit 64;;
  esac
done
STAMP="$(date +%Y%m%d-%H%M%S)"
run() { if [ "${MODE}" = dry ]; then echo "[dry] $*"; else "$@"; fi; }
note() { echo ">>> $*"; }
[ -d "${TREE}/audio" ] || { echo "FATAL: ${TREE}/audio missing" >&2; exit 1; }
[ -f "${SRC}/aera_palplayer.cpp" ] || { echo "FATAL: missing ${SRC}/aera_palplayer.cpp" >&2; exit 1; }
backup() { [ -f "$1" ] && run cp -a "$1" "$1.bak-t12-${STAMP}"; }

if [ "${MODE}" = revert ]; then
  note "restoring newest .bak-t12 backups"
  for file in "${TREE}/audio/aera_palplayer.cpp" \
              "${TREE}/audio/aera_audio_bridge.cpp"; do
    newest="$(ls -1t "${file}".bak-t12-* 2>/dev/null | head -1)"
    [ -n "${newest}" ] && cp -a "${newest}" "${file}" && \
        echo "restored ${file} <- ${newest}"
  done
  echo "revert done"
  exit 0
fi

# 1) palplayer: verified stream type 1 + fast exit without PAL teardown
note "1) installing T12 aera-palplayer (stream type 1 + fast exit)"
backup "${TREE}/audio/aera_palplayer.cpp"
run cp -f "${SRC}/aera_palplayer.cpp" "${TREE}/audio/aera_palplayer.cpp"

# 2) bridge: volume default, explicit stream type, per-client FIFO name
note "2) patching bridge (volume 60%, --stream-type 1, client-pid FIFO)"
BRIDGE="${TREE}/audio/aera_audio_bridge.cpp"
backup "${BRIDGE}"
if [ "${MODE}" = dry ]; then
  echo "[dry] bridge: kDefaultVolumePercent 30->60"
  echo "[dry] bridge: add kPalStreamType=1 and pass --stream-type 1"
  echo "[dry] bridge: FIFO suffix getpid() -> credentials.pid"
else
  python3 - "${BRIDGE}" <<'PY'
import sys
path = sys.argv[1]
text = open(path).read()

# a) default software volume: 30% -> 60%
old = "constexpr int kDefaultVolumePercent = 30;"
new = "constexpr int kDefaultVolumePercent = 60;"
if old in text:
    text = text.replace(old, new, 1)
    print("   volume default -> 60")
elif new in text:
    print("   volume default already 60")
else:
    print("   WARN: volume default anchor missing")

# b) explicit palplayer stream type constant
anchor = 'constexpr char kPalPlayer[] = "/system/bin/aera-palplayer";'
if "kPalStreamType" not in text:
    assert anchor in text, "kPalPlayer anchor missing"
    text = text.replace(
        anchor,
        anchor + '\n/* Verified on TB323FU (T11c): type 1 = PAL_STREAM_LOW_LATENCY. */\n'
                 'constexpr int kPalStreamType = 1;',
        1)
    print("   added kPalStreamType=1")
else:
    print("   kPalStreamType already present")

# c) pass --stream-type 1 explicitly to the child
old_exec = ('execl(kPalPlayer, "aera-palplayer", "--fifo", fifo.c_str(), '
            'nullptr);')
new_exec = ('setenv("AERA_PAL_STREAM_TYPE", "1", 1);\n'
            '  execl(kPalPlayer, "aera-palplayer", "--fifo", fifo.c_str(),\n'
            '        "--stream-type", "1", nullptr);')
if old_exec in text:
    text = text.replace(old_exec, new_exec, 1)
    print("   palplayer exec now passes --stream-type 1")
elif "--stream-type" in text:
    print("   palplayer exec already passes stream type")
else:
    print("   WARN: palplayer exec anchor missing")

# d) per-client FIFO name (avoid stale FIFO shared across sequential clients)
old = ('const std::string fifo = "/tmp/aera-browser-audio-" +\n'
       '                           std::to_string(static_cast<long long>(getpid()));')
new = ('const std::string fifo = "/tmp/aera-browser-audio-" +\n'
       '                           std::to_string(static_cast<long long>(credentials.pid));')
if old in text:
    text = text.replace(old, new, 1)
    print("   FIFO name now uses client pid")
elif "credentials.pid" in text:
    print("   FIFO name already per-client")
else:
    print("   WARN: FIFO name anchor missing")

open(path, "w").write(text)
PY
fi

# 3) bootstrap seed: /tmp/aera-pal-stream-type=1 (T11c already added)
note "3) ensuring bootstrap seeds /tmp/aera-pal-stream-type=1"
BOOT="${TREE}/recovery/root/system/bin/aera-audio-bootstrap"
if grep -q 'aera-pal-stream-type' "${BOOT}"; then
  echo "   bootstrap already seeds the stream-type file"
else
  backup "${BOOT}"
  if [ "${MODE}" = dry ]; then
    echo "[dry] insert seed before 'TB323FU AGM backend is ready'"
  else
    python3 - "${BOOT}" <<'PY'
import sys
path = sys.argv[1]
text = open(path).read()
anchor = 'echo "AERA audio: TB323FU AGM backend is ready"'
assert anchor in text, "bootstrap AGM-ready anchor missing"
text = text.replace(
    anchor,
    'echo 1 > /tmp/aera-pal-stream-type 2>/dev/null || true\n' + anchor, 1)
open(path, "w").write(text)
print("   bootstrap seeds stream-type file")
PY
  fi
fi

# 4) bootstrap seed: default software volume 60% when the file is missing
note "4) ensuring bootstrap seeds /tmp/aera-audio-volume=60 when missing"
if grep -q 'aera-audio-volume' "${BOOT}"; then
  echo "   bootstrap already seeds the volume file"
else
  backup "${BOOT}"
  if [ "${MODE}" = dry ]; then
    echo "[dry] insert '[ -f /tmp/aera-audio-volume ] || echo 60 > ...'"
  else
    python3 - "${BOOT}" <<'PY'
import sys
path = sys.argv[1]
text = open(path).read()
anchor = 'echo 1 > /tmp/aera-pal-stream-type 2>/dev/null || true'
assert anchor in text, "bootstrap stream-type anchor missing"
text = text.replace(
    anchor,
    '[ -f /tmp/aera-audio-volume ] || echo 60 > /tmp/aera-audio-volume 2>/dev/null || true\n' + anchor,
    1)
open(path, "w").write(text)
print("   bootstrap seeds volume file")
PY
  fi
fi

note "done (stamp=${STAMP})"
cat <<'TXT'

Build/flash (maintainer):
  bash /root/aera-worktree/build-batch.sh
  flash recovery_b only

Verify after boot:
  # 单次播放（EOF 退出码应为 0，不应 134）
  /system/bin/aera-palplayer --fifo /tmp/pcm2.fifo --stream-type 1; echo "rc=$?"
  # bridge + artillery（持续播放时 palplayer 存活；播完不 SIGABRT）
  /system/bin/aera-audio-bridge --browser-audio &
  # artillery 播放 5s 后:
  ps -A | grep aera-palplayer
  dmesg | grep -E 'aw882xx_start_pa|start success'
  cat /proc/asound/card0/pcm*/sub0/status
  logcat -d | grep -E 'libc\+\+abi|FORTIFY|SIGABRT' | tail -10
  cat /tmp/aera-audio-volume; # 音量：默认 60；可 echo 80 > /tmp/aera-audio-volume
TXT
