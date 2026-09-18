#!/data/data/com.termux/files/usr/bin/sh
set -e

REPO="https://github.com/Oneboboz/Moonlight-Mux-Frp.git"
BASE="$HOME/Moonlight-Mux-Frp"

echo "========================================"
echo " Moonlight MUX - Android One-Click Setup"
echo "========================================"
echo

if ! command -v git >/dev/null 2>&1; then
  echo "Git not found. Install it with:"
  echo "  pkg update && pkg install git"
  exit 1
fi

if [ -d "$BASE/.git" ]; then
  echo "[1/4] Updating existing repository..."
  git -C "$BASE" pull --ff-only
else
  echo "[1/4] Cloning repository..."
  git clone "$REPO" "$BASE"
fi

cd "$BASE/android"

echo "[2/4] Making scripts executable..."
chmod +x install.sh mux.sh termux-boot/start-moonlight-mux

echo "[3/4] Running Android installer..."
./install.sh

echo
echo "[4/4] Starting MUX..."
"$HOME/moonlight-mux/mux.sh" start

echo
echo "========================================"
echo " Installation finished"
echo "========================================"
echo "Status:"
"$HOME/moonlight-mux/mux.sh" status
echo
echo "Moonlight address: 127.0.0.1"
