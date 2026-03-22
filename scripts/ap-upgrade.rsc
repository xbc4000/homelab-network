# ap-upgrade.rsc
# Push firmware upgrades to all connected CAPsMAN APs.
# Runs 20 minutes after auto-update.rsc to allow time for router reboot
# and CAPsMAN reconnection before attempting AP upgrades.
#
# CAPsMAN will push the RouterOS version matching the controller to each AP.
# APs reboot individually after receiving the upgrade — WiFi will briefly
# drop per AP as it reboots (typically 60-90 seconds each).
#
# Scheduler: Sunday 03:20:00 weekly
# Policy: read,write,policy,reboot
# =============================================================================

:local capCount [:len [/caps-man remote-cap find]]

:if ($capCount = 0) do={
    /log warning "AP-UPGRADE: No APs connected to CAPsMAN — skipping AP upgrade"
    /log warning "AP-UPGRADE: Check /caps-man remote-cap print and retry manually"
} else={
    /log info ("AP-UPGRADE: " . $capCount . " AP(s) connected — checking firmware")

    # Check each AP's current version vs controller
    :foreach cap in=[/caps-man remote-cap find] do={
        :local name [/caps-man remote-cap get $cap name]
        :local ver  [/caps-man remote-cap get $cap version]
        :local ctrl [/system resource get version]
        /log info ("AP-UPGRADE: " . $name . " running " . $ver)
    }

    # Push upgrade to all APs — CAPsMAN handles version matching
    /caps-man remote-cap upgrade [find]

    :beep frequency=523 length=100ms; :delay 50ms
    :beep frequency=784 length=100ms; :delay 50ms
    :beep frequency=1047 length=300ms

    /log info "AP-UPGRADE: Upgrade command sent to all APs — APs will reboot individually"
    /log info "AP-UPGRADE: WiFi will briefly drop per AP during reboot (~60-90 seconds each)"
}
