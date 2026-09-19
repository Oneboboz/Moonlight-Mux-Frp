#!/data/data/com.termux/files/usr/bin/sh
BASE="$HOME/moonlight-mux"
MUX="$BASE/sakuramux_moonlight_linux_arm64"
CONF="$BASE/mux.env"
PIDFILE="$BASE/mux.pid"
LOGDIR="$BASE/logs"
LOG="$LOGDIR/mux.log"
IPFILE="$BASE/server.ip"
mkdir -p "$LOGDIR"

load_config() {
  [ -f "$CONF" ] || { echo "Config not found: $CONF"; echo "Run: $0 setup PUBLIC_HOST PUBLIC_PORT KEY"; return 1; }
  . "$CONF"
}
is_running() {
  [ -f "$PIDFILE" ] || return 1
  pid="$(cat "$PIDFILE" 2>/dev/null)"
  [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null
}
resolve_ipv4() {
  ip="$(ping -c 1 -W 2 "$1" 2>/dev/null | sed -n '1{s/^[^(]*(\([0-9][0-9.]*\)).*/\1/;p;q;}')"
  case "$ip" in ''|*[!0-9.]*) ip="" ;;
  esac
  if [ -n "$ip" ]; then
    echo "$ip" > "$IPFILE"
    echo "$ip"
    return 0
  fi
  [ -s "$IPFILE" ] && cat "$IPFILE" && return 0
  return 1
}
setup() {
  [ -n "$1" ] && [ -n "$2" ] && [ -n "$3" ] || { echo "Usage: $0 setup PUBLIC_HOST PUBLIC_PORT KEY"; return 2; }
  cat > "$CONF" <<EOF
MUX_HOST='$1'
MUX_PORT='$2'
MUX_KEY='$3'
EOF
  chmod 600 "$CONF"
  echo "Configuration saved. Key hidden."
}
start() {
  load_config || return 1
  [ -x "$MUX" ] || { echo "MUX binary not found: $MUX"; return 1; }
  if is_running; then echo "MUX: RUNNING (PID $(cat "$PIDFILE"))"; return 0; fi
  ip="$(resolve_ipv4 "$MUX_HOST")" || { echo "Could not resolve $MUX_HOST to IPv4."; return 1; }
  echo "Resolved $MUX_HOST -> $ip"
  nohup "$MUX" -mode client -key "$MUX_KEY" -local 127.0.0.1 -server "$ip:$MUX_PORT" -debug >> "$LOG" 2>&1 &
  pid=$!
  echo "$pid" > "$PIDFILE"
  sleep 1
  if is_running; then echo "MUX: RUNNING (PID $pid)"; return 0; fi
  echo "MUX failed to stay running:"; tail -n 30 "$LOG" 2>/dev/null
  rm -f "$PIDFILE"; return 1
}
stop() {
  if ! is_running; then rm -f "$PIDFILE"; echo "MUX: NOT RUNNING"; return 0; fi
  pid="$(cat "$PIDFILE")"; kill "$pid" 2>/dev/null; sleep 1
  kill -0 "$pid" 2>/dev/null && kill -9 "$pid" 2>/dev/null
  rm -f "$PIDFILE"; echo "MUX: STOPPED"
}
status() {
  load_config || return 1
  if is_running; then echo "MUX: RUNNING"; echo "PID: $(cat "$PIDFILE")"; else echo "MUX: STOPPED"; fi
  [ -s "$IPFILE" ] && echo "Server IP: $(cat "$IPFILE")"
  echo "Local ports: TCP 47984 47989 48010; UDP 47998 47999 48000 48002 48010"
}
logs() { tail -n 100 "$LOG"; }
case "${1:-}" in
  setup) setup "$2" "$3" "$4" ;;
  start) start ;;
  stop) stop ;;
  restart) stop; sleep 1; start ;;
  status) status ;;
  logs) logs ;;
  *) echo "Usage: $0 {setup|start|stop|restart|status|logs}"; exit 2 ;;
esac
