# Monitoring Stack

Complete documentation for the homelab observability stack — metrics, logs,
dashboards, and alerting. All services run on the Raspberry Pi 4 (10.40.40.2)
via Docker/Portainer.

---

## Architecture Overview

```
MikroTik RB3011                     iDRAC1 (10.30.30.10)
     │ syslog UDP 5514                    │
     │                               iDRAC2 (10.30.30.11)
     ▼                                    │ syslog UDP 514
RPi rsyslog                               │
  ├── /var/log/mikrotik.log ◄─────────────┘
  └── /var/log/idrac.log ◄── filtered by src IP

promtail
  ├── scrapes mikrotik.log → Loki {job="mikrotik"}
  └── scrapes idrac.log   → Loki {job="idrac", hostname=<parsed>}

idrac-exporter (Redfish/IPMI HTTP poll)
  ├── 10.30.30.10 → Prometheus metrics
  └── 10.30.30.11 → Prometheus metrics

idrac-telegraf (SNMP + custom fields → InfluxDB)
  ├── system-name, model, servicetag, globalstatus
  ├── power-state, system-watts, system-uptime
  ├── fan speeds, temperatures, disk inventory
  ├── RAID battery, CMOS battery, intrusion sensor
  ├── memory-status, storage-status, psu-status
  └── system event log (log-number, log-dates, log-severity, log-entry)

SNMP exporter (router SNMP → Prometheus)
mktxp / node_exporter / pihole-exporter → Prometheus

Grafana  ──► InfluxDB (idrac-hosts measurement)
         ──► Prometheus (idrac_exporter, snmp, mktxp)
         ──► Loki (mikrotik + idrac logs)
```

---

## RPi Service Ports

| Service | Port | Notes |
|---------|------|-------|
| Grafana | 3000 | Dashboard UI |
| Prometheus | 9090 | Metrics TSDB |
| idrac-exporter | 9348 | Redfish HTTP scraper (job: idrac-exporter) |
| snmp-exporter | 9116 | SNMP → Prometheus bridge |
| Loki | 3100 | Log aggregation |
| promtail | — | Log shipper (no external port) |
| rsyslog | 514 UDP, 5514 UDP | Syslog receiver (iDRAC on 514, MikroTik on 5514) |

---

## Log Pipeline

### MikroTik → Loki

```
Router syslog action → UDP 10.40.40.2:5514
→ rsyslog rule: :fromhost-ip, isequal, "10.10.10.1"  → /var/log/mikrotik.log
→ promtail job: mikrotik  →  Loki {job="mikrotik", routerboard=<hostname>}
```

Topics forwarded to RPi: `info`, `firewall`, `warning`, `error`

**RouterOS UDP socket bug**: When adding a new remote logging action, RouterOS
does not initialize the UDP socket until the target is toggled. Fix:
```
/system/logging/action set [find name=remote-rpi] remote=127.0.0.1
/system/logging/action set [find name=remote-rpi] remote=10.40.40.2
```

### iDRAC → Loki

```
iDRAC1/iDRAC2 syslog → UDP 10.40.40.2:514 (hardcoded in iDRAC UI)
→ rsyslog rule: :fromhost-ip, isequal, "10.30.30.10"  → /var/log/idrac.log
               :fromhost-ip, isequal, "10.30.30.11"  → /var/log/idrac.log
→ promtail job: idrac  →  Loki {job="idrac", hostname=<parsed from syslog line>}
```

promtail pipeline stage parses hostname from syslog lines:
```yaml
pipeline_stages:
  - regex:
      expression: '^\S+\s+(?P<hostname>\S+)\s+'
  - labels:
      hostname:
```

### Log Rotation (RPi tmpfs)

`/var/log` on DietPi RPi is a 50 MB tmpfs — without rotation rsyslog fills
it and dies silently. Logrotate config at `/etc/logrotate.d/rpi-logs`:

```
/var/log/syslog
/var/log/user.log
/var/log/idrac.log
/var/log/mikrotik.log
{
    size 5M
    rotate 2
    compress
    missingok
    notifempty
    sharedscripts
    postrotate
        /usr/lib/rsyslog/rsyslog-rotate
    endscript
}
```

---

## Prometheus Config

Config: `/etc/prometheus/prometheus.yml` on RPi

| Job | Target | Metrics |
|-----|--------|---------|
| `idrac-exporter` | 10.40.40.2:9348 | Redfish: CPU, memory, storage, network, power, sensors |
| `snmp` | 10.10.10.1 (router) | Interface counters, CPU, memory |
| `mktxp` | 10.10.10.1 | RouterOS-specific: resource, routes, neighbors, DHCP |
| `node_exporter` | servers | Host OS metrics |
| `pihole-exporter` | 172.17.0.2 | DNS query stats (auth broken — see security notes) |

SNMP community: `txmh` (set in `/opt/snmp-exporter/snmp.yml`)

---

## InfluxDB Schema

Measurement: `idrac-hosts`
Tag: `system-name` (values: `PER730XD-iDRAC`, `PER630-iDRAC`)

| Field | Type | Description |
|-------|------|-------------|
| system-model | string | Dell model string |
| system-servicetag | string | Service tag |
| system-globalstatus | int | 1=Other 2=Unknown 3=OK 4=Non-Critical 5=Critical 6=Non-Recoverable |
| power-state | int | 1=Other 2=Unknown 3=Off 4=On |
| system-watts | float | Current power draw (W) |
| system-uptime | int | System uptime in seconds |
| idrac-url | string | https://10.30.30.1x |
| bios-version | string | BIOS version string |
| system-osname | string | OS reported to iDRAC |
| psu-status | int | PSU aggregate health |
| memory-status | int | Memory health |
| storage-status | int | Storage health |
| cmos-batterystate | int | CMOS battery state |
| raid-batterystate | int | RAID controller battery state |
| intrusion-sensor | int | Chassis intrusion state |
| fan1-speed … fan6-speed | int | Fan RPM per fan slot |
| disks-name | string (tag) | Disk slot label |
| disks-state | int | Disk state (1-10) |
| disks-mediatype | int | 1=Unknown 2=HDD 3=SSD 4=NVMe |
| disks-capacity | int | Capacity in MB |
| disks-predictivefail | int | 0=OK 1=Warning |
| log-number | string (tag) | SEL entry number |
| log-dates | string | SEL entry timestamp |
| log-severity | int | 1-6 severity codes |
| log-entry | string | SEL event text |

---

## Grafana Dashboards

Two dashboards are maintained in `config/`. Import via **Dashboards → Import → Upload JSON**.

---

### Dell iDRAC — Dual Host Command Center

**File**: `config/grafana-idrac-command-center.json`
**UID**: `idrac-dual-command-center`
**Datasources**: InfluxDB + Prometheus + Loki
**Variables**: Left Host, Right Host (both query `idrac-hosts` tag `system-name`)

Side-by-side real-time comparison of both Dell servers. Left column = PER730XD
(cyan `rgb(0,183,255)`), right column = PER630 (magenta `rgb(255,0,178)`).
Color coding is consistent across every panel type.

#### Dashboard Sections

| Row | Content |
|-----|---------|
| **Header** | System Overview table + Global Status Map |
| Power Consumption | Combined W timeseries (both hosts, 24 h) |
| Temperature Gauges | Inlet / Exhaust / CPU1 / CPU2 per host |
| Temperature History | Multi-line °C timeseries (all 8 sensors) |
| Fan Gauges | 6 fans per host (RPM gauges) |
| Fan Speed History | Per-host 6-fan timeseries panels |
| Status Stats | PSU / CMOS Battery / RAID Battery / Intrusion / Memory / Storage per host |
| Info Stats | BIOS Version / OS / Service Tag / Indicator LED per host |
| Power Statistics — Redfish | Avg/Min/Max W stats + Min/Avg/Max timeseries (Prometheus) |
| Disk Inventory | Disk name / state / media type / capacity / predictive fail (InfluxDB table) |
| Drive Detail — Redfish | Drive name / model / protocol / type / serial (Prometheus table) |
| CPU & Memory | CPU model banner, core/thread/socket counts, memory module table (DDR type / ECC / speed / capacity) |
| RAID Array & Storage | Controller health, volume health, RAID array table, storage controller list |
| Network Adapters | NIC port table: link status + speed, per host |
| Link Speeds — Redfish | Port 1–4 speed history timeseries per host |
| System Event Log | InfluxDB SEL tables — log #, date, severity, event |
| iDRAC Syslog — Loki | Log volume timeseries + live PER730XD + PER630 log streams |

#### System Overview Table (top-left)

6 separate InfluxDB queries merged via Grafana `merge` transformation:

| Column | Field | Display |
|--------|-------|---------|
| System Name | system-name | Clickable link → iDRAC web UI |
| System Model | system-model | Plain text |
| Service Tag | system-servicetag | Plain text |
| Power State | power-state | Color background (Off=red, On=green) |
| Global Status | system-globalstatus | Color background (OK=green, Non-Critical=orange, Critical=red) |
| Uptime | system-uptime | Human-readable (unit: seconds) |

#### Global Status Map (top-right)

`status-history` panel — shows `system-globalstatus` over time for each host
as colored rows. Host rows colored with their assigned left/right color.

---

### Homelab Log Intelligence — Router & iDRAC

**File**: `config/grafana-homelab-log-intelligence.json`
**UID**: `homelab-log-intelligence`
**Datasources**: Loki only
**Variables**: Loki datasource, routerboard, topics, search pattern, exclude pattern, smoothing, iDRAC host filter

Combined log dashboard — all logs from all sources in one place. No hardware
telemetry panels — this is purely a log analysis dashboard.

#### Panel Sections

**MikroTik Loki (39 panels)**

| Section | Content |
|---------|---------|
| Overview | Log volume timeseries (stacked by topic), total log count stat |
| Raw Log Streams | Full stream, filtered stream, per-topic streams (firewall, DHCP, error, warning, info) |
| Firewall | Blocked connections volume + stream, src/dst IP tables, protocol breakdown |
| DHCP | Lease events stream, hostname activity table |
| Critical Events | Error/warning/critical stream |
| Pattern Search | Variable-driven regex search across all MikroTik logs |

**iDRAC Loki (15 panels)**

| Section | Content |
|---------|---------|
| iDRAC Overview | Log volume timeseries by hostname, total count stats (per host) |
| PER730XD Stream | Live filtered log stream (`{job="idrac"} \|~ "(?i)idrac1\|730"`) |
| PER630 Stream | Live filtered log stream (`{job="idrac"} \|~ "(?i)idrac2\|630"`) |
| Audit Events | iDRAC audit log filter stream |
| Config Changes | iDRAC configuration change filter stream |
| Full Combined | All iDRAC logs unfiltered |

**Log filter technique**: Content-based `|~` filters are used instead of
label filters because the `hostname` label may not be indexed on existing
entries at query time.

---

## Loki Label Scheme

| Label | Values | Source |
|-------|--------|--------|
| `job` | `mikrotik`, `idrac` | Promtail static config |
| `routerboard` | hostname from syslog | Promtail regex pipeline |
| `hostname` | `idrac1`, `idrac2` | Promtail regex pipeline (parsed from syslog line) |
| `filename` | log file path | Promtail auto |

---

## Dashboard Import

1. Open Grafana at `http://10.40.40.2:3000`
2. **Dashboards → New → Import**
3. Upload JSON file from `config/`
4. Map datasource UIDs if they differ from your instance:
   - InfluxDB: update `"uid": "bfecel4s1xpfke"` if needed
   - Prometheus: update `"uid": "ffdyoshklrd34f"` if needed
   - Loki: update `"uid": "afe2dny5fm70ga"` if needed
5. Save

---

## Known Issues / Notes

- **pihole-exporter auth**: Pi-hole v6 changed its API auth format. The
  Prometheus pihole-exporter is using the wrong password format and returns 401.
  Metrics are absent until the exporter is updated or reconfigured.
- **InfluxDB token**: The InfluxDB API token in Grafana datasource config
  should be rotated (flagged in security notes).
- **iDRAC Loki "No data"**: If iDRAC log panels show no data, check:
  1. `tail -f /var/log/idrac.log` on RPi — confirm iDRAC is sending
  2. `docker logs promtail` — confirm promtail is shipping
  3. Use content filter `|~ "(?i)idrac"` instead of label filter `{hostname=~"..."}`
     since new labels may not be indexed on historical entries
- **RouterOS UDP socket**: If MikroTik logs stop appearing, toggle the remote
  action address (see Log Pipeline section above)
