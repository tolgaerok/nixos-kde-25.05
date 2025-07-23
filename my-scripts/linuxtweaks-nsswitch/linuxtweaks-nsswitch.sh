#!/bin/bash
# tolga erok
# 19/5/2025

# fix nsswitch issue

set -e

# Define the new configuration content
tweaked_nsswitch=$(cat <<'EOF'
# Name Service Switch configuration file.
# See nsswitch.conf(5) for details.
# Tolga Erok
# 13/3/2025
# BigLinux
# Optimized for speed while maintaining LAN connectivity
# -------------------------------------------------------------------------
#    files          → Fastest lookup (uses /etc/hosts first).
#    myhostname     → Ensures the local system name resolves quickly.
#    resolve        → Uses systemd-resolved caching for efficiency.
#    dns            → Queries external DNS if not found locally.
#    mdns4_minimal  → Enables LAN device discovery (Samba, printers, etc.).
# -------------------------------------------------------------------------
# sudo systemctl enable --now systemd-resolved && sudo systemctl restart avahi-daemon NetworkManager smb systemd-resolved

# Optional Tweaks
aliases: files                               # Resolves email aliases locally using /etc/aliases (fast).
ethers: files                                # Resolves MAC addresses locally using /etc/ethers (fast).
group: files [SUCCESS=merge] systemd         # Resolves groups first from local /etc/group, then uses systemd if necessary.
gshadow: files systemd                       # Resolves group shadow information locally, falls back to systemd for system groups.
netgroup: files                              # Resolves network groups locally using /etc/netgroup (fast).

# For network name resolution
networks: files resolve dns mdns4_minimal    # Resolves network names first from /etc/networks, then uses systemd-resolved, external DNS, and mDNS for local device discovery.

passwd: files systemd                        # Resolves user information first from local /etc/passwd, then from systemd for system users.
protocols: files                             # Resolves network protocols locally using /etc/protocols (fast).
publickey: files                             # Resolves public key information locally using /etc/ssh/ssh_known_hosts.
rpc: files                                   # Resolves RPC (remote procedure call) information locally from /etc/rpc (fast).
services: files                              # Resolves services locally using /etc/services (fast).
shadow: files systemd                        # Resolves shadow password information locally from /etc/shadow, falls back to systemd for system users.

# For hostname resolution
hosts: files myhostname resolve dns mdns4_minimal  # Resolves hostnames first from /etc/hosts, uses the system's hostname, systemd-resolved for DNS caching, external DNS if necessary, and mDNS for local network devices.

# OLD
# hosts: mymachines mdns_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] files myhostname dns

# BUG FIX TOLGA EROK
# The change from mdns_minimal to mdns4_minimal targets IPv4 mDNS for more modern and reliable local network resolution
# Apply and then:

# sudo systemctl restart avahi-daemon && sudo systemctl restart NetworkManager && sudo systemctl restart smb systemd-resolved
# hosts: mymachines mdns4_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] files myhostname dns

# Fedora version
# hosts: files myhostname mdns4_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] dns
EOF
)


echo "[*] Checking if authselect is managing /etc/nsswitch.conf..."

if authselect current | grep -q "Profile ID"; then
    echo "[*] Authselect is active. Opting out to allow manual nsswitch.conf editing..."
    sudo authselect opt-out
else
    echo "[*] Authselect is already opted out. Continuing..."
fi

# Backup existing nsswitch.conf
if [ ! -f /etc/nsswitch.conf.bak ]; then
    echo "[*] Creating backup: /etc/nsswitch.conf.bak"
    sudo cp /etc/nsswitch.conf /etc/nsswitch.conf.bak
else
    echo "[*] Backup already exists: /etc/nsswitch.conf.bak"
fi

# Replace contents with my custom config
echo "[*] Replacing /etc/nsswitch.conf with custom optimized configuration..."
echo "$tweaked_nsswitch" | sudo tee /etc/nsswitch.conf > /dev/null
sudo systemctl enable --now systemd-resolved && sudo systemctl restart avahi-daemon NetworkManager smb systemd-resolved
echo "[✓] /etc/nsswitch.conf successfully updated and ready for editing anytime."
