# pihole-restart.rsc
# Restart the Pi-hole container cleanly.
# DNS is temporarily switched to Google during restart, then restored
# automatically by netwatch when Pi-hole comes back up.
#
# Run from VLAN10 or VLAN30 only (SSH/Winbox restriction).
# Usage: /import file=pihole-restart.rsc
# =============================================================================

# Pre-switch DNS to Google so nothing breaks during restart
/ip dns set servers=8.8.8.8,8.8.4.4
/log info "Pi-hole restart: DNS temporarily switched to Google"

# Stop container
/container stop [find name~"pihole"]
:delay 5s

# Start container
/container start [find name~"pihole"]
/log info "Pi-hole restart: container started — netwatch will restore DNS when healthy"

# Netwatch monitors 172.17.0.2 every 15s and will automatically
# restore servers=172.17.0.2,8.8.8.8,8.8.4.4 once Pi-hole responds
