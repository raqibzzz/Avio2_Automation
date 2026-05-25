# Avio2 Manager — Claude Code Project

## What to build
A local Windows desktop app (PyQt6) for managing multiple Matrox Avio2 IP-KVM devices via their REST API. The app allows adding devices by IP, viewing health/device info, sources, network, streams, users, and executing actions (reboot, factory reset, volume, ping).

## Run instructions
```
pip install PyQt6 requests
python avio2_manager.py
```
Devices are saved to `devices.json` next to the script.

---

## Matrox Avio2 REST API

### Auth flow
All API calls require a Bearer token obtained by:
```
POST https://{ip}/auth/v1/users/login
Headers: Content-Type: application/json, Accept: application/json
Auth: HTTP Basic Auth  (username:password encoded as Base64)
Default credentials: Tester / Matrox1234!
```
Response (200):
```json
{
  "accessToken": "...",
  "authenticationMode": "Local",
  "firstName": "Tester",
  "lastName": "Tester",
  "role": "Admin",
  "expirationIn": 259199,
  "expirationAt": "2026-04-17T18:06:05Z"
}
```
Use `Authorization: Bearer {accessToken}` on all subsequent calls.
Self-signed cert — always use `verify=False` / `requests.Session().verify = False`.

### Three API namespaces
| Namespace | Base URL              | Purpose |
|-----------|----------------------|---------|
| auth      | `https://{ip}/auth`  | Login, logout, users, session length |
| mgmt      | `https://{ip}/mgmt`  | Health, reboot, firmware, device info |
| app       | `https://{ip}/app`   | Sources, streams, codec, network, volume, etc. |

### Key confirmed endpoints (all require Bearer token unless noted)
```
GET  /mgmt/v1/healthstatus              → {isHealthy:bool, messages:[], healthStatusCollection:[{moduleName,isHealthy,messages}]}
GET  /mgmt/v1/healthstatus/ishealthy    → true | false  (no auth needed for discovery)
GET  /mgmt/v1/deviceinformation         → {serialNumber, macAddress, hardwareRevision, ...}
GET  /mgmt/v1/deviceinformation/packageversion  → RAW STRING like "1.00.0065" (not a dict!)
POST /mgmt/v1/reboot                    → 204 No Content on success
POST /mgmt/v1/configreset               → 204 No Content on success

GET  /app/v2/device/status/temperature  → list or dict with celsius values
GET  /app/v2/device/status/operationalmode → {operationalMode: 1=RX, 2=TX, 3=Dual}
GET  /app/v2/device/status/video/codec  → {codec: 1=ProAV, 2=JPEGXS, 3=H.264, 4=H.265}
GET  /app/v2/device/status/reboot/needed → bool or {rebootNeeded:bool}
GET  /app/v2/device/settings/identity   → {name: "device name"}
GET  /app/v2/device/info/sources        → list of source objects OR {sources:[...]}
GET  /app/v2/device/status/network      → network summary
GET  /app/v2/device/status/network/details → detailed connectors (may be list or dict)
GET  /app/v2/device/status/streams/video   → list of stream indices [0,1,...]
GET  /app/v2/device/status/streams/video/{index} → {scaling,isHdcp,codec,isPresent,state,bitrateKbits,nmosId,streamType,index,streamLabel,sdpUrl,isEncrypted,streamConnectionStatus}
GET  /app/v2/device/status/streams/audio   → list of audio stream indices
GET  /app/v2/device/status/streams/audio/{index} → {audioDataType,trackingClock,isPresent,...}
GET  /app/v2/device/settings/volume     → {level: 0-100}
PUT  /app/v2/device/settings/volume     body: {"level": int}  → 204
PUT  /app/v2/device/settings/volume/mute body: {"muted": bool} → 204

GET  /auth/v1/users/local               → list of {username, firstName, lastName, role(1=Admin,2=User)}
GET  /auth/v1/users/session-length      → {seconds: 259199}
PUT  /auth/v1/users/session-length      body: {"seconds": int}  → 204
     Preset values: 72h=259199, 6days=518400, 30days=2592000
```

### CRITICAL parsing notes
- `firmware` endpoint returns a **raw string** `"1.00.0065"` NOT a dict — use `isinstance(v, str)` check before `.get()`
- `network/details` may return a list, a dict with various wrapper keys, or even a raw string on some firmware — handle all three
- `sources` may return a plain list OR `{"sources": [...]}` — check both
- `temperature` may be a list of `{celsius: N}` OR a dict with nested `temperatures` key
- `operationalMode` and `codec` values are **integers** mapped to strings:
  - operationalMode: 1=Receiver(RX), 2=Transmitter(TX), 3=Dual
  - codec: 1=ProAV, 2=JPEGXS, 3=H.264, 4=H.265
- Boolean fields should display as "Yes"/"No" not True/False
- `bitrateKbits` should display as e.g. "4,252,765 Kbps  (4252.8 Mbps)"

---

## Device info
| Device | IP | Role |
|--------|----|------|
| RX (Receiver)    | 192.168.189.121 | Primary test device |
| TX (Transmitter) | 192.168.189.174 | Source for RX |

Default credentials for both: `Tester` / `Matrox1234!`

---

## UI requirements

### Layout
- Left sidebar (234px wide, dark navy) with Matrox blue logo bar at top
- "+" button to add devices, device list below
- Main panel to the right with device panel or welcome screen

### Device panel tabs
1. **Overview** — Health status with module badges (Mgmt/Auth/App), Device Info card (name, serial, MAC, firmware), Live Status card (mode, temperature with color coding, codec, reboot needed)
2. **Sources** — List of sources from RX device, show connected badge if available
3. **Network** — Network connectors and interfaces
4. **Streams** — Video and audio stream status with connection badge
5. **Users** — Local user list with roles, session length presets
6. **Actions** — Ping (fresh login + health check), Reboot (with confirm), Factory Reset (with confirm), Volume slider + set, Mute/Unmute

### Color palette (Matrox WebUI-inspired)
```python
P = {
    "bg":          "#080e1c",   # main background
    "bg_side":     "#0b1222",   # sidebar
    "bg_card":     "#0f1928",   # card backgrounds
    "bg_row":      "#121f30",   # alternating rows, hover
    "bg_hdr":      "#0d1530",   # device header bar
    "accent":      "#2563eb",   # primary blue (buttons, active tab)
    "accent_h":    "#1d4ed8",   # button hover
    "accent_dim":  "#1a3560",   # ghost button bg
    "success":     "#22c55e",   # health OK, connected
    "succ_dim":    "#052e16",   # success badge background
    "succ_lt":     "#4ade80",   # success badge text
    "warn":        "#f59e0b",   # warning (reboot, high temp)
    "warn_dim":    "#2d1a00",   # warning button bg
    "danger":      "#ef4444",   # error, factory reset
    "dang_dim":    "#2d0a0a",   # danger button bg
    "txt":         "#eef2ff",   # primary text
    "txt2":        "#8fa8c8",   # secondary text, labels
    "txt3":        "#3d5470",   # muted text, section headers
    "border":      "#172540",   # card borders, dividers
    "matrox":      "#1d3fa8",   # Matrox brand blue for logo bar
    "rx":          "#f97316",   # RX device orange
    "tx":          "#3b82f6",   # TX device blue
}
```

### Threading
- Use QThread workers for ALL API calls — never block the UI thread
- Pattern: `Worker(fn)` where fn is a callable that returns data
- Connect `worker.result` signal to UI update slot
- Keep references to workers (self._w) to prevent garbage collection

### Key UX details
- Ping must do a fresh `login()` call first, then `/mgmt/v1/healthstatus/ishealthy`
- Connection status in header should update after login completes (green "● Connected" or red error)
- Tab content is lazy-loaded on first visit and cached; Refresh button re-runs the API calls
- All info rows: left column 195px wide with secondary text color, right column bold primary text
- Cards have `background:#0f1928; border:1px solid #172540; border-radius:8px`
- Active tab has bottom border: `border-bottom: 2px solid #2563eb`

---

## File structure
```
avio2_manager/
├── avio2_manager.py   ← entire app, single file
├── devices.json       ← auto-created, stores saved devices
└── README.md
```

## Dependencies
```
PyQt6>=6.4
requests>=2.28
```
Install: `pip install PyQt6 requests`
No venv required — can run from any Python 3.10+ installation.
