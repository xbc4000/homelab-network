# usb-check.rsc
# Runs 90 seconds after every boot via startup scheduler (enabled by auto-update
# before the post-update reboot, disabled again after running).
# Checks if the USB SSD is mounted and accessible.
# If not mounted, increments a reboot counter stored in the script's comment field
# and reboots to try again.
# After 3 consecutive failed attempts, stops rebooting and alarms loudly.
#
# Counter storage: script comment field (persistent across reboots, no file I/O needed).
# Counter is cleared to "0" automatically when USB mounts successfully.
# Detection: /disk find slot=usb1-part1 (consistent with usb-periodic-check).
#
# Scheduler: startup + 90 second delay (disabled=yes at rest, enabled by auto-update
#            before update reboot, self-disables after running)
# Policy: reboot,read,write,policy,test
# =============================================================================

:local maxAttempts 3
:local usbMounted false

# Check USB SSD by looking for the partition in the disk list
:if ([:len [/disk find slot=usb1-part1]] > 0) do={ :set usbMounted true }

:if ($usbMounted = true) do={
    /log info "USB-CHECK: USB SSD mounted and accessible"

    # Clear the reboot counter on successful mount
    /system script set [find name=usb-check] comment="0"
    /log info "USB-CHECK: Reboot counter cleared"

} else={
    # USB not mounted — read reboot counter from script comment field
    :local count [:tonum [/system script get [find name=usb-check] comment]]
    :if ([:typeof $count] = "nil") do={ :set count 0 }

    /log warning ("USB-CHECK: USB SSD NOT mounted — attempt " . ($count + 1) . " of " . $maxAttempts)

    :if ($count < $maxAttempts) do={
        # Increment counter and store in comment field
        :local newCount ($count + 1)
        /system script set [find name=usb-check] comment=$newCount

        /log warning ("USB-CHECK: Rebooting to retry USB mount (attempt " . $newCount . " of " . $maxAttempts . ")")

        # Triple descending beep before reboot
        :beep frequency=880 length=150ms; :delay 100ms
        :beep frequency=660 length=150ms; :delay 100ms
        :beep frequency=440 length=300ms
        :delay 3s

        /system reboot

    } else={
        # Max attempts reached — stop rebooting, alarm loudly
        /log error "USB-CHECK: USB SSD failed to mount after 3 reboots — REQUIRES PHYSICAL ATTENTION"

        # Clear counter so next manual reboot gets 3 more attempts
        /system script set [find name=usb-check] comment="0"

        # Ascending alarm pattern repeated 3 times — unmistakable
        :for i from=1 to=3 do={
            :beep frequency=440 length=50ms; :delay 30ms
            :beep frequency=550 length=50ms; :delay 30ms
            :beep frequency=660 length=50ms; :delay 30ms
            :beep frequency=880 length=50ms; :delay 30ms
            :beep frequency=1100 length=50ms; :delay 30ms
            :beep frequency=880 length=50ms; :delay 30ms
            :beep frequency=660 length=50ms; :delay 30ms
            :beep frequency=550 length=50ms; :delay 30ms
            :beep frequency=440 length=300ms
            :delay 500ms
        }
    }
}
