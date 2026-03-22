# Beeper Alert System

The RB3011UiAS has a built-in piezo beeper. RouterOS `:beep` command controls it directly.
All scripts have `dont-require-permissions=yes` so they can be called from netwatch and schedulers without permission issues.

## Alert Tones

| Script | Tone Pattern | Trigger |
|--------|-------------|---------|
| `alert-up` | Two rising tones (523→784 Hz) | Host comes back online, ethernet link up |
| `alert-down` | Three descending tones (880→660→440 Hz) | Host goes down, ethernet link down |
| `alert-wan-down` | Five rapid 1000 Hz beeps + two 800 Hz tones | WAN goes down |
| `attack-alarm` | Three sweeping up-down patterns (440→1100→440 Hz) | DDoS/SSH/port scan blacklist increase |
| `dhcp-new-lease` | C6-E6-G6 ascending arpeggio (1047→1319→1568 Hz) | New DHCP lease assigned |
| `wifi-connect` | C6-E6-G6 ascending arpeggio (1047→1319→1568 Hz) | WiFi client connects |
| `wifi-disconnect` | G6-E6-C6 descending arpeggio (1568→1319→1047 Hz) | WiFi client disconnects |
| `super-mario` | Full Super Mario Bros overworld theme | `/system script run super-mario` |

## Schedulers

| Scheduler | Interval | Script | Purpose |
|-----------|----------|--------|---------|
| `eth-monitor` | 3s | eth-monitor | Polls all ethernet interfaces for link state changes |
| `wifi-monitor` | 5s | wifi-monitor | Polls CAPsMAN registration table for connect/disconnect |
| `attack-monitor` | 10s | attack-monitor | Polls firewall blacklist counts for any increase |

## Netwatch Hosts

| Host | Comment | Interval | Down Action | Up Action |
|------|---------|----------|-------------|-----------|
| 10.10.10.10 | Server1 | 30s | alert-down + log warning | alert-up + log info |
| 10.20.20.10 | Server2 | 30s | alert-down + log warning | alert-up + log info |
| 10.30.30.10 | iDRAC1 | 60s | alert-down + log warning | alert-up + log info |
| 10.30.30.11 | iDRAC2 | 60s | alert-down + log warning | alert-up + log info |
| 8.8.8.8 | WAN | 30s | alert-wan-down + log error | alert-up + log info |
| 172.17.0.2 | Pi-hole | 15s | alert-down + switch DNS to Google | alert-up + restore DNS to Pi-hole |
| 10.60.60.200 | mAP2nD-1 | 30s | alert-down + log warning | alert-up + log info |
| 10.60.60.201 | wAP2nD-1 | 30s | alert-down + log warning | alert-up + log info |

## DHCP Lease Logging

The `dhcp-new-lease` script is assigned to all six DHCP servers. On each new lease it plays the arpeggio tone and logs:
```
New lease: <IP> MAC: <MAC>
```

## Running Mario Manually

```
/system script run super-mario
```
