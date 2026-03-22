# pihole-restart.rsc
# Run this to restart the Pi-hole container and restore DNS
/container stop 0
:delay 5s
/container start 0
/log info "Pi-hole container restarted"
