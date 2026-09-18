#!/data/data/com.termux/files/usr/bin/sh

MUX="$HOME/moonlight-mux/sakuramux_moonlight_linux_arm64"
KEY="CHANGE_ME"
SERVER="PUBLIC_HOST:PUBLIC_PORT"

exec "$MUX" \
  -mode client \
  -key "$KEY" \
  -local 127.0.0.1 \
  -server "$SERVER" \
  -debug
