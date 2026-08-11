#!/system/bin/sh
# ==============================================================================
# OnyxZygisk · late-start service stage
#
# Mirrors service.sh for classic Zygisk modules when their lifecycle is not
# already managed by Magisk's built-in Zygisk implementation.
# ==============================================================================

DEBUG=@DEBUG@

MODDIR=${0%/*}
if [ "$ZYGISK_ENABLED" ]; then
  exit 0
fi

# ── Boot-loop fail-safe: health witness ───────────────────────────────────────
# zygisk-init.sh increments a counter on every boot; reaching this point plus
# a grace window proves the boot was healthy, so the counter resets. A boot
# loop kills the device before the sleep ends, the counter survives, and the
# injection kill switch eventually latches (see zygisk-init.sh).
(
  sleep 120
  rm -f "@WORK_DIRECTORY@/boot_fail_count"
  if [ -f "@WORK_DIRECTORY@/injection_disabled" ]; then
    log -p w -t "zygisk-sh" "Boot-loop fail-safe is latched; injection stays OFF until @WORK_DIRECTORY@/injection_disabled is removed"
  fi
) &

cd "$MODDIR"

if [ "$(which magisk)" ]; then
  for file in ../*; do
    if [ -d "$file" ] && [ -d "$file/zygisk" ] && ! [ -f "$file/disable" ]; then
      if [ -f "$file/service.sh" ]; then
        cd "$file"
        log -p i -t "zygisk-sh" "Manually trigger service.sh for $file"
        sh "$(realpath ./service.sh)" &
        cd "$MODDIR"
      fi
    fi
  done
fi
