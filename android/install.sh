#!/data/data/com.termux/files/usr/bin/sh
BASE="$HOME/moonlight-mux"
MUX="$BASE/sakuramux_moonlight_linux_arm64"
URL="https://nya.globalslb.net/natfrp/client/mux/moonlight/1.0.1/sakuramux_moonlight_linux_arm64"
mkdir -p "$BASE/logs"
echo "=== Moonlight MUX / Termux installer ==="
printf "SakuraFrp public host: "; read -r HOST
printf "SakuraFrp public TCP port: "; read -r PORT
printf "MUX key: "; read -r KEY
[ -n "$HOST" ] && [ -n "$PORT" ] && [ -n "$KEY" ] || { echo "All values are required."; exit 1; }
echo "Downloading official MUX 1.0.1 ARM64..."
if command -v curl >/dev/null 2>&1; then curl -fL --retry 3 -o "$MUX" "$URL" || exit 1
elif command -v wget >/dev/null 2>&1; then wget -O "$MUX" "$URL" || exit 1
else echo "Install curl or wget first."; exit 1; fi
chmod 700 "$MUX"
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
cp "$SCRIPT_DIR/mux.sh" "$BASE/mux.sh"; chmod 700 "$BASE/mux.sh"
"$BASE/mux.sh" setup "$HOST" "$PORT" "$KEY"
mkdir -p "$HOME/.termux/boot"
cp "$SCRIPT_DIR/termux-boot/start-moonlight-mux" "$HOME/.termux/boot/start-moonlight-mux"
chmod 700 "$HOME/.termux/boot/start-moonlight-mux"
echo "Done. Use: $BASE/mux.sh start"
echo "Moonlight host: 127.0.0.1"
echo "Open Termux:Boot once, then reboot to test."
