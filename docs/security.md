# Security Configuration

## Access Control

### Management Access

- **Winbox**: Port 8291, restricted to 10.10.10.0/24 (Server1) and 10.30.30.0/24 (iDRAC) only
- **SSH**: Port 2222, restricted to 10.10.10.0/24 and 10.30.30.0/24 only, strong-crypto=yes
- **API**: Port 8728, restricted to 10.10.10.0/24 and 10.30.30.0/24, for mktxp Grafana exporter
- **FTP, Telnet, HTTP, HTTPS, reverse-proxy, API-SSL**: Disabled
- **MAC server**: Disabled (all interfaces)
- **MAC ping**: Disabled
- **Neighbor discovery**: Disabled (all interfaces)
- **Bandwidth server**: Disabled
- **IP Cloud DDNS**: Auto (disabled), Back to Home VPN enabled
- **IP Cloud update-time**: Disabled (using NTP instead)

### Users

- `YOUR-ADMIN-USER` — full access, primary admin
- `mktxp_user` — read+api only, for Grafana metrics exporter
- `admin` — removed

### SNMP

- Community string: renamed from `public` (actual name stored on router only)
- Address restriction: 10.10.10.0/24 and 10.20.20.0/24 only
- Used by mktxp for Grafana metrics export

---

## Firewall

### Input Chain (traffic to router)

1. Accept established/related/untracked
2. Drop invalid
3. Accept loopback (127.0.0.1)
4. Accept ICMP from LAN interfaces only (not WAN — WAN ICMP falls through to rate-limit rules)
5. Accept from Server1 VLAN (full access)
6. Accept from Server2 VLAN (full access)
7. Accept from iDRAC VLAN (full access)
8. Accept from RPi VLAN — DNS (TCP/UDP 53) and NTP (UDP 123) only
9. Accept from AV VLAN — DNS (TCP/UDP 53) only
10. Accept from WiFi VLAN — DNS (TCP/UDP 53) and NTP (UDP 123) only
11. Accept Back to Home VPN (UDP 65504) from WAN
12. Accept from back-to-home-vpn interface
13. Drop all not from LAN
14. [SEC] Drop TCP NULL scan, TCP FIN/no-ACK
15. [SEC] SSH brute-force ladder (4 attempts → blacklisted 1w3d)
16. [SEC] Port scanner detection (2 week blacklist)
17. [DDOS] Drop blacklisted sources
18. [DDOS] Accept ICMP within rate limit (50/s, burst 100) — WAN ICMP reaches here
19. [DDOS] Drop ICMP flood
20. [DDOS] Drop DNS/NTP/SSDP amplification attempts from WAN
21. **Default drop**

### Forward Chain (traffic through router)

Inter-VLAN policy matrix:

| Source | Server1 | Server2 | iDRAC | RPi | AV | WiFi | WAN |
|--------|---------|---------|-------|-----|----|------|-----|
| Server1 | — | ✅ | ✅ | ❌ | ❌ | ✅ (AP mgmt) | ✅ |
| Server2 | ✅ | — | ✅ | ❌ | ❌ | ✅ (AP mgmt) | ✅ |
| iDRAC | ✅ | ✅ | — | ✅ | ❌ | ❌ | ❌ |
| RPi | ❌ | ❌ | ❌ | — | ❌ | ❌ | ✅ |
| AV | ❌ | ❌ | ❌ | ❌ | — | ❌ | ✅ |
| WiFi | ❌ | ❌ | ❌ | ❌ | ❌ | — | ✅ |
| WiFi | DNS to Pi-hole (172.17.0.2:53) only from container net | | | | | | |
| BTH VPN | ✅ all VLANs | | | | | | |

Game server inbound (WAN → 10.20.20.3 AMP):
- Minecraft Java: TCP 25565
- Minecraft Bedrock: UDP 19132
- Garry's Mod: UDP/TCP 27015
- TeamSpeak 6: UDP 9987, TCP 30033

Forward chain ends with `[FWD] Default drop all unmatched` — no implicit forwarding.

### RAW Chain (before conntrack)

- Accept all LAN traffic (bypass conntrack for performance)
- Drop bogon src/dst from WAN
- Drop bad TCP flags (FIN+SYN, SYN+RST)
- Drop spoofed loopback/RFC1918/CGNAT sources from WAN

---

## DDoS Protection

### Filter chain (address-list blacklist)

Any source in `ddos-blacklist` is dropped at both input and forward chains.

### Filter chain (ICMP rate limiting)

- Input: accept first 50/s with burst 100, drop remainder
- Forward from WAN: same rate limiting applied

### Filter chain (amplification drops)

- DNS UDP from WAN dropped at input
- DNS TCP from WAN dropped at input
- NTP UDP from WAN dropped at input
- SSDP (UDP 1900) dropped globally at input

### Whitelist (exempt from all DDoS rules)

- 8.8.8.8 — Google DNS
- 8.8.4.4 — Google DNS
- 10.50.50.20 — Admin workstation
- 10.10.10.0/24 — Server1 VLAN
- 10.20.20.0/24 — Server2 VLAN

---

## SSH Brute Force Protection (4-stage ladder)

4 connection attempts within 1 minute → blacklisted for 1 week 3 days

| Stage | List timeout | Trigger |
|-------|-------------|---------|
| Stage 1 | 1m | New connection to port 2222 |
| Stage 2 | 1m | Source already in ssh-stage1 |
| Stage 3 | 1m | Source already in ssh-stage2 |
| Blacklist | 1w3d | Source already in ssh-stage3 |

---

## Port Scanner Detection

PSD rule: 21 ports within a 3-second window, 3+ connections (1 heavy) → blacklisted 2 weeks.

---

## Attack Monitor

Scheduler runs every 10 seconds checking combined count of `ddos-blacklist`,
`ssh-blacklist`, `port-scanners`. Any increase triggers the attack-alarm beeper
and logs a warning.

---

## IPv6 Firewall

ISP does not currently provide IPv6 (CGNAT). Defensive rules added for
future-proofing:

- Input: accept established, accept ICMPv6, accept BTH VPN, default drop
- Forward: accept established, accept ICMPv6, block WAN initiation, default drop

---

## CAPsMAN Security

- DTLS encryption between router and APs (certificate=auto, ca-certificate=auto)
- AP firmware upgrade policy: suggest-same-version
- Access list: roaming reject (-120..-80 dBm) → accept all → default deny
- Client-to-client forwarding: enabled (required for Roku, Chromecast, mDNS, Spotify Connect)

---

## AP Security (both mAP2nD-1 and wAP2nD-1)

- `admin` user disabled, `YOUR-ADMIN-USER` only
- SSH port 2222, no address restriction (router VLAN isolation provides protection)
- Winbox no address restriction (router VLAN isolation provides protection)
- FTP/telnet/www/www-ssl/api/api-ssl/reverse-proxy disabled
- MAC server disabled (all interfaces)
- MAC ping disabled
- Neighbor discovery disabled
- Bandwidth server disabled
- Strong SSH crypto enabled
- Default firewall rules removed (router firewall provides all protection)
- DNS allow-remote-requests disabled
- IPv6 firewall: lean 6-rule set (established, ICMPv6, default drop)
- No NAT (APs are L2 bridges, not routers)
