# syslog-setup.rsc
# Configure syslog forwarding to Pi-hole (172.17.0.2 UDP 514).
# Sets up remote logging action and adds topic rules.
#
# Safe to re-run — checks are implicit via RouterOS deduplication.
# Run from VLAN10 or VLAN30 only (SSH/Winbox restriction).
# Usage: /import file=syslog-setup.rsc
# =============================================================================

# Set logging action 3 (remote) to point at Pi-hole
/system logging action set 3 remote=172.17.0.2

# Local memory topics (kept on router only)
/system logging add topics=dhcp
/system logging add topics=pppoe
/system logging add topics=warning
/system logging add topics=firewall

# Remote topics (forwarded to Pi-hole syslog)
/system logging add action=remote topics=info
/system logging add action=remote topics=firewall
/system logging add action=remote topics=warning
/system logging add action=remote topics=error

/log info "Syslog forwarding configured — remote=172.17.0.2"
