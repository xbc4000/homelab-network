# Beeper Alert System

The RB3011UiAS has a built-in piezo beeper controlled by RouterOS `:beep`.
All alert and monitor scripts carry `dont-require-permissions=yes` so they
work correctly when called from netwatch and schedulers without a `test`
policy grant.

> **RouterOS 7.22 Beep Restriction**: `:beep` only works at the **absolute
> top level** of a scheduler's `on-event`. It silently fails inside any
> `do={}` block, even with `policy=test`. See
> [Troubleshooting](troubleshooting.md#beeper-not-working-from-scheduler)
> for the full explanation and the two-scheduler pattern used by the boot
> fanfare system.

---

## Alert Tone Scripts

These scripts play a tone and/or log a message. Called by netwatch, DHCP
servers, and schedulers.

### Generic Alert Scripts

| Script | Tone | Triggered by |
|--------|------|-------------|
| `alert-up` | Two rising tones — 523 Hz → 784 Hz | Host comes online, ethernet up |
| `alert-down` | Three descending — 880 → 660 → 440 Hz | Host goes down, ethernet down |
| `alert-wan-down` | Five rapid 1000 Hz + two 800 Hz pulses | WAN goes down |
| `attack-alarm` | Three sweeping up-down patterns 440→1100→440 Hz | DDoS/SSH/scan blacklist hit |
| `pihole-down-alert` | Three descending — 523 → 392 → 262 Hz (C5-G4-C4) | Pi-hole container unreachable |
| `map-up-alert` | Two rising — 659 → 880 Hz (E5-A5) | mAP2nD-1 comes online |
| `wap-up-alert` | Two rising — 880 → 1319 Hz (A5-E6) | wAP2nD-1 comes online |

### WAN Down Handler (`wan-down-handler`)

Wraps `alert-wan-down` with PPPoE flap detection. Counts consecutive WAN
down events using global variable `$wanDownCount`. On 3+ consecutive drops,
plays an additional alarm pattern and logs `PPPOE FLAPPING DETECTED`. Then
calls `alert-wan-down` regardless.

---

## DHCP Lease Scripts

Each DHCP server pool has its own lease script. All play a tone and log the
IP and MAC address of the new lease.

| DHCP Server | Script | Tone |
|-------------|--------|------|
| `dhcp-server1` | `dhcp-server1-lease` | Deep two-tone — G3 (196 Hz) → C4 (262 Hz) |
| `dhcp-server2` | `dhcp-server2-lease` | Three-tone — A3 (220 Hz) → D4 (294 Hz) → A4 (440 Hz) |
| `dhcp-idrac` | `dhcp-new-lease` | Generic arpeggio — C6 → E6 → G6 |
| `dhcp-pi` | `dhcp-pi-lease` | Three rising — C5 (523 Hz) → E5 (659 Hz) → G5 (784 Hz) |
| `dhcp-av` | `dhcp-new-lease` | Generic arpeggio — C6 → E6 → G6 |
| `dhcp-wifi` | `dhcp-wifi-lease` | Device-specific (see below) |

### WiFi Lease Handler (`dhcp-wifi-lease`)

Handles the `pihole-admin-wifi` firewall address-list and plays
device-specific tones for known MACs:

| Device | MAC | Tone on connect | Tone on release |
|--------|-----|----------------|-----------------|
| Phone 1 (TXMGF6) | `62:B9:08:0B:44:C5` | Ascending C6-D6-E6-G6 | — |
| Phone 2 (TX1Y4) | `34:7D:F6:68:AF:3D` | Descending G6-E6-C6-G5 | — |
| Unknown device | any other MAC | Rapid 880/440 Hz alarm × 6 | — |

On `leaseBound=1` (new lease), the known MACs are added to `pihole-admin-wifi`.
On `leaseBound=0` (release), they are removed. The `pihole-admin-wifi` list
grants those IPs access to the Pi-hole web UI on port 80/443 through the
forward firewall.

---

## Scheduled Monitor Scripts

These scripts poll a condition on a schedule and play an alert tone when
something changes or exceeds a threshold.

**State persistence**: `wifi-monitor`, `eth-monitor`, and `attack-monitor`
store their previous state in the script's own **comment field** — not global
variables. Global variables do not persist between separate scheduled runs in
RouterOS 7.22. The comment field is persistent and survives reboots.

| Scheduler | Script | Interval | What it watches |
|-----------|--------|----------|----------------|
| `eth-monitor` | `eth-monitor` | 3s | Running ethernet interface count |
| `wifi-monitor` | `wifi-monitor` | 5s | CAPsMAN registration table count |
| `attack-monitor` | `attack-monitor` | 10s | Total ddos-blacklist + ssh-blacklist + port-scanners count |
| `login-monitor-sched` | `login-monitor` | 5s | Active user session count |
| `ssh-probe-monitor-sched` | `ssh-probe-monitor` | 10s | ssh-stage1 address-list length |
| `temp-monitor-sched` | `temp-monitor` | 1m | CPU temperature |
| `dhcp-pool-monitor-sched` | `dhcp-pool-monitor` | 5m | WiFi DHCP pool free addresses |
| `usb-periodic-check-sched` | `usb-periodic-check` | 5m | USB SSD mounted |

### Monitor Alert Details

| Script | Alert tone | Condition |
|--------|-----------|-----------|
| `eth-monitor` | alert-up tone (523→784 Hz) | Ethernet count increased |
| `eth-monitor` | alert-down tone (880→660→440 Hz) | Ethernet count decreased |
| `wifi-monitor` | WiFi connect tone (1047→1319→1568 Hz) | WiFi client count increased |
| `wifi-monitor` | WiFi disconnect tone (1568→1319→1047 Hz) | WiFi client count decreased |
| `attack-monitor` | Sweeping 440→1100→440 Hz | Blacklist count increased |
| `login-monitor` | G5→C6→E6 rising (784→1047→1319 Hz) | New active router session |
| `ssh-probe-monitor` | E5→C5→G4 descending (659→523→392 Hz) | New IP in ssh-stage1 list |
| `temp-monitor` | Alternating 1000/1200 Hz alarm | Temperature ≥ 60°C |
| `dhcp-pool-monitor` | Alternating 660/440 Hz × 4 | WiFi pool has fewer than 10 free IPs |
| `usb-periodic-check` | Three deep 300 Hz pulses | USB SSD not mounted |

### First-Run Behaviour

`wifi-monitor`, `eth-monitor`, and `attack-monitor` store their previous
count in the script comment field. On the very first run after a fresh
install (comment = `"0"`), they initialise without sounding an alarm. Beeps
begin from the second scheduler cycle when a real change is detected.

---

## Netwatch Hosts

| Host | Comment | Interval | Down action | Up action |
|------|---------|----------|-------------|-----------|
| 10.10.10.2 | Server1 | 30s | `alert-down` | `alert-up` |
| 10.20.20.2 | Server2 | 30s | `alert-down` | `alert-up` |
| 10.20.20.3 | AMP | 30s | `alert-down` | `alert-up` |
| 10.30.30.10 | iDRAC1 | 60s | `alert-down` | `alert-up` |
| 10.30.30.11 | iDRAC2 | 60s | `alert-down` | `alert-up` |
| 10.40.40.2 | RPi | 60s | `alert-down` | `alert-up` |
| 8.8.8.8 | WAN | 30s | `wan-down-handler` | `alert-up` |
| 172.17.0.2 | Pi-hole | 15s | `pihole-down-alert` + DNS→Google | `alert-up` + DNS→Pi-hole |
| 10.60.60.200 | mAP2nD-1 | 30s | `alert-down` | `map-up-alert` |
| 10.60.60.201 | wAP2nD-1 | 30s | `alert-down` | `wap-up-alert` |

Pi-hole uses a 15-second interval so DNS failover is fast. The down script
switches `/ip dns set servers=8.8.8.8,8.8.4.4` before the alert tone so DNS
resolves immediately on the next query. The up script restores
`172.17.0.2,8.8.8.8,8.8.4.4`.

The APs use dedicated up scripts (`map-up-alert`, `wap-up-alert`) with
higher-pitched tones than the generic `alert-up` so you can distinguish AP
recovery from server recovery by ear.

---

## Boot Fanfare System

On every cold boot, the router plays one of 11 rotating fanfares once it has
confirmed WAN is up and the USB SSD is mounted.

### Architecture

The system uses a **two-scheduler pattern** to work around the RouterOS 7.22
`:beep` restriction:

```
[startup-fanfare-sched]              [fanfare-sched-N]
 interval=1m, start-time=startup      disabled=yes, start-time=startup
 on-event (no :beep here):           on-event (top level — :beep works):
   check WAN + USB ready              :beep ...melody...
   check global var (once-per-boot)   /system scheduler disable [find name=fanfare-sched-N]
   read idx from startup-fanfare
   /system scheduler enable fanfare-sched-N
   increment idx, write back
```

`startup-fanfare-sched` contains all the logic but zero beep calls.
`fanfare-sched-N` contains only the melody at the absolute top level of
`on-event` (no `do={}` nesting) where `:beep` has the required `test`
permission. Each fanfare scheduler self-disables after playing so it cannot
fire again on the same boot.

### Index Storage

The next fanfare index (0–10) is stored in the **comment field** of the
`startup-fanfare` script. This persists across reboots without needing files
or global variables. The script source is empty — only the comment field
matters.

```
/system script print where name=startup-fanfare
# comment field shows the next index (0-10)
```

### Readiness Checks

`startup-fanfare-sched` retries every minute until both conditions are true:

1. At least one active default route (`/ip route find dst-address=0.0.0.0/0 active=yes`)
2. USB SSD is mounted (`/disk find slot=usb1-part1`)

Once ready, it sets global `$startupFanfarePlayed = true` so it cannot fire
again on the same boot, even if the scheduler keeps running.

### The 11 Fanfares

| Index | Name | Scheduler | Manual script |
|-------|------|-----------|--------------|
| 0 | Tetris Theme A | `fanfare-sched-0` | `fanfare-tetris` |
| 1 | Star Trek TOS Fanfare | `fanfare-sched-1` | `fanfare-startrek` |
| 2 | Close Encounters 5-note | `fanfare-sched-2` | `fanfare-close-encounters` |
| 3 | Imperial March opening | `fanfare-sched-3` | `fanfare-imperial-march` |
| 4 | Doctor Who theme | `fanfare-sched-4` | `fanfare-doctor-who` |
| 5 | Morse SOS (···---···) | `fanfare-sched-5` | `fanfare-morse-sos` |
| 6 | Big Ben Westminster chime | `fanfare-sched-6` | `fanfare-big-ben` |
| 7 | Nokia ringtone | `fanfare-sched-7` | `fanfare-nokia` |
| 8 | Jeopardy think music | `fanfare-sched-8` | `fanfare-jeopardy` |
| 9 | Mission Impossible theme | `fanfare-sched-9` | `fanfare-mission-impossible` |
| 10 | Reveille bugle call | `fanfare-sched-10` | `fanfare-reveille` |

Each fanfare script (e.g. `fanfare-tetris`) can also be run on demand at any
time:

```
/system script run fanfare-tetris
/system script run fanfare-imperial-march
```

### Forcing a Specific Fanfare on Next Boot

Set the comment field of `startup-fanfare` to the desired index:

```
/system script set [find name=startup-fanfare] comment=3
# Next boot will play Imperial March (index 3)
```

### Triggering the Fanfare Right Now (Without Rebooting)

```
/system scheduler enable fanfare-sched-5
# Plays Morse SOS within 5 seconds, then self-disables
```

---

## Super Mario Bros Theme

The full Super Mario Bros overworld theme is a standalone on-demand script.

```
/system script run super-mario
```

Runs for approximately 75 seconds. Works when called from terminal or
Winbox — the script runs in a context with `test` permission.

---

## WiFi Connect / Disconnect Tones

Two scripts are called by the legacy CAPsMAN `on-event` callbacks (if
configured) but are primarily used by `wifi-monitor`:

| Script | Tone |
|--------|------|
| `wifi-connect` | 1047→1319→1568 Hz ascending (C6-E6-G6) |
| `wifi-disconnect` | 1568→1319→1047 Hz descending (G6-E6-C6) |

---

## Running Any Alert Manually

All alert and fanfare scripts can be called from terminal at any time:

```
/system script run alert-up
/system script run alert-down
/system script run alert-wan-down
/system script run attack-alarm
/system script run pihole-down-alert
/system script run super-mario
/system script run fanfare-nokia
```
