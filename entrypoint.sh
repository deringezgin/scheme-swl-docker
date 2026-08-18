#!/usr/bin/env bash
set -euo pipefail

Xvfb :99 -screen 0 1280x800x24 -ac -nolisten tcp > /tmp/xvfb.log 2>&1 &

for _ in {1..100}; do
  [[ -S /tmp/.X11-unix/X99 ]] && break
  sleep 0.05
done

if [[ ! -S /tmp/.X11-unix/X99 ]]; then
  echo "Xvfb failed to start; see /tmp/xvfb.log" >&2
  exit 1
fi

fluxbox > /tmp/fluxbox.log 2>&1 &
x11vnc -display :99 -forever -shared -nopw -rfbport 5900 \
  -listen 127.0.0.1 -bg -o /tmp/x11vnc.log
websockify --web=/usr/share/novnc 6000 localhost:5900 \
  > /tmp/websockify.log 2>&1 &

exec swl
