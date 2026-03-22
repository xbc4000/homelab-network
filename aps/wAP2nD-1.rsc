# wAP2nD-1 Setup Script
# Model: RBwAP2nDr2
# Radio MAC: 74:4D:28:52:FC:C3 (used by CAPsMAN provisioning)
# Ethernet MAC: 74:4D:28:52:FC:C2
# Management IP: 10.60.60.201/24
# Channel: 11 / 2462 MHz
# Role: Secondary AP — plugged into ether2 on mAP2nD-1
# Single ethernet port device
#
# INSTRUCTIONS:
# 1. Hard reset AP (hold reset button 5 seconds until LED flashes, release)
# 2. Connect laptop directly to ether1 on the wAP
# 3. Set laptop ethernet to static IP: 10.60.60.250/24
# 4. Open Winbox, connect to 192.168.88.1, user=admin, password blank
# 5. Upload this file via Files tab
# 6. In terminal run: /import file=wAP2nD-1.rsc
# 7. Winbox will disconnect — normal, import continues on AP
# 8. From router SSH in to set password:
#    /system ssh address=10.60.60.201 port=2222 user=YOUR-ADMIN-USER
#    /user set [find name=YOUR-ADMIN-USER] password=YOURPASSWORD
# =============================================================================
/ip dhcp-client remove [find]
/interface bridge add name=bridge1 protocol-mode=none
/interface bridge port add interface=ether1 bridge=bridge1
/ip address add address=10.60.60.201/24 interface=bridge1 network=10.60.60.0
/ip route add gateway=10.60.60.1
/ip dns set servers=10.60.60.1 allow-remote-requests=no
/system identity set name="wAP2nD-1"
/system clock set time-zone-name=America/Toronto
/system ntp client set enabled=yes
/system ntp client servers add address=pool.ntp.org
/system ntp client servers add address=time.cloudflare.com
/ip service disable telnet,ftp,www,www-ssl,api,api-ssl,reverse-proxy
/ip service set ssh port=2222 address=""
/ip firewall filter remove [find dynamic=no]
/ip firewall nat remove [find]
/ip dhcp-server remove [find]
/ip dhcp-server network remove [find]
/tool mac-server set allowed-interface-list=none
/tool mac-server mac-winbox set allowed-interface-list=none
/tool mac-server ping set enabled=no
/ip neighbor discovery-settings set discover-interface-list=none
/tool bandwidth-server set enabled=no
/ip ssh set strong-crypto=yes
/ipv6 firewall filter remove [find dynamic=no]
/ipv6 firewall address-list remove [find]
/ipv6 firewall filter add chain=input action=accept \
    connection-state=established,related,untracked \
    comment="[IPv6] Accept established"
/ipv6 firewall filter add chain=input action=accept protocol=icmpv6 \
    comment="[IPv6] Accept ICMPv6"
/ipv6 firewall filter add chain=input action=drop \
    comment="[IPv6] Default drop input"
/ipv6 firewall filter add chain=forward action=accept \
    connection-state=established,related,untracked \
    comment="[IPv6] Accept established fwd"
/ipv6 firewall filter add chain=forward action=accept protocol=icmpv6 \
    comment="[IPv6] Accept ICMPv6 fwd"
/ipv6 firewall filter add chain=forward action=drop \
    comment="[IPv6] Default drop fwd"
/user add name=YOUR-ADMIN-USER group=full
/user disable admin
/interface wireless cap set enabled=yes interfaces=wlan1 \
    caps-man-addresses=10.60.60.1
