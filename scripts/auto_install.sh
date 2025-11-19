#!/bin/bash
# Zeek Auto Installer for Ubuntu 24.04
# Run as root on each node (manager and workers).

set -e

echo "=== Zeek Auto Installer (Ubuntu 24.04) ==="

echo "[*] Adding Zeek repository..."
echo 'deb http://download.opensuse.org/repositories/security:/zeek/xUbuntu_24.04/ /' | tee /etc/apt/sources.list.d/security:zeek.list
curl -fsSL https://download.opensuse.org/repositories/security:zeek/xUbuntu_24.04/Release.key | gpg --dearmor | tee /etc/apt/trusted.gpg.d/security_zeek.gpg > /dev/null

echo "[*] Updating package index..."
apt update

echo "[*] Installing Zeek..."
apt install -y zeek

# Ensure setcap is available
if ! command -v setcap >/dev/null 2>&1; then
  echo "[*] Installing libcap2-bin (provides setcap)..."
  apt install -y libcap2-bin
fi

# Add Zeek to PATH (system-wide)
if ! grep -q "/opt/zeek/bin" /etc/profile; then
  echo "[*] Adding /opt/zeek/bin to PATH via /etc/profile..."
  echo 'export PATH="$PATH:/opt/zeek/bin"' >> /etc/profile
fi

# Apply capabilities
if [ -f /opt/zeek/bin/zeek ]; then
  echo "[*] Applying capabilities to /opt/zeek/bin/zeek..."
  setcap cap_net_raw,cap_net_admin=+eip /opt/zeek/bin/zeek || echo "Warning: setcap failed, check libcap2-bin and filesystem support."
else
  echo "Warning: /opt/zeek/bin/zeek not found. Verify installation."
fi

# Apply sysctl tuning if config exists relative to script path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/../configs/sysctl-zeek.conf" ]; then
  echo "[*] Installing sysctl tuning..."
  cp "$SCRIPT_DIR/../configs/sysctl-zeek.conf" /etc/sysctl.d/99-zeek.conf
  sysctl -p /etc/sysctl.d/99-zeek.conf || echo "Warning: sysctl apply failed, please review 99-zeek.conf."
else
  echo "Note: sysctl-zeek.conf not found in ../configs; skipping sysctl install."
fi

echo
echo "=== Zeek installation complete. Next steps: ==="
echo "1) Configure /opt/zeek/etc/node.cfg on the manager (see configs/node.cfg.example)."
echo "2) Set up passwordless SSH from MANAGER_IP to WORKER1_IP and WORKER2_IP."
echo "3) Deploy disable-offload.service on worker nodes if desired."
echo "4) Run 'zeekctl deploy' from the manager."
