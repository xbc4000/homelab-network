# Troubleshooting

## Lost Winbox Access

Winbox is restricted to VLAN10 (10.10.10.0/24) and VLAN30 (10.30.30.0/24) only.

If locked out, connect a laptop directly to ether2 (Server1 VLAN10) or ether6 (iDRAC VLAN30) and access the router at 10.10.10.1 or 10.30.30.1.

If that fails, physical console via the RJ45 serial port at 115200 baud 8N1.

---

## Pi-hole Down / DNS Broken

Netwatch auto-switches DNS to Google when Pi-hole is unreachable so internet should still work.

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
- Firewall must allow UDP 5246/5247 (CAPsMAN control) — these are intra-bridge and not WAN-facing so should be fine

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

## Attack Alarm Firing

Check the blacklist:
```
/ip firewall address-list print where list=ddos-blacklist
```

External CDN and cloud IPs (Google Cloud, Cloudflare, Fastly) will periodically appear — this is normal. They expire after 1 hour automatically.

If your own internal IPs appear, add them to the whitelist:
```
/ip firewall address-list add list=whitelist address=X.X.X.X comment="description"
```

To clear all blacklists manually:
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
`container: yes` must be present. If missing, run `/system/device-mode/update container=yes` and physically press the reset button to confirm.

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

- `wifi-monitor` script uses a global variable `$wifiCount` — on first run it initialises and does not beep. Beeps start from the second scheduler cycle.
- `eth-monitor` script uses a global variable `$ethStates` — same behaviour on first run.
- `attack-monitor` uses `$attackCount` — same. So no false alarm beep on router boot.

---

## RouterOS 7.22 Syntax Notes

Differences from v6 discovered during this build:

| What you want | Correct v7 syntax |
|---------------|-------------------|
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
