#!/usr/bin/env bash
# =============================================================================
# Server1 (Dell PER730XD) — Fedora Network Configuration
# =============================================================================
# VLAN:       VLAN10 (Server1 LAN)
# IP:         10.10.10.2/24 static
# Gateway:    10.10.10.1
# DNS:        10.10.10.1 (Pi-hole via router)
# Bond:       bond0 — active-backup (eno3 primary, eno4 slave)
# iDRAC USB:  169.254.0.2/24 static, never-default
#
# Router port mapping (RB3011):
#   ether2-SRV1-NIC1  →  eno3  (bond primary)
#   ether3-SRV1-NIC2  →  eno4  (bond slave)
#   ether6-iDRAC1     →  iDRAC dedicated port (VLAN30)
#
# NIC MACs:
#   eno3:  24:6e:96:27:91:44
#   eno4:  24:6e:96:27:91:45
#   iDRAC USB: 44:a8:42:4b:bf:96
#
# Run as root or with sudo.
# Safe to re-run — delete commands are idempotent (ignore errors if missing).
# =============================================================================

set -euo pipefail

echo "=== Server1 network setup starting ==="

# -----------------------------------------------------------------------------
# STEP 1: Remove all auto-generated connections
# -----------------------------------------------------------------------------
echo "--- Removing auto-generated connections ---"
for conn in "Wired connection 1" "Wired connection 2" "Wired connection 3" \
            "Wired connection 4" "Wired connection 5"; do
    nmcli connection delete "$conn" 2>/dev/null && echo "Deleted: $conn" \
        || echo "Not found (ok): $conn"
done

# -----------------------------------------------------------------------------
# STEP 2: Create bond0 — active-backup, static 10.10.10.2/24
# -----------------------------------------------------------------------------
echo "--- Creating bond0 ---"
nmcli connection add \
    type bond \
    con-name server1-bond0 \
    ifname bond0 \
    bond.options "mode=active-backup,miimon=100,primary=eno3" \
    ipv4.method manual \
    ipv4.addresses 10.10.10.2/24 \
    ipv4.gateway 10.10.10.1 \
    ipv4.dns 10.10.10.1 \
    ipv4.ignore-auto-dns yes \
    ipv6.method disabled \
    connection.mdns no \
    connection.llmnr no \
    connection.lldp disable \
    802-3-ethernet.wake-on-lan none \
    connection.autoconnect yes

# -----------------------------------------------------------------------------
# STEP 3: Add eno3 as bond primary slave
# -----------------------------------------------------------------------------
echo "--- Adding eno3 as bond primary slave ---"
nmcli connection add \
    type ethernet \
    con-name server1-bond0-eno3 \
    ifname eno3 \
    master bond0 \
    connection.slave-type bond \
    ipv4.method disabled \
    ipv6.method disabled \
    802-3-ethernet.wake-on-lan none \
    connection.autoconnect yes

# -----------------------------------------------------------------------------
# STEP 4: Add eno4 as bond secondary slave
# -----------------------------------------------------------------------------
echo "--- Adding eno4 as bond secondary slave ---"
nmcli connection add \
    type ethernet \
    con-name server1-bond0-eno4 \
    ifname eno4 \
    master bond0 \
    connection.slave-type bond \
    ipv4.method disabled \
    ipv6.method disabled \
    802-3-ethernet.wake-on-lan none \
    connection.autoconnect yes

# -----------------------------------------------------------------------------
# STEP 5: Configure iDRAC USB NIC — static 169.254.0.2, never default
# -----------------------------------------------------------------------------
echo "--- Configuring iDRAC USB NIC ---"
nmcli connection add \
    type ethernet \
    con-name server1-idrac \
    ifname idrac \
    ipv4.method manual \
    ipv4.addresses 169.254.0.2/24 \
    ipv4.never-default yes \
    ipv6.method disabled \
    connection.mdns no \
    connection.llmnr no \
    connection.lldp disable \
    802-3-ethernet.wake-on-lan none \
    connection.autoconnect yes

# -----------------------------------------------------------------------------
# STEP 6: Bring everything up
# -----------------------------------------------------------------------------
echo "--- Bringing up connections ---"
nmcli connection up server1-bond0-eno3
nmcli connection up server1-bond0-eno4
nmcli connection up server1-bond0
nmcli connection up server1-idrac

# -----------------------------------------------------------------------------
# STEP 7: Verify
# -----------------------------------------------------------------------------
echo ""
echo "=== Verification ==="
echo "--- Bond status ---"
cat /proc/net/bonding/bond0

echo ""
echo "--- IP addresses ---"
ip addr show bond0
ip addr show idrac

echo ""
echo "--- Routes ---"
ip route

echo ""
echo "--- Connectivity ---"
ping -c2 -W2 10.10.10.1 && echo "Router: OK" || echo "Router: FAIL"
ping -c2 -W2 8.8.8.8    && echo "Internet: OK" || echo "Internet: FAIL"

echo ""
echo "=== Server1 network setup complete ==="
