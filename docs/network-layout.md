# Network Layout

## Physical Hardware

| Device | Model | Role | Location |
|--------|-------|------|----------|
| Router | RB3011UiAS | Core router, CAPsMAN controller, container host | Rack |
| Storage | USB SSD 256GB | Container storage, Dude DB, backups | USB port |
| Server1 | Dell PER730XD | Workstation — Fedora, daily driver, gaming | Rack |
| Server2 | Dell PER630 | Ubuntu Server / AMP game panel | Rack |
| RPi | Raspberry Pi 4 | DietPi, Portainer, Grafana, metrics exporters, Raspotify | Rack |
| AP1 | mAP2nD-1 | 2.4GHz WiFi ch1, CAPsMAN CAP | Wall |
| AP2 | wAP2nD-1 | 2.4GHz WiFi ch11, CAPsMAN CAP | Wall |

---

## Physical Port Mapping (RB3011)

| Port | Name | VLAN | Device |
|------|------|------|--------|
| ether1 | ether1-WAN | — | ISP PPPoE uplink |
| ether2 | ether2-SRV1-NIC1 | 10 (untagged) | Server1 NIC1 — bond primary (eno3) |
| ether3 | ether3-SRV1-NIC2 | 10 (untagged) | Server1 NIC2 — bond slave (eno4) |
| ether4 | ether4-SRV2-NIC1 | 20 (untagged) | Server2 NIC1 (management) |
| ether5 | ether5-SRV2-NIC2 | 20 (untagged) | Server2 NIC2 (AMP game panel) |
| ether6 | ether6-iDRAC1 | 30 (untagged) | iDRAC — PER730XD OOB |
| ether7 | ether7-iDRAC2 | 30 (untagged) | iDRAC — PER630 OOB |
| ether8 | ether8-RPi | 40 (untagged) | Raspberry Pi |
| ether9 | ether9-BDR | 50 (untagged) | Blu-ray Player |
| ether10 | ether10-AP | 60 (untagged) | mAP2nD-1 uplink (CAPsMAN trunk) |
| SFP | — | — | Unused |

**AP chain**: Router ether10 → mAP2nD-1 ether1 → mAP2nD-1 ether2 → wAP2nD-1 ether1

---

## VLAN Assignments

| VLAN | Name | Subnet | Gateway | Purpose |
|------|------|--------|---------|---------|
| 10 | vlan10-server1 | 10.10.10.0/24 | 10.10.10.1 | Server1 (PER730XD) — workstation |
| 20 | vlan20-server2 | 10.20.20.0/24 | 10.20.20.1 | Server2 (PER630) + AMP |
| 30 | vlan30-idrac | 10.30.30.0/24 | 10.30.30.1 | iDRAC OOB management |
| 40 | vlan40-pi | 10.40.40.0/24 | 10.40.40.1 | Raspberry Pi |
| 50 | vlan50-av | 10.50.50.0/24 | 10.50.50.1 | AV / Blu-ray |
| 60 | vlan60-wifi | 10.60.60.0/24 | 10.60.60.1 | WiFi clients + APs |
| — | container | 172.17.0.0/24 | 172.17.0.1 | Pi-hole container (veth) |

---

## Static IP Assignments

| Hostname | DNS Name | IP | MAC | VLAN |
|----------|----------|-----|-----|------|
| RB3011-GW | router.home | 10.10.10.1 | — | — |
| PER730XD bond0 NIC1 | server1.home | 10.10.10.2 | 24:6E:96:27:91:44 (primary) | 10 |
| PER730XD bond0 NIC2 | server1-nic2.home | 10.10.10.3 | 24:6E:96:27:91:45 (slave) | 10 |
| PER630 NIC1 | server2.home | 10.20.20.2 | 24:6E:96:AB:39:ED | 20 |
| PER630 NIC2 (AMP) | amp.home | 10.20.20.3 | 24:6E:96:AB:39:EC | 20 |
| iDRAC PER730XD | idrac1.home | 10.30.30.10 | 44:A8:42:4B:BF:95 | 30 |
| iDRAC PER630 | idrac2.home | 10.30.30.11 | 84:7B:EB:D6:0B:A2 | 30 |
| Raspberry Pi | rpi.home | 10.40.40.2 | D8:3A:DD:3C:A2:CC | 40 |
| Pi-hole container | pihole.home | 172.17.0.2 | 1C:DE:04:9D:80:98 | container |
| mAP2nD-1 | ap1.home | 10.60.60.200 | DC:2C:6E:10:54:EE | 60 |
| wAP2nD-1 | ap2.home | 10.60.60.201 | 74:4D:28:52:FC:C2 | 60 |

---

## DHCP Pools

| VLAN | Pool Range | Lease Time |
|------|-----------|-----------|
| 10 Server1 | 10.10.10.10–10.10.10.99 | 12h |
| 20 Server2 | 10.20.20.10–10.20.20.99 | 12h |
| 30 iDRAC | 10.30.30.10–10.30.30.30 | 1d |
| 40 RPi | 10.40.40.10–10.40.40.30 | 12h |
| 50 AV | 10.50.50.10–10.50.50.20 | 6h |
| 60 WiFi | 10.60.60.10–10.60.60.199 | 4h |

APs use static IPs above the WiFi pool (10.60.60.200–201).

---

## Inter-VLAN Isolation Rules

| Source | Can Reach |
|--------|-----------|
| Server1 (VLAN10) | Server2, iDRAC, WiFi APs (mgmt), WAN |
| Server2 (VLAN20) | Server1, iDRAC, WiFi APs (mgmt), WAN |
| iDRAC (VLAN30) | Server1, Server2, RPi (metrics only), no WAN |
| RPi (VLAN40) | All VLANs (metrics scraping), WAN |
| AV (VLAN50) | WAN only |
| WiFi (VLAN60) | WAN + Pi-hole DNS (172.17.0.2:53) only |
| BTH VPN | All VLANs |

---

## WiFi (CAPsMAN)

| Setting | Value |
|---------|-------|
| SSID | Blakey Wifi |
| Security | WPA2-PSK, AES-CCMP |
| AP1 channel | 1 / 2412 MHz / 20MHz |
| AP2 channel | 11 / 2462 MHz / 20MHz |
| Roaming threshold | Force off below -80 dBm |
| Client-to-client | Enabled (mDNS, Roku, Chromecast, Spotify Connect) |
| Local forwarding | Enabled (traffic stays on bridge-main, not tunnelled) |
| CAPsMAN type | Legacy `/caps-man` (required for MIPS/Atheros AR9300 APs) |

---

## DNS

Router resolves `.home` names locally. All clients use the router's VLAN
gateway IP as their DNS server, which forwards to Pi-hole at 172.17.0.2.

If Pi-hole is down, netwatch automatically fails over to 8.8.8.8,8.8.4.4
within 15 seconds.

---

## WAN

- **Connection**: PPPoE over ether1-WAN
- **Type**: CGNAT (ISP assigns private 10.71.x.x range)
- **Public IP**: Pending — ISP switch in progress
- **Back to Home VPN**: WireGuard, port 65504, managed by MikroTik Cloud

---

## Game Server Port Forwarding (pending public IP)

All game traffic forwards to 10.20.20.3 (AMP, Server2 NIC2).

| Service | Protocol | External Port | Internal Port |
|---------|----------|--------------|--------------|
| Minecraft Java | TCP | 25565 | 25565 |
| Minecraft Bedrock | UDP | 19132 | 19132 |
| Garry's Mod | UDP | 27015 | 27015 |
| Garry's Mod RCON | TCP | 27015 | 27015 |
| TeamSpeak 6 Voice | UDP | 9987 | 9987 |
| TeamSpeak 6 Files | TCP | 30033 | 30033 |

DNAT and forward filter rules are already in place. Will activate automatically
once ISP provides a public IP.
