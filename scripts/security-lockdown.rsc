# security-lockdown.rsc
# Apply full security lockdown to the router.
# Disables all unnecessary services, restricts management access,
# hardens SSH, disables discovery and MAC services.
#
# MUST be run from VLAN10 (10.10.10.0/24) or VLAN30 (10.30.30.0/24).
# Running from WiFi or any other VLAN will lock you out immediately.
#
# Safe to re-run — all commands are idempotent.
# Usage: /import file=security-lockdown.rsc
# =============================================================================

# Disable unused services
/ip service set ftp disabled=yes
/ip service set telnet disabled=yes
/ip service set www disabled=yes
/ip service set www-ssl disabled=yes
/ip service set reverse-proxy disabled=yes
/ip service set api-ssl disabled=yes

# Restrict management services to VLAN10 and VLAN30 only
/ip service set ssh address=10.10.10.0/24,10.30.30.0/24 port=2222
/ip service set winbox address=10.10.10.0/24,10.30.30.0/24
/ip service set api address=10.10.10.0/24,10.30.30.0/24

# Strong SSH crypto
/ip ssh set strong-crypto=yes

# Disable MAC server and MAC ping
/tool mac-server set allowed-interface-list=none
/tool mac-server mac-winbox set allowed-interface-list=none
/tool mac-server ping set enabled=no

# Disable neighbor discovery on all interfaces
/ip neighbor discovery-settings set discover-interface-list=none

# Disable bandwidth server
/tool bandwidth-server set enabled=no

# Disable IP Cloud update-time (use NTP instead)
/ip cloud set update-time=no

# RP filter and SYN cookies
/ip settings set rp-filter=strict tcp-syncookies=yes

/log warning "Security lockdown applied"
