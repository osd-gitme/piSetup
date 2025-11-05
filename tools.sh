#!/usr/bin/env bash
# =========================================================
# Raspberry Pi Setup Script
# - Assigns static IP dynamically via parameter (101–116)
# - Installs required tools: net-tools, python3
# - Ensures network service is active (systemd-networkd or fallback)
# - Designed for Git clone or curl execution
# =========================================================
# Author: Steven Hanks
# Repository: https://github.com/osd-gitme/piSetup
# =========================================================

set -euo pipefail

# ---- CONFIG ----
NETWORK_IFACE="wlan0"        # Change to eth0 for wired setups
BASE_IP="192.168.1"
GATEWAY="192.168.1.1"
DNS1="1.1.1.1"
DNS2="8.8.8.8"
SSID="4DF Net 3"
PASSWORD="psyopPSYOP@@"
NETPLAN_FILE="/etc/netplan/50-cloud-init.yaml"
# ----------------

# ---- 1. Parse & validate IP input ----
if [[#!/usr/bin/env bash
# =========================================================
# Raspberry Pi Setup Script
# - Assigns static IP dynamically via parameter (101–116)
# - Installs required tools: net-tools, python3
# - Ensures network service is active (systemd-networkd or fallback)
# - Designed for Git clone or curl execution
# =========================================================
# Author: Steven Hanks
# Repository: https://github.com/osd-gitme/piSetup
# =========================================================

set -euo pipefail

# ---- CONFIG ----
NETWORK_IFACE="wlan0"        # Change to eth0 for wired setups
BASE_IP="192.168.1"
GATEWAY="192.168.1.1"
DNS1="1.1.1.1"
DNS2="8.8.8.8"
SSID="4DF Net 3"
PASSWORD="psyopPSYOP@@"
NETPLAN_FILE="/etc/netplan/50-cloud-init.yaml"
# ----------------

# ---- 1. Parse & validate IP input ----
if [[ $# -lt 1 ]]; then
  read -rp "Enter last octet for static IP (101–116): " LAST_OCTET
else
  LAST_OCTET="$1"
fi

# Validate range (101–116)
if ! [[ "$LAST_OCTET" =~ ^[0-9]+$ ]] || (( LAST_OCTET < 101 || LAST_OCTET > 116 )); then
  echo "[!] Invalid IP range. Please choose a value between 101 and 116."
  exit 1
fi

STATIC_IP="${BASE_IP}.${LAST_OCTET}/24"

echo "=== Raspberry Pi Static IP Setup ==="
echo "[*] Configuring static IP: ${STATIC_IP}"

# ---- 2. Require sudo ----
if [[ $EUID -ne 0 ]]; then
  echo "[!] Please run as root (use: sudo bash tools <octet>)"
  exit 1
fi

# ---- 3. Install dependencies ----
echo "[*] Installing dependencies (net-tools, python3, network service)..."
apt-get update -y
apt-get install -y net-tools python3 || true

# Try to install or verify systemd-networkd
if apt-cache show systemd-networkd >/dev/null 2>&1; then
  apt-get install -y systemd-networkd
  echo "[*] systemd-networkd package installed or already present."
else
  echo "[i] systemd-networkd package not found — assuming service is included."
fi

# Enable network service if present
 $# -lt 1 ]]; then
  read -rp "Enter last octet for static IP (101–116): " LAST_OCTET
else
  LAST_OCTET="$1"
fi

# Validate range (101–116)
if ! [[ "$LAST_OCTET" =~ ^[0-9]+$ ]] || (( LAST_OCTET < 101 || LAST_OCTET > 116 )); then
  echo "[!] Invalid IP range. Please choose a value between 101 and 116."
  exit 1
fi

STATIC_IP="${BASE_IP}.${LAST_OCTET}/24"

echo "=== Raspberry Pi Static IP Setup ==="
echo "[*] Configuring static IP: ${STATIC_IP}"

# ---- 2. Require sudo ----
if [[ $EUID -ne 0 ]]; then
  echo "[!] Please run as root (use: sudo bash tools <octet>)"
  exit 1
fi

# ---- 3. Install dependencies ----
echo "[*] Installing dependencies (net-tools, python3, network service)..."
apt-get update -y
apt-get install -y net-tools python3 || true

# Try to install or verify systemd-networkd
if apt-cache show systemd-networkd >/dev/null 2>&1; then
  apt-get install -y systemd-networkd
  echo "[*] systemd-networkd package installed or already present."
else
  echo "[i] systemd-networkd package not found — assuming service is included."
fi

# Enable network service if present
systemctl enable systemd-networkd 2>/dev/null || echo "[i] systemd-networkd enable skipped."
systemctl start systemd-networkd 2>/dev/null || echo "[i] systemd-networkd start skipped."

# ---- 4. Write netplan configuration ----
echo "[*] Writing Netplan config to ${NETPLAN_FILE}..."

cat > "$NETPLAN_FILE" <<EOF
network:
  version: 2
  renderer: networkd
  wifis:
    ${NETWORK_IFACE}:
      dhcp4: no
      addresses:
        - ${STATIC_IP}
      routes:
        - to: default
          via: ${GATEWAY}
      nameservers:
        addresses:
          - ${DNS1}
          - ${DNS2}
      access-points:
        "${SSID}":
          password: "${PASSWORD}"
EOF

# ---- 5. Apply network configuration ----
echo "[*] Applying Netplan..."
netplan apply || {
  echo "[!] Netplan apply failed. Attempting NetworkManager fallback..."
  sed -i 's/renderer: networkd/renderer: NetworkManager/' "$NETPLAN_FILE"
  netplan apply || echo "[!] Fallback failed — check /etc/netplan/50-cloud-init.yaml manually."
}

# ---- 6. Verify installation ----
echo "[*] Verifying installation..."
sleep 3

echo "Installed tools:"
command -v ifconfig >/dev/null && echo "  ✓ net-tools installed" || echo "  ✗ net-tools missing"
command -v python3 >/dev/null && echo "  ✓ python3 installed" || echo "  ✗ python3 missing"

echo
echo "[*] Current network state for ${NETWORK_IFACE}:"
ip a show "${NETWORK_IFACE}" | grep "inet " || echo "[!] No IP assigned (check Wi-Fi credentials)."

# ---- 7. Save success log ----
LOG_FILE="/var/log/piSetup.log"
echo "$(date): Setup complete. Assigned IP ${STATIC_IP}" | tee -a "$LOG_FILE"

echo
echo "✅ Setup complete! This Pi now has static IP ${STATIC_IP}"
echo "🪵 Log saved to: ${LOG_FILE}"
