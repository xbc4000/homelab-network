# Server Network Configuration

NIC bonding and static IP setup for Server1 (PER730XD) and Server2 (PER630).
Both servers run Fedora and use NetworkManager (`nmcli`) for network config.

---

## Overview

| Server | Model | VLAN | IP | Bond | Status |
|--------|-------|------|----|------|--------|
| Server1 | Dell PER730XD | VLAN10 | 10.10.10.2/24 | bond0 active-backup | ✅ Done |
| Server2 | Dell PER630 | VLAN20 | 10.20.20.2/24 | bond0 active-backup | ⏳ Pending |

---

## Server1 — Dell PER730XD

### Hardware

| Interface | MAC | Role |
|-----------|-----|------|
| eno3 | 24:6e:96:27:91:44 | Bond primary — router ether2-SRV1-NIC1 |
| eno4 | 24:6e:96:27:91:45 | Bond slave — router ether3-SRV1-NIC2 |
| eno1 | 24:6e:96:27:91:40 | Unused (no carrier) |
| eno2 | 24:6e:96:27:91:42 | Unused (no carrier) |
| idrac | 44:a8:42:4b:bf:96 | iDRAC USB NIC — 169.254.0.2/24 |

### Router Port Mapping

```
RB3011 ether2-SRV1-NIC1  (VLAN10, pvid=10)  →  Server1 eno3  (bond primary)
RB3011 ether3-SRV1-NIC2  (VLAN10, pvid=10)  →  Server1 eno4  (bond slave)
RB3011 ether6-iDRAC1     (VLAN30, pvid=30)  →  Server1 iDRAC dedicated port
```

### NetworkManager Connections

| Connection Name | Interface | Purpose |
|----------------|-----------|---------|
| server1-bond0 | bond0 | Bond master — static 10.10.10.2/24 |
| server1-bond0-eno3 | eno3 | Bond primary slave |
| server1-bond0-eno4 | eno4 | Bond secondary slave |
| server1-idrac | idrac | iDRAC USB NIC — 169.254.0.2/24 |

### Configuration

- **Bond mode:** active-backup
- **Primary:** eno3 (primary_reselect always)
- **MII polling:** 100ms
- **IPv6:** disabled on all interfaces
- **mDNS / LLMNR / LLDP:** disabled
- **Wake-on-LAN:** disabled
- **iDRAC:** static 169.254.0.2/24, `never-default yes` (no routing through iDRAC)

### Setup Script

See `servers/server1-network.sh`. Run once after a fresh Fedora install:

```bash
sudo bash servers/server1-network.sh
```

The script:
1. Deletes all auto-generated "Wired connection N" connections
2. Creates bond0 with static IP and correct bond options
3. Adds eno3 and eno4 as bond slaves
4. Configures iDRAC USB NIC
5. Brings everything up and prints verification output

### Verify After Running

```bash
# Bond state — confirm eno3 active, eno4 standby, both 1000Mbps
cat /proc/net/bonding/bond0

# IP — confirm 10.10.10.2/24 on bond0, 169.254.0.2/24 on idrac
ip addr show

# Routes — single default via 10.10.10.1, no default via idrac
ip route

# Connectivity
ping -c3 10.10.10.1    # router
ping -c3 router.home   # DNS
ping -c3 8.8.8.8       # internet
```

Expected route table:

```
default via 10.10.10.1 dev bond0 proto static metric 300
10.10.10.0/24 dev bond0 proto kernel scope link src 10.10.10.2 metric 300
169.254.0.0/24 dev idrac proto kernel scope link src 169.254.0.2 metric 102
```

### Failover Test

To verify active-backup failover works:

```bash
# Unplug eno3 cable (or disable the router port) — eno4 should take over
# within 200ms (2× miimon interval)
watch -n0.5 cat /proc/net/bonding/bond0
# Confirm: Currently Active Slave switches to eno4
# Plug eno3 back in — should revert to eno3 as primary
```

---

## Server2 — Dell PER630

### Status: ⏳ Pending

Bonding not yet configured. Template script is at `servers/server2-network.sh`
with all commands commented out pending NIC interface name confirmation.

### Known MACs (from router static leases)

| MAC | Router Lease | Role |
|-----|-------------|------|
| 24:6e:96:ab:39:ed | 10.20.20.2 | NIC1 — bond primary |
| 24:6e:96:ab:39:ec | 10.20.20.3 | NIC2 — AMP / spare |

### Router Port Mapping

```
RB3011 ether4-SRV2-NIC1  (VLAN20, pvid=20)  →  Server2 primary NIC
RB3011 ether5-SRV2-NIC2  (VLAN20, pvid=20)  →  Server2 spare NIC
RB3011 ether7-iDRAC2     (VLAN30, pvid=30)  →  Server2 iDRAC dedicated port
```

### Setup Steps (when ready)

1. Confirm interface names: `ip addr show` on Server2
2. Update `servers/server2-network.sh` with correct interface names
3. Uncomment and run: `sudo bash servers/server2-network.sh`

---

## Notes

### Why active-backup and not LACP/802.3ad

The RB3011 does not have a dedicated managed switch between it and the servers —
cables plug directly into router ports. LACP (802.3ad) requires the switch/router
to also be configured for LACP on those ports. Active-backup works with any
router port with zero additional router configuration and provides full failover
if one cable or port fails.

### iDRAC USB NIC

The iDRAC USB NIC (`idrac` interface, `enp0s20u12u3`) is a virtual USB Ethernet
adapter that provides OS-to-iDRAC communication over the internal USB bus — no
physical cable required. It uses the 169.254.0.0/16 link-local range and is
configured with `ipv4.never-default yes` so it never becomes the default route.
The iDRAC's physical Ethernet port (OOB management) is a separate interface on
VLAN30 connected to `ether6-iDRAC1` on the router.

### Re-running After Reinstall

The setup script is safe to re-run on a fresh Fedora install. It handles missing
connections gracefully (`2>/dev/null || true` on deletes) and `nmcli connection add`
will fail loudly if a connection with that name already exists — which is the
correct behaviour to prevent accidental double-configuration.
