# syslog-setup.rsc
# Run this after Pi-hole is stable to enable syslog forwarding
# Pi-hole receives logs on UDP 514
/system logging action set 3 remote=172.17.0.2
/system logging add topics=info action=remote
/system logging add topics=firewall action=remote
/log info "Syslog forwarding to Pi-hole enabled"
