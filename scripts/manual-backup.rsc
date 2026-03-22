# manual-backup.rsc
# Run this on the router any time you want an immediate backup
# Usage: paste into router terminal
/export file=usb1-part1/backups/daily/rb3011-config
/system backup save name=usb1-part1/backups/weekly/rb3011-full
/log info "Manual backup completed"
