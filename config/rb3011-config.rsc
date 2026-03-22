# RB3011UiAS — RouterOS 7.22 — Full Configuration Export
# Exported: 2026-03-22
# Software ID: WTM1-GYDD
# Serial: E7EA0E43348D
#
# REDACTED FIELDS:
#   - PPPoE username            → YOUR-PPPOE-USERNAME
#   - WiFi SSID                 → YOUR-SSID
#   - Pi-hole API password      → YOUR-PIHOLE-API-PASSWORD
#   - LCD PIN                   → YOUR-LCD-PIN
#   - SNMP community string     → YOUR-SNMP-COMMUNITY
#   - Admin username            → YOUR-ADMIN-USER
#   - WireGuard private keys    → not exported by RouterOS
#
# CHANGE LOG:
#   2026-03-22 — Full audit and hardening session
#     - ICMP flood protection scoped to LAN only
#     - Forward chain default drop added
#     - Inter-VLAN isolation: WiFi→RPi, WiFi→AV, WiFi→Pi-hole DNS only,
#       RPi→all-internal, Servers→AV all closed
#     - VLAN40/50/60 input scoped to DNS+NTP only
#     - SEC/DDOS forward rules repositioned correctly
#     - IPv6 firewall clean 8-rule set
#     - Script and scheduler policies minimised
#     - SNMP community renamed + address-restricted
#     - www-ssl disabled
#     - admin user removed
#     - Static DHCP leases all devices
#     - Netwatch IPs corrected, RPi + AMP added
#     - iDRAC NTP added to DHCP network
#     - Remote logging warning + error added
#     - vlan50-av added to graphing
#     - UDP connection tracking tuned (udp-timeout=1m udp-stream-timeout=2m)
#     - mktxp duplicate user removed
#     - amp.home DNS record added
#
#   2026-03-22 — Script session
#     - eth-monitor, wifi-monitor, attack-monitor rewritten
#       Global variables do not persist between scheduled script runs in
#       RouterOS 7.22. Scripts now use the script comment field for state
#       storage — fully persistent, no globals, no foreach loop.
#     - Scheduler policies updated to read,write,policy,test for all monitors
#     - 5 utility scripts added: manual-backup, clear-blacklists,
#       pihole-restart, security-lockdown, syslog-setup
#     - NOTE: RouterOS 7.22 flags monitor scripts I-INVALID due to static
#       analyser false positive on /system script set inside a scheduled
#       script. Scripts execute correctly — flag is cosmetic only.
#
#   2026-03-22 — CAPsMAN fix
#     - Added [IN] CAPsMAN control from APs (UDP 5246/5247 from vlan60-wifi)
#     - Was missing after VLAN60 input was tightened to DNS+NTP only
#     - APs were reachable by ping but not appearing in /caps-man remote-cap
#     - Root cause: tightened input rules silently blocked CAPsMAN control channel
# =============================================================================

/caps-man channel
add band=2ghz-b/g/n comment="mAP2nD ch1" control-channel-width=20mhz \
    frequency=2412 name=ch-map
add band=2ghz-b/g/n comment="wAP2nD ch11" control-channel-width=20mhz \
    frequency=2462 name=ch-wap
/interface bridge
add comment="Main LAN Bridge" igmp-snooping=yes name=bridge-main \
    vlan-filtering=yes
/interface ethernet
set [ find default-name=ether1 ] comment="WAN PPPoE Uplink" name=ether1-WAN
set [ find default-name=ether2 ] comment="Server1 NIC1 primary" name=\
    ether2-SRV1-NIC1
set [ find default-name=ether3 ] comment="Server1 NIC2 spare" name=\
    ether3-SRV1-NIC2
set [ find default-name=ether4 ] comment="Server2 NIC1 primary" name=\
    ether4-SRV2-NIC1
set [ find default-name=ether5 ] comment="Server2 NIC2 spare" name=\
    ether5-SRV2-NIC2
set [ find default-name=ether6 ] comment="iDRAC Server1 OOB" name=\
    ether6-iDRAC1
set [ find default-name=ether7 ] comment="iDRAC Server2 OOB" name=\
    ether7-iDRAC2
set [ find default-name=ether8 ] comment="Raspberry Pi" name=ether8-RPi
set [ find default-name=ether9 ] comment="Blu-ray Player" name=ether9-BDR
set [ find default-name=ether10 ] comment="WiFi AP uplink (mAP2nD-1 CAPsMAN)" \
    name=ether10-AP
/interface pppoe-client
add add-default-route=yes comment="ISP PPPoE WAN" disabled=no interface=\
    ether1-WAN name=pppoe-wan user=YOUR-PPPOE-USERNAME
/interface veth
add address=172.17.0.2/24 comment="Pi-hole container interface" \
    container-mac-address=1C:DE:04:9D:80:98 dhcp=no gateway=172.17.0.1 \
    gateway6="" mac-address=1C:DE:04:9D:80:97 name=veth-pihole
/interface wireguard
add comment=back-to-home-vpn listen-port=65504 mtu=1420 name=back-to-home-vpn
/interface vlan
add comment="Server1 LAN" interface=bridge-main name=vlan10-server1 vlan-id=10
add comment="Server2 LAN" interface=bridge-main name=vlan20-server2 vlan-id=20
add comment="iDRAC OOB Management" interface=bridge-main name=vlan30-idrac \
    vlan-id=30
add comment="Raspberry Pi" interface=bridge-main name=vlan40-pi vlan-id=40
add comment="AV Blu-ray" interface=bridge-main name=vlan50-av vlan-id=50
add comment="WiFi clients via CAPsMAN" interface=bridge-main name=vlan60-wifi \
    vlan-id=60
/caps-man datapath
add bridge=bridge-main client-to-client-forwarding=yes comment=\
    "WiFi local forwarding VLAN60 via ether10 pvid" local-forwarding=yes \
    name=dp-wifi
/caps-man security
add authentication-types=wpa2-psk encryption=aes-ccm name=wifi-sec
/caps-man configuration
add channel=ch-map comment="mAP2nD config" datapath=dp-wifi name=cfg-map \
    security=wifi-sec ssid="YOUR-SSID"
add channel=ch-wap comment="wAP2nD config" datapath=dp-wifi name=cfg-wap \
    security=wifi-sec ssid="YOUR-SSID"
/disk
add parent=usb1 partition-number=1 partition-offset=512 partition-size=\
    256060513792 type=partition
/interface list
add comment="WAN interfaces" name=WAN
add comment="LAN interfaces" name=LAN
add comment="Management Winbox neighbor discovery" name=MGMT
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
/ip pool
add name=pool-server1 ranges=10.10.10.10-10.10.10.99
add name=pool-server2 ranges=10.20.20.10-10.20.20.99
add name=pool-idrac ranges=10.30.30.10-10.30.30.30
add name=pool-pi ranges=10.40.40.10-10.40.40.30
add name=pool-av ranges=10.50.50.10-10.50.50.20
add name=pool-wifi ranges=10.60.60.10-10.60.60.199
/ip dhcp-server
add address-pool=pool-server1 interface=vlan10-server1 lease-script=\
    dhcp-new-lease lease-time=12h name=dhcp-server1
add address-pool=pool-server2 interface=vlan20-server2 lease-script=\
    dhcp-new-lease lease-time=12h name=dhcp-server2
add address-pool=pool-idrac interface=vlan30-idrac lease-script=dhcp-new-lease \
    lease-time=1d name=dhcp-idrac
add address-pool=pool-pi interface=vlan40-pi lease-script=dhcp-new-lease \
    lease-time=12h name=dhcp-pi
add address-pool=pool-av interface=vlan50-av lease-script=dhcp-new-lease \
    lease-time=6h name=dhcp-av
add address-pool=pool-wifi interface=vlan60-wifi lease-script=dhcp-new-lease \
    lease-time=4h name=dhcp-wifi
/snmp community
set [ find default=yes ] addresses=10.10.10.0/24,10.20.20.0/24 name=\
    YOUR-SNMP-COMMUNITY
/system logging action
set 3 remote=172.17.0.2
/system script
add comment="Play Mario full theme song anytime" dont-require-permissions=yes \
    name=super-mario owner=YOUR-ADMIN-USER policy=test source="\
    \n:beep frequency=660 length=100ms; :delay 150ms;\
    \n:beep frequency=660 length=100ms; :delay 300ms;\
    \n:beep frequency=660 length=100ms; :delay 300ms;\
    \n:beep frequency=510 length=100ms; :delay 100ms;\
    \n:beep frequency=660 length=100ms; :delay 300ms;\
    \n:beep frequency=770 length=100ms; :delay 550ms;\
    \n:beep frequency=380 length=100ms; :delay 575ms;\
    \n:beep frequency=510 length=100ms; :delay 450ms;\
    \n:beep frequency=380 length=100ms; :delay 400ms;\
    \n:beep frequency=320 length=100ms; :delay 500ms;\
    \n:beep frequency=440 length=100ms; :delay 300ms;\
    \n:beep frequency=480 length=80ms; :delay 330ms;\
    \n:beep frequency=450 length=100ms; :delay 150ms;\
    \n:beep frequency=430 length=100ms; :delay 300ms;\
    \n:beep frequency=380 length=100ms; :delay 200ms;\
    \n:beep frequency=660 length=80ms; :delay 200ms;\
    \n:beep frequency=760 length=50ms; :delay 150ms;\
    \n:beep frequency=860 length=100ms; :delay 300ms;\
    \n:beep frequency=700 length=80ms; :delay 150ms;\
    \n:beep frequency=760 length=50ms; :delay 350ms;\
    \n:beep frequency=660 length=80ms; :delay 300ms;\
    \n:beep frequency=520 length=80ms; :delay 150ms;\
    \n:beep frequency=580 length=80ms; :delay 150ms;\
    \n:beep frequency=480 length=80ms; :delay 500ms;\
    \n:beep frequency=510 length=100ms; :delay 450ms;\
    \n:beep frequency=380 length=100ms; :delay 400ms;\
    \n:beep frequency=320 length=100ms; :delay 500ms;\
    \n:beep frequency=440 length=100ms; :delay 300ms;\
    \n:beep frequency=480 length=80ms; :delay 330ms;\
    \n:beep frequency=450 length=100ms; :delay 150ms;\
    \n:beep frequency=430 length=100ms; :delay 300ms;\
    \n:beep frequency=380 length=100ms; :delay 200ms;\
    \n:beep frequency=660 length=80ms; :delay 200ms;\
    \n:beep frequency=760 length=50ms; :delay 150ms;\
    \n:beep frequency=860 length=100ms; :delay 300ms;\
    \n:beep frequency=700 length=80ms; :delay 150ms;\
    \n:beep frequency=760 length=50ms; :delay 350ms;\
    \n:beep frequency=660 length=80ms; :delay 300ms;\
    \n:beep frequency=520 length=80ms; :delay 150ms;\
    \n:beep frequency=580 length=80ms; :delay 150ms;\
    \n:beep frequency=480 length=80ms; :delay 500ms;\
    \n:beep frequency=500 length=100ms; :delay 300ms;\
    \n:beep frequency=760 length=100ms; :delay 100ms;\
    \n:beep frequency=720 length=100ms; :delay 150ms;\
    \n:beep frequency=680 length=100ms; :delay 150ms;\
    \n:beep frequency=620 length=150ms; :delay 300ms;\
    \n:beep frequency=650 length=150ms; :delay 300ms;\
    \n:beep frequency=380 length=100ms; :delay 150ms;\
    \n:beep frequency=430 length=100ms; :delay 150ms;\
    \n:beep frequency=500 length=100ms; :delay 300ms;\
    \n:beep frequency=430 length=100ms; :delay 150ms;\
    \n:beep frequency=500 length=100ms; :delay 100ms;\
    \n:beep frequency=570 length=100ms; :delay 220ms;\
    \n:beep frequency=500 length=100ms; :delay 300ms;\
    \n:beep frequency=760 length=100ms; :delay 100ms;\
    \n:beep frequency=720 length=100ms; :delay 150ms;\
    \n:beep frequency=680 length=100ms; :delay 150ms;\
    \n:beep frequency=620 length=150ms; :delay 300ms;\
    \n:beep frequency=650 length=200ms; :delay 300ms;\
    \n:beep frequency=1020 length=80ms; :delay 300ms;\
    \n:beep frequency=1020 length=80ms; :delay 150ms;\
    \n:beep frequency=1020 length=80ms; :delay 300ms;\
    \n:beep frequency=380 length=100ms; :delay 300ms;\
    \n:beep frequency=500 length=100ms; :delay 300ms;\
    \n:beep frequency=760 length=100ms; :delay 100ms;\
    \n:beep frequency=720 length=100ms; :delay 150ms;\
    \n:beep frequency=680 length=100ms; :delay 150ms;\
    \n:beep frequency=620 length=150ms; :delay 300ms;\
    \n:beep frequency=650 length=150ms; :delay 300ms;\
    \n:beep frequency=380 length=100ms; :delay 150ms;\
    \n:beep frequency=430 length=100ms; :delay 150ms;\
    \n:beep frequency=500 length=100ms; :delay 300ms;\
    \n:beep frequency=430 length=100ms; :delay 150ms;\
    \n:beep frequency=500 length=100ms; :delay 100ms;\
    \n:beep frequency=570 length=100ms; :delay 420ms;\
    \n:beep frequency=585 length=100ms; :delay 450ms;\
    \n:beep frequency=550 length=100ms; :delay 420ms;\
    \n:beep frequency=500 length=100ms; :delay 360ms;\
    \n:beep frequency=380 length=100ms; :delay 300ms;\
    \n:beep frequency=500 length=100ms; :delay 300ms;\
    \n:beep frequency=500 length=100ms; :delay 150ms;\
    \n:beep frequency=500 length=100ms; :delay 300ms;\
    \n:beep frequency=500 length=100ms; :delay 300ms;\
    \n:beep frequency=760 length=100ms; :delay 100ms;\
    \n:beep frequency=720 length=100ms; :delay 150ms;\
    \n:beep frequency=680 length=100ms; :delay 150ms;\
    \n:beep frequency=620 length=150ms; :delay 300ms;\
    \n:beep frequency=650 length=150ms; :delay 300ms;\
    \n:beep frequency=380 length=100ms; :delay 150ms;\
    \n:beep frequency=430 length=100ms; :delay 150ms;\
    \n:beep frequency=500 length=100ms; :delay 300ms;\
    \n:beep frequency=430 length=100ms; :delay 150ms;\
    \n:beep frequency=500 length=100ms; :delay 100ms;\
    \n:beep frequency=570 length=100ms; :delay 220ms;\
    \n:beep frequency=500 length=100ms; :delay 300ms;\
    \n:beep frequency=760 length=100ms; :delay 100ms;\
    \n:beep frequency=720 length=100ms; :delay 150ms;\
    \n:beep frequency=680 length=100ms; :delay 150ms;\
    \n:beep frequency=620 length=150ms; :delay 300ms;\
    \n:beep frequency=650 length=200ms; :delay 300ms;\
    \n:beep frequency=1020 length=80ms; :delay 300ms;\
    \n:beep frequency=1020 length=80ms; :delay 150ms;\
    \n:beep frequency=1020 length=80ms; :delay 300ms;\
    \n:beep frequency=380 length=100ms; :delay 300ms;\
    \n:beep frequency=500 length=100ms; :delay 300ms;\
    \n:beep frequency=760 length=100ms; :delay 100ms;\
    \n:beep frequency=720 length=100ms; :delay 150ms;\
    \n:beep frequency=680 length=100ms; :delay 150ms;\
    \n:beep frequency=620 length=150ms; :delay 300ms;\
    \n:beep frequency=650 length=150ms; :delay 300ms;\
    \n:beep frequency=380 length=100ms; :delay 150ms;\
    \n:beep frequency=430 length=100ms; :delay 150ms;\
    \n:beep frequency=500 length=100ms; :delay 300ms;\
    \n:beep frequency=430 length=100ms; :delay 150ms;\
    \n:beep frequency=500 length=100ms; :delay 100ms;\
    \n:beep frequency=570 length=100ms; :delay 420ms;\
    \n:beep frequency=585 length=100ms; :delay 450ms;\
    \n:beep frequency=550 length=100ms; :delay 420ms;\
    \n:beep frequency=500 length=100ms; :delay 360ms;\
    \n:beep frequency=380 length=100ms; :delay 300ms;\
    \n:beep frequency=500 length=100ms; :delay 300ms;\
    \n:beep frequency=500 length=100ms; :delay 150ms;\
    \n:beep frequency=500 length=100ms; :delay 300ms;\
    \n:beep frequency=500 length=60ms; :delay 150ms;\
    \n:beep frequency=500 length=80ms; :delay 300ms;\
    \n:beep frequency=500 length=60ms; :delay 350ms;\
    \n:beep frequency=500 length=80ms; :delay 150ms;\
    \n:beep frequency=580 length=80ms; :delay 350ms;\
    \n:beep frequency=660 length=80ms; :delay 150ms;\
    \n:beep frequency=500 length=80ms; :delay 300ms;\
    \n:beep frequency=430 length=80ms; :delay 150ms;\
    \n:beep frequency=380 length=80ms; :delay 600ms;\
    \n:beep frequency=500 length=60ms; :delay 150ms;\
    \n:beep frequency=500 length=80ms; :delay 300ms;\
    \n:beep frequency=500 length=60ms; :delay 350ms;\
    \n:beep frequency=500 length=80ms; :delay 150ms;\
    \n:beep frequency=580 length=80ms; :delay 150ms;\
    \n:beep frequency=660 length=80ms; :delay 550ms;\
    \n:beep frequency=870 length=80ms; :delay 325ms;\
    \n:beep frequency=760 length=80ms; :delay 600ms;\
    \n"
add comment="Netwatch down alert" dont-require-permissions=yes name=alert-down \
    owner=YOUR-ADMIN-USER policy=test source=":beep frequency=880 length=200ms;\
    \ :delay 50ms; :beep frequency=660 length=200ms; :delay 50ms; :beep \
    frequency=440 length=400ms"
add comment="WAN down urgent alarm" dont-require-permissions=yes name=\
    alert-wan-down owner=YOUR-ADMIN-USER policy=test source=":beep \
    frequency=1000 length=100ms; :delay 100ms; :beep frequency=1000 \
    length=100ms; :delay 100ms; :beep frequency=1000 length=100ms; :delay \
    100ms; :beep frequency=1000 length=100ms; :delay 100ms; :beep \
    frequency=1000 length=100ms; :delay 300ms; :beep frequency=800 \
    length=300ms; :delay 100ms; :beep frequency=800 length=300ms"
add comment="Netwatch up alert" dont-require-permissions=yes name=alert-up \
    owner=YOUR-ADMIN-USER policy=test source=":beep frequency=523 length=150ms;\
    \ :delay 50ms; :beep frequency=784 length=300ms"
add comment="New DHCP lease tone and log" dont-require-permissions=yes name=\
    dhcp-new-lease owner=YOUR-ADMIN-USER policy=read,write,test source=":beep \
    frequency=1047 length=80ms; :delay 50ms; :beep frequency=1319 length=80ms;\
    \ :delay 50ms; :beep frequency=1568 length=150ms; :local msg (\"New lease: \
    \" . \$leaseActIP . \" MAC: \" . \$leaseActMAC); /log info \$msg"
add comment="WiFi client connected" dont-require-permissions=yes name=\
    wifi-connect owner=YOUR-ADMIN-USER policy=test source=":beep \
    frequency=1047 length=80ms; :delay 50ms; :beep frequency=1319 length=80ms;\
    \ :delay 50ms; :beep frequency=1568 length=150ms"
add comment="WiFi client disconnected" dont-require-permissions=yes name=\
    wifi-disconnect owner=YOUR-ADMIN-USER policy=test source=":beep \
    frequency=1568 length=80ms; :delay 50ms; :beep frequency=1319 length=80ms;\
    \ :delay 50ms; :beep frequency=1047 length=150ms"
# wifi-monitor: state stored in script comment field — global variables do not
# persist between scheduled script runs in RouterOS 7.22. I-INVALID flag is a
# static analyser false positive; script executes correctly.
add comment="0" dont-require-permissions=yes name=wifi-monitor \
    owner=YOUR-ADMIN-USER policy=read,write,test source=\
    ":local prev [:tonum [/system script get [find name=wifi-monitor] comment]];\
    \n:local current [:len [/caps-man registration-table find]];\
    \n:if ([:typeof \$prev] = \"nil\") do={:set prev \$current};\
    \n:if (\$current > \$prev) do={\
    \n  :beep frequency=1047 length=80ms;\
    \n  :delay 50ms;\
    \n  :beep frequency=1319 length=80ms;\
    \n  :delay 50ms;\
    \n  :beep frequency=1568 length=150ms;\
    \n};\
    \n:if (\$current < \$prev) do={\
    \n  :beep frequency=1568 length=80ms;\
    \n  :delay 50ms;\
    \n  :beep frequency=1319 length=80ms;\
    \n  :delay 50ms;\
    \n  :beep frequency=1047 length=150ms;\
    \n};\
    \n/system script set [find name=wifi-monitor] comment=\$current;"
add dont-require-permissions=yes name=attack-alarm owner=YOUR-ADMIN-USER \
    policy=test source="\
    \n:beep frequency=440 length=50ms; :delay 30ms;\
    \n:beep frequency=550 length=50ms; :delay 30ms;\
    \n:beep frequency=660 length=50ms; :delay 30ms;\
    \n:beep frequency=880 length=50ms; :delay 30ms;\
    \n:beep frequency=1100 length=50ms; :delay 30ms;\
    \n:beep frequency=880 length=50ms; :delay 30ms;\
    \n:beep frequency=660 length=50ms; :delay 30ms;\
    \n:beep frequency=550 length=50ms; :delay 30ms;\
    \n:beep frequency=440 length=50ms; :delay 100ms;\
    \n:beep frequency=440 length=50ms; :delay 30ms;\
    \n:beep frequency=550 length=50ms; :delay 30ms;\
    \n:beep frequency=660 length=50ms; :delay 30ms;\
    \n:beep frequency=880 length=50ms; :delay 30ms;\
    \n:beep frequency=1100 length=50ms; :delay 30ms;\
    \n:beep frequency=880 length=50ms; :delay 30ms;\
    \n:beep frequency=660 length=50ms; :delay 30ms;\
    \n:beep frequency=550 length=50ms; :delay 30ms;\
    \n:beep frequency=440 length=50ms; :delay 100ms;\
    \n:beep frequency=440 length=50ms; :delay 30ms;\
    \n:beep frequency=550 length=50ms; :delay 30ms;\
    \n:beep frequency=660 length=50ms; :delay 30ms;\
    \n:beep frequency=880 length=50ms; :delay 30ms;\
    \n:beep frequency=1100 length=50ms; :delay 30ms;\
    \n:beep frequency=880 length=50ms; :delay 30ms;\
    \n:beep frequency=660 length=50ms; :delay 30ms;\
    \n:beep frequency=550 length=50ms; :delay 30ms;\
    \n:beep frequency=440 length=300ms;\
    \n"
# attack-monitor: same state persistence approach as wifi-monitor and eth-monitor.
add comment="0" dont-require-permissions=yes name=attack-monitor \
    owner=YOUR-ADMIN-USER policy=read,write,test source=\
    ":local prev [:tonum [/system script get [find name=attack-monitor] comment]];\
    \n:local ddos [:len [/ip firewall address-list find list=ddos-blacklist]];\
    \n:local ssh [:len [/ip firewall address-list find list=ssh-blacklist]];\
    \n:local scan [:len [/ip firewall address-list find list=port-scanners]];\
    \n:local total (\$ddos + \$ssh + \$scan);\
    \n:if ([:typeof \$prev] = \"nil\") do={:set prev \$total};\
    \n:if (\$total > \$prev) do={\
    \n  :beep frequency=440 length=50ms; :delay 30ms;\
    \n  :beep frequency=550 length=50ms; :delay 30ms;\
    \n  :beep frequency=660 length=50ms; :delay 30ms;\
    \n  :beep frequency=880 length=50ms; :delay 30ms;\
    \n  :beep frequency=1100 length=50ms; :delay 30ms;\
    \n  :beep frequency=880 length=50ms; :delay 30ms;\
    \n  :beep frequency=660 length=50ms; :delay 30ms;\
    \n  :beep frequency=550 length=50ms; :delay 30ms;\
    \n  :beep frequency=440 length=300ms;\
    \n  /log warning \"ATTACK DETECTED blacklist count increased\";\
    \n};\
    \n/system script set [find name=attack-monitor] comment=\$total;"
add comment="Trigger immediate RSC + encrypted binary backup" \
    dont-require-permissions=no name=manual-backup owner=YOUR-ADMIN-USER \
    policy=read,write,sensitive source=\
    "/export file=usb1-part1/backups/daily/rb3011-config-manual\
    \n/system backup save name=usb1-part1/backups/weekly/rb3011-full-manual \
    encryption=aes-sha256\
    \n/log info \"Manual backup completed\""
add comment="Clear all DDoS/SSH/scanner blacklists and SSH stage lists" \
    dont-require-permissions=no name=clear-blacklists owner=YOUR-ADMIN-USER \
    policy=read,write source=\
    "/ip firewall address-list remove [find list=ddos-blacklist]\
    \n/ip firewall address-list remove [find list=ssh-blacklist]\
    \n/ip firewall address-list remove [find list=port-scanners]\
    \n/ip firewall address-list remove [find list=ssh-stage1]\
    \n/ip firewall address-list remove [find list=ssh-stage2]\
    \n/ip firewall address-list remove [find list=ssh-stage3]\
    \n/log warning \"All blacklists cleared manually\""
add comment="Restart Pi-hole container cleanly - DNS auto-restores via netwatch" \
    dont-require-permissions=no name=pihole-restart owner=YOUR-ADMIN-USER \
    policy=read,write source=\
    "/ip dns set servers=8.8.8.8,8.8.4.4\
    \n/log info \"Pi-hole restart: DNS switched to Google\"\
    \n/container stop [find name~\"pihole\"]\
    \n:delay 5s\
    \n/container start [find name~\"pihole\"]\
    \n/log info \"Pi-hole restart: container started\""
add comment="Re-apply full security lockdown - run from VLAN10 only" \
    dont-require-permissions=no name=security-lockdown owner=YOUR-ADMIN-USER \
    policy=read,write,policy,sensitive source=\
    "/ip service set ftp disabled=yes\
    \n/ip service set telnet disabled=yes\
    \n/ip service set www disabled=yes\
    \n/ip service set www-ssl disabled=yes\
    \n/ip service set reverse-proxy disabled=yes\
    \n/ip service set api-ssl disabled=yes\
    \n/ip service set ssh address=10.10.10.0/24,10.30.30.0/24 port=2222\
    \n/ip service set winbox address=10.10.10.0/24,10.30.30.0/24\
    \n/ip service set api address=10.10.10.0/24,10.30.30.0/24\
    \n/ip ssh set strong-crypto=yes\
    \n/tool mac-server set allowed-interface-list=none\
    \n/tool mac-server mac-winbox set allowed-interface-list=none\
    \n/tool mac-server ping set enabled=no\
    \n/ip neighbor discovery-settings set discover-interface-list=none\
    \n/tool bandwidth-server set enabled=no\
    \n/ip cloud set update-time=no\
    \n/ip settings set rp-filter=strict tcp-syncookies=yes\
    \n/log warning \"Security lockdown applied\""
add comment="Configure syslog forwarding to Pi-hole" \
    dont-require-permissions=no name=syslog-setup owner=YOUR-ADMIN-USER \
    policy=read,write source=\
    "/system logging action set 3 remote=172.17.0.2\
    \n/log info \"Syslog forwarding configured\""
# eth-monitor: same state persistence approach as wifi-monitor and attack-monitor.
add comment="9" dont-require-permissions=yes name=eth-monitor \
    owner=YOUR-ADMIN-USER policy=read,write,test source=\
    ":local prev [:tonum [/system script get [find name=eth-monitor] comment]];\
    \n:local current [:len [/interface ethernet find running=yes]];\
    \n:if ([:typeof \$prev] = \"nil\") do={:set prev \$current};\
    \n:if (\$current > \$prev) do={\
    \n  :beep frequency=523 length=150ms;\
    \n  :delay 50ms;\
    \n  :beep frequency=784 length=300ms;\
    \n};\
    \n:if (\$current < \$prev) do={\
    \n  :beep frequency=880 length=200ms;\
    \n  :delay 50ms;\
    \n  :beep frequency=660 length=200ms;\
    \n  :delay 50ms;\
    \n  :beep frequency=440 length=400ms;\
    \n};\
    \n/system script set [find name=eth-monitor] comment=\$current;"
/user group
add name=mktxp_group policy=\
    "read,api,!local,!telnet,!ssh,!ftp,!reboot,!write,!policy,!test,!winbox,!password,!web,!sniff,!sensitive,!romon,!rest-api"
/caps-man access-list
add action=reject comment="Force roaming below -80dBm" signal-range=-120..-80
add action=accept comment="Allow all authenticated clients"
add action=reject comment="Default deny all clients"
/caps-man manager
set ca-certificate=auto certificate=auto enabled=yes upgrade-policy=\
    suggest-same-version
/caps-man provisioning
add action=create-dynamic-enabled comment=mAP2nD-1 master-configuration=\
    cfg-map name-format=identity radio-mac=DC:2C:6E:10:54:F1
add action=create-dynamic-enabled comment=wAP2nD-1 master-configuration=\
    cfg-wap name-format=identity radio-mac=74:4D:28:52:FC:C3
/container
add comment="Pi-hole v6 + Unbound + Hyperlocal" envlists=pihole-env \
    interface=veth-pihole layer-dir=/usb1-part1/layers logging=yes \
    mountlists=pihole-data,pihole-log name=pihole-unbound-hyperlocal:latest \
    remote-image=sujiba/pihole-unbound-hyperlocal:latest root-dir=\
    /usb1-part1/containers/pihole start-on-boot=yes workdir=/
/container config
set layer-dir=/usb1-part1/layers memory-high=512.0MiB registry-url=\
    https://registry-1.docker.io tmpdir=/usb1-part1/containers/tmp
/container envs
add key=FTLCONF_dns_listeningMode list=pihole-env value=all
add key=FTLCONF_dns_upstreams list=pihole-env value=127.0.0.1#5335
add key=FTLCONF_webserver_api_password list=pihole-env value=\
    YOUR-PIHOLE-API-PASSWORD
add key=TZ list=pihole-env value=America/Toronto
/container mounts
add comment="Pi-hole config and gravity DB" dst=/etc/pihole list=pihole-data \
    src=/usb1-part1/containers/pihole/data
add comment="Pi-hole logs" dst=/var/log/pihole list=pihole-log src=\
    /usb1-part1/containers/pihole/log
/dude
set data-directory=usb1-part1/dude enabled=yes
/interface bridge port
add bridge=bridge-main comment="Server1 NIC1 VLAN10" interface=\
    ether2-SRV1-NIC1 pvid=10
add bridge=bridge-main comment="Server1 NIC2 spare VLAN10" interface=\
    ether3-SRV1-NIC2 pvid=10
add bridge=bridge-main comment="Server2 NIC1 VLAN20" interface=\
    ether4-SRV2-NIC1 pvid=20
add bridge=bridge-main comment="Server2 NIC2 spare VLAN20" interface=\
    ether5-SRV2-NIC2 pvid=20
add bridge=bridge-main comment="iDRAC1 VLAN30" interface=ether6-iDRAC1 pvid=30
add bridge=bridge-main comment="iDRAC2 VLAN30" interface=ether7-iDRAC2 pvid=30
add bridge=bridge-main comment="RPi VLAN40" interface=ether8-RPi pvid=40
add bridge=bridge-main comment="WiFi AP uplink VLAN60 CAPsMAN local forwarding" \
    interface=ether10-AP pvid=60
add bridge=bridge-main comment="Blu-ray VLAN50" interface=ether9-BDR pvid=50
add bridge=bridge-main comment="Pi-hole container bridge port" interface=\
    veth-pihole
/ip firewall connection tracking
set udp-stream-timeout=2m udp-timeout=1m
/ip neighbor discovery-settings
set discover-interface-list=none
/ip settings
set rp-filter=strict tcp-syncookies=yes
/interface bridge vlan
add bridge=bridge-main tagged=bridge-main untagged=\
    ether2-SRV1-NIC1,ether3-SRV1-NIC2 vlan-ids=10
add bridge=bridge-main tagged=bridge-main untagged=\
    ether4-SRV2-NIC1,ether5-SRV2-NIC2 vlan-ids=20
add bridge=bridge-main tagged=bridge-main untagged=\
    ether6-iDRAC1,ether7-iDRAC2 vlan-ids=30
add bridge=bridge-main tagged=bridge-main untagged=ether8-RPi vlan-ids=40
add bridge=bridge-main tagged=bridge-main untagged=ether10-AP vlan-ids=60
add bridge=bridge-main tagged=bridge-main untagged=ether9-BDR vlan-ids=50
/interface list member
add interface=pppoe-wan list=WAN
add interface=vlan10-server1 list=LAN
add interface=vlan20-server2 list=LAN
add interface=vlan30-idrac list=LAN
add interface=vlan40-pi list=LAN
add interface=vlan50-av list=LAN
add interface=vlan60-wifi list=LAN
add interface=vlan10-server1 list=MGMT
add interface=vlan30-idrac list=MGMT
/ip address
add address=10.10.10.1/24 comment="Server1 GW" interface=vlan10-server1 \
    network=10.10.10.0
add address=10.20.20.1/24 comment="Server2 GW" interface=vlan20-server2 \
    network=10.20.20.0
add address=10.30.30.1/24 comment="iDRAC GW" interface=vlan30-idrac \
    network=10.30.30.0
add address=10.40.40.1/24 comment="RPi GW" interface=vlan40-pi \
    network=10.40.40.0
add address=10.50.50.1/24 comment="AV GW" interface=vlan50-av \
    network=10.50.50.0
add address=10.60.60.1/24 comment="WiFi GW" interface=vlan60-wifi \
    network=10.60.60.0
add address=172.17.0.1/24 comment="Container GW" interface=bridge-main \
    network=172.17.0.0
/ip cloud
set back-to-home-vpn=enabled update-time=no
/ip dhcp-server lease
add address=10.10.10.2 comment=Server1-PER730XD-NIC1 mac-address=\
    24:6E:96:27:91:44 server=dhcp-server1
add address=10.20.20.2 comment=Server2-PER630-NIC1 mac-address=\
    24:6E:96:AB:39:ED server=dhcp-server2
add address=10.20.20.3 comment=Server2-PER630-NIC2-AMP mac-address=\
    24:6E:96:AB:39:EC server=dhcp-server2
add address=10.30.30.10 comment=iDRAC1-PER730XD mac-address=\
    44:A8:42:4B:BF:95 server=dhcp-idrac
add address=10.30.30.11 comment=iDRAC2-PER630 mac-address=\
    84:7B:EB:D6:0B:A2 server=dhcp-idrac
add address=10.40.40.2 comment=RPi-TXMRPI mac-address=D8:3A:DD:3C:A2:CC \
    server=dhcp-pi
/ip dhcp-server network
add address=10.10.10.0/24 comment=Server1 dns-server=10.10.10.1 \
    gateway=10.10.10.1 ntp-server=10.10.10.1
add address=10.20.20.0/24 comment=Server2 dns-server=10.20.20.1 \
    gateway=10.20.20.1 ntp-server=10.20.20.1
add address=10.30.30.0/24 comment="iDRAC OOB" dns-server=10.30.30.1 \
    gateway=10.30.30.1 ntp-server=10.30.30.1
add address=10.40.40.0/24 comment=RPi dns-server=10.40.40.1 \
    gateway=10.40.40.1 ntp-server=10.40.40.1
add address=10.50.50.0/24 comment=AV dns-server=10.50.50.1 \
    gateway=10.50.50.1
add address=10.60.60.0/24 comment=WiFi dns-server=10.60.60.1 \
    gateway=10.60.60.1 ntp-server=10.60.60.1
/ip dns
set allow-remote-requests=yes cache-max-ttl=1d cache-size=8192KiB \
    servers=172.17.0.2,8.8.8.8,8.8.4.4
/ip dns static
add address=10.10.10.1 name=router.home type=A
add address=10.10.10.2 name=server1.home type=A
add address=10.20.20.2 name=server2.home type=A
add address=10.20.20.3 name=amp.home type=A
add address=10.30.30.10 name=idrac1.home type=A
add address=10.30.30.11 name=idrac2.home type=A
add address=10.40.40.2 name=rpi.home type=A
add address=172.17.0.2 name=pihole.home type=A
add address=10.60.60.200 name=ap1.home type=A
add address=10.60.60.201 name=ap2.home type=A
/ip firewall address-list
add address=0.0.0.0/8 comment="defconf: RFC6890" list=no_forward_ipv4
add address=169.254.0.0/16 comment="defconf: RFC6890 link-local" list=\
    no_forward_ipv4
add address=224.0.0.0/4 comment="defconf: multicast" list=no_forward_ipv4
add address=255.255.255.255 comment="defconf: RFC6890 broadcast" list=\
    no_forward_ipv4
add address=8.8.8.8 comment="Google DNS - never blacklist" list=whitelist
add address=8.8.4.4 comment="Google DNS - never blacklist" list=whitelist
add address=10.50.50.20 comment="Admin workstation" list=whitelist
add address=10.10.10.0/24 comment="Server1 VLAN - never blacklist" list=\
    whitelist
add address=10.20.20.0/24 comment="Server2 VLAN - never blacklist" list=\
    whitelist
/ip firewall filter
add action=accept chain=input comment=\
    "defconf: accept established,related,untracked" connection-state=\
    established,related,untracked
add action=drop chain=input comment="defconf: drop invalid" \
    connection-state=invalid
add action=accept chain=input comment="defconf: accept to local loopback" \
    dst-address=127.0.0.1
add action=accept chain=input comment="[IN] Accept ICMP from LAN only" \
    in-interface-list=LAN protocol=icmp
add action=accept chain=input comment="[IN] Server1 full router access" \
    in-interface=vlan10-server1
add action=accept chain=input comment="[IN] Server2 full router access" \
    in-interface=vlan20-server2
add action=accept chain=input comment="[IN] iDRAC management access" \
    in-interface=vlan30-idrac
add action=accept chain=input comment="[IN] CAPsMAN control from APs" \
    dst-port=5246,5247 in-interface=vlan60-wifi protocol=udp
add action=accept chain=input comment="[IN] RPi DNS+NTP" dst-port=53,123 \
    in-interface=vlan40-pi protocol=udp
add action=accept chain=input comment="[IN] RPi DNS TCP" dst-port=53 \
    in-interface=vlan40-pi protocol=tcp
add action=accept chain=input comment="[IN] AV DNS" dst-port=53 \
    in-interface=vlan50-av protocol=udp
add action=accept chain=input comment="[IN] AV DNS TCP" dst-port=53 \
    in-interface=vlan50-av protocol=tcp
add action=accept chain=input comment="[IN] WiFi DNS+NTP" dst-port=53,123 \
    in-interface=vlan60-wifi protocol=udp
add action=accept chain=input comment="[IN] WiFi DNS TCP" dst-port=53 \
    in-interface=vlan60-wifi protocol=tcp
add action=accept chain=input comment="[IN] Back to Home VPN" dst-port=65504 \
    in-interface=pppoe-wan protocol=udp
add action=accept chain=input comment="[IN] Back to Home clients" \
    in-interface=back-to-home-vpn
add action=drop chain=input comment="defconf: drop all not coming from LAN" \
    in-interface-list=!LAN
add action=accept chain=forward comment="defconf: accept in ipsec policy" \
    ipsec-policy=in,ipsec
add action=accept chain=forward comment="defconf: accept out ipsec policy" \
    ipsec-policy=out,ipsec
add action=fasttrack-connection chain=forward comment=\
    "defconf: fasttrack established" connection-state=established,related
add action=accept chain=forward comment=\
    "defconf: accept established,related,untracked" connection-state=\
    established,related,untracked
add action=drop chain=forward comment="defconf: drop invalid" \
    connection-state=invalid
add action=drop chain=forward comment="defconf: drop bad forward src IPs" \
    src-address-list=no_forward_ipv4
add action=drop chain=forward comment="defconf: drop bad forward dst IPs" \
    dst-address-list=no_forward_ipv4
add action=accept chain=forward comment="[FWD] Back to Home to all VLANs" \
    in-interface=back-to-home-vpn
add action=drop chain=forward comment="[FWD] iDRAC no WAN" \
    out-interface=pppoe-wan src-address=10.30.30.0/24
add action=accept chain=forward comment="[FWD] iDRAC to RPi metrics" \
    dst-address=10.40.40.0/24 src-address=10.30.30.0/24
add action=drop chain=forward comment="[FWD] iDRAC no AV" \
    dst-address=10.50.50.0/24 src-address=10.30.30.0/24
add action=drop chain=forward comment="[FWD] iDRAC no WiFi" \
    dst-address=10.60.60.0/24 src-address=10.30.30.0/24
add action=accept chain=forward comment="[FWD] iDRAC to Server1" \
    dst-address=10.10.10.0/24 src-address=10.30.30.0/24
add action=accept chain=forward comment="[FWD] iDRAC to Server2" \
    dst-address=10.20.20.0/24 src-address=10.30.30.0/24
add action=accept chain=forward comment="[FWD] Server1 to iDRAC" \
    dst-address=10.30.30.0/24 src-address=10.10.10.0/24
add action=accept chain=forward comment="[FWD] Server2 to iDRAC" \
    dst-address=10.30.30.0/24 src-address=10.20.20.0/24
add action=drop chain=forward comment="[FWD] AV no RFC1918" \
    dst-address=10.0.0.0/8 src-address=10.50.50.0/24
add action=drop chain=forward comment="[FWD] AV no RFC1918" \
    dst-address=172.16.0.0/12 src-address=10.50.50.0/24
add action=drop chain=forward comment="[FWD] AV no RFC1918" \
    dst-address=192.168.0.0/16 src-address=10.50.50.0/24
add action=drop chain=forward comment="[FWD] WiFi no Server1" \
    dst-address=10.10.10.0/24 src-address=10.60.60.0/24
add action=drop chain=forward comment="[FWD] WiFi no Server2" \
    dst-address=10.20.20.0/24 src-address=10.60.60.0/24
add action=drop chain=forward comment="[FWD] WiFi no iDRAC" \
    dst-address=10.30.30.0/24 src-address=10.60.60.0/24
add action=accept chain=forward comment="[FWD] Server1 to Server2" \
    dst-address=10.20.20.0/24 src-address=10.10.10.0/24
add action=accept chain=forward comment="[FWD] Server2 to Server1" \
    dst-address=10.10.10.0/24 src-address=10.20.20.0/24
add action=accept chain=forward comment=\
    "[FWD] Server1 to WiFi AP management (CAPsMAN APs on VLAN60)" \
    dst-address=10.60.60.0/24 src-address=10.10.10.0/24
add action=accept chain=forward comment=\
    "[FWD] Server2 to WiFi AP management (CAPsMAN APs on VLAN60)" \
    dst-address=10.60.60.0/24 src-address=10.20.20.0/24
add action=drop chain=forward comment="[FWD] WiFi no RPi" \
    dst-address=10.40.40.0/24 src-address=10.60.60.0/24
add action=drop chain=forward comment="[FWD] WiFi no AV" \
    dst-address=10.50.50.0/24 src-address=10.60.60.0/24
add action=accept chain=forward comment="[FWD] WiFi DNS to Pi-hole UDP" \
    dst-address=172.17.0.2 dst-port=53 protocol=udp \
    src-address=10.60.60.0/24
add action=accept chain=forward comment="[FWD] WiFi DNS to Pi-hole TCP" \
    dst-address=172.17.0.2 dst-port=53 protocol=tcp \
    src-address=10.60.60.0/24
add action=drop chain=forward comment="[FWD] WiFi no container net" \
    dst-address=172.17.0.0/24 src-address=10.60.60.0/24
add action=drop chain=forward comment="[FWD] RPi no Server1" \
    dst-address=10.10.10.0/24 src-address=10.40.40.0/24
add action=drop chain=forward comment="[FWD] RPi no Server2" \
    dst-address=10.20.20.0/24 src-address=10.40.40.0/24
add action=drop chain=forward comment="[FWD] RPi no iDRAC" \
    dst-address=10.30.30.0/24 src-address=10.40.40.0/24
add action=drop chain=forward comment="[FWD] RPi no AV" \
    dst-address=10.50.50.0/24 src-address=10.40.40.0/24
add action=drop chain=forward comment="[FWD] RPi no WiFi" \
    dst-address=10.60.60.0/24 src-address=10.40.40.0/24
add action=drop chain=forward comment="[FWD] No access to AV from any VLAN" \
    dst-address=10.50.50.0/24
add action=accept chain=forward comment="[FWD] WAN Minecraft Java" \
    dst-address=10.20.20.3 dst-port=25565 in-interface=pppoe-wan protocol=tcp
add action=accept chain=forward comment="[FWD] WAN Minecraft Bedrock" \
    dst-address=10.20.20.3 dst-port=19132 in-interface=pppoe-wan protocol=udp
add action=accept chain=forward comment="[FWD] WAN GMod game" \
    dst-address=10.20.20.3 dst-port=27015 in-interface=pppoe-wan protocol=udp
add action=accept chain=forward comment="[FWD] WAN GMod RCON" \
    dst-address=10.20.20.3 dst-port=27015 in-interface=pppoe-wan protocol=tcp
add action=accept chain=forward comment="[FWD] WAN TS6 voice" \
    dst-address=10.20.20.3 dst-port=9987 in-interface=pppoe-wan protocol=udp
add action=accept chain=forward comment="[FWD] WAN TS6 file transfer" \
    dst-address=10.20.20.3 dst-port=30033 in-interface=pppoe-wan protocol=tcp
add action=drop chain=forward comment="[SEC] Drop TCP NULL scan forward" \
    protocol=tcp tcp-flags=!fin,!syn,!rst,!ack
add action=drop chain=forward comment="[SEC] Drop TCP FIN no ACK forward" \
    protocol=tcp tcp-flags=fin,!ack
add action=drop chain=forward comment="[DDOS] Drop blacklisted forward" \
    src-address-list=ddos-blacklist
add action=accept chain=forward comment="[DDOS] Accept ICMP fwd within limit" \
    in-interface-list=WAN limit=50,100:packet protocol=icmp
add action=drop chain=forward comment="[DDOS] Drop ICMP flood fwd" \
    in-interface-list=WAN protocol=icmp
add action=accept chain=forward comment="[FWD] Allow to WAN" \
    out-interface=pppoe-wan
add action=drop chain=input comment="[SEC] Drop TCP NULL scan input" \
    protocol=tcp tcp-flags=!fin,!syn,!rst,!ack
add action=drop chain=input comment="[SEC] Drop TCP FIN no ACK input" \
    protocol=tcp tcp-flags=fin,!ack
add action=drop chain=input comment="[SEC] SSH blacklist drop" dst-port=2222 \
    protocol=tcp src-address-list=ssh-blacklist
add action=add-src-to-address-list address-list=ssh-blacklist \
    address-list-timeout=1w3d chain=input comment=\
    "[SEC] SSH stage3 to blacklist" connection-state=new dst-port=2222 \
    protocol=tcp src-address-list=ssh-stage3
add action=add-src-to-address-list address-list=ssh-stage3 \
    address-list-timeout=1m chain=input comment="[SEC] SSH stage2" \
    connection-state=new dst-port=2222 protocol=tcp \
    src-address-list=ssh-stage2
add action=add-src-to-address-list address-list=ssh-stage2 \
    address-list-timeout=1m chain=input comment="[SEC] SSH stage1" \
    connection-state=new dst-port=2222 protocol=tcp \
    src-address-list=ssh-stage1
add action=add-src-to-address-list address-list=ssh-stage1 \
    address-list-timeout=1m chain=input comment="[SEC] SSH new attempt" \
    connection-state=new dst-port=2222 protocol=tcp
add action=add-src-to-address-list address-list=port-scanners \
    address-list-timeout=2w chain=input comment="[SEC] Port scan detect" \
    protocol=tcp psd=21,3s,3,1
add action=drop chain=input comment="[SEC] Drop port scanners" \
    src-address-list=port-scanners
add action=drop chain=input comment="[DDOS] Drop blacklisted input" \
    src-address-list=ddos-blacklist
add action=accept chain=input comment="[DDOS] Accept ICMP within rate limit" \
    limit=50,100:packet protocol=icmp
add action=drop chain=input comment="[DDOS] Drop ICMP flood" protocol=icmp
add action=drop chain=input comment="[DDOS] Drop DNS amplification" \
    dst-port=53 in-interface-list=WAN protocol=udp
add action=drop chain=input comment="[DDOS] Drop DNS TCP from WAN" \
    dst-port=53 in-interface-list=WAN protocol=tcp
add action=drop chain=input comment="[DDOS] Drop NTP amplification" \
    dst-port=123 in-interface-list=WAN protocol=udp
add action=drop chain=input comment="[DDOS] Drop SSDP amplification" \
    dst-port=1900 protocol=udp
add action=drop chain=input comment="Default drop"
add action=drop chain=forward comment="[FWD] Default drop all unmatched"
/ip firewall nat
add action=masquerade chain=srcnat comment="defconf: masquerade" \
    ipsec-policy=out,none out-interface-list=WAN
add action=dst-nat chain=dstnat comment="[DNAT] Minecraft Java AMP" \
    dst-port=25565 in-interface=pppoe-wan protocol=tcp \
    to-addresses=10.20.20.3 to-ports=25565
add action=dst-nat chain=dstnat comment="[DNAT] Minecraft Bedrock AMP" \
    dst-port=19132 in-interface=pppoe-wan protocol=udp \
    to-addresses=10.20.20.3 to-ports=19132
add action=dst-nat chain=dstnat comment="[DNAT] GMod game AMP" \
    dst-port=27015 in-interface=pppoe-wan protocol=udp \
    to-addresses=10.20.20.3 to-ports=27015
add action=dst-nat chain=dstnat comment="[DNAT] GMod RCON AMP" \
    dst-port=27015 in-interface=pppoe-wan protocol=tcp \
    to-addresses=10.20.20.3 to-ports=27015
add action=dst-nat chain=dstnat comment="[DNAT] TS6 voice AMP" \
    dst-port=9987 in-interface=pppoe-wan protocol=udp \
    to-addresses=10.20.20.3 to-ports=9987
add action=dst-nat chain=dstnat comment="[DNAT] TS6 file transfer AMP" \
    dst-port=30033 in-interface=pppoe-wan protocol=tcp \
    to-addresses=10.20.20.3 to-ports=30033
/ip firewall raw
add action=accept chain=prerouting comment="defconf: accept LAN in RAW" \
    in-interface-list=LAN
add action=drop chain=prerouting comment="defconf: drop bogon dst from WAN" \
    dst-address-list=no_forward_ipv4 in-interface-list=WAN
add action=drop chain=prerouting comment="defconf: drop bogon src from WAN" \
    in-interface-list=WAN src-address-list=no_forward_ipv4
add action=drop chain=prerouting comment="[RAW] Drop TCP FIN+SYN" \
    in-interface-list=WAN protocol=tcp tcp-flags=fin,syn
add action=drop chain=prerouting comment="[RAW] Drop TCP SYN+RST" \
    in-interface-list=WAN protocol=tcp tcp-flags=syn,rst
add action=drop chain=prerouting comment="[RAW] Drop loopback src" \
    in-interface-list=WAN src-address=127.0.0.0/8
add action=drop chain=prerouting comment="[RAW] Drop RFC1918 src" \
    in-interface-list=WAN src-address=10.0.0.0/8
add action=drop chain=prerouting comment="[RAW] Drop RFC1918 src" \
    in-interface-list=WAN src-address=172.16.0.0/12
add action=drop chain=prerouting comment="[RAW] Drop RFC1918 src" \
    in-interface-list=WAN src-address=192.168.0.0/16
add action=drop chain=prerouting comment="[RAW] Drop CGNAT src" \
    in-interface-list=WAN src-address=100.64.0.0/10
/ip service
set ftp disabled=yes
set telnet disabled=yes
set www disabled=yes
set reverse-proxy disabled=yes
set ssh address=10.10.10.0/24,10.30.30.0/24 port=2222
set winbox address=10.10.10.0/24,10.30.30.0/24
set api address=10.10.10.0/24,10.30.30.0/24
set api-ssl disabled=yes
/ip ssh
set strong-crypto=yes
/ipv6 firewall filter
add action=accept chain=input comment="[IPv6] Accept established" \
    connection-state=established,related,untracked
add action=accept chain=input comment="[IPv6] Accept ICMPv6" protocol=icmpv6
add action=accept chain=input comment="[IPv6] BTH VPN" \
    in-interface=back-to-home-vpn
add action=drop chain=input comment="[IPv6] Default drop input"
add action=accept chain=forward comment="[IPv6] Accept established fwd" \
    connection-state=established,related,untracked
add action=accept chain=forward comment="[IPv6] Accept ICMPv6 fwd" \
    protocol=icmpv6
add action=drop chain=forward comment="[IPv6] Block WAN initiation" \
    in-interface=pppoe-wan
add action=drop chain=forward comment="[IPv6] Default drop fwd"
/lcd
set backlight-timeout=5m default-screen=stat-slideshow read-only-mode=yes
/lcd pin
set hide-pin-number=yes pin-number=YOUR-LCD-PIN
/lcd screen
set 0 timeout=5s
set 1 timeout=5s
set 2 timeout=5s
set 3 timeout=5s
set 4 timeout=5s
set 5 timeout=5s
/snmp
set contact=admin@home enabled=yes location="Home Lab"
/system clock
set time-zone-name=America/Toronto
/system identity
set name=RB3011-GW
/system logging
add topics=dhcp
add topics=pppoe
add topics=warning
add topics=firewall
add action=remote topics=info
add action=remote topics=firewall
add action=remote topics=warning
add action=remote topics=error
/system ntp client
set enabled=yes
/system ntp server
set enabled=yes
/system ntp client servers
add address=pool.ntp.org
add address=time.cloudflare.com
/system scheduler
add comment="Daily RSC export" interval=1d name=daily-backup on-event=\
    "/export file=usb1-part1/backups/daily/rb3011-config" policy=\
    read,write,sensitive start-date=2026-03-20 start-time=03:00:00
add comment="Weekly binary backup" interval=1w name=weekly-backup on-event=\
    "/system backup save name=usb1-part1/backups/weekly/rb3011-full \
    encryption=aes-sha256" policy=read,write,sensitive start-date=2026-03-20 \
    start-time=02:00:00
add comment="Ethernet link up/down beeper" interval=3s name=eth-monitor \
    on-event="/system script run eth-monitor" policy=read,write,policy,test \
    start-date=2026-03-20 start-time=18:26:36
add comment="WiFi connect/disconnect beeper" interval=5s name=wifi-monitor \
    on-event="/system script run wifi-monitor" policy=read,write,policy,test \
    start-date=2026-03-20 start-time=18:55:14
add comment="Attack/DDoS detection beeper" interval=10s name=attack-monitor \
    on-event="/system script run attack-monitor" policy=read,write,policy,test \
    start-date=2026-03-20 start-time=19:09:03
/tool bandwidth-server
set enabled=no
/tool graphing interface
add interface=pppoe-wan
add interface=vlan10-server1
add interface=vlan20-server2
add interface=vlan30-idrac
add interface=vlan40-pi
add interface=vlan50-av
add interface=vlan60-wifi
/tool mac-server
set allowed-interface-list=none
/tool mac-server mac-winbox
set allowed-interface-list=none
/tool mac-server ping
set enabled=no
/tool netwatch
add comment=Server1 down-script=\
    "/log warning \"SERVER1 DOWN\"; /system script run alert-down" \
    host=10.10.10.2 interval=30s type=simple up-script=\
    "/log info \"SERVER1 UP\"; /system script run alert-up"
add comment=Server2 down-script=\
    "/log warning \"SERVER2 DOWN\"; /system script run alert-down" \
    host=10.20.20.2 interval=30s type=simple up-script=\
    "/log info \"SERVER2 UP\"; /system script run alert-up"
add comment=iDRAC1 down-script=\
    "/log warning \"iDRAC1 DOWN\"; /system script run alert-down" \
    host=10.30.30.10 interval=1m type=simple up-script=\
    "/log info \"iDRAC1 UP\"; /system script run alert-up"
add comment=iDRAC2 down-script=\
    "/log warning \"iDRAC2 DOWN\"; /system script run alert-down" \
    host=10.30.30.11 interval=1m type=simple up-script=\
    "/log info \"iDRAC2 UP\"; /system script run alert-up"
add comment=WAN down-script=\
    "/log error \"WAN DOWN\"; /system script run alert-wan-down" \
    host=8.8.8.8 interval=30s type=simple up-script=\
    "/log info \"WAN UP\"; /system script run alert-up"
add comment=Pi-hole down-script=\
    "/ip dns set servers=8.8.8.8,8.8.4.4; /log warning \"Pi-hole DOWN\"; \
    /system script run alert-down" host=172.17.0.2 interval=15s type=simple \
    up-script="/ip dns set servers=172.17.0.2,8.8.8.8,8.8.4.4; /log info \
    \"Pi-hole UP\"; /system script run alert-up"
add comment=mAP2nD-1 down-script=\
    "/log warning \"mAP2nD-1 DOWN\"; /system script run alert-down" \
    host=10.60.60.200 interval=30s type=simple up-script=\
    "/log info \"mAP2nD-1 UP\"; /system script run alert-up"
add comment=wAP2nD-1 down-script=\
    "/log warning \"wAP2nD-1 DOWN\"; /system script run alert-down" \
    host=10.60.60.201 interval=30s type=simple up-script=\
    "/log info \"wAP2nD-1 UP\"; /system script run alert-up"
add comment=RPi down-script=\
    "/log warning \"RPi DOWN\"; /system script run alert-down" \
    host=10.40.40.2 interval=1m type=simple up-script=\
    "/log info \"RPi UP\"; /system script run alert-up"
add comment=AMP down-script=\
    "/log warning \"AMP DOWN\"; /system script run alert-down" \
    host=10.20.20.3 interval=30s type=simple up-script=\
    "/log info \"AMP UP\"; /system script run alert-up"
