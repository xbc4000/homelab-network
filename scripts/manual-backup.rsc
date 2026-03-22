# manual-backup.rsc
# Trigger an immediate full backup — both RSC export and encrypted binary.
# Run from VLAN10 or VLAN30 only (SSH/Winbox restriction).
#
# Usage: /import file=manual-backup.rsc
# =============================================================================

# RSC export (plaintext — contains credentials, stored locally only)
/export file=usb1-part1/backups/daily/rb3011-config-manual

# Encrypted binary backup
/system backup save name=usb1-part1/backups/weekly/rb3011-full-manual \
    encryption=aes-sha256

/log info "Manual backup completed — RSC and encrypted binary saved to USB SSD"
