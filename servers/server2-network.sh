#!/usr/bin/env bash
# =============================================================================
# Server2 (Dell PER630) — Fedora Network Configuration
# =============================================================================
# VLAN:       VLAN20 (Server2 LAN)
# IP:         10.20.20.2/24 static
# Gateway:    10.20.20.1
# DNS:        10.20.20.1 (Pi-hole via router)
# Bond:       bond0 — active-backup (primary NIC TBD, slave NIC TBD)
# AMP port:   10.20.20.3/24 static (second NIC, separate connection — no bond)
#
# Router port mapping (RB3011):
#   ether4-SRV2-NIC1  →  primary NIC (bond primary)
#   ether5-SRV2-NIC2  →  slave NIC (bond slave) OR AMP dedicated port
#
# NIC MACs:
#   NIC1 (bond primary): 24:6e:96:ab:39:ed
#   NIC2 (AMP/spare):    24:6e:96:ab:39:ec
#   iDRAC USB:           TBD
#
# NOTE: Server2 bonding not yet configured.
#       Run ip addr show on Server2 to confirm NIC interface names
#       (likely eno3/eno4 same as Server1) before applying.
#
# Run as root or with sudo.
# =============================================================================

set -euo pipefail

echo "Server2 network setup — NOT YET IMPLEMENTED"
echo "Confirm interface names on Server2 before running:"
echo "  ip addr show"
echo "  nmcli connection show"
exit 1

# =============================================================================
# Template — edit interface names before uncommenting and running
# =============================================================================

# BOND_PRIMARY="eno3"      # confirm on Server2
# BOND_SLAVE="eno4"        # confirm on Server2
# BOND_IP="10.20.20.2/24"
# BOND_GW="10.20.20.1"
# BOND_DNS="10.20.20.1"

# Remove auto-generated connections
# for conn in "Wired connection 1" "Wired connection 2" "Wired connection 3" \
#             "Wired connection 4" "Wired connection 5"; do
#     nmcli connection delete "$conn" 2>/dev/null || true
# done

# Create bond0
# nmcli connection add \
#     type bond \
#     con-name server2-bond0 \
#     ifname bond0 \
#     bond.options "mode=active-backup,miimon=100,primary=${BOND_PRIMARY}" \
#     ipv4.method manual \
#     ipv4.addresses "${BOND_IP}" \
#     ipv4.gateway "${BOND_GW}" \
#     ipv4.dns "${BOND_DNS}" \
#     ipv4.ignore-auto-dns yes \
#     ipv6.method disabled \
#     connection.mdns no \
#     connection.llmnr no \
#     connection.lldp disable \
#     802-3-ethernet.wake-on-lan none \
#     connection.autoconnect yes

# Add primary slave
# nmcli connection add \
#     type ethernet \
#     con-name server2-bond0-eno3 \
#     ifname "${BOND_PRIMARY}" \
#     master bond0 \
#     connection.slave-type bond \
#     ipv4.method disabled \
#     ipv6.method disabled \
#     802-3-ethernet.wake-on-lan none \
#     connection.autoconnect yes

# Add secondary slave
# nmcli connection add \
#     type ethernet \
#     con-name server2-bond0-eno4 \
#     ifname "${BOND_SLAVE}" \
#     master bond0 \
#     connection.slave-type bond \
#     ipv4.method disabled \
#     ipv6.method disabled \
#     802-3-ethernet.wake-on-lan none \
#     connection.autoconnect yes

# Configure iDRAC USB NIC
# nmcli connection add \
#     type ethernet \
#     con-name server2-idrac \
#     ifname idrac \
#     ipv4.method manual \
#     ipv4.addresses 169.254.0.2/24 \
#     ipv4.never-default yes \
#     ipv6.method disabled \
#     connection.mdns no \
#     connection.llmnr no \
#     connection.lldp disable \
#     802-3-ethernet.wake-on-lan none \
#     connection.autoconnect yes

# Bring up
# nmcli connection up server2-bond0-eno3
# nmcli connection up server2-bond0-eno4
# nmcli connection up server2-bond0
# nmcli connection up server2-idrac
