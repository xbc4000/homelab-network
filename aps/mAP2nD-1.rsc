# mAP2nD-1 Setup Script
# Model: RBmAP2nD
# Radio MAC: DC:2C:6E:10:54:F1 (used by CAPsMAN provisioning)
# Ethernet MAC: DC:2C:6E:10:54:EE
# Management IP: 10.60.60.200/24
# Channel: 1 / 2412 MHz
# Role: Primary AP — plugged into ether10 on RB3011
#       wAP2nD-1 daisy-chains through ether2 on this AP
#
# INSTRUCTIONS:
# 1. Hard reset AP (hold reset button 5 seconds until LED flashes, release)
# 2. Connect laptop directly to ether2 on the mAP
# 3. Set laptop ethernet to static IP: 10.60.60.250/24
# 4. Open Winbox, connect to 192.168.88.1, user=admin, password blank
# 5. Upload this file via Files tab
# 6. In terminal run: /import file=mAP2nD-1.rsc
# 7. Winbox will disconnect — normal, import continues on AP
# 8. From router SSH in to set password:
#    /system ssh address=10.60.60.200 port=2222 user=YOUR-ADMIN-USER
#    /user set [find name=YOUR-ADMIN-USER] password=YOURPASSWORD
# =============================================================================

/ip dhcp-client remove [find]
/interface bridge add name=bridge1 protocol-mode=none
/interface bridge port add interface=ether1 bridge=bridge1
/interface bridge port add interface=ether2 bridge=bridge1
/ip address add address=10.60.60.200/24 interface=bridge1
/ip route add gateway=10.60.60.1
/ip dns set servers=10.60.60.1
/system identity set name="mAP2nD-1"
/system clock set time-zone-name=America/Toronto
/system ntp client set enabled=yes
/system ntp client servers add address=pool.ntp.org
/ip service disable telnet,ftp,www,www-ssl,api,api-ssl,reverse-proxy
/ip service set ssh port=2222 address=""
/ip service set winbox address=""
/ip firewall filter remove [find dynamic=no]
/tool mac-server set allowed-interface-list=none
/tool mac-server mac-winbox set allowed-interface-list=none
/tool mac-server ping set enabled=no
/ip neighbor discovery-settings set discover-interface-list=none
/tool bandwidth-server set enabled=no
/ip ssh set strong-crypto=yes
/user add name=YOUR-ADMIN-USER group=full
/user disable admin
/interface wireless cap set enabled=yes interfaces=wlan1 caps-man-addresses=10.60.60.1
