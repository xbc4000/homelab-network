# Security Configuration

## Access Control

### Management Access
- **Winbox**: Port 8291, restricted to 10.10.10.0/24 (Server1) and 10.30.30.0/24 (iDRAC) only
- **SSH**: Port 2222, restricted to 10.10.10.0/24 and 10.30.30.0/24 only, strong-crypto=yes
- **API**: Port 8728, restricted to 10.10.10.0/24 and 10.30.30.0/24, for mktxp Grafana exporter
- **FTP, Telnet, HTTP, reverse-proxy, API-SSL**: Disabled
- **MAC server**: Disabled
- **MAC ping**: Disabled
- **Neighbor discovery**: Disabled
- **Bandwidth server**: Disabled
- **IP Cloud DDNS**: Auto (disabled), Back to Home VPN enabled
- **IP Cloud update-time**: Disabled (using NTP instead)

### Users
- `YOUR-ADMIN-USER` — full access, primary admin
- `mktxp_group` — read+api only, for Grafana metrics exporter
- `admin` — disabled

---

## Firewall

### Input Chain (traffic to router)
1. Accept established/related/untracked
2. Drop invalid
3. Accept ICMP
4. Accept loopback (127.0.0.1) — required for CAPsMAN
5. Accept from Server1 VLAN
6. Accept from Server2 VLAN
7. Accept from iDRAC VLAN
8. Accept from RPi VLAN
9. Accept from AV VLAN
10. Accept from WiFi VLAN
11. Accept Back to Home VPN (UDP 17723) from WAN
12. Drop all not from LAN
13. Security rules (TCP scan drops, SSH ladder, port scanner detection)
14. DDoS rules (ICMP rate limit, DNS/NTP/SSDP amplification drops, connection limits)
15. **Default drop**

### Forward Chain (traffic through router)
- iDRAC: can reach Server1, Server2, and RPi (metrics). Cannot reach WAN, AV, or WiFi.
- AV: internet only, no RFC1918
- WiFi: internet only, no servers or iDRAC. Client-to-client traffic allowed (mDNS, Roku, Chromecast etc.)
- Server1 ↔ Server2: bidirectional
- Servers → iDRAC: allowed
- Servers → WiFi APs (VLAN60): allowed for AP management

### RAW Chain (before conntrack)
- Accept all LAN traffic
- Drop bogon src/dst from WAN
- Drop bad TCP flags (FIN+SYN, SYN+RST)
- Drop spoofed loopback/RFC1918/CGNAT sources from WAN

---

## DDoS Protection

### Mangle (prerouting — from WAN)
- SYN flood: every 200th new SYN from WAN → source blacklisted 1h
- UDP flood: every 500th UDP from WAN → source blacklisted 1h
- AV outbound: every 100th new TCP connection → source blacklisted 10m
- WiFi outbound: every 100th new TCP connection → source blacklisted 10m

### Filter (connection limit)
- Any source not on whitelist exceeding 200 simultaneous connections → blacklisted 1h

### Whitelist (exempt from all DDoS rules)
- 8.8.8.8 — Google DNS
- 8.8.4.4 — Google DNS
- 10.50.50.20 — Admin workstation
- 10.10.10.98 — PER730XD (Server1)
- 10.10.10.0/24 — Server1 VLAN
- 10.20.20.0/24 — Server2 VLAN

**Note**: External CDN and cloud IPs (Google Cloud, Cloudflare, Fastly) will occasionally appear in the ddos-blacklist due to burst connection patterns. This is normal — entries expire after 1 hour automatically.

---

## SSH Brute Force Protection (4-stage ladder)

4 failed connection attempts within 1 minute → blacklisted for 1 week 3 days

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

Scheduler runs every 10 seconds checking combined count of `ddos-blacklist`, `ssh-blacklist`, `port-scanners`. Any increase triggers the attack-alarm beeper and logs a warning.

---

## CAPsMAN Security

- DTLS encryption between router and APs (certificate=auto, ca-certificate=auto)
- AP firmware upgrade policy: suggest-same-version
- Access list: roaming reject (-120..-80 dBm) → accept all → default deny
- Client-to-client forwarding: enabled (required for Roku, Chromecast, mDNS, Spotify Connect etc.)

---

## AP Security (both mAP2nD-1 and wAP2nD-1)

- Admin user disabled, YOUR-ADMIN-USER only
- SSH port 2222, no address restriction (managed via router VLAN isolation)
- Winbox no address restriction (managed via router VLAN isolation)
- FTP/telnet/www/api/api-ssl/reverse-proxy disabled
- MAC server disabled
- MAC ping disabled
- Neighbor discovery disabled
- Bandwidth server disabled
- Strong SSH crypto enabled
- Default firewall rules removed (router firewall provides all protection)
