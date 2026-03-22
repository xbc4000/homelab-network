# Network Layout

## Hardware

| Device | Model | Role |
|--------|-------|------|
| Router | RB3011UiAS | Core router, CAPsMAN controller, container host |
| Storage | USB SSD (256GB) | Container storage, Dude DB, backups |
| AP1 | mAP2nD-1 | Atheros AR9300, 2.4GHz, ether10 on router |
| AP2 | wAP2nD-1 | Atheros AR9300, 2.4GHz, ether2 on mAP2nD-1 |
| Server1 | Dell PER730XD | Primary server, VLAN10 |
| Server2 | Dell PER630 | Secondary server, VLAN20 |

## VLAN Layout

| VLAN | Subnet | Name | Ports | Purpose |
|------|--------|------|-------|---------|
| 10 | 10.10.10.0/24 | vlan10-server1 | ether2 (NIC1), ether3 (NIC2 spare) | Dell PER730XD |
| 20 | 10.20.20.0/24 | vlan20-server2 | ether4 (NIC1), ether5 (NIC2 spare) | Dell PER630 |
| 30 | 10.30.30.0/24 | vlan30-idrac | ether6, ether7 | iDRAC OOB management |
| 40 | 10.40.40.0/24 | vlan40-pi | ether8 | Raspberry Pi |
| 50 | 10.50.50.0/24 | vlan50-av | ether9 | Blu-ray Player (AV) |
| 60 | 10.60.60.0/24 | vlan60-wifi | ether10 → APs | WiFi clients via CAPsMAN |
| — | 172.17.0.0/24 | bridge-main | veth-pihole | Pi-hole container |

## Physical Port Mapping

| Port | Interface Name | Connected To |
|------|----------------|--------------|
| ether1 | ether1-WAN | ISP modem (PPPoE) |
| ether2 | ether2-SRV1-NIC1 | Server1 NIC1 primary |
| ether3 | ether3-SRV1-NIC2 | Server1 NIC2 spare |
| ether4 | ether4-SRV2-NIC1 | Server2 NIC1 primary |
| ether5 | ether5-SRV2-NIC2 | Server2 NIC2 spare |
| ether6 | ether6-iDRAC1 | Server1 iDRAC |
| ether7 | ether7-iDRAC2 | Server2 iDRAC |
| ether8 | ether8-RPi | Raspberry Pi |
| ether9 | ether9-BDR | Blu-ray Player |
| ether10 | ether10-AP | mAP2nD-1 (CAPsMAN uplink) |

## IP Address Assignments

| Host | IP | VLAN | Notes |
|------|----|------|-------|
| Router (Server1 GW) | 10.10.10.1 | 10 | |
| Router (Server2 GW) | 10.20.20.1 | 20 | |
| Router (iDRAC GW) | 10.30.30.1 | 30 | |
| Router (RPi GW) | 10.40.40.1 | 40 | |
| Router (AV GW) | 10.50.50.1 | 50 | |
| Router (WiFi GW) | 10.60.60.1 | 60 | |
| Router (Container GW) | 172.17.0.1 | — | |
| Server1 (PER730XD) | 10.10.10.98 | 10 | DHCP reserved |
| Server2 (PER630) | 10.20.20.x | 20 | DHCP |
| iDRAC1 | 10.30.30.10 | 30 | DHCP |
| iDRAC2 | 10.30.30.11 | 30 | DHCP |
| Raspberry Pi | 10.40.40.x | 40 | DHCP |
| Pi-hole (container) | 172.17.0.2 | — | Static veth |
| mAP2nD-1 | 10.60.60.200 | 60 | Static on AP |
| wAP2nD-1 | 10.60.60.201 | 60 | Static on AP |

## DNS Static Entries

| Hostname | IP |
|----------|----|
| router.home | 10.10.10.1 |
| server1.home | 10.10.10.2 |
| server2.home | 10.20.20.2 |
| idrac1.home | 10.30.30.10 |
| idrac2.home | 10.30.30.11 |
| rpi.home | 10.40.40.2 |
| pihole.home | 172.17.0.2 |
| ap1.home | 10.60.60.200 |
| ap2.home | 10.60.60.201 |

## VLAN Isolation Rules

| Source | Can reach | Cannot reach |
|--------|-----------|--------------|
| Server1 | Server2, iDRAC, WiFi APs, WAN | — |
| Server2 | Server1, iDRAC, WiFi APs, WAN | — |
| iDRAC | Server1, Server2, RPi (metrics collection) | WAN, AV, WiFi |
| RPi | WAN, router | — |
| AV | WAN only | All RFC1918 |
| WiFi | WAN only | Servers, iDRAC |
| WiFi clients | WAN only | Each other (client isolation enabled) |

## DNS

- **Primary**: Pi-hole at 172.17.0.2 — Unbound recursive resolver, no upstream needed
- **Fallback**: 8.8.8.8, 8.8.4.4 — auto-failover via netwatch when Pi-hole is unreachable
- **Failover timing**: Netwatch checks Pi-hole every 15 seconds and switches DNS servers automatically

## WiFi

- **SSID**: Blakey Wifi
- **Security**: WPA2-PSK AES-CCMP
- **Controller**: Legacy CAPsMAN (`/caps-man`) on router — required for MIPS/Atheros AR9300 APs which are incompatible with the new `/interface wifi` CAPsMAN
- **mAP2nD-1**: Channel 1 (2412 MHz), MAC DC:2C:6E:10:54:F1
- **wAP2nD-1**: Channel 11 (2462 MHz), MAC 74:4D:28:52:FC:C3
- **Roaming**: Clients forced to roam when signal drops below -80 dBm (CAPsMAN access-list reject rule)
- **Client isolation**: WiFi-to-WiFi traffic blocked at the firewall forward chain
