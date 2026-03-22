# Services & Containers

## Pi-hole v6 + Unbound + Hyperlocal

- **Image**: `sujiba/pihole-unbound-hyperlocal:latest`
- **Versions** (at time of setup): Pi-hole v6.4, Web v6.4.1, FTL v6.5
- **Interface**: veth-pihole (172.17.0.2/24, gateway 172.17.0.1)
- **Root dir**: `usb1-part1/containers/pihole`
- **Mounts**:
  - `usb1-part1/containers/pihole/data` → `/etc/pihole` (config, gravity.db, tls.pem)
  - `usb1-part1/containers/pihole/log` → `/var/log/pihole` (query logs)
- **Web UI**: http://172.17.0.2/admin or https://172.17.0.2/admin (self-signed cert)
- **DNS port**: 53 (UDP/TCP)
- **Unbound**: Bundled inside container, listens on `127.0.0.1#5335` — resolves from root, no upstream needed
- **start-on-boot**: yes
- **Status**: HEALTHY

### Environment Variables

| Variable | Value |
|----------|-------|
| TZ | America/Toronto |
| FTLCONF_webserver_api_password | (set in /container envs — not in repo) |
| FTLCONF_dns_listeningMode | all |
| FTLCONF_dns_upstreams | 127.0.0.1#5335 |

### DNS Failover

Netwatch monitors 172.17.0.2 every 15 seconds.

- Pi-hole **DOWN** → DNS automatically switches to `8.8.8.8,8.8.4.4`
- Pi-hole **UP** → DNS automatically restores to `172.17.0.2,8.8.8.8,8.8.4.4`

### Syslog

The router forwards logs to Pi-hole on UDP 514 using the default `remote`
logging action (action index 3, remote=172.17.0.2).

Topics sent to Pi-hole (remote): `info`, `firewall`, `warning`, `error`

Topics kept in router memory only: `dhcp`, `pppoe`, `warning`, `firewall`

---

## Back to Home VPN

- **Type**: WireGuard (managed by MikroTik Cloud)
- **VPN DNS name**: `YOURSERIAL.vpn.mynetname.net`
- **Port**: 65504 UDP (open in firewall on WAN)
- **Client**: MikroTik smartphone app
- **Status**: Running, USA1 relay

Allows remote access to the entire home lab from anywhere using the MikroTik
app. Connects through MikroTik's relay servers automatically.

BTH users can reach all VLANs including game servers at 10.20.20.3.

---

## AMP Game Panel (Server2 NIC2 — 10.20.20.3)

AMP (Application Management Panel) runs on Server2's second NIC, dedicated
to game server traffic.

### Game Servers and Ports

| Game | Protocol | Port | Forwarded from WAN |
|------|----------|------|--------------------|
| Minecraft Java | TCP | 25565 | ✅ (pending public IP) |
| Minecraft Bedrock | UDP | 19132 | ✅ (pending public IP) |
| Garry's Mod | UDP | 27015 | ✅ (pending public IP) |
| Garry's Mod RCON | TCP | 27015 | ✅ (pending public IP) |
| TeamSpeak 6 | UDP | 9987 | ✅ (pending public IP) |
| TeamSpeak 6 File | TCP | 30033 | ✅ (pending public IP) |

**Note**: ISP is currently CGNAT (WAN IP 10.71.x.x). Port forwarding rules
are in place and will activate automatically once ISP provides a public IP.
AMP web panel (port 8080) is LAN-only — not forwarded externally.

---

## The Dude

- **Package**: dude (bundled with RouterOS 7.22 extras)
- **Data directory**: `usb1-part1/dude`
- **Status**: enabled, running
- **Connect**: Dude client → router IP, default port 2210
- Best accessed from Server1 (VLAN10 has full router access)

---

## Container Runtime Configuration

```
registry-url:  https://registry-1.docker.io
tmpdir:        usb1-part1/containers/tmp
layer-dir:     usb1-part1/layers
memory-high:   512MiB
```

---

## USB SSD Directory Structure

```
usb1-part1/
├── layers/                    # Container image layers
├── containers/
│   ├── tmp/                   # Container extraction temp dir
│   └── pihole/
│       ├── data/              # Pi-hole /etc/pihole (pihole.toml, gravity.db, tls.pem)
│       └── log/               # Pi-hole /var/log/pihole (query logs)
├── backups/
│   ├── daily/                 # Daily RSC config export (runs at 03:00)
│   └── weekly/                # Weekly encrypted binary backup (runs at 02:00 Monday)
├── dude/                      # The Dude database and config
└── logs/                      # Router log exports (manual)
```

**Note**: Daily RSC backup contains credentials in plaintext (PPPoE username,
Pi-hole password). The file is stored locally on the USB SSD only — not
uploaded anywhere. Weekly binary backup is AES-SHA256 encrypted.

---

## Scheduled Backups

| Scheduler | Time | Type | Output |
|-----------|------|------|--------|
| `daily-backup` | 03:00 daily | RSC text export | `usb1-part1/backups/daily/rb3011-config.rsc` |
| `weekly-backup` | 02:00 Monday | AES-SHA256 encrypted binary | `usb1-part1/backups/weekly/rb3011-full.backup` |

---

## Graphing

Interface traffic graphs enabled for: `pppoe-wan`, `vlan10-server1`,
`vlan20-server2`, `vlan30-idrac`, `vlan40-pi`, `vlan50-av`, `vlan60-wifi`

Access via Winbox → Tools → Graphing.

---

## SNMP

- **Status**: Enabled
- **Community**: renamed from `public` (stored on router only — not in repo)
- **Address restriction**: 10.10.10.0/24 and 10.20.20.0/24 only
- **Contact**: YOUR-EMAIL
- **Location**: Home Lab
- Used by mktxp for Grafana metrics export (mktxp_user: read+api only)
