# RB3011 Home Lab — RouterOS 7.22

```
╔══════════════════════════════════════════════════════════════════╗
║  RB3011-GW  ·  RouterOS 7.22  ·  MikroTik RB3011UiAS             ║
║  6 VLANs  ·  CAPsMAN  ·  Pi-hole v6  ·  WireGuard VPN            ║
╚══════════════════════════════════════════════════════════════════╝
```

Complete configuration for a MikroTik RB3011UiAS home lab router —
hardened, documented, and ready to restore from a factory reset.

---

## Hardware

| Device | Model | Role |
|--------|-------|------|
| Router | RB3011UiAS | Core router, CAPsMAN controller, container host |
| Storage | USB SSD 256 GB | Container storage, Dude DB, backups |
| AP1 | mAP2nD-1 | 2.4 GHz WiFi ch1, CAPsMAN CAP |
| AP2 | wAP2nD-1 | 2.4 GHz WiFi ch11, CAPsMAN CAP (daisy-chained via mAP) |
| Server1 | Dell PER730XD | VLAN10 — hypervisor |
| Server2 | Dell PER630 | VLAN20 — Ubuntu Server + AMP game panel |

---

## Network Overview

```
Internet (PPPoE CGNAT)
        │
   ether1-WAN
        │
   RB3011-GW  (10.x.x.1 gateway for all VLANs)
   ├── ether2/3  VLAN10  10.10.10.0/24  Server1 (bond0)
   ├── ether4/5  VLAN20  10.20.20.0/24  Server2 + AMP
   ├── ether6/7  VLAN30  10.30.30.0/24  iDRAC OOB (no WAN)
   ├── ether8    VLAN40  10.40.40.0/24  Raspberry Pi
   ├── ether9    VLAN50  10.50.50.0/24  AV / Blu-ray
   ├── ether10   VLAN60  10.60.60.0/24  WiFi + CAPsMAN APs
   ├── veth      172.17.0.0/24          Pi-hole container
   └── wireguard back-to-home-vpn       WireGuard / all VLANs
```

### VLAN Table

| VLAN | Subnet | Purpose | WAN | Inter-VLAN |
|------|--------|---------|-----|------------|
| 10 | 10.10.10.0/24 | Server1 (PER730XD) | Yes | ↔ VLAN20, VLAN30, VLAN60 (AP mgmt) |
| 20 | 10.20.20.0/24 | Server2 + AMP (PER630) | Yes | ↔ VLAN10, VLAN30, VLAN60 (AP mgmt) |
| 30 | 10.30.30.0/24 | iDRAC OOB | No | → VLAN10, VLAN20, VLAN40 (metrics) |
| 40 | 10.40.40.0/24 | Raspberry Pi | Yes | Isolated |
| 50 | 10.50.50.0/24 | AV / Blu-ray | Yes | Isolated |
| 60 | 10.60.60.0/24 | WiFi clients + APs | Yes | DNS to Pi-hole only |
| — | 172.17.0.0/24 | Pi-hole container (veth) | — | Router-internal |

---

## Features

### Networking
- **6 isolated VLANs** with strict inter-VLAN firewall and explicit default drop on all chains
- **802.1Q VLAN filtering** on bridge-main — hardware-accelerated, no software bridge workarounds
- **IGMP snooping** enabled for efficient multicast (Chromecast, Roku, Spotify Connect)
- **PPPoE WAN** over ether1 — CGNAT now, public IP rules ready to activate
- **Back to Home VPN** — WireGuard managed by MikroTik Cloud, port 65504 UDP

### DNS
- **Pi-hole v6 + Unbound + Hyperlocal** — fully recursive DNS, resolves from root nameservers, no upstream resolver needed
- **DNS auto-failover** — netwatch switches to Google DNS within 15 seconds when Pi-hole is down
- **Local `.home` DNS** — all infrastructure devices have static A records on the router

### WiFi (CAPsMAN)
- **Two APs** — mAP2nD-1 (ch1) and wAP2nD-1 (ch11), daisy-chained via ether10
- **Roaming** — clients forced off below −80 dBm signal
- **Client-to-client forwarding** — mDNS, Roku, Chromecast, Spotify Connect all work
- **Per-device WiFi tones** — known phones get distinct DHCP lease melodies

### Security
- **SSH brute-force ladder** — 4 attempts → 10-day blacklist (3-stage addreslist chain)
- **Port scanner detection** — PSD 21/3s → 2-week blacklist
- **DDoS protection** — ICMP rate limiting, DNS/NTP/SSDP amplification drops
- **RAW chain** — bogon, RFC1918, CGNAT src drops before routing
- **TCP flag scanning** — NULL scan and FIN-no-ACK drops on input + forward
- **Services hardened** — FTP, Telnet, WWW, API-SSL, reverse-proxy all disabled
- **Winbox/SSH/API** restricted to VLAN10 and VLAN30 only
- **Strong SSH crypto** — AES-CTR only, SHA1 disabled
- **IPv6 firewall** — 8-rule defensive set (ISP is CGNAT, no global IPv6)

### Monitoring & Alerts
- **Netwatch** — 10 hosts monitored, beeper alerts on up/down
- **Ethernet monitor** — beeps on link up/down (3s poll)
- **WiFi monitor** — beeps on connect/disconnect (5s poll)
- **Attack monitor** — beeps when any blacklist count increases (10s poll)
- **Login monitor** — beeps on new active router session (5s poll)
- **SSH probe monitor** — beeps when ssh-stage1 list grows (10s poll)
- **Temperature monitor** — alarm at 60°C (1m poll)
- **DHCP pool monitor** — alarm when WiFi pool drops below 10 free IPs (5m)
- **USB mount monitor** — deep alarm if USB SSD not mounted (5m)

### Boot Fanfare System
- **11 rotating fanfares** play once per boot after WAN + USB are ready
- Cycles through: Tetris, Star Trek, Close Encounters, Imperial March, Doctor Who, Morse SOS, Big Ben, Nokia, Jeopardy, Mission Impossible, Reveille
- Index stored persistently in script comment field — survives reboots
- Uses two-scheduler pattern to work around RouterOS 7.22 `:beep` top-level restriction

### Other
- **Super Mario Bros theme** — on-demand `/system script run super-mario`
- **LCD touchscreen** — stat slideshow with 5s rotation, PIN lock, read-only mode
- **The Dude** — network monitoring database on USB SSD
- **Syslog** forwarding to Pi-hole (info, firewall, warning, error)
- **SNMP** — restricted to VLAN10/VLAN20, renamed community string
- **Interface graphing** — pppoe-wan, vlan10–vlan60
- **Weekly RouterOS auto-update** — encrypted backup then install, AP firmware pushed 20 min later

### Backups
- **Daily RSC export** — plaintext, USB SSD only, 03:00 daily
- **Weekly encrypted binary** — AES-SHA256, USB SSD, 02:00 weekly
- **Pre-update backup** — taken automatically before any RouterOS upgrade

---

## Repository Structure

```
homelab-network-1/
├── config/
│   └── rb3011-config.rsc        # Complete router config (credentials redacted)
├── aps/
│   ├── mAP2nD-1.rsc             # mAP2nD-1 one-shot setup script
│   └── wAP2nD-1.rsc             # wAP2nD-1 one-shot setup script
├── docs/
│   ├── network-layout.md        # VLANs, IPs, port mapping, isolation rules
│   ├── services.md              # Pi-hole, VPN, AMP, Dude, backups, SNMP
│   ├── security.md              # Firewall chains, DDoS, SSH ladder, hardening
│   ├── beeper-alerts.md         # All alert scripts, schedulers, boot fanfare system
│   ├── servers.md               # Server NIC bonding and network config (PER730XD, PER630)
│   └── troubleshooting.md       # Common issues, RouterOS 7.22 syntax notes
├── servers/
│   ├── server1-network.sh       # NetworkManager bond setup for Server1 (PER730XD)
│   └── server2-network.sh       # Template bond setup for Server2 (PER630, pending)
├── scripts/
│   ├── auto-update.rsc          # Weekly RouterOS update — backup then install
│   ├── ap-upgrade.rsc           # Push firmware to CAPsMAN APs after router update
│   ├── usb-check.rsc            # Startup USB SSD mount check — reboots up to 3×
│   ├── manual-backup.rsc        # Trigger immediate RSC + encrypted binary backup
│   ├── clear-blacklists.rsc     # Clear all DDoS/SSH/scanner blacklists
│   ├── pihole-restart.rsc       # Restart Pi-hole container cleanly
│   ├── security-lockdown.rsc    # Re-apply full security lockdown
│   └── syslog-setup.rsc         # Configure syslog forwarding to Pi-hole
└── README.md
```

---

## Quick Reference

### Router Access

| Method | Address | Restriction |
|--------|---------|-------------|
| Winbox | 10.10.10.1 port 8291 | VLAN10 / VLAN30 only |
| SSH | 10.10.10.1 port 2222 | VLAN10 / VLAN30 only |
| Serial | RJ45 console port | 115200 baud 8N1 |

### DNS Names

| Hostname | IP |
|---------|----|
| router.home | 10.10.10.1 |
| server1.home | 10.10.10.2 |
| server1-nic2.home | 10.10.10.3 |
| server2.home | 10.20.20.2 |
| amp.home | 10.20.20.3 |
| idrac1.home | 10.30.30.10 |
| idrac2.home | 10.30.30.11 |
| rpi.home | 10.40.40.2 |
| pihole.home | 172.17.0.2 |
| ap1.home | 10.60.60.200 |
| ap2.home | 10.60.60.201 |

### Service Ports

| Service | Port | Protocol | Accessible from |
|---------|------|----------|----------------|
| Pi-hole web UI | 80 / 443 | TCP | pihole-admin-wifi list, Server1 |
| The Dude | 2210 | TCP | VLAN10 |
| Back to Home VPN | 65504 | UDP | WAN |
| Minecraft Java | 25565 | TCP | WAN → 10.20.20.3 |
| Minecraft Bedrock | 19132 | UDP | WAN → 10.20.20.3 |
| Garry's Mod | 27015 | UDP/TCP | WAN → 10.20.20.3 |
| TeamSpeak 6 Voice | 9987 | UDP | WAN → 10.20.20.3 |
| TeamSpeak 6 Files | 30033 | TCP | WAN → 10.20.20.3 |

---

## AP Setup

Both APs are configured via import scripts — one shot, no mid-import
disconnects.

```
# From router terminal, after AP is factory reset and on VLAN60:
/import aps/mAP2nD-1.rsc
/import aps/wAP2nD-1.rsc

# Then SSH in to set password:
/system ssh address=10.60.60.200 port=2222 user=YOUR-ADMIN-USER
/system ssh address=10.60.60.201 port=2222 user=YOUR-ADMIN-USER
```

Scripts handle: bridge setup, static IP, NTP, timezone, service hardening,
DNS allow-remote-requests disabled, MAC server lockdown, CAP mode.

**AP chain**: Router ether10 → mAP2nD-1 ether1 → mAP2nD-1 ether2 → wAP2nD-1 ether1

---

## Restore from Factory Reset

1. Import config: `System → Files → Upload rb3011-config.rsc` then
   `/import rb3011-config.rsc` from terminal
2. Set PPPoE username: `/interface pppoe-client set pppoe-wan user=YOURUSERNAME`
3. Set Pi-hole API password in container envs
4. Set LCD PIN: `/lcd pin set pin-number=YOURPIN`
5. Set SNMP community: `/snmp community set [find default=yes] name=YOURSTRING`
6. Set WiFi password: `/caps-man security set [find name=wifi-sec] passphrase=YOURPASS`
7. Enable usb-check scheduler: `/system scheduler enable usb-check`
8. Restore Pi-hole data from USB backup if needed

---

## Important Notes

- WiFi passphrase — stored in `/caps-man security` on router, not in repo
- Pi-hole API password — stored in `/container envs`, not in repo
- SNMP community string — on router, not in repo
- LCD PIN — on router, not in repo
- PPPoE username — on router, not in repo
- WireGuard private keys — not exported by RouterOS
- Weekly encrypted backup password — keep it safe, stored nowhere in this repo
- Daily RSC backup is plaintext (PPPoE username visible) — stored on USB SSD only
- ISP is currently CGNAT (`10.71.x.x`) — game server port forwarding rules are in
  place but inactive until ISP provides a public IP
- RouterOS version: **7.22** (stable, 2026-03-09)

---

## Documentation

| Doc | Contents |
|-----|---------|
| [network-layout.md](docs/network-layout.md) | Physical ports, VLANs, IPs, DHCP pools, inter-VLAN rules, WiFi, WAN |
| [services.md](docs/services.md) | Pi-hole, Back to Home VPN, AMP, The Dude, USB structure, backups, SNMP |
| [security.md](docs/security.md) | Firewall chains, DDoS, SSH brute-force ladder, port scan detection, hardening |
| [beeper-alerts.md](docs/beeper-alerts.md) | All alert scripts, schedulers, netwatch table, boot fanfare system |
| [servers.md](docs/servers.md) | Server NIC bonding, NetworkManager setup, iDRAC config, failover testing |
| [troubleshooting.md](docs/troubleshooting.md) | Common issues, CAPsMAN tips, RouterOS 7.22 syntax notes, beeper gotchas |
