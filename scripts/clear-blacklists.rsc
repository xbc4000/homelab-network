# clear-blacklists.rsc
# Clear all DDoS, SSH brute-force, and port-scanner blacklists.
# Also clears the SSH stage lists so any in-progress ladder is reset.
#
# Use when:
#   - A legitimate IP (e.g. CDN, cloud server) was incorrectly blacklisted
#   - You want to reset all counters after a genuine attack has passed
#   - Troubleshooting connectivity from a blocked IP
#
# Run from VLAN10 or VLAN30 only (SSH/Winbox restriction).
# Usage: /import file=clear-blacklists.rsc
# =============================================================================

/ip firewall address-list remove [find list=ddos-blacklist]
/ip firewall address-list remove [find list=ssh-blacklist]
/ip firewall address-list remove [find list=port-scanners]
/ip firewall address-list remove [find list=ssh-stage1]
/ip firewall address-list remove [find list=ssh-stage2]
/ip firewall address-list remove [find list=ssh-stage3]

/log warning "All blacklists cleared manually"
