# auto-update.rsc
# Check for RouterOS updates on the stable channel.
# If a new version is available, take an encrypted backup then install.
# Router will reboot automatically after install.
# AP upgrade is handled separately by ap-upgrade.rsc 20 minutes later.
#
# Scheduler: Sunday 03:00:00 weekly
# Policy: read,write,policy,reboot,sensitive
# =============================================================================

/system package update set channel=stable
/system package update check-for-updates
:delay 15s

:local status [/system package update get status]
:local latest [/system package update get latest-version]
:local current [/system resource get version]

:if ($status = "New version is available") do={
    /log warning ("AUTO-UPDATE: New RouterOS available: " . $latest . " (current: " . $current . ") — taking backup and installing")

    # Encrypted pre-update backup
    /system backup save name=usb1-part1/backups/pre-update/rb3011-pre-update \
        encryption=aes-sha256

    :delay 10s

    # Beep to signal update about to install
    :beep frequency=880 length=100ms; :delay 50ms
    :beep frequency=880 length=100ms; :delay 50ms
    :beep frequency=1320 length=300ms

    # Re-enable usb-check so it runs on the post-update reboot
    /system scheduler enable usb-check
    /log info "AUTO-UPDATE: usb-check scheduler re-enabled for post-update reboot"

    :delay 5s
    /system package update install

} else={
    /log info ("AUTO-UPDATE: RouterOS is up to date (" . $current . ")")
}
