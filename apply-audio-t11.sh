#!/bin/bash
# =============================================================================
# apply-audio-t11.sh — AERA recovery audio T11 (TB323FU)
#
# Fixes the PAL start path stuck at tinyalsa `pcm_plug_open: failed to open
# plugin` by:
#   1. making aera-palplayer's PAL stream type configurable (default 13 =
#      DEEP_BUFFER tunnel candidate; /tmp/aera-pal-stream-type override);
#   2. adding the stock /vendor/lib64 to the PAL child LD path so all stock
#      PAL plugin libraries (libstream_*, libsession_*, libdev_*) are visible;
#   3. shipping /system/bin/aera-pal-probe.sh to test the candidate stream
#      types on-device without rebuilding.
#
#   bash apply-audio-t11.sh --dry-run   # show changes only
#   bash apply-audio-t11.sh             # apply (backups .bak-t11-<stamp>)
#   bash apply-audio-t11.sh --revert    # restore newest backups
# =============================================================================
set -uo pipefail

TREE=/root/aera-worktree
EV=<WORKSPACE>
SRC="${EV}/round6/src"
MODE=apply
for arg in "$@"; do
  case "${arg}" in
    --dry-run) MODE=dry;;
    --revert) MODE=revert;;
    --tree=*) TREE="${arg#--tree=}";;
    -h|--help) sed -n '1,18p' "$0"; exit 0;;
    *) echo "unknown argument: ${arg}" >&2; exit 64;;
  esac
done
STAMP="$(date +%Y%m%d-%H%M%S)"
run() { if [ "${MODE}" = dry ]; then echo "[dry] $*"; else "$@"; fi; }
note() { echo ">>> $*"; }
[ -d "${TREE}/audio" ] || { echo "FATAL: ${TREE}/audio missing" >&2; exit 1; }
[ -f "${SRC}/aera_palplayer.cpp" ] || { echo "FATAL: missing ${SRC}/aera_palplayer.cpp" >&2; exit 1; }
backup() { [ -f "$1" ] && run cp -a "$1" "$1.bak-t11-${STAMP}"; }

if [ "${MODE}" = revert ]; then
  note "restoring newest .bak-t11 backups"
  for file in "${TREE}/audio/aera_palplayer.cpp" \
              "${TREE}/audio/aera_audio_bridge.cpp"; do
    newest="$(ls -1t "${file}".bak-t11-* 2>/dev/null | head -1)"
    [ -n "${newest}" ] && cp -a "${newest}" "${file}" && \
        echo "restored ${file} <- ${newest}"
  done
  rm -f "${TREE}/recovery/root/system/bin/aera-pal-probe.sh"
  echo "revert done"
  exit 0
fi

# 1) palplayer with configurable stream type
note "1) installing configurable aera-palplayer"
backup "${TREE}/audio/aera_palplayer.cpp"
run cp -f "${SRC}/aera_palplayer.cpp" "${TREE}/audio/aera_palplayer.cpp"

# 2) boot-time probe helper (runs candidate stream types on-device)
note "2) installing /system/bin/aera-pal-probe.sh"
PROBE="${TREE}/recovery/root/system/bin/aera-pal-probe.sh"
if [ "${MODE}" = dry ]; then
  echo "[dry] install ${PROBE}"
else
  mkdir -p "$(dirname "${PROBE}")"
  cp -f "${SRC}/aera-pal-probe.sh" "${PROBE}"
  chmod 0755 "${PROBE}"
fi

# 3) bridge child LD path: add /vendor/lib64 (stock PAL plugin libraries)
note "3) patching bridge PAL child LD_LIBRARY_PATH (adds /vendor/lib64)"
BRIDGE="${TREE}/audio/aera_audio_bridge.cpp"
OLD='/AERA/audio/abi:/AERA/audio/lib64:/system/lib64'
NEW='/AERA/audio/abi:/AERA/audio/lib64:/vendor/lib64:/system/lib64'
if grep -q "${NEW}" "${BRIDGE}"; then
  echo "   bridge LD path already includes /vendor/lib64"
elif grep -q "${OLD}" "${BRIDGE}"; then
  backup "${BRIDGE}"
  if [ "${MODE}" = dry ]; then
    echo "[dry] replace child LD path with ${NEW}"
  else
    python3 - "${BRIDGE}" "${OLD}" "${NEW}" <<'PY'
import sys
path, old, new = sys.argv[1], sys.argv[2], sys.argv[3]
text = open(path).read()
assert old in text, "bridge LD path anchor not found"
text = text.replace(old, new)
open(path, "w").write(text)
print("   bridge patched")
PY
  fi
else
  echo "   WARN: bridge LD path anchor not found; check manually"
fi

note "done (stamp=${STAMP})"
cat <<'TXT'

Build/flash (maintainer):
  bash /root/aera-worktree/build-batch.sh
  flash recovery_b only

After boot (all read-only /tmp writes only):
  # make a 1s 48k/16b/2ch raw tone if not present (busybox/sox optional)
  ls -l /tmp/tone.raw || echo "need /tmp/tone.raw (the maintainer already has /tmp/tone.raw in verification)"

  # one-shot matrix: stream types 13/12/11/0/16/21/24/1
  sh /system/bin/aera-pal-probe.sh /tmp/tone.raw 2>&1 | tee /tmp/aera-pal-probe.out

  # or single test (no rebuild needed):
  echo 13 > /tmp/aera-pal-stream-type
  /system/bin/aera-palplayer --fifo /tmp/pcm2.fifo --stream-type 13

  # expected for a working candidate:
  #   no "pcm_plug_open: failed to open plugin"
  #   "PAL stream opened ... / PAL stream started"
  #   /proc/asound/card0/pcm*/sub0/status = RUNNING
  #   dmesg | grep aw882xx_start_pa -> start success
TXT
