# clear-blacklists.rsc
# Run this to clear all DDoS/SSH/scanner blacklists
# Useful after false positives or testing
/ip firewall address-list remove [find list=ddos-blacklist]
/ip firewall address-list remove [find list=ssh-blacklist]
/ip firewall address-list remove [find list=ssh-stage1]
/ip firewall address-list remove [find list=ssh-stage2]
/ip firewall address-list remove [find list=ssh-stage3]
/ip firewall address-list remove [find list=port-scanners]
/log info "All blacklists cleared"
