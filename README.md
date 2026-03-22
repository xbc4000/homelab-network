# RB3011 Home Lab — RouterOS 7.22 Configuration

Complete configuration for a MikroTik RB3011UiAS home lab router running
RouterOS 7.22, with two CAPsMAN access points, Pi-hole v6 + Unbound DNS,
AMP game panel, and hardened security throughout.

## Hardware

| Device | Model | Role |
|--------|-------|------|
| Router | RB3011UiAS | Core router, CAPsMAN controller, container host |
| Storage | USB SSD (256GB) | Container storage, Dude DB, backups |
| AP1 | mAP2nD-1 | 2.4GHz WiFi ch1, CAPsMAN CAP |
| AP2 | wAP2nD-1 | 2.4GHz WiFi ch11, CAPsMAN CAP (daisy-chained via mAP) |
| Server1 | Dell PER730XD | VLAN10 — hypervisor |
| Server2 | Dell PER630 | VLAN20 — Ubuntu Server + AMP game panel |

## Features

- **6 isolated VLANs** with strict inter-VLAN firewall rules and explicit default drop
- **CAPsMAN** managed WiFi using legacy `/caps-man` — required for MIPS/Atheros AR9300 APs
- **Pi-hole v6 + Unbound + Hyperlocal** container — fully recursive DNS, no upstream resolver needed
- **DNS auto-failover** — netwatch switches to Google DNS within 15 seconds when Pi-hole is unreachable
- **WiFi roaming** — clients forced off APs below -80 dBm signal
- **WiFi client-to-client forwarding** — mDNS, Roku, Chromecast, Spotify Connect all work
- **iDRAC → RPi access** — iDRAC can reach Raspberry Pi for metrics collection
- **Back to Home VPN** — remote access via MikroTik app (WireGuard, port 65504)
- **AMP game panel** — Minecraft Java, Minecraft Bedrock, Garry's Mod, TeamSpeak 6
- **DDoS protection** — ICMP rate limiting, DNS/NTP/SSDP amplification drops, address-list blacklisting
- **SSH brute-force ladder** — 4 attempts → blacklisted for 10 days
- **Port scanner detection** — 2 week blacklist
- **Beeper alert system** — distinct tones for DHCP leases, WiFi connect/disconnect, ethernet up/down, WAN down, attacks
- **Super Mario Bros theme** on demand
- **LCD touchscreen** with stat slideshow and PIN lock
- **Security lockdown** — all services hardened, Winbox/SSH/API restricted to VLAN10/VLAN30
- **Strong SSH crypto** (AES-CTR, no SHA1)
- **IGMP snooping** enabled for efficient multicast
- **IPv6 firewall** — defensive rules (ISP is currently CGNAT, no global IPv6 assigned)
- **The Dude** network monitoring on USB SSD
- **Syslog** forwarding to Pi-hole (topics: info, firewall, warning, error)
- **Encrypted backups** — daily RSC export, weekly AES-SHA256 binary backup
- **Interface graphing** — pppoe-wan, vlan10–vlan60
- **SNMP** restricted to VLAN10/VLAN20, renamed community string
- **Static DHCP leases** for all infrastructure devices
- **Netwatch** monitoring all hosts with beeper alerts

## Repository Structure

```
homelab-network/
├── config/
│   └── rb3011-config.rsc       # Complete router configuration (redacted live export)
├── aps/
│   ├── mAP2nD-1.rsc            # mAP2nD-1 setup script (import after reset)
│   └── wAP2nD-1.rsc            # wAP2nD-1 setup script (import after reset)
├── docs/
│   ├── network-layout.md       # VLAN layout, IP assignments, port mapping, isolation rules
│   ├── services.md             # Pi-hole, Back to Home, AMP, Dude, container config, backups
│   ├── security.md             # Firewall chains, DDoS, SSH ladder, AP security
│   ├── beeper-alerts.md        # All beeper scripts, schedulers, netwatch table
│   └── troubleshooting.md      # Common issues and RouterOS v7.22 syntax notes
├── scripts/
│   ├── manual-backup.rsc       # Trigger an immediate backup
│   ├── clear-blacklists.rsc    # Clear all DDoS/SSH/scanner blacklists + SSH stage lists
│   ├── pihole-restart.rsc      # Restart Pi-hole container cleanly
│   ├── security-lockdown.rsc   # Apply security lockdown (run from VLAN10 only)
│   └── syslog-setup.rsc        # Configure syslog forwarding to Pi-hole
└── README.md
```

## Quick Reference

| Item | Value |
|------|-------|
| Router hostname | RB3011-GW |
| Admin user | YOUR-ADMIN-USER |
| Winbox | Port 8291, VLAN10/VLAN30 only |
| SSH | Port 2222, VLAN10/VLAN30 only |
| Pi-hole web UI | http://172.17.0.2/admin |
| Back to Home VPN | Port 65504 UDP — see `/ip cloud print` on router |
| router.home | 10.10.10.1 |
| server1.home | 10.10.10.2 |
| server2.home | 10.20.20.2 |
| amp.home | 10.20.20.3 |
| idrac1.home | 10.30.30.10 |
| idrac2.home | 10.30.30.11 |
| rpi.home | 10.40.40.2 |
| pihole.home | 172.17.0.2 |
| ap1.home | 10.60.60.200 |
| ap2.home | 10.60.60.201 |

## Important Notes

- WiFi password is stored in `/caps-man security` on the router — not in this repo
- Pi-hole API password is stored in `/container envs` on the router — not in this repo
- SNMP community string is on the router — not in this repo
- LCD PIN is on the router — not in this repo
- ISP PPPoE username is on the router — not in this repo
- The Dude listens on port 2210 by default
- Weekly backup is AES-SHA256 encrypted — keep the password safe
- Daily RSC backup is plaintext and stored locally on USB SSD only
- RouterOS version: **7.22** (latest stable as of 2026-03-22)
- Firmware: **7.22** (matches RouterOS — nothing to upgrade)

## VLAN Overview

| VLAN | Subnet | Purpose | WAN | Inter-VLAN |
|------|--------|---------|-----|------------|
| 10 | 10.10.10.0/24 | Server1 | ✅ | ↔ VLAN20, VLAN30 |
| 20 | 10.20.20.0/24 | Server2 + AMP | ✅ | ↔ VLAN10, VLAN30 |
| 30 | 10.30.30.0/24 | iDRAC OOB | ❌ | → VLAN10, VLAN20, VLAN40 |
| 40 | 10.40.40.0/24 | Raspberry Pi | ✅ | Isolated |
| 50 | 10.50.50.0/24 | AV / Blu-ray | ✅ | Isolated |
| 60 | 10.60.60.0/24 | WiFi clients + APs | ✅ | DNS to Pi-hole only |

## AP Setup

Both APs use import scripts for reliable one-shot configuration. See `aps/` directory.

The scripts handle: bridge setup, static IP, NTP, timezone, service hardening,
DNS allow-remote-requests disabled, firewall cleanup, MAC server lockdown,
CAP mode — all in one import without mid-import disconnection issues.

**AP chain**: Router ether10 → mAP2nD-1 ether1 → mAP2nD-1 ether2 → wAP2nD-1 ether1

After import, SSH from router to set password:

```
/system ssh address=10.60.60.200 port=2222 user=YOUR-ADMIN-USER
/user set [find name=YOUR-ADMIN-USER] password=YOURPASSWORD
```

Repeat for wAP at 10.60.60.201.

## Game Servers (AMP — 10.20.20.3)

| Game | Protocol | Port |
|------|----------|------|
| Minecraft Java | TCP | 25565 |
| Minecraft Bedrock | UDP | 19132 |
| Garry's Mod | UDP/TCP | 27015 |
| TeamSpeak 6 Voice | UDP | 9987 |
| TeamSpeak 6 File Transfer | TCP | 30033 |

DNAT and forward filter rules are in place. Port forwarding will activate
automatically once ISP provides a public IP (currently CGNAT).

## RouterOS Version

Tested on RouterOS **7.22** (stable, released 2026-03-09). All configuration
uses RouterOS 7 syntax. Notable differences from v6 documented in
[docs/troubleshooting.md](docs/troubleshooting.md).
