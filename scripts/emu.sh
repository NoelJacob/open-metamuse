#!/usr/bin/env bash
# Pixel_9 emulator lifecycle for the Muse parity work.
# Usage: emu.sh start|wait|status|stop|restart
set -u
AVD=Pixel_9
DEV=emulator-5554
LOG=/tmp/emu-pixel9.log
case "${1:-status}" in
  start)
    if adb devices 2>/dev/null | grep -q "$DEV[[:space:]].*device$"; then
      echo "$DEV already online"; exit 0
    fi
    rm -f "$LOG"
    nohup emulator @"$AVD" -no-window -no-snapshot -memory 1536 -scale 0.5 \
      -no-boot-anim -gpu host > "$LOG" 2>&1 &
    echo "booting $AVD (log $LOG)"
    ;;
  wait)
    for _ in $(seq 1 40); do
      if adb devices 2>/dev/null | grep -q "$DEV[[:space:]].*device$"; then
        if timeout 20 adb -s "$DEV" shell 'echo ok' 2>/dev/null | grep -q ok; then
          echo "$DEV online + shell ok"; exit 0
        fi
      fi
      sleep 15
    done
    echo "$DEV not ready" >&2; exit 1
    ;;
  status)
    timeout 20 adb devices; timeout 20 adb -s "$DEV" shell 'echo ok' 2>&1 | tail -n 1
    ;;
  stop)
    timeout 20 adb -s "$DEV" emu kill 2>/dev/null || pkill -f "emulator.*$AVD"
    echo stopped
    ;;
  restart)
    "$0" stop; sleep 5; "$0" start
    ;;
esac
