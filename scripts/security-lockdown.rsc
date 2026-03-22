# security-lockdown.rsc
# Run this ONLY while connected from Server1 (10.10.10.x)
# Restricts Winbox and SSH to trusted VLANs only
# WARNING: Will lock out access from all other subnets
/ip service set winbox address=10.10.10.0/24,10.30.30.0/24
/ip service set ssh address=10.10.10.0/24,10.30.30.0/24
/tool mac-server set allowed-interface-list=none
/tool mac-server mac-winbox set allowed-interface-list=none
/ip neighbor discovery-settings set discover-interface-list=none
/ip firewall filter add chain=input action=drop comment="Default drop"
/log info "Security lockdown applied"
