# Avio2 Manager
**Local desktop dashboard for Matrox Avio2 IP-KVM devices**
Matrox SQA | Raqib Abdullah Muktadir

---

## Setup (one time)

1. Make sure you're using your existing robot-tests venv:
   ```
   cd C:\Users\rabdulla\robot-tests
   .venv\Scripts\activate
   ```

2. Install the one new dependency:
   ```
   pip install customtkinter
   ```
   (requests is already installed from robotframework-requests)

3. Run the app:
   ```
   python avio2_manager.py
   ```

---

## Usage

- Click **+** in the sidebar to add a device by IP
- Default credentials are pre-filled (Tester / Matrox1234!) — change if needed
- Optionally give the device a label (e.g. "RX Lab Bench" or "TX Studio")
- Device list is saved to `devices.json` next to the script — persists between runs

### Tabs per device

| Tab | What it shows |
|-----|---------------|
| Overview | Health status, device info, firmware, temperature, codec, operational mode |
| Sources | All sources known to the receiver (RX only) |
| Network | Network interfaces and IP details |
| Streams | Active video and audio stream status |
| Users | Local user accounts, session length settings |
| Actions | Reboot, factory reset, volume/mute control, ping |

---

## Notes

- Self-signed cert warnings are suppressed automatically (same as Robot Framework)
- Tokens are cached and auto-refreshed before expiry
- All API calls are non-blocking (run in background threads) so the UI stays responsive
- The app never sends anything outside your local network

---

## Building a standalone .exe (optional)

If you want to share with teammates without requiring Python:

```
pip install pyinstaller
pyinstaller --onefile --windowed --name "Avio2Manager" avio2_manager.py
```

The `.exe` will be in the `dist/` folder.
