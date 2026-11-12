#!/bin/bash
# =============================================================================
# apply-audio-t10.sh — AERA recovery audio T10 integration (TB323FU)
#
# Fixes the AGM-host SIGABRT (stock PAL ResourceManager cannot find the legacy
# flat mixer XMLs under /vendor/etc) and adds the dedicated stock-A17 PAL
# consumer `aera-palplayer` + the Awinic HAL probe `aera-aw-hal`.
#
#   bash apply-audio-t10.sh --dry-run   # show changes only
#   bash apply-audio-t10.sh             # apply (backups .bak-t10-<stamp>)
#   bash apply-audio-t10.sh --revert    # restore the most recent backup
#
# Never builds and never flashes. Run from the device tree or pass --tree.
# =============================================================================
set -uo pipefail

TREE=/root/aera-worktree
EV=<WORKSPACE>
SRC="${EV}/round5/src"
MODE=apply
for arg in "$@"; do
  case "${arg}" in
    --dry-run) MODE=dry;;
    --revert) MODE=revert;;
    --tree) :;;
    --tree=*) TREE="${arg#--tree=}";;
    -h|--help) sed -n '1,20p' "$0"; exit 0;;
    *) echo "unknown argument: ${arg}" >&2; exit 64;;
  esac
done
STAMP="$(date +%Y%m%d-%H%M%S)"
run() { if [ "${MODE}" = dry ]; then echo "[dry] $*"; else "$@"; fi; }
note() { echo ">>> $*"; }

[ -d "${TREE}/audio" ] || { echo "FATAL: ${TREE}/audio not found" >&2; exit 1; }
[ -f "${SRC}/aera_palplayer.cpp" ] || { echo "FATAL: missing ${SRC}/aera_palplayer.cpp" >&2; exit 1; }

backup() {
  local file="$1"
  [ -f "${file}" ] || return 0
  run cp -a "${file}" "${file}.bak-t10-${STAMP}"
}

# ---------------------------------------------------------------------------
# revert
# ---------------------------------------------------------------------------
if [ "${MODE}" = revert ]; then
  note "restoring newest .bak-t10 backups under ${TREE}"
  for file in \
      "${TREE}/recovery/root/system/bin/aera-audio-bootstrap" \
      "${TREE}/audio/aera_audio_bridge.cpp" \
      "${TREE}/audio/Android.bp" \
      "${TREE}/device.mk"; do
    newest="$(ls -1t "${file}".bak-t10-* 2>/dev/null | head -1)"
    if [ -n "${newest}" ]; then
      cp -a "${newest}" "${file}" && echo "restored ${file} <- ${newest}"
    fi
  done
  rm -f "${TREE}/audio/aera_palplayer.cpp" "${TREE}/audio/aera_aw_hal.c"
  echo "revert done"
  exit 0
fi

# ---------------------------------------------------------------------------
# 1) install new sources
# ---------------------------------------------------------------------------
note "1) installing aera-palplayer / aera-aw-hal sources"
run cp -f "${SRC}/aera_palplayer.cpp" "${TREE}/audio/aera_palplayer.cpp"
run cp -f "${SRC}/aera_aw_hal.c" "${TREE}/audio/aera_aw_hal.c"

# ---------------------------------------------------------------------------
# 2) patch Android.bp
# ---------------------------------------------------------------------------
note "2) patching audio/Android.bp"
BP="${TREE}/audio/Android.bp"
if grep -q 'name: "aera-palplayer"' "${BP}"; then
  echo "   Android.bp already contains aera-palplayer"
else
  backup "${BP}"
  if [ "${MODE}" = dry ]; then
    echo "[dry] append aera-palplayer + aera-aw-hal cc_binary blocks to ${BP}"
  else
    cat >> "${BP}" <<'BPEOF'

// AERA-T10: dedicated stock-A17 PAL consumer. Runs in its own process with
// LD_LIBRARY_PATH pointing at /AERA/audio/abi first, so the stock A17 PAL
// runtime is isolated from the AOSP16 recovery C++/binder runtime.
cc_binary {
    name: "aera-palplayer",
    recovery: true,
    srcs: ["aera_palplayer.cpp"],
    shared_libs: ["libdl", "liblog"],
    cpp_std: "c++17",
    cflags: [
        "-Wall",
        "-Wextra",
        "-Werror",
    ],
}

// AERA-T10: Awinic HAL probe/fallback (diagnostic; not started by default).
cc_binary {
    name: "aera-aw-hal",
    recovery: true,
    srcs: ["aera_aw_hal.c"],
    shared_libs: ["libdl"],
    cflags: [
        "-Wall",
        "-Wextra",
        "-Werror",
    ],
}
BPEOF
    echo "   appended cc_binary blocks"
  fi
fi

# ---------------------------------------------------------------------------
# 3) patch bridge: spawn aera-palplayer for --play-fifo children
# ---------------------------------------------------------------------------
note "3) patching audio/aera_audio_bridge.cpp (palplayer hand-off)"
BRIDGE="${TREE}/audio/aera_audio_bridge.cpp"
if grep -q 'kPalPlayer' "${BRIDGE}"; then
  echo "   bridge already patches palplayer"
else
  backup "${BRIDGE}"
  if [ "${MODE}" = dry ]; then
    echo "[dry] add kPalPlayer + prefer it in StartPlayer()"
  else
    python3 - "$BRIDGE" <<'PY'
import sys
path = sys.argv[1]
text = open(path).read()
anchor = 'constexpr char kSelf[] = "/proc/self/exe";\n'
assert anchor in text, "kSelf anchor not found"
text = text.replace(
    anchor,
    anchor +
    '/* AERA-T10: dedicated stock-A17 PAL consumer (separate process). */\n'
    'constexpr char kPalPlayer[] = "/system/bin/aera-palplayer";\n',
    1)
old = ('  execl(kSelf, "aera-audio-bridge", "--play-fifo", fifo.c_str(), '
       'nullptr);\n  _exit(127);\n')
assert old in text, "play-fifo exec anchor not found"
new = ('  /* AERA-T10: the FIFO is consumed by the dedicated A17 PAL player so\n'
       '   * the bridge keeps the AOSP16 recovery C++/binder runtime. Keep the\n'
       '   * in-binary player as a fallback for older ramdisk builds. */\n'
       '  execl(kPalPlayer, "aera-palplayer", "--fifo", fifo.c_str(), nullptr);\n'
       '  execl(kSelf, "aera-audio-bridge", "--play-fifo", fifo.c_str(),\n'
       '        nullptr);\n'
       '  _exit(127);\n')
text = text.replace(old, new, 1)
open(path, "w").write(text)
print("   bridge patched")
PY
  fi
fi

# ---------------------------------------------------------------------------
# 4) patch device.mk (PRODUCT_PACKAGES)
# ---------------------------------------------------------------------------
note "4) patching device.mk"
MK="${TREE}/device.mk"
if grep -q 'aera-palplayer' "${MK}"; then
  echo "   device.mk already lists aera-palplayer"
else
  backup "${MK}"
  if [ "${MODE}" = dry ]; then
    echo "[dry] add aera-palplayer + aera-aw-hal to PRODUCT_PACKAGES"
  else
    python3 - "${MK}" <<'PY'
import sys
path = sys.argv[1]
text = open(path).read()
old = ('# AERA native audio (official AudioReach/PAL port, batch3)\n'
       'PRODUCT_PACKAGES += \\\n'
       '    aera-audio-bridge \\\n'
       '    aera-audio-service\n')
assert old in text, "device.mk PRODUCT_PACKAGES audio block not found"
new = ('# AERA native audio (official AudioReach/PAL port, batch3)\n'
       'PRODUCT_PACKAGES += \\\n'
       '    aera-audio-bridge \\\n'
       '    aera-audio-service \\\n'
       '    aera-palplayer \\\n'
       '    aera-aw-hal\n')
text = text.replace(old, new, 1)
open(path, "w").write(text)
print("   device.mk patched")
PY
  fi
fi

# ---------------------------------------------------------------------------
# 5) patch bootstrap: /vendor/etc mixer compat overlay (fixes PAL SIGABRT)
# ---------------------------------------------------------------------------
note "5) patching aera-audio-bootstrap (vendor mixer compat overlay)"
BOOT="${TREE}/recovery/root/system/bin/aera-audio-bootstrap"
if grep -q 'prepare_vendor_mixer_compat()' "${BOOT}"; then
  echo "   bootstrap already patches the mixer compat overlay"
else
  backup "${BOOT}"
  if [ "${MODE}" = dry ]; then
    echo "[dry] insert prepare_vendor_mixer_compat + call before AGM services"
  else
    python3 - "${BOOT}" <<'PY'
import sys
path = sys.argv[1]
text = open(path).read()

func = '''
# AERA-T10: stock PAL (AudioReach) expects the legacy flat mixer/resourcemanager
# XMLs directly under /vendor/etc:
#   /vendor/etc/mixer_paths_canoe_qrd.xml   (variant from snd_card_name)
#   /vendor/etc/mixer_paths_canoe.xml       (variant-less fallback)
# Stock Android creates that view at first boot; recovery does not, so PAL's
# ResourceManager::init_audio fails (-22) and libc++abi terminates the AGM host
# with SIGABRT. Build a tiny overlayfs view of /vendor/etc and add the flat
# legacy names, without touching the read-only vendor partition.
prepare_vendor_mixer_compat() {
    [ -e /vendor/etc/mixer_paths_canoe_qrd.xml ] && return 0
    sku=/vendor/etc/audio/sku_canoe
    if [ ! -d "${sku}" ]; then
        echo "AERA audio: WARN missing ${sku}; cannot create PAL mixer compat view"
        return 0
    fi
    upper=/tmp/aera-vendor-etc-upper
    work=/tmp/aera-vendor-etc-work
    merged=/tmp/aera-vendor-etc-merged
    mkdir -p "${upper}" "${work}" "${merged}" 2>/dev/null || true
    if grep -q " ${merged} overlay " /proc/mounts; then
        echo "AERA audio: PAL mixer compat overlay already mounted"
        return 0
    fi
    # Legacy flat names used by stock PAL ResourceManager.
    for name in mixer_paths_canoe_qrd.xml resourcemanager_canoe_qrd.xml \\
                plugin_manager.xml audio_module_config_primary.xml \\
                mcs_defs_canoe_qrd.xml mixer_paths_canoe_qrd_wsa884x.xml; do
        [ -f "${sku}/${name}" ] && ln -sf "${sku}/${name}" "${upper}/${name}" 2>/dev/null
    done
    # Variant-less fallbacks map to the QRD variant of this SKU.
    [ -f "${sku}/mixer_paths_canoe_qrd.xml" ] && \\
        ln -sf "${sku}/mixer_paths_canoe_qrd.xml" "${upper}/mixer_paths_canoe.xml" 2>/dev/null
    [ -f "${sku}/resourcemanager_canoe_qrd.xml" ] && \\
        ln -sf "${sku}/resourcemanager_canoe_qrd.xml" "${upper}/resourcemanager_canoe.xml" 2>/dev/null
    if ! mount -t overlay overlay \\
        -o "lowerdir=/vendor/etc,upperdir=${upper},workdir=${work}" \\
        "${merged}" 2>/dev/null; then
        echo "AERA audio: WARN overlayfs mount failed; PAL mixer_paths will stay missing"
        return 0
    fi
    if ! mount -o bind "${merged}" /vendor/etc 2>/dev/null; then
        echo "AERA audio: WARN could not bind mixer compat overlay onto /vendor/etc"
        return 0
    fi
    if [ -e /vendor/etc/mixer_paths_canoe_qrd.xml ]; then
        echo "AERA audio: vendor mixer compat overlay ready"
    else
        echo "AERA audio: WARN mixer compat overlay did not expose legacy names"
    fi
}
'''

anchor = 'if [ "${vendor_is_mounted}" = 1 ]; then\n'
assert anchor in text, "vendor branch anchor not found"
text = text.replace(anchor, func + "\n" + anchor, 1)

call_anchor = ('if [ "${vendor_is_mounted}" = 0 ] && '
               '[ -d "${vendor_root}/lib/rfsa/adsp" ] &&\n')
assert call_anchor in text, "post-vendor anchor not found"
text = text.replace(
    call_anchor,
    'prepare_vendor_mixer_compat\n\n' + call_anchor, 1)
open(path, "w").write(text)
print("   bootstrap patched")
PY
  fi
fi

# ---------------------------------------------------------------------------
# 6) report
# ---------------------------------------------------------------------------
note "done (stamp=${STAMP})"
cat <<'TXT'

Build/flash (maintainer):
  bash /root/aera-worktree/build-batch.sh        # or the usual build command
  flash recovery_b only

Verify after boot:
  cat /tmp/aera-audio.log | tail -40       # expect "vendor mixer compat overlay ready"
  ls -l /vendor/etc/mixer_paths_canoe_qrd.xml /vendor/etc/mixer_paths_canoe.xml
  getprop init.svc.aera-agm-service        # expect running, no SIGABRT restart loop
  logcat -d | grep -iE 'libc\+\+abi|SIGABRT|init_audio|mixer_paths' | tail -20
  /system/bin/aera-audio-bridge --browser-audio &   # then artillery/browser
  cat /proc/asound/card0/pcm*/sub0/status  # expect RUNNING while playing
  dmesg | grep -iE 'aw882xx_start_pa|start success' | tail -10

Ownership/rollback: every changed file has a .bak-t10-<stamp> backup; run
  bash apply-audio-t10.sh --revert
TXT
