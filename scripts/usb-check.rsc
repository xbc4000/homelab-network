# usb-check.rsc
# Runs 90 seconds after every boot via startup scheduler.
# Checks if the USB SSD is mounted and accessible.
# If not mounted, increments a reboot counter stored on internal flash
# and reboots to try again.
# After 3 consecutive failed attempts, stops rebooting and alarms loudly
# so you know the drive needs physical attention.
#
# Counter file: usb-reboot-count (on internal flash, NOT on the USB)
# Counter is cleared automatically when USB mounts successfully.
#
# Scheduler: startup + 90 second delay
# Policy: read,write,policy,reboot
# =============================================================================

:local maxAttempts 3
:local countFile "usb-reboot-count"
:local usbPath "usb1-part1"
:local mounted false

# Check if USB SSD is accessible by looking for the partition in file list
:foreach f in=[/file find] do={
    :if ([/file get $f name] = $usbPath) do={
        :set mounted true
    }
}

:if ($mounted = true) do={
    /log info "USB-CHECK: USB SSD mounted and accessible"

    # Clear the reboot counter on successful mount
    :if ([:len [/file find name=$countFile]] > 0) do={
        /file remove [find name=$countFile]
        /log info "USB-CHECK: Reboot counter cleared"
    }

} else={
    # USB not mounted — check reboot counter
    :local count 0

    :if ([:len [/file find name=$countFile]] > 0) do={
        :set count [:tonum [/file get [find name=$countFile] contents]]
    }

    /log warning ("USB-CHECK: USB SSD NOT mounted — attempt " . ($count + 1) . " of " . $maxAttempts)

    :if ($count < $maxAttempts) do={
        # Increment counter and write to internal flash
        :local newCount ($count + 1)
        :if ([:len [/file find name=$countFile]] > 0) do={
            /file set [find name=$countFile] contents=$newCount
        } else={
            /file add name=$countFile contents=$newCount
        }

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
        /file remove [find name=$countFile]

        # Attack alarm pattern repeated 3 times — unmistakable
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
