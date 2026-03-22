# Troubleshooting

## Lost Winbox / SSH Access

Winbox and SSH are restricted to VLAN10 (10.10.10.0/24) and VLAN30 (10.30.30.0/24) only.

If locked out, connect a laptop directly to ether2 (Server1 VLAN10) or ether6
(iDRAC VLAN30) and access the router at 10.10.10.1 or 10.30.30.1.

If that fails, physical console via the RJ45 serial port at 115200 baud 8N1.

---

## Pi-hole Down / DNS Broken

Netwatch auto-switches DNS to Google when Pi-hole is unreachable so internet
should still work within 15 seconds.

Check Pi-hole container status:
```
/container print
```

Start if stopped:
```
/container start 0
```

Check container logs:
```
/log print where topics~"container"
```

Manually restore DNS if needed:
```
/ip dns set servers=172.17.0.2,8.8.8.8,8.8.4.4
```

---

## WiFi Not Working

Check CAPsMAN sees the APs:
```
/caps-man remote-cap print
/caps-man registration-table print
```

If APs are not registering:

- Confirm ether10 link is up and mAP2nD-1 is powered
- Connect to AP via Winbox MAC address and check: `/interface wireless cap print`
- CAP mode must be enabled with `caps-man-addresses=10.60.60.1`
- CAPsMAN requires UDP 5246/5247 inbound from VLAN60 — verify the firewall rule exists:
  ```
  /ip firewall filter print where comment~"CAPsMAN"
  ```
  If missing, add it:
  ```
  /ip firewall filter add chain=input action=accept \
      in-interface=vlan60-wifi protocol=udp dst-port=5246,5247 \
      comment="[IN] CAPsMAN control from APs" \
      place-before=[find comment="[IN] RPi DNS+NTP"]
  ```

If APs are reachable by ping but not appearing in `/caps-man remote-cap print`:

- This is almost always the CAPsMAN firewall rule missing (see above)
- Or the router rebooted and regenerated its CAPsMAN certificate — the APs need
  to clear their cached cert and reconnect. SSH to each AP and run:
  ```
  /certificate remove [find]
  /interface wireless cap set enabled=no
  /interface wireless cap set enabled=yes
  ```

If the wAP is not registering but the mAP is:

- The wAP connects through the mAP (ether2 on mAP → ether1 on wAP)
- Verify the mAP ether2 link is up: `/interface ethernet print` on the mAP

---

## VLAN Not Routing

Verify bridge VLAN filtering is on:
```
/interface bridge print detail where name=bridge-main
```

`vlan-filtering=yes` must be present.

Check the VLAN table:
```
/interface bridge vlan print
```

Each VLAN should have `bridge-main` tagged and the correct port(s) untagged.

---

## Device Not Getting Correct IP / Static Lease Not Working

Check that static leases are present:
```
/ip dhcp-server lease print
```

If a device got a dynamic lease before the static lease was added, the old
lease must be removed so the device re-requests:
```
/ip dhcp-server lease remove [find dynamic=yes server=dhcp-server1]
```

Then renew the NIC on the device (`dhclient -r && dhclient` on Linux).

---

## Attack Alarm Firing

Check the blacklists:
```
/ip firewall address-list print where list=ddos-blacklist
/ip firewall address-list print where list=ssh-blacklist
/ip firewall address-list print where list=port-scanners
```

External CDN and cloud IPs (Google Cloud, Cloudflare, Fastly) can occasionally
appear in ddos-blacklist due to burst traffic patterns. This is expected —
entries expire after 1 hour automatically.

If your own internal IPs appear, add them to the whitelist:
```
/ip firewall address-list add list=whitelist address=X.X.X.X comment="description"
```

To clear all blacklists manually (use `clear-blacklists.rsc` or run directly):
```
/ip firewall address-list remove [find list=ddos-blacklist]
/ip firewall address-list remove [find list=ssh-blacklist]
/ip firewall address-list remove [find list=port-scanners]
```

---

## Container Won't Start

Verify container support is enabled in device mode:
```
/system/device-mode/print
```

`container: yes` must be present. If missing:
```
/system/device-mode/update container=yes
```
Then physically press the reset button to confirm (within 5 minutes).

Check USB directories exist:
```
/file print where name~"usb1"
```

Check container config:
```
/container/config/print
/container/print detail
```

---

## Game Servers Not Reachable from Internet

First confirm you have a public IP:
```
/ip address print
```

If the `pppoe-wan` address shows `10.71.x.x` — that is a CGNAT address. Port
forwarding will not work until the ISP provides a public IP. Call the ISP and
request a public static IP.

If you have a public IP, verify DNAT rules are present:
```
/ip firewall nat print where chain=dstnat
```

Verify forward filter rules are present:
```
/ip firewall filter print where comment~"WAN"
```

Test from outside the network (mobile data, not home WiFi):
```
nmap -p 25565 YOUR-WAN-IP        # Minecraft Java
nmap -sU -p 19132 YOUR-WAN-IP    # Bedrock
nmap -sU -p 27015 YOUR-WAN-IP    # GMod
nmap -sU -p 9987 YOUR-WAN-IP     # TS6 voice
nmap -p 30033 YOUR-WAN-IP        # TS6 file transfer
```

---

## Back to Home VPN Pairing Fails

BTH pairing requires the MikroTik app to reach the router's API or HTTP
service for local discovery. Both are restricted to VLAN10/VLAN30 only.

**Recommended method — pair using secret from VLAN10:**

On the router (SSH from Server1):
```
/ip cloud back-to-home user add name=DEVICENAME comment="description"
/ip cloud back-to-home user print detail
```

Use the generated secret or QR code in the MikroTik app → Add Router →
Manual/QR entry. This bypasses local HTTP/API discovery entirely.

BTH VPN runs on WireGuard port 65504. Confirm the firewall rule is present:
```
/ip firewall filter print where comment~"Back to Home VPN"
```

---

## Beepers Not Working

Check all scripts have the correct flag:
```
/system script print where dont-require-permissions=no
```

Any script listed there needs to be fixed:
```
/system script set [find dont-require-permissions=no] dont-require-permissions=yes
```

Test a script manually:
```
/system script run alert-down
```

---

## Beeper-related Notes

- `wifi-monitor` uses global `$wifiCount` — on first run it initialises and
  does not beep. Beeps start from the second scheduler cycle.
- `eth-monitor` uses global `$ethStates` — same behaviour on first run.
- `attack-monitor` uses `$attackCount` — same. No false alarm on router boot.

---

## IPv6 Firewall Accumulating Duplicate Rules

If `/ipv6 firewall filter print terse` shows more than 10 rules (2 dynamic +
8 static), duplicates have accumulated. Wipe and rebuild:

```
/ipv6 firewall filter remove [find dynamic=no]
```

Verify only 2 dynamic rules remain (both with `D` flag, both BTH VPN). Then
re-add the 8 static rules from `config/rb3011-config.rsc`.

---

## RouterOS 7.22 Syntax Notes

Differences from v6 discovered during this build:

| What you want | Correct v7 syntax |
|---------------|------------------|
| Add container env | `/container/envs/add list=name key=X value=Y` |
| Add container mount | `/container/mounts/add list=name dst=X src=Y` |
| Add container | `/container add remote-image=X mountlists=Y,Z envlists=A` |
| Create directory | `/file add name=path/to/dir type=directory` |
| Set Dude data dir | `/dude set data-directory=usb1-part1/dude` |
| Set syslog remote | `/system logging action set 3 remote=X` then `/system logging add action=remote topics=Y` |
| CAPsMAN (legacy APs) | `/caps-man` not `/interface wifi` — MIPS/Atheros AR9300 requires legacy CAPsMAN |
| Scripts from netwatch | Must have `dont-require-permissions=yes` |
| LCD touchscreen | `/lcd` not `/system lcd` |
| Pipe in terminal | Not supported — use `where` filter: `/ip firewall filter print where comment~"text"` |
| Remove only static firewall rules | `/ip firewall filter remove [find dynamic=no]` |
| DHCP network set by index | `/ip dhcp-server network set 2 ntp-server=X` (use index if `find` doesn't match) |
| Print full detail | `print detail` — shows all fields including ones hidden in compact table view |
