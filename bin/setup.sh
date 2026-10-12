#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
IMAGE_TAG="claudetanamo:latest"
ANCHOR_SRC="$ROOT_DIR/pf/claudetanamo.pf.conf"
ANCHOR_DEST="/etc/pf.anchors/claudetanamo"

echo "=== [Claudetánamo Bay] Init ==="

if ! command -v container >/dev/null 2>&1; then
  echo "[-] Error: Apple 'container' CLI not found in PATH." >&2
  exit 1
fi

if ! container system status >/dev/null 2>&1; then
  echo "[+] Starting container system..."
  container system start

  echo "[+] Waiting for container system readiness..."
  until container system status >/dev/null 2>&1; do
    sleep 0.5
  done
fi

echo "[+] Constructing cell image ($IMAGE_TAG)..."
HOST_UID="$(id -u)"
HOST_GID="$(id -g)"

container build \
  --build-arg USER_ID="${HOST_UID}" \
  --build-arg GROUP_ID="${HOST_GID}" \
  -t "$IMAGE_TAG" \
  -f "$ROOT_DIR/Containerfile" \
  "$ROOT_DIR"

echo "[+] Installing macOS pf anchor configuration..."
sudo cp "$ANCHOR_SRC" "$ANCHOR_DEST"
sudo chmod 644 "$ANCHOR_DEST"

# register anchor in /etc/pf.conf if missing
if ! grep -q 'anchor "claudetanamo"' /etc/pf.conf 2>/dev/null; then
  echo "[+] Registering anchor in /etc/pf.conf..."
  sudo cp /etc/pf.conf "/etc/pf.conf.backup.$(date +%Y%m%d%H%M%S)"
  echo "" | sudo tee -a /etc/pf.conf >/dev/null
  echo "# Claudetanamo jail anchor" | sudo tee -a /etc/pf.conf >/dev/null
  echo 'anchor "claudetanamo"' | sudo tee -a /etc/pf.conf >/dev/null
  echo 'load anchor "claudetanamo" from "/etc/pf.anchors/claudetanamo"' | sudo tee -a /etc/pf.conf >/dev/null
fi

echo "[+] Loading packet filter rules..."
sudo pfctl -vnf /etc/pf.conf
sudo pfctl -f /etc/pf.conf
sudo pfctl -a claudetanamo -f "$ANCHOR_DEST"
sudo pfctl -e 2>/dev/null || true

# reloading /etc/pf.conf drops the NAT rules vmnet installed for the VMs,
# so restart the container system to have them rebuilt
echo "[+] Restarting container system (stops running containers)..."
container system stop
container system start
until container system status >/dev/null 2>&1; do
  sleep 0.5
done

echo "=== Setup complete! ==="
