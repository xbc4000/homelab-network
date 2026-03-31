# ap-upgrade.rsc
# Downloads MIPSBE firmware packages to USB and lets CAPsMAN push upgrades
# automatically to connected APs on their next reconnect.
# Runs 20 minutes after auto-update.rsc to allow time for router reboot
# and CAPsMAN reconnection before downloading AP packages.
#
# Router is ARM — APs are MIPSBE. CAPsMAN cannot push packages it does not
# have locally. This script fetches routeros and wireless for MIPSBE from
# MikroTik CDN and places them in usb1-part1/firmware/aps/. CAPsMAN then
# serves them automatically based on upgrade-policy=require-same-version.
#
# APs reboot individually after receiving the upgrade — WiFi will briefly
# drop per AP during reboot (typically 60-90 seconds each).
#
# CAPsMAN config required:
#   /caps-man manager set package-path=usb1-part1/firmware/aps upgrade-policy=require-same-version
#
# Scheduler: Sunday 03:20:00 weekly (disabled at rest, runs after auto-update)
# Policy: ftp,read,write,test
# =============================================================================

:local capCount [:len [/caps-man remote-cap find]]

:if ($capCount = 0) do={
    /log warning "AP-UPGRADE: No APs connected to CAPsMAN — skipping"
} else={
    :local ver [/system package get [find name=routeros] version]
    /log info ("AP-UPGRADE: " . $capCount . " AP(s) connected, fetching MIPSBE packages for " . $ver)

    # Download routeros and wireless packages for MIPSBE if not already present
    :local pkgs ({"routeros"; "wireless"})
    :foreach pkg in=$pkgs do={
        :local pkgFile ($pkg . "-" . $ver . "-mipsbe.npk")
        :local pkgPath ("usb1-part1/firmware/aps/" . $pkgFile)
        :if ([:len [/file find name=$pkgPath]] = 0) do={
            /log info ("AP-UPGRADE: Fetching " . $pkgFile)
            /tool fetch url=("https://download.mikrotik.com/routeros/" . $ver . "/" . $pkgFile) dst-path=$pkgPath
        }
    }

    /log info "AP-UPGRADE: Packages ready, CAPsMAN will push on next AP reconnect"

    :beep frequency=523 length=100ms; :delay 50ms
    :beep frequency=784 length=100ms; :delay 50ms
    :beep frequency=1047 length=300ms
}
