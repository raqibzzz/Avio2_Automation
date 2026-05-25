"""
Avio2 Manager  —  Matrox SQA
PyQt6 | Raqib Abdullah Muktadir
"""
import sys, os, json, time
from datetime import datetime
import urllib3
urllib3.disable_warnings()
import requests
from PyQt6.QtCore import (Qt, QThread, pyqtSignal, QTimer, QSize, QPoint)
from PyQt6.QtGui  import (QFont, QColor, QPixmap, QPainter, QPen, QBrush,
                           QLinearGradient, QIcon, QCursor)
from PyQt6.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, QGridLayout,
    QLabel, QPushButton, QLineEdit, QScrollArea, QFrame, QStackedWidget,
    QSizePolicy, QSlider, QDialog, QMessageBox, QSpacerItem, QComboBox,
    QTextEdit, QTabWidget, QGroupBox, QCheckBox, QSpinBox
)

DEVICES_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "devices.json")

# ── Palette ───────────────────────────────────────────────────────────────────
P = {
    "bg":         "#080e1c", "bg_side":    "#0b1222", "bg_card":    "#0f1928",
    "bg_row":     "#121f30", "bg_hdr":     "#0d1530", "bg_input":   "#0a1220",
    "accent":     "#2563eb", "accent_h":   "#1d4ed8", "accent_dim": "#1a3560",
    "success":    "#22c55e", "succ_dim":   "#052e16", "succ_lt":    "#4ade80",
    "warn":       "#f59e0b", "warn_dim":   "#2d1a00",
    "danger":     "#ef4444", "dang_dim":   "#2d0a0a",
    "txt":        "#eef2ff", "txt2":       "#8fa8c8", "txt3":       "#3d5470",
    "border":     "#172540", "border2":    "#1e3456",
    "matrox":     "#1d3fa8", "rx":         "#f97316", "tx":         "#3b82f6",
}

OP_MODES = {1:"Receiver (RX)", 2:"Transmitter (TX)", 3:"Dual Mode"}
CODECS   = {1:"ProAV", 2:"JPEGXS", 3:"H.264", 4:"H.265"}
ROLES    = {1:"Admin", 2:"User"}

LABELS = {
    "scaling":"Scaling Enabled","isHdcp":"HDCP Protected","codec":"Codec",
    "isPresent":"Signal Present","state":"State","bitrateKbits":"Bitrate",
    "nmosId":"NMOS ID","streamType":"Stream Type","index":"Index",
    "streamLabel":"Label","sdpUrl":"SDP URL","isEncrypted":"Encrypted",
    "streamConnectionStatus":"Connection Status",
    "audioDataType":"Audio Type","trackingClock":"Tracking Clock",
    "sampleRate":"Sample Rate","bitDepth":"Bit Depth","channelCount":"Channels",
    "serialNumber":"Serial Number","macAddress":"MAC Address",
    "hardwareRevision":"Hardware Revision","name":"Device Name",
    "operationalMode":"Operational Mode","currentMode":"Current Mode",
    "currentCodec":"Active Codec","configuredCodec":"Configured Codec",
    "rebootNeeded":"Reboot Required","ipAddress":"IP Address",
    "subnetMask":"Subnet Mask","gateway":"Gateway","dns":"DNS Server",
    "dhcp":"DHCP","speed":"Link Speed","duplex":"Duplex","linkState":"Link State",
    "mtu":"MTU","macAddr":"MAC Address","connectorId":"Connector",
    "interfaceId":"Interface","sourceName":"Source Name","celsius":"Temperature",
    "role":"Role","username":"Username","seconds":"Duration",
    "isEnabled":"Enabled","isActive":"Active","statusMessage":"Status",
    "locateDeviceEnabled":"Locate LED Active","firmwareVersion":"Firmware",
    "packageVersion":"Firmware","discoveryMethod":"Discovery Method",
    "nmosSenderLabel":"NMOS Sender Label","nmosReceiverLabel":"NMOS Receiver Label",
    "connectionStatus":"Connection Status","registryUrl":"Registry URL",
    "nodeId":"Node ID","level":"Volume Level","muted":"Muted",
    "licenseType":"License Type","isInstalled":"Installed",
}

def lbl(k): return LABELS.get(k, k.replace("_"," ").title())
def fmtv(k, v):
    if v is None or v == "": return "—"
    if isinstance(v, bool):  return "Yes" if v else "No"
    if k == "bitrateKbits":
        try: return f"{int(v):,} Kbps  ({round(int(v)/1000,1)} Mbps)"
        except: pass
    if k in ("operationalMode","currentMode"): return OP_MODES.get(v, str(v))
    if k in ("codec","currentCodec","configuredCodec"): return CODECS.get(v, str(v))
    if k == "role":     return ROLES.get(v, str(v))
    if k == "celsius":  return f"{v} °C"
    if k == "sampleRate" and isinstance(v,int): return f"{v:,} Hz"
    if k == "seconds" and isinstance(v,(int,float)): return f"{v}s  ({round(v/3600,1)} h)"
    return str(v)

def safe_d(v): return v if isinstance(v,dict) else {}
def safe_l(v): return v if isinstance(v,list) else []

def load_devices():
    if os.path.exists(DEVICES_FILE):
        try:
            with open(DEVICES_FILE) as f: return json.load(f)
        except: pass
    return []

def save_devices(devs):
    with open(DEVICES_FILE,"w") as f: json.dump(devs,f,indent=2)

# ── API Client ────────────────────────────────────────────────────────────────
class Avio2Client:
    def __init__(self, ip, username="Tester", password="Matrox1234!"):
        self.ip=ip; self.username=username; self.password=password
        self.token=None; self.token_expiry=None
        self.session=requests.Session(); self.session.verify=False

    def _a(self,p):  return f"https://{self.ip}/auth{p}"
    def _m(self,p):  return f"https://{self.ip}/mgmt{p}"
    def _ap(self,p): return f"https://{self.ip}/app{p}"
    def _h(self):    return {"Authorization":f"Bearer {self.token}","Accept":"application/json"}

    def login(self):
        try:
            r = self.session.post(self._a("/v1/users/login"),
                headers={"Content-Type":"application/json","Accept":"application/json"},
                auth=(self.username,self.password), timeout=8)
            if r.status_code == 200:
                d=r.json(); self.token=d["accessToken"]
                self.token_expiry=datetime.now().timestamp()+d.get("expirationIn",86400)
                return True, d
            return False, f"HTTP {r.status_code}"
        except requests.exceptions.ConnectionError: return False,"Connection refused"
        except requests.exceptions.Timeout:         return False,"Timed out"
        except Exception as e:                       return False, str(e)

    def _ok(self):
        if not self.token or (self.token_expiry and datetime.now().timestamp()>self.token_expiry-300):
            ok,_=self.login(); return ok
        return True

    def get(self,url):
        if not self._ok(): return None
        try:
            r=self.session.get(url,headers=self._h(),timeout=8)
            if r.status_code==200:
                try: return r.json()
                except: return r.text
            return None
        except: return None

    def post(self,url,data=None):
        if not self._ok(): return None,"Auth failed"
        try:
            r=self.session.post(url,headers={**self._h(),"Content-Type":"application/json"},json=data,timeout=8)
            return r.status_code,r.text
        except Exception as e: return None,str(e)

    def put(self,url,data=None):
        if not self._ok(): return None,"Auth failed"
        try:
            r=self.session.put(url,headers={**self._h(),"Content-Type":"application/json"},json=data,timeout=8)
            return r.status_code,r.text
        except Exception as e: return None,str(e)

    # Core endpoints
    def health(self):          return self.get(self._m("/v1/healthstatus"))
    def device_info(self):     return self.get(self._m("/v1/deviceinformation"))
    def firmware(self):        return self.get(self._m("/v1/deviceinformation/packageversion"))
    def temperature(self):     return self.get(self._ap("/v2/device/status/temperature"))
    def op_mode(self):         return self.get(self._ap("/v2/device/status/operationalmode"))
    def codec(self):           return self.get(self._ap("/v2/device/status/video/codec"))
    def reboot_needed(self):   return self.get(self._ap("/v2/device/status/reboot/needed"))
    def identity(self):        return self.get(self._ap("/v2/device/settings/identity"))
    def sources(self):         return self.get(self._ap("/v2/device/info/sources"))
    def network(self):         return self.get(self._ap("/v2/device/status/network"))
    def network_det(self):     return self.get(self._ap("/v2/device/status/network/details"))
    def users(self):           return self.get(self._a("/v1/users/local"))
    def session_len(self):     return self.get(self._a("/v1/users/session-length"))
    def do_reboot(self):       return self.post(self._m("/v1/reboot"))
    def do_factory_reset(self):return self.post(self._m("/v1/configreset"))
    def set_volume(self,lvl):  return self.put(self._ap("/v2/device/settings/volume"),{"level":lvl})
    def set_mute(self,muted):  return self.put(self._ap("/v2/device/settings/volume/mute"),{"muted":muted})
    def set_session(self,s):   return self.put(self._a("/v1/users/session-length"),{"seconds":s})

    # ── 10 new endpoints ──────────────────────────────────────────────────────
    def licenses(self):        return self.get(self._ap("/v2/device/status/licenses"))
    def locate_status(self):   return self.get(self._ap("/v2/device/status/locatedevice"))
    def set_locate(self,on):   return self.put(self._ap("/v2/device/settings/locatedevice"),{"enabled":on})
    def video_connectors(self):return self.get(self._ap("/v2/device/status/video"))
    def audio_connectors(self):return self.get(self._ap("/v2/device/info/audio"))
    def nmos_status(self):     return self.get(self._ap("/v2/device/status/nmos"))
    def connected_devices(self):return self.get(self._ap("/v2/device/status/connecteddevices"))
    def codec_settings(self):  return self.get(self._ap("/v2/device/settings/video/codec"))
    def set_codec(self,codec_val): return self.put(self._ap("/v2/device/settings/video/codec"),{"codec":codec_val})
    def set_identity(self,name):   return self.put(self._ap("/v2/device/settings/identity"),{"name":name})
    def volume(self):          return self.get(self._ap("/v2/device/settings/volume"))
    def mute(self):            return self.get(self._ap("/v2/device/settings/volume/mute"))
    def usb_devices(self):     return self.get(self._ap("/v2/device/status/usb"))
    def bitrate_bounds(self):  return self.get(self._ap("/v2/device/info/video/minmax-bitrates"))
    def expected_bitrate(self):return self.get(self._ap("/v2/device/info/video/expected-bitrate"))

    def video_streams(self):
        ids=safe_l(self.get(self._ap("/v2/device/status/streams/video")))
        return [s for i in ids if (s:=self.get(self._ap(f"/v2/device/status/streams/video/{i}"))) and isinstance(s,dict)]

    def audio_streams(self):
        ids=safe_l(self.get(self._ap("/v2/device/status/streams/audio")))
        return [s for i in ids if (s:=self.get(self._ap(f"/v2/device/status/streams/audio/{i}"))) and isinstance(s,dict)]

    def usb_streams(self):
        ids=safe_l(self.get(self._ap("/v2/device/status/streams/usb")))
        return [s for i in ids if (s:=self.get(self._ap(f"/v2/device/status/streams/usb/{i}"))) and isinstance(s,dict)]

    def ping_check(self):
        t0=time.time(); ok,_=self.login()
        if not ok: return False,0
        try:
            r=self.session.get(self._m("/v1/healthstatus/ishealthy"),headers=self._h(),timeout=4)
            return r.status_code==200, round((time.time()-t0)*1000)
        except: return False,0

# ── Worker thread ─────────────────────────────────────────────────────────────
class Worker(QThread):
    result = pyqtSignal(object)
    def __init__(self,fn): super().__init__(); self._fn=fn
    def run(self):
        try: self.result.emit(self._fn())
        except: self.result.emit(None)

# ── Global stylesheet ─────────────────────────────────────────────────────────
QSS = f"""
* {{ font-family:'Segoe UI'; }}
QWidget {{ background:{P['bg']}; color:{P['txt']}; font-size:12px; }}
QScrollArea {{ border:none; }}
QScrollBar:vertical {{ background:{P['bg_side']}; width:6px; border-radius:3px; }}
QScrollBar::handle:vertical {{ background:{P['border2']}; border-radius:3px; min-height:30px; }}
QScrollBar::add-line:vertical, QScrollBar::sub-line:vertical {{ height:0; }}
QScrollBar:horizontal {{ height:0; }}
QLabel {{ background:transparent; color:{P['txt']}; }}
QLineEdit {{
    background:{P['bg_input']}; color:{P['txt']}; border:1px solid {P['border2']};
    border-radius:8px; padding:10px 14px; font-size:13px; selection-background-color:{P['accent']};
}}
QLineEdit:focus {{ border:1px solid {P['accent']}; background:{P['bg_row']}; }}
QLineEdit:hover {{ border:1px solid {P['border2']}; }}
QComboBox {{
    background:{P['bg_input']}; color:{P['txt']}; border:1px solid {P['border2']};
    border-radius:8px; padding:8px 14px; font-size:12px; min-height:36px;
}}
QComboBox:focus {{ border:1px solid {P['accent']}; }}
QComboBox::drop-down {{ border:none; width:28px; }}
QComboBox QAbstractItemView {{
    background:{P['bg_card']}; color:{P['txt']}; border:1px solid {P['border2']};
    selection-background-color:{P['accent_dim']};
}}
QPushButton {{
    background:{P['accent']}; color:#fff; border:none;
    border-radius:8px; padding:9px 20px; font-size:12px; font-weight:600;
    min-height:36px;
}}
QPushButton:hover  {{ background:{P['accent_h']}; }}
QPushButton:pressed {{ background:{P['matrox']}; }}
QPushButton[variant="flat"] {{
    background:transparent; color:{P['txt2']}; border:1px solid {P['border2']};
    border-radius:8px;
}}
QPushButton[variant="flat"]:hover {{ background:{P['bg_row']}; color:{P['txt']}; border-color:{P['accent']}; }}
QPushButton[variant="warn"] {{
    background:{P['warn_dim']}; color:{P['warn']}; border:1px solid {P['warn']}; border-radius:8px;
}}
QPushButton[variant="warn"]:hover {{ background:#3d2800; }}
QPushButton[variant="danger"] {{
    background:{P['dang_dim']}; color:{P['danger']}; border:1px solid {P['danger']}; border-radius:8px;
}}
QPushButton[variant="danger"]:hover {{ background:#3d0000; }}
QPushButton[variant="ghost"] {{
    background:{P['accent_dim']}; color:{P['accent']}; border:1px solid {P['accent']}; border-radius:8px;
}}
QPushButton[variant="ghost"]:hover {{ background:{P['accent']}; color:#fff; }}
QPushButton[variant="success"] {{
    background:{P['succ_dim']}; color:{P['succ_lt']}; border:1px solid {P['success']}; border-radius:8px;
}}
QPushButton[variant="success"]:hover {{ background:#0a4020; }}
QFrame[role="card"] {{
    background:{P['bg_card']}; border:1px solid {P['border']}; border-radius:10px;
}}
QFrame[role="divider"] {{ background:{P['border']}; max-height:1px; min-height:1px; border:none; }}
QFrame[role="sub"] {{
    background:{P['bg_row']}; border:1px solid {P['border']}; border-radius:6px;
}}
"""

# ── UI helpers ────────────────────────────────────────────────────────────────
def ltext(text, size=12, bold=False, color=None, wrap=False, align=None):
    lb = QLabel(text)
    f  = QFont("Segoe UI", size); f.setBold(bold); lb.setFont(f)
    st = "background:transparent;"
    if color: st += f"color:{color};"
    lb.setStyleSheet(st)
    if wrap: lb.setWordWrap(True)
    if align: lb.setAlignment(align)
    return lb

def divider():
    f = QFrame(); f.setProperty("role","divider"); f.setFixedHeight(1); return f

def badge(text, bg, fg="#fff"):
    l = QLabel(f"  {text}  ")
    l.setStyleSheet(f"background:{bg};color:{fg};border-radius:4px;"
                    f"font-weight:700;font-size:10px;padding:2px 0;")
    l.setFixedHeight(22); return l

def card_widget(title=None):
    f = QFrame(); f.setProperty("role","card")
    lay = QVBoxLayout(f); lay.setSpacing(0); lay.setContentsMargins(0,0,0,0)
    if title:
        hdr = ltext(title.upper(), 9, bold=True, color=P["txt3"])
        hdr.setContentsMargins(18,14,18,8)
        lay.addWidget(hdr)
    return f, lay

def info_row(key_text, val_text, val_color=None):
    row = QWidget(); row.setStyleSheet("background:transparent;")
    h = QHBoxLayout(row); h.setContentsMargins(18,4,18,4); h.setSpacing(0)
    k = ltext(key_text, 11, color=P["txt2"])
    k.setFixedWidth(200); k.setAlignment(Qt.AlignmentFlag.AlignLeft|Qt.AlignmentFlag.AlignVCenter)
    v = ltext(val_text, 11, bold=True, color=val_color or P["txt"], wrap=True)
    h.addWidget(k); h.addWidget(v,1); return row

def pad_bottom(lay, n=12): lay.addSpacing(n)

def scrollify(widget):
    sa = QScrollArea(); sa.setWidgetResizable(True); sa.setWidget(widget)
    sa.setHorizontalScrollBarPolicy(Qt.ScrollBarPolicy.ScrollBarAlwaysOff)
    sa.setFrameShape(QFrame.Shape.NoFrame); return sa

def render_dict(lay, d, skip=None):
    skip = set(skip or [])
    for k,v in d.items():
        if k in skip or isinstance(v,(dict,list)) or v is None or v == "": continue
        lay.addWidget(info_row(lbl(k), fmtv(k,v)))

def btn(text, variant="accent", w=None, h=36):
    b = QPushButton(text)
    if variant != "accent": b.setProperty("variant", variant)
    if w: b.setFixedWidth(w)
    b.setFixedHeight(h)
    return b

def section_btn_row(*buttons):
    w = QWidget(); w.setStyleSheet("background:transparent;")
    lay = QHBoxLayout(w); lay.setContentsMargins(18,8,18,14); lay.setSpacing(10)
    for b in buttons: lay.addWidget(b)
    lay.addStretch(); return w

# ── Add Device Dialog — fully redesigned ─────────────────────────────────────
class AddDeviceDialog(QDialog):
    def __init__(self, parent):
        super().__init__(parent)
        self.setWindowTitle("Add Device")
        self.setFixedSize(460, 460)
        self.setModal(True)
        self.setStyleSheet(QSS)
        self.result_data = None

        root = QVBoxLayout(self)
        root.setSpacing(0)
        root.setContentsMargins(0, 0, 0, 0)

        # ── Blue header ───────────────────────────────────────────────────
        hdr = QWidget()
        hdr.setStyleSheet(f"background:qlineargradient(x1:0,y1:0,x2:1,y2:0,"
                           f"stop:0 {P['matrox']},stop:1 #1a4ab8);")
        hdr.setFixedHeight(72)
        hl  = QHBoxLayout(hdr); hl.setContentsMargins(24,0,24,0); hl.setSpacing(16)

        icon = QLabel("M")
        icon.setFixedSize(40,40)
        icon.setAlignment(Qt.AlignmentFlag.AlignCenter)
        icon.setStyleSheet("background:#ffffff22;border-radius:8px;"
                            "color:#fff;font-size:18px;font-weight:800;")
        title_col = QWidget(); title_col.setStyleSheet("background:transparent;")
        tc = QVBoxLayout(title_col); tc.setSpacing(1); tc.setContentsMargins(0,0,0,0)
        tc.addWidget(ltext("Add New Device", 15, bold=True, color="#ffffff"))
        tc.addWidget(ltext("Connect to an Avio2 device on your network", 10, color="#a0c0e8"))
        hl.addWidget(icon)
        hl.addWidget(title_col, 1)
        root.addWidget(hdr)

        # ── Form body ─────────────────────────────────────────────────────
        body = QWidget(); body.setStyleSheet(f"background:{P['bg_card']};")
        fl   = QVBoxLayout(body)
        fl.setContentsMargins(24, 24, 24, 20)
        fl.setSpacing(0)

        def field(label_text, placeholder, default="", pw=False):
            lbl_w = ltext(label_text, 11, color=P["txt2"])
            lbl_w.setContentsMargins(0,0,0,5)
            fl.addWidget(lbl_w)
            e = QLineEdit()
            e.setPlaceholderText(placeholder)
            if default: e.setText(default)
            if pw: e.setEchoMode(QLineEdit.EchoMode.Password)
            e.setFixedHeight(44)
            fl.addWidget(e)
            fl.addSpacing(14)
            return e

        self.e_ip   = field("IP Address",      "e.g. 192.168.189.121", "192.168.189.")
        self.e_user = field("Username",         "Tester",               "Tester")
        self.e_pass = field("Password",         "••••••••",             "Matrox1234!", pw=True)
        self.e_lbl  = field("Label (optional)", "e.g. RX Lab Bench")

        fl.addSpacing(6)
        btn_row = QHBoxLayout(); btn_row.setSpacing(12)
        cancel_b = btn("Cancel", "flat", w=120)
        connect_b = btn("Connect  →", w=140)
        cancel_b.clicked.connect(self.reject)
        connect_b.clicked.connect(self._submit)
        btn_row.addStretch()
        btn_row.addWidget(cancel_b)
        btn_row.addWidget(connect_b)
        fl.addLayout(btn_row)

        root.addWidget(body, 1)

        self.e_ip.setFocus()
        self.e_ip.returnPressed.connect(self._submit)
        self.e_pass.returnPressed.connect(self._submit)

    def _submit(self):
        ip = self.e_ip.text().strip()
        if not ip:
            self.e_ip.setStyleSheet(f"border:1px solid {P['danger']};border-radius:8px;"
                                     f"background:{P['bg_input']};color:{P['txt']};padding:10px 14px;")
            return
        self.result_data = {
            "ip":       ip,
            "username": self.e_user.text().strip() or "Tester",
            "password": self.e_pass.text().strip() or "Matrox1234!",
            "label":    self.e_lbl.text().strip(),
        }
        self.accept()

# ── Overview Tab ──────────────────────────────────────────────────────────────
class OverviewTab(QWidget):
    def __init__(self, client):
        super().__init__(); self.client=client
        root = QVBoxLayout(self); root.setContentsMargins(0,0,0,0)
        inner = QWidget()
        self.lay = QVBoxLayout(inner)
        self.lay.setContentsMargins(16,16,16,16); self.lay.setSpacing(10)

        hc,hl = card_widget("Health Status")
        self.h_status = ltext("Checking…",13,bold=True,color=P["txt2"])
        self.h_status.setContentsMargins(18,0,18,6)
        hl.addWidget(self.h_status)
        self.h_mods_row = QWidget(); self.h_mods_row.setStyleSheet("background:transparent;")
        self.h_mods_lay = QHBoxLayout(self.h_mods_row)
        self.h_mods_lay.setContentsMargins(18,0,18,14); self.h_mods_lay.setSpacing(8)
        self.h_mods_lay.addStretch()
        hl.addWidget(self.h_mods_row)
        self.lay.addWidget(hc)

        dc,self.dlay = card_widget("Device Information")
        self.lay.addWidget(dc)

        lc,self.llay = card_widget("Live Status")
        self.lay.addWidget(lc)

        self.lay.addStretch()
        root.addWidget(scrollify(inner))
        self.refresh()

    def refresh(self):
        def fetch(): return {
            "health":self.client.health(),"info":self.client.device_info(),
            "fw":self.client.firmware(),"temp":self.client.temperature(),
            "mode":self.client.op_mode(),"codec":self.client.codec(),
            "reboot":self.client.reboot_needed(),"identity":self.client.identity(),
        }
        self._w=Worker(fetch); self._w.result.connect(self._render); self._w.start()

    def _clr(self,lay,keep=1):
        while lay.count()>keep:
            it=lay.takeAt(keep)
            if it.widget(): it.widget().deleteLater()

    def _render(self,d):
        if not d: return
        # Health
        for i in reversed(range(self.h_mods_lay.count()-1)):
            w=self.h_mods_lay.itemAt(i).widget()
            if w: w.deleteLater()
        h=safe_d(d.get("health"))
        if h:
            ok=h.get("isHealthy",False)
            self.h_status.setText("● All Systems Healthy" if ok else "● Unhealthy")
            self.h_status.setStyleSheet(
                f"color:{P['success'] if ok else P['danger']};background:transparent;font-weight:700;font-size:13px;")
            for i,mod in enumerate(safe_l(h.get("healthStatusCollection",[]))):
                ok_m=mod.get("isHealthy",False)
                self.h_mods_lay.insertWidget(i, badge(
                    f"{'✓' if ok_m else '✗'}  {mod.get('moduleName','')}",
                    P["succ_dim"] if ok_m else P["dang_dim"],
                    P["succ_lt"]  if ok_m else P["danger"]))
        else:
            self.h_status.setText("● Unreachable")
            self.h_status.setStyleSheet(f"color:{P['danger']};background:transparent;font-weight:700;font-size:13px;")

        # Device info
        self._clr(self.dlay)
        info=safe_d(d.get("info")); ident=safe_d(d.get("identity"))
        fw=d.get("fw")
        fw_str=fw if isinstance(fw,str) else safe_d(fw).get("packageVersion") or safe_d(fw).get("version")
        rows=[]
        if ident.get("name"):           rows.append(("Device Name",       ident["name"],  None))
        if info.get("serialNumber"):    rows.append(("Serial Number",     info["serialNumber"],None))
        if info.get("macAddress"):      rows.append(("MAC Address",       info["macAddress"],None))
        if info.get("hardwareRevision"):rows.append(("Hardware Revision", info["hardwareRevision"],None))
        if fw_str:                      rows.append(("Firmware",          fw_str, P["accent"]))
        if rows:
            for k,v,c in rows: self.dlay.addWidget(info_row(k,v,c))
        else:
            self.dlay.addWidget(ltext("  No device information returned",11,color=P["txt3"]))
        pad_bottom(self.dlay)

        # Live status
        self._clr(self.llay)
        rows2=[]
        mode_raw=d.get("mode")
        if isinstance(mode_raw,dict):
            mv=mode_raw.get("operationalMode") or mode_raw.get("currentMode")
            if mv is not None: rows2.append(("Operational Mode",fmtv("operationalMode",mv),P["tx"] if mv==2 else P["rx"]))
        elif isinstance(mode_raw,int):
            rows2.append(("Operational Mode",fmtv("operationalMode",mode_raw),P["tx"] if mode_raw==2 else P["rx"]))

        temp_raw=d.get("temp"); tv=None
        if isinstance(temp_raw,list) and temp_raw:
            t=temp_raw[0]; tv=safe_d(t).get("celsius") or safe_d(t).get("value") if isinstance(t,dict) else t
        elif isinstance(temp_raw,dict):
            temps=temp_raw.get("temperatures") or [temp_raw]; t=temps[0] if temps else {}
            tv=safe_d(t).get("celsius") or safe_d(t).get("value") if isinstance(t,dict) else None
        if tv is not None:
            try:
                fv=float(tv); tc=P["danger"] if fv>70 else P["warn"] if fv>55 else P["success"]
                rows2.append(("Temperature",f"{tv} °C",tc))
            except: pass

        codec_raw=d.get("codec")
        if isinstance(codec_raw,dict):
            cv=codec_raw.get("codec") or codec_raw.get("currentCodec")
            if cv is not None: rows2.append(("Active Codec",fmtv("codec",cv),P["accent"]))
        elif isinstance(codec_raw,int):
            rows2.append(("Active Codec",fmtv("codec",codec_raw),P["accent"]))

        rb_raw=d.get("reboot")
        rb=rb_raw if isinstance(rb_raw,bool) else safe_d(rb_raw).get("rebootNeeded") if isinstance(rb_raw,dict) else None
        if rb is not None:
            rows2.append(("Reboot Required","Yes — please reboot" if rb else "No",P["warn"] if rb else P["success"]))

        if rows2:
            for k,v,c in rows2: self.llay.addWidget(info_row(k,v,c))
        else:
            self.llay.addWidget(ltext("  No live status returned",11,color=P["txt3"]))
        pad_bottom(self.llay)

# ── Sources Tab ───────────────────────────────────────────────────────────────
class SourcesTab(QWidget):
    def __init__(self,client):
        super().__init__(); self.client=client
        root=QVBoxLayout(self); root.setContentsMargins(0,0,0,0)
        self.inner=QWidget()
        self.lay=QVBoxLayout(self.inner)
        self.lay.setContentsMargins(16,16,16,16); self.lay.setSpacing(10)
        self.lay.addStretch()
        root.addWidget(scrollify(self.inner))
        self.refresh()

    def refresh(self):
        self._clr(); self.lay.addWidget(ltext("Loading sources…",12,color=P["txt2"]))
        self._w=Worker(self.client.sources); self._w.result.connect(self._render); self._w.start()

    def _clr(self):
        while self.lay.count():
            it=self.lay.takeAt(0)
            if it.widget(): it.widget().deleteLater()

    def _render(self,raw):
        self._clr()
        src_list=(raw if isinstance(raw,list)
                  else safe_d(raw).get("sources") or safe_d(raw).get("sourceList") or [] if isinstance(raw,dict) else [])
        if not src_list:
            self.lay.addWidget(ltext("No sources found\n(RX only — or none configured)",12,color=P["txt3"],wrap=True))
            self.lay.addStretch(); return

        self.lay.addWidget(ltext(f"{len(src_list)} SOURCE(S)",9,bold=True,color=P["txt3"]))
        for src in src_list:
            if not isinstance(src,dict): continue
            c,cl=card_widget()
            top=QWidget(); top.setStyleSheet("background:transparent;")
            tl=QHBoxLayout(top); tl.setContentsMargins(18,12,18,6); tl.setSpacing(8)
            name=(src.get("name") or src.get("sourceName") or src.get("label")
                  or src.get("id") or src.get("sourceId") or "Unknown Source")
            tl.addWidget(ltext(name,13,bold=True))
            tl.addStretch()
            connected=src.get("connected") or src.get("isConnected")
            if connected is not None:
                tl.addWidget(badge("CONNECTED" if connected else "DISCONNECTED",
                                    P["succ_dim"] if connected else P["bg_row"],
                                    P["succ_lt"]  if connected else P["txt2"]))
            cl.addWidget(top)
            render_dict(cl,src,{"name","sourceName","label","connected","isConnected"})
            pad_bottom(cl)
            self.lay.addWidget(c)
        self.lay.addStretch()

# ── Network Tab ───────────────────────────────────────────────────────────────
class NetworkTab(QWidget):
    def __init__(self,client):
        super().__init__(); self.client=client
        root=QVBoxLayout(self); root.setContentsMargins(0,0,0,0)
        self.inner=QWidget()
        self.lay=QVBoxLayout(self.inner)
        self.lay.setContentsMargins(16,16,16,16); self.lay.setSpacing(10)
        self.lay.addStretch()
        root.addWidget(scrollify(self.inner))
        self.refresh()

    def refresh(self):
        self._clr(); self.lay.addWidget(ltext("Loading network…",12,color=P["txt2"]))
        def fetch():
            d=self.client.network_det()
            if d is None: d=self.client.network()
            return d
        self._w=Worker(fetch); self._w.result.connect(self._render); self._w.start()

    def _clr(self):
        while self.lay.count():
            it=self.lay.takeAt(0)
            if it.widget(): it.widget().deleteLater()

    def _render(self,raw):
        self._clr()
        if raw is None:
            self.lay.addWidget(ltext("Could not retrieve network status",12,color=P["txt3"]))
            self.lay.addStretch(); return
        if isinstance(raw,list):     conns=raw
        elif isinstance(raw,dict):   conns=raw.get("connectors") or raw.get("interfaces") or raw.get("networkConnectors") or [raw]
        else:
            self.lay.addWidget(ltext(str(raw),11,color=P["txt2"],wrap=True)); self.lay.addStretch(); return

        conns=[c for c in conns if isinstance(c,dict)]
        if not conns:
            self.lay.addWidget(ltext("No network interfaces found",12,color=P["txt3"])); self.lay.addStretch(); return

        self.lay.addWidget(ltext(f"{len(conns)} INTERFACE(S)",9,bold=True,color=P["txt3"]))
        for conn in conns:
            title=conn.get("connectorId") or conn.get("id") or conn.get("name") or "Interface"
            c,cl=card_widget(str(title))
            skip={"connectorId","id","name","interfaces","networkInterfaces"}
            render_dict(cl,conn,skip)
            for iface in safe_l(conn.get("interfaces") or conn.get("networkInterfaces",[])):
                if not isinstance(iface,dict): continue
                sub=QFrame(); sub.setProperty("role","sub")
                sl=QVBoxLayout(sub); sl.setContentsMargins(0,8,0,8); sl.setSpacing(2)
                sub_title=iface.get("interfaceId") or iface.get("id") or "Interface"
                sl.addWidget(ltext(f"  {sub_title}",10,bold=True,color=P["txt2"]))
                render_dict(sl,iface,{"interfaceId","id"})
                cl.addWidget(sub)
            pad_bottom(cl)
            self.lay.addWidget(c)
        self.lay.addStretch()

# ── Streams Tab ───────────────────────────────────────────────────────────────
class StreamsTab(QWidget):
    def __init__(self,client):
        super().__init__(); self.client=client
        root=QVBoxLayout(self); root.setContentsMargins(0,0,0,0)
        self.inner=QWidget()
        self.lay=QVBoxLayout(self.inner)
        self.lay.setContentsMargins(16,16,16,16); self.lay.setSpacing(10)
        self.lay.addStretch()
        root.addWidget(scrollify(self.inner))
        self.refresh()

    def refresh(self):
        self._clr(); self.lay.addWidget(ltext("Loading streams…",12,color=P["txt2"]))
        def fetch(): return self.client.video_streams(),self.client.audio_streams(),self.client.usb_streams()
        self._w=Worker(fetch); self._w.result.connect(lambda r: self._render(*r) if r else None); self._w.start()

    def _clr(self):
        while self.lay.count():
            it=self.lay.takeAt(0)
            if it.widget(): it.widget().deleteLater()

    def _render(self,vs,as_,us):
        self._clr()
        for section,streams in [("Video Streams",vs),("Audio Streams",as_),("USB Streams",us)]:
            self.lay.addWidget(ltext(section.upper(),9,bold=True,color=P["txt3"]))
            if not streams:
                self.lay.addWidget(ltext("  No active streams",11,color=P["txt3"])); continue
            for s in streams:
                c,cl=card_widget()
                top=QWidget(); top.setStyleSheet("background:transparent;")
                tl=QHBoxLayout(top); tl.setContentsMargins(18,10,18,4)
                lbl_txt=s.get("streamLabel") or s.get("label") or ""
                conn_st=s.get("streamConnectionStatus","")
                if lbl_txt: tl.addWidget(ltext(lbl_txt,12,bold=True))
                tl.addStretch()
                if conn_st:
                    ok=str(conn_st).lower()=="connected"
                    tl.addWidget(badge(str(conn_st),P["succ_dim"] if ok else P["bg_row"],P["succ_lt"] if ok else P["txt2"]))
                cl.addWidget(top)
                render_dict(cl,s,{"streamLabel","label","streamConnectionStatus"})
                pad_bottom(cl)
                self.lay.addWidget(c)
        self.lay.addStretch()

# ── Users Tab ─────────────────────────────────────────────────────────────────
class UsersTab(QWidget):
    def __init__(self,client):
        super().__init__(); self.client=client
        root=QVBoxLayout(self); root.setContentsMargins(0,0,0,0)
        self.inner=QWidget()
        self.lay=QVBoxLayout(self.inner)
        self.lay.setContentsMargins(16,16,16,16); self.lay.setSpacing(10)
        self.lay.addStretch()
        root.addWidget(scrollify(self.inner))
        self.refresh()

    def refresh(self):
        self._clr()
        def fetch(): return self.client.users(),self.client.session_len()
        self._w=Worker(fetch); self._w.result.connect(lambda r: self._render(*r) if r else None); self._w.start()

    def _clr(self):
        while self.lay.count():
            it=self.lay.takeAt(0)
            if it.widget(): it.widget().deleteLater()

    def _render(self,users_raw,sess_raw):
        self._clr()
        sc,sl=card_widget("Session Length")
        sess=safe_d(sess_raw)
        if sess.get("seconds") is not None:
            sl.addWidget(info_row("Current Length",fmtv("seconds",sess["seconds"])))
        bw=QWidget(); bw.setStyleSheet("background:transparent;")
        bl=QHBoxLayout(bw); bl.setContentsMargins(18,8,18,14); bl.setSpacing(10)
        for lt,secs in [("72 hours",259199),("6 days",518400),("30 days",2592000)]:
            b=btn(lt,"ghost",w=110,h=30)
            b.clicked.connect(lambda _,s=secs: self._set_sess(s))
            bl.addWidget(b)
        bl.addStretch(); sl.addWidget(bw)
        self.lay.addWidget(sc)

        uc,ul=card_widget("Local Users")
        for u in safe_l(users_raw):
            if not isinstance(u,dict): continue
            row=QFrame(); row.setProperty("role","sub")
            rl=QHBoxLayout(row); rl.setContentsMargins(14,10,14,10)
            rl.addWidget(ltext(u.get("username","?"),12,bold=True))
            nm=f"{u.get('firstName','')} {u.get('lastName','')}".strip()
            if nm: rl.addWidget(ltext(nm,11,color=P["txt2"]))
            rl.addStretch()
            rn=u.get("role",2)
            rl.addWidget(badge(ROLES.get(rn,"User"),P["accent_dim"] if rn==1 else P["bg_card"],P["accent"] if rn==1 else P["txt2"]))
            uw=QWidget(); uw.setStyleSheet("background:transparent;")
            uw_l=QVBoxLayout(uw); uw_l.setContentsMargins(18,0,18,0)
            uw_l.addWidget(row)
            ul.addWidget(uw)
        pad_bottom(ul)
        self.lay.addWidget(uc)
        self.lay.addStretch()

    def _set_sess(self,secs):
        status,msg=self.client.set_session(secs)
        if status==204: QMessageBox.information(self,"Success",f"Session length set to {round(secs/3600,1)}h"); self.refresh()
        else: QMessageBox.critical(self,"Error",f"Failed\n{msg}")

# ── Actions Tab ───────────────────────────────────────────────────────────────
class ActionsTab(QWidget):
    def __init__(self,client):
        super().__init__(); self.client=client
        root=QVBoxLayout(self); root.setContentsMargins(0,0,0,0)
        inner=QWidget()
        lay=QVBoxLayout(inner); lay.setContentsMargins(16,16,16,16); lay.setSpacing(10)

        # Ping
        pc,pl=card_widget("Quick Health Check")
        self.ping_lbl=ltext("",12,color=P["txt2"]); self.ping_lbl.setContentsMargins(18,0,18,0)
        pl.addWidget(self.ping_lbl)
        ping_b=btn("Ping Device","ghost",w=140); ping_b.clicked.connect(self._ping)
        pl.addWidget(section_btn_row(ping_b)); lay.addWidget(pc)

        # Reboot
        rc,rl=card_widget("Reboot")
        rl.addWidget(ltext("  Reboots the device. It will be unavailable for ~60 seconds.",11,color=P["txt2"],wrap=True))
        rb=btn("⟳   Reboot Device","warn",w=168); rb.clicked.connect(self._reboot)
        rl.addWidget(section_btn_row(rb)); lay.addWidget(rc)

        # Factory reset
        fc,fl2=card_widget("Configuration Reset")
        fl2.addWidget(ltext("  Resets all configuration to factory defaults. Cannot be undone.",11,color=P["txt2"],wrap=True))
        fb=btn("⚠   Factory Reset","danger",w=180); fb.clicked.connect(self._factory_reset)
        fl2.addWidget(section_btn_row(fb)); lay.addWidget(fc)

        # Audio
        ac,al=card_widget("Audio")
        vw=QWidget(); vw.setStyleSheet("background:transparent;")
        vl=QHBoxLayout(vw); vl.setContentsMargins(18,4,18,4); vl.setSpacing(12)
        vl.addWidget(ltext("Volume",11,color=P["txt2"]))
        self.vol_sl=QSlider(Qt.Orientation.Horizontal); self.vol_sl.setRange(0,100); self.vol_sl.setValue(80); self.vol_sl.setFixedWidth(200)
        self.vol_sl.setStyleSheet(f"""
            QSlider::groove:horizontal{{height:4px;background:{P['border2']};border-radius:2px;}}
            QSlider::handle:horizontal{{background:{P['accent']};width:14px;height:14px;border-radius:7px;margin:-5px 0;}}
            QSlider::sub-page:horizontal{{background:{P['accent']};border-radius:2px;}}""")
        self.vol_lbl=ltext("80",12,bold=True); self.vol_lbl.setFixedWidth(28)
        self.vol_sl.valueChanged.connect(lambda v: self.vol_lbl.setText(str(v)))
        set_b=btn("Set",w=56,h=32); set_b.clicked.connect(self._set_vol)
        vl.addWidget(self.vol_sl); vl.addWidget(self.vol_lbl); vl.addWidget(set_b); vl.addStretch()
        al.addWidget(vw)
        mw=QWidget(); mw.setStyleSheet("background:transparent;")
        ml=QHBoxLayout(mw); ml.setContentsMargins(18,0,18,14); ml.setSpacing(10)
        for t,v in [("🔇  Mute",True),("🔊  Unmute",False)]:
            b=btn(t,"flat",w=110,h=32); b.clicked.connect(lambda _,val=v: self._set_mute(val)); ml.addWidget(b)
        ml.addStretch(); al.addWidget(mw); lay.addWidget(ac)

        lay.addStretch()
        root.addWidget(scrollify(inner))

    def _ping(self):
        self.ping_lbl.setText("Pinging…"); self.ping_lbl.setStyleSheet("color:#8fa8c8;background:transparent;")
        def do(): return self.client.ping_check()
        self._pw=Worker(do)
        def done(r):
            ok,ms=r if r else (False,0)
            if ok:
                self.ping_lbl.setText(f"✓  Device healthy  ({ms} ms)")
                self.ping_lbl.setStyleSheet(f"color:{P['success']};background:transparent;font-weight:700;")
            else:
                self.ping_lbl.setText("✗  Unreachable or unhealthy")
                self.ping_lbl.setStyleSheet(f"color:{P['danger']};background:transparent;font-weight:700;")
        self._pw.result.connect(done); self._pw.start()

    def _reboot(self):
        if QMessageBox.question(self,"Confirm Reboot","Reboot this device?\nIt will be offline ~60 seconds.")==QMessageBox.StandardButton.Yes:
            s,msg=self.client.do_reboot()
            (QMessageBox.information if s in (200,202,204) else QMessageBox.critical)(self,"Reboot",f"{'Sent.' if s in (200,202,204) else f'Failed: HTTP {s}'}\n{msg}")

    def _factory_reset(self):
        if QMessageBox.question(self,"⚠ Confirm Reset","Reset ALL config to factory defaults?\nCannot be undone.")==QMessageBox.StandardButton.Yes:
            s,msg=self.client.do_factory_reset()
            (QMessageBox.information if s in (200,202,204) else QMessageBox.critical)(self,"Reset",f"{'Sent.' if s in (200,202,204) else f'Failed: HTTP {s}'}\n{msg}")

    def _set_vol(self):
        s,msg=self.client.set_volume(self.vol_sl.value())
        if s==204: QMessageBox.information(self,"Volume",f"Volume set to {self.vol_sl.value()}")
        else: QMessageBox.critical(self,"Error",f"Failed\n{msg}")

    def _set_mute(self,muted):
        s,msg=self.client.set_mute(muted)
        if s==204: QMessageBox.information(self,"Audio","Muted" if muted else "Unmuted")
        else: QMessageBox.critical(self,"Error",f"Failed\n{msg}")

# ── NEW: Licenses Tab ─────────────────────────────────────────────────────────
class LicensesTab(QWidget):
    def __init__(self,client):
        super().__init__(); self.client=client
        root=QVBoxLayout(self); root.setContentsMargins(0,0,0,0)
        self.inner=QWidget()
        self.lay=QVBoxLayout(self.inner)
        self.lay.setContentsMargins(16,16,16,16); self.lay.setSpacing(10)
        self.lay.addStretch()
        root.addWidget(scrollify(self.inner))
        self.refresh()

    def refresh(self):
        self._clr(); self.lay.addWidget(ltext("Loading licenses…",12,color=P["txt2"]))
        self._w=Worker(self.client.licenses); self._w.result.connect(self._render); self._w.start()

    def _clr(self):
        while self.lay.count():
            it=self.lay.takeAt(0)
            if it.widget(): it.widget().deleteLater()

    def _render(self,raw):
        self._clr()
        items=raw if isinstance(raw,list) else safe_d(raw).get("licenses") or safe_d(raw).get("items") or [] if isinstance(raw,dict) else []
        if not items:
            self.lay.addWidget(ltext("No license information available",12,color=P["txt3"])); self.lay.addStretch(); return
        self.lay.addWidget(ltext(f"{len(items)} LICENSE(S)",9,bold=True,color=P["txt3"]))
        for item in items:
            if not isinstance(item,dict): continue
            c,cl=card_widget()
            top=QWidget(); top.setStyleSheet("background:transparent;")
            tl=QHBoxLayout(top); tl.setContentsMargins(18,12,18,6)
            name=item.get("licenseType") or item.get("name") or item.get("type") or "License"
            tl.addWidget(ltext(name,13,bold=True)); tl.addStretch()
            installed=item.get("isInstalled") or item.get("installed")
            if installed is not None:
                tl.addWidget(badge("INSTALLED" if installed else "NOT INSTALLED",
                                    P["succ_dim"] if installed else P["dang_dim"],
                                    P["succ_lt"]  if installed else P["danger"]))
            cl.addWidget(top)
            render_dict(cl,item,{"licenseType","name","type","isInstalled","installed"})
            pad_bottom(cl); self.lay.addWidget(c)
        self.lay.addStretch()

# ── NEW: Diagnostics Tab ──────────────────────────────────────────────────────
class DiagnosticsTab(QWidget):
    def __init__(self,client):
        super().__init__(); self.client=client
        root=QVBoxLayout(self); root.setContentsMargins(0,0,0,0)
        self.inner=QWidget()
        self.lay=QVBoxLayout(self.inner)
        self.lay.setContentsMargins(16,16,16,16); self.lay.setSpacing(10)

        # Locate device
        lc,ll=card_widget("Locate Device")
        ll.addWidget(ltext("  Flash the device LEDs to physically identify it on a rack.",11,color=P["txt2"],wrap=True))
        self.locate_status=ltext("",11,color=P["txt2"]); self.locate_status.setContentsMargins(18,0,18,0)
        ll.addWidget(self.locate_status)
        row=QWidget(); row.setStyleSheet("background:transparent;")
        rl=QHBoxLayout(row); rl.setContentsMargins(18,8,18,14); rl.setSpacing(10)
        on_b=btn("🔦  Turn On","success",w=130); on_b.clicked.connect(lambda: self._locate(True))
        off_b=btn("Turn Off","flat",w=110); off_b.clicked.connect(lambda: self._locate(False))
        rl.addWidget(on_b); rl.addWidget(off_b); rl.addStretch()
        ll.addWidget(row); self.lay.addWidget(lc)

        # Video connectors status
        vc,vl=card_widget("Video Connectors")
        self.vid_lay=vl; self.lay.addWidget(vc)

        # Audio connectors
        acc,acl=card_widget("Audio Connectors")
        self.aud_lay=acl; self.lay.addWidget(acc)

        self.lay.addStretch()
        root.addWidget(scrollify(self.inner))
        self.refresh()

    def refresh(self):
        def fetch(): return {
            "locate":self.client.locate_status(),
            "video":self.client.video_connectors(),
            "audio":self.client.audio_connectors(),
        }
        self._w=Worker(fetch); self._w.result.connect(self._render); self._w.start()

    def _render(self,d):
        if not d: return
        loc=safe_d(d.get("locate"))
        enabled=loc.get("enabled") or loc.get("locateDeviceEnabled") or loc.get("isEnabled")
        if enabled is not None:
            self.locate_status.setText(f"  Status: {'● Active — LEDs flashing' if enabled else '● Inactive'}")
            self.locate_status.setStyleSheet(f"color:{P['warn'] if enabled else P['txt2']};background:transparent;")

        def fill(lay,raw,keep=1):
            while lay.count()>keep:
                it=lay.takeAt(keep)
                if it.widget(): it.widget().deleteLater()
            items=raw if isinstance(raw,list) else safe_d(raw).get("connectors") or [] if isinstance(raw,dict) else []
            items=[i for i in items if isinstance(i,dict)]
            if not items:
                lay.addWidget(ltext("  No connectors found",11,color=P["txt3"])); return
            for conn in items:
                cid=conn.get("connectorId") or conn.get("id") or "Connector"
                sub=QFrame(); sub.setProperty("role","sub")
                sl=QVBoxLayout(sub); sl.setContentsMargins(0,8,0,8); sl.setSpacing(2)
                sl.addWidget(ltext(f"  {cid}",11,bold=True,color=P["txt2"]))
                render_dict(sl,conn,{"connectorId","id"})
                cw=QWidget(); cw.setStyleSheet("background:transparent;")
                cwl=QVBoxLayout(cw); cwl.setContentsMargins(18,0,18,8); cwl.addWidget(sub)
                lay.addWidget(cw)
            lay.addSpacing(6)

        fill(self.vid_lay, d.get("video"))
        fill(self.aud_lay, d.get("audio"))

    def _locate(self,on):
        s,msg=self.client.set_locate(on)
        if s in (200,202,204):
            QMessageBox.information(self,"Locate Device",f"Locate LEDs {'activated' if on else 'deactivated'}.")
            self.refresh()
        else:
            QMessageBox.critical(self,"Error",f"Failed\n{msg}")

# ── NEW: Device Settings Tab ──────────────────────────────────────────────────
class DeviceSettingsTab(QWidget):
    def __init__(self,client):
        super().__init__(); self.client=client
        root=QVBoxLayout(self); root.setContentsMargins(0,0,0,0)
        inner=QWidget()
        lay=QVBoxLayout(inner); lay.setContentsMargins(16,16,16,16); lay.setSpacing(10)

        # Rename device
        nc,nl=card_widget("Rename Device")
        nl.addWidget(ltext("  Change the display name of this device.",11,color=P["txt2"]))
        nw=QWidget(); nw.setStyleSheet("background:transparent;")
        nwl=QHBoxLayout(nw); nwl.setContentsMargins(18,8,18,14); nwl.setSpacing(10)
        self.name_field=QLineEdit(); self.name_field.setPlaceholderText("New device name…"); self.name_field.setFixedHeight(38)
        save_b=btn("Save Name",w=110,h=38); save_b.clicked.connect(self._save_name)
        nwl.addWidget(self.name_field,1); nwl.addWidget(save_b)
        nl.addWidget(nw); lay.addWidget(nc)

        # Codec settings
        cc,cl2=card_widget("Video Codec")
        cl2.addWidget(ltext("  Change the video codec used by this device.",11,color=P["txt2"]))
        cw=QWidget(); cw.setStyleSheet("background:transparent;")
        cwl=QHBoxLayout(cw); cwl.setContentsMargins(18,8,18,14); cwl.setSpacing(10)
        self.codec_combo=QComboBox()
        for v,k in CODECS.items(): self.codec_combo.addItem(k,v)
        self.codec_combo.setFixedHeight(38)
        apply_b=btn("Apply Codec",w=120,h=38); apply_b.clicked.connect(self._set_codec)
        cwl.addWidget(self.codec_combo,1); cwl.addWidget(apply_b)
        cl2.addWidget(cw); lay.addWidget(cc)

        # Bitrate info
        bc,bl=card_widget("Bitrate Information")
        self.bitrate_lay=bl; lay.addWidget(bc)

        # NMOS status
        mc,ml=card_widget("NMOS Status")
        self.nmos_lay=ml; lay.addWidget(mc)

        lay.addStretch()
        root.addWidget(scrollify(inner))
        self.refresh()

    def refresh(self):
        def fetch(): return {
            "identity":self.client.identity(),
            "codec_s":self.client.codec_settings(),
            "bitrate_b":self.client.bitrate_bounds(),
            "bitrate_e":self.client.expected_bitrate(),
            "nmos":self.client.nmos_status(),
        }
        self._w=Worker(fetch); self._w.result.connect(self._render); self._w.start()

    def _clr(self,lay,keep=1):
        while lay.count()>keep:
            it=lay.takeAt(keep)
            if it.widget(): it.widget().deleteLater()

    def _render(self,d):
        if not d: return
        ident=safe_d(d.get("identity"))
        if ident.get("name"): self.name_field.setText(ident["name"])

        cs=d.get("codec_s")
        if isinstance(cs,dict):
            cv=cs.get("codec") or cs.get("configuredCodec")
            if cv is not None:
                for i in range(self.codec_combo.count()):
                    if self.codec_combo.itemData(i)==cv:
                        self.codec_combo.setCurrentIndex(i); break

        self._clr(self.bitrate_lay)
        bb=safe_d(d.get("bitrate_b")); be=d.get("bitrate_e")
        if bb:
            if bb.get("minBitrateKbits") is not None:
                self.bitrate_lay.addWidget(info_row("Min Bitrate",fmtv("bitrateKbits",bb["minBitrateKbits"])))
            if bb.get("maxBitrateKbits") is not None:
                self.bitrate_lay.addWidget(info_row("Max Bitrate",fmtv("bitrateKbits",bb["maxBitrateKbits"])))
        if be is not None:
            val=be if not isinstance(be,dict) else safe_d(be).get("bitrateKbits") or safe_d(be).get("expectedBitrateKbits")
            if val: self.bitrate_lay.addWidget(info_row("Expected Bitrate",fmtv("bitrateKbits",val),P["accent"]))
        if self.bitrate_lay.count()==1:
            self.bitrate_lay.addWidget(ltext("  Bitrate info not available",11,color=P["txt3"]))
        pad_bottom(self.bitrate_lay)

        self._clr(self.nmos_lay)
        nmos=safe_d(d.get("nmos"))
        if nmos:
            render_dict(self.nmos_lay,nmos)
        else:
            self.nmos_lay.addWidget(ltext("  NMOS not available or not configured",11,color=P["txt3"]))
        pad_bottom(self.nmos_lay)

    def _save_name(self):
        name=self.name_field.text().strip()
        if not name: QMessageBox.warning(self,"Error","Name cannot be empty"); return
        s,msg=self.client.set_identity(name)
        if s in (200,202,204): QMessageBox.information(self,"Saved",f"Device name set to '{name}'")
        else: QMessageBox.critical(self,"Error",f"Failed\n{msg}")

    def _set_codec(self):
        val=self.codec_combo.currentData()
        s,msg=self.client.set_codec(val)
        if s in (200,202,204): QMessageBox.information(self,"Codec",f"Codec set to {CODECS.get(val,str(val))}")
        else: QMessageBox.critical(self,"Error",f"Failed\n{msg}")

# ── Device Panel ──────────────────────────────────────────────────────────────
class DevicePanel(QWidget):
    def __init__(self,dev):
        super().__init__(); self.dev=dev
        self.client=Avio2Client(dev["ip"],dev["username"],dev["password"])
        self.tabs={}
        root=QVBoxLayout(self); root.setContentsMargins(0,0,0,0); root.setSpacing(0)
        root.addWidget(self._make_header())
        root.addWidget(self._make_div())
        root.addWidget(self._make_tabbar())
        root.addWidget(self._make_div())
        self.stack=QStackedWidget(); root.addWidget(self.stack,1)
        self._switch("Overview")
        self._do_connect()

    def _make_div(self):
        f=QFrame(); f.setProperty("role","divider"); f.setFixedHeight(1); return f

    def _make_header(self):
        hdr=QWidget(); hdr.setStyleSheet(f"background:{P['bg_hdr']};"); hdr.setFixedHeight(60)
        hl=QHBoxLayout(hdr); hl.setContentsMargins(20,0,20,0)
        lft=QWidget(); lft.setStyleSheet("background:transparent;")
        ll=QVBoxLayout(lft); ll.setSpacing(2); ll.setContentsMargins(0,0,0,0)
        ll.addWidget(ltext(self.dev.get("label") or self.dev["ip"],15,bold=True))
        ll.addWidget(ltext(self.dev["ip"],10,color=P["txt3"]))
        hl.addWidget(lft,1)
        rht=QWidget(); rht.setStyleSheet("background:transparent;")
        rl=QHBoxLayout(rht); rl.setSpacing(12); rl.setContentsMargins(0,0,0,0)
        self.conn_lbl=ltext("● Connecting…",11,color=P["txt3"])
        ref=btn("↻  Refresh","ghost",w=90,h=26); ref.clicked.connect(self._refresh)
        rl.addWidget(self.conn_lbl); rl.addWidget(ref)
        hl.addWidget(rht); return hdr

    def _make_tabbar(self):
        bar=QWidget(); bar.setStyleSheet(f"background:{P['bg_side']};"); bar.setFixedHeight(40)
        bl=QHBoxLayout(bar); bl.setContentsMargins(0,0,0,0); bl.setSpacing(0)
        self.tab_btns={}
        TABS=["Overview","Sources","Network","Streams","Users","Actions",
              "Licenses","Diagnostics","Settings"]
        for name in TABS:
            b=QPushButton(name); b.setFixedHeight(40)
            b.setStyleSheet(f"QPushButton{{background:transparent;color:{P['txt2']};border:none;border-radius:0;padding:0 14px;font-size:11px;}}"
                            f"QPushButton:hover{{background:{P['bg_row']};color:{P['txt']};}}")
            b.clicked.connect(lambda _,n=name: self._switch(n))
            bl.addWidget(b); self.tab_btns[name]=b
        bl.addStretch(); return bar

    def _switch(self,name):
        for n,b in self.tab_btns.items():
            if n==name:
                b.setStyleSheet(f"QPushButton{{background:{P['bg_row']};color:{P['accent']};border:none;border-bottom:2px solid {P['accent']};border-radius:0;padding:0 14px;font-size:11px;font-weight:700;}}")
            else:
                b.setStyleSheet(f"QPushButton{{background:transparent;color:{P['txt2']};border:none;border-radius:0;padding:0 14px;font-size:11px;}}QPushButton:hover{{background:{P['bg_row']};color:{P['txt']};}}")
        if name not in self.tabs:
            cls={"Overview":OverviewTab,"Sources":SourcesTab,"Network":NetworkTab,
                 "Streams":StreamsTab,"Users":UsersTab,"Actions":ActionsTab,
                 "Licenses":LicensesTab,"Diagnostics":DiagnosticsTab,
                 "Settings":DeviceSettingsTab}[name]
            t=cls(self.client); self.tabs[name]=t; self.stack.addWidget(t)
        self.stack.setCurrentWidget(self.tabs[name])

    def _refresh(self):
        w=self.stack.currentWidget()
        if hasattr(w,"refresh"): w.refresh()

    def _do_connect(self):
        self._cw=Worker(self.client.login)
        def done(r):
            ok=r[0] if r else False
            if ok:
                self.conn_lbl.setText("● Connected")
                self.conn_lbl.setStyleSheet(f"color:{P['success']};background:transparent;font-weight:700;")
            else:
                msg=r[1] if r else "Failed"
                self.conn_lbl.setText(f"● {msg}")
                self.conn_lbl.setStyleSheet(f"color:{P['danger']};background:transparent;")
        self._cw.result.connect(done); self._cw.start()

# ── Sidebar device button ─────────────────────────────────────────────────────
class DeviceBtn(QWidget):
    sig_click  = pyqtSignal(dict)
    sig_remove = pyqtSignal(dict)

    def __init__(self,dev,active=False):
        super().__init__(); self.dev=dev; self.setFixedHeight(54)
        lay=QHBoxLayout(self); lay.setContentsMargins(8,0,8,0); lay.setSpacing(0)
        inner=QWidget()
        inner.setStyleSheet(f"background:{P['bg_card'] if active else 'transparent'};border-radius:8px;")
        inner.setCursor(Qt.CursorShape.PointingHandCursor)
        il=QVBoxLayout(inner); il.setContentsMargins(14,7,8,7); il.setSpacing(1)
        label_txt=dev.get("label") or dev["ip"]
        il.addWidget(ltext(label_txt,12,bold=True,color=P["accent"] if active else P["txt"]))
        il.addWidget(ltext(dev["ip"],9,color=P["txt3"]))
        inner.mousePressEvent=lambda _: self.sig_click.emit(self.dev)
        xb=QPushButton("×"); xb.setFixedSize(22,22)
        xb.setStyleSheet(f"QPushButton{{background:transparent;color:{P['txt3']};border:none;font-size:14px;border-radius:4px;}}"
                          f"QPushButton:hover{{background:{P['dang_dim']};color:{P['danger']};}}")
        xb.clicked.connect(lambda: self.sig_remove.emit(self.dev))
        lay.addWidget(inner,1); lay.addWidget(xb)

# ── Main Window ───────────────────────────────────────────────────────────────
class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Avio2 Manager  |  Matrox SQA")
        self.resize(1280,780); self.setMinimumSize(1000,640)
        self.setStyleSheet(QSS)
        self.devices=[]; self.active_ip=None
        self.devices=load_devices()
        root=QWidget(); self.setCentralWidget(root)
        hl=QHBoxLayout(root); hl.setSpacing(0); hl.setContentsMargins(0,0,0,0)
        hl.addWidget(self._make_sidebar())
        self.main_stack=QStackedWidget(); hl.addWidget(self.main_stack,1)
        self._render_sidebar(); self._show_welcome()

    def _make_sidebar(self):
        side=QWidget(); side.setFixedWidth(240); side.setStyleSheet(f"background:{P['bg_side']};")
        sl=QVBoxLayout(side); sl.setSpacing(0); sl.setContentsMargins(0,0,0,0)

        logo=QWidget(); logo.setFixedHeight(60)
        logo.setStyleSheet(f"background:qlineargradient(x1:0,y1:0,x2:1,y2:0,stop:0 {P['matrox']},stop:1 #1a4ab8);")
        ll=QHBoxLayout(logo); ll.setContentsMargins(16,0,16,0); ll.setSpacing(10)
        m=QLabel(" M "); m.setStyleSheet("background:#ffffff22;color:#fff;border-radius:6px;font-weight:800;font-size:14px;padding:3px 7px;")
        ll.addWidget(m); ll.addWidget(ltext("Avio2 Manager",13,bold=True,color="#fff")); ll.addStretch()
        sl.addWidget(logo)

        f=QFrame(); f.setProperty("role","divider"); f.setFixedHeight(1); sl.addWidget(f)

        dh=QWidget(); dh.setFixedHeight(38); dh.setStyleSheet("background:transparent;")
        dhl=QHBoxLayout(dh); dhl.setContentsMargins(16,0,10,0)
        dhl.addWidget(ltext("DEVICES",9,bold=True,color=P["txt3"])); dhl.addStretch()
        add=QPushButton("+"); add.setFixedSize(28,28)
        add.setStyleSheet(f"QPushButton{{background:{P['accent']};color:#fff;border:none;border-radius:6px;font-size:17px;font-weight:700;}}"
                           f"QPushButton:hover{{background:{P['accent_h']};}}")
        add.clicked.connect(self._add_device); dhl.addWidget(add)
        sl.addWidget(dh)

        sa=QScrollArea(); sa.setWidgetResizable(True); sa.setFrameShape(QFrame.Shape.NoFrame)
        sa.setHorizontalScrollBarPolicy(Qt.ScrollBarPolicy.ScrollBarAlwaysOff)
        self.dev_list_w=QWidget(); self.dev_list_w.setStyleSheet("background:transparent;")
        self.dev_list_lay=QVBoxLayout(self.dev_list_w)
        self.dev_list_lay.setContentsMargins(6,4,6,4); self.dev_list_lay.setSpacing(2)
        self.dev_list_lay.addStretch()
        sa.setWidget(self.dev_list_w); sl.addWidget(sa,1)
        return side

    def _render_sidebar(self):
        while self.dev_list_lay.count()>1:
            it=self.dev_list_lay.takeAt(0)
            if it.widget(): it.widget().deleteLater()
        if not self.devices:
            l=ltext("No devices.\nClick  +  to add one.",11,color=P["txt3"])
            l.setAlignment(Qt.AlignmentFlag.AlignCenter); l.setContentsMargins(0,24,0,0)
            self.dev_list_lay.insertWidget(0,l); return
        for i,dev in enumerate(self.devices):
            b=DeviceBtn(dev,active=self.active_ip==dev["ip"])
            b.sig_click.connect(self._select); b.sig_remove.connect(self._remove)
            self.dev_list_lay.insertWidget(i,b)

    def _select(self,dev):
        self.active_ip=dev["ip"]; self._render_sidebar()
        while self.main_stack.count()>1:
            w=self.main_stack.widget(1); self.main_stack.removeWidget(w); w.deleteLater()
        p=DevicePanel(dev); self.main_stack.addWidget(p); self.main_stack.setCurrentWidget(p)

    def _show_welcome(self):
        w=QWidget(); w.setStyleSheet(f"background:{P['bg']};")
        lay=QVBoxLayout(w); lay.setAlignment(Qt.AlignmentFlag.AlignCenter)
        ring=QLabel("M"); ring.setFixedSize(72,72)
        ring.setAlignment(Qt.AlignmentFlag.AlignCenter)
        ring.setStyleSheet(f"background:{P['matrox']};border-radius:36px;color:#fff;font-size:30px;font-weight:800;")
        lay.addWidget(ring,alignment=Qt.AlignmentFlag.AlignCenter)
        lay.addSpacing(16)
        lay.addWidget(ltext("Avio2 Manager",24,bold=True),alignment=Qt.AlignmentFlag.AlignCenter)
        lay.addWidget(ltext("Matrox SQA  ·  Local Device Dashboard",11,color=P["txt3"]),alignment=Qt.AlignmentFlag.AlignCenter)
        sep=QFrame(); sep.setFixedSize(300,1); sep.setStyleSheet(f"background:{P['border']};")
        lay.addSpacing(22); lay.addWidget(sep,alignment=Qt.AlignmentFlag.AlignCenter); lay.addSpacing(22)
        lay.addWidget(ltext("Select a device from the sidebar\nor click  +  to add a new one.",12,color=P["txt2"]),
                      alignment=Qt.AlignmentFlag.AlignCenter)
        self.main_stack.addWidget(w); self.main_stack.setCurrentWidget(w)

    def _add_device(self):
        dlg=AddDeviceDialog(self)
        if dlg.exec()==QDialog.DialogCode.Accepted and dlg.result_data:
            cfg=dlg.result_data
            if any(d["ip"]==cfg["ip"] for d in self.devices):
                QMessageBox.warning(self,"Duplicate",f"{cfg['ip']} already in list."); return
            self.devices.append(cfg); save_devices(self.devices)
            self._render_sidebar(); self._select(cfg)

    def _remove(self,dev):
        if QMessageBox.question(self,"Remove",f"Remove {dev.get('label') or dev['ip']}?")==QMessageBox.StandardButton.Yes:
            self.devices=[d for d in self.devices if d["ip"]!=dev["ip"]]
            save_devices(self.devices)
            if self.active_ip==dev["ip"]: self.active_ip=None; self._show_welcome()
            self._render_sidebar()

if __name__=="__main__":
    app=QApplication(sys.argv); app.setStyle("Fusion")
    win=MainWindow(); win.show(); sys.exit(app.exec())
