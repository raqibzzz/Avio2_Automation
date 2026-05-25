# Robot-Tests Folder — Merge Context

## What This Folder Is

This `robot-tests` folder was created by merging two separate robot-tests folders from two different computers:

- **`robot-tests - DELL NODE`** — from a Dell machine
- **`robot-tests - DESKTOP NODE`** — from a Desktop machine

The merge was performed on **April 23, 2026** using Claude (Cowork mode).

---

## What Was Done

### Goal
Combine all files from both folders into a single `robot-tests` folder with nothing deleted and no files from either source lost.

### Merge Decisions

#### 1. Unique `.robot` test files — both kept
The two computers had different naming conventions for their test files:

- **DELL NODE** used flat names: `ValidLogin.robot`, `EmptyCredentials.robot`, `TabNavigation.robot`, etc.
- **DESKTOP NODE** used numbered prefixes: `Login001_ValidLogin.robot`, `Login002_TabNavigation.robot`, etc., and also had a full set of Shortcuts tests (`Shortcut001` through `Shortcut009`, plus `Shortcuts.robot`)

Since the filenames didn't conflict, all test files from both computers are present at the root level.

#### 2. `Resource/keywords.robot` and `Resource/variables.robot` — DESKTOP NODE version used
Both folders had a `Resource/` subfolder with `keywords.robot` and `variables.robot`. These files were **different**:

- The DESKTOP NODE versions were a **strict superset** of the DELL NODE versions — they contained all the original login-related keywords/variables, plus additional shortcuts-related keywords and variables added later.
- Decision: **DESKTOP NODE's versions were used**, as they contain everything from both.

If you need to check what was in DELL NODE's version, the key difference is that DESKTOP NODE added:
- In `keywords.robot`: `Open Browser And Login`, `Open Shortcuts Panel`, `Open OSD Menu`, `Open Menu For Item`, `Go To Dashboard`, `Set OSD Shortcut`, `Check Key Conflict`, `Set Valid Shortcut And Save`, `Is Shortcuts Available`
- In `variables.robot`: All login-related variables (USERNAME_FIELD, PASSWORD_FIELD, etc.) and all shortcuts-related variables (SHORTCUTS_CARD, OSD_MENU_BTN, EDIT_OPTION, KEY_INPUT, OK_BUTTON, etc.)

#### 3. `tests_v1/` — identical, included once
Both folders had an identical `tests_v1/` subfolder with older versions of the login tests. One copy was included.

#### 4. `results/` folder — both preserved in subfolders
Both folders had a `results/` directory with test run outputs (log.html, output.xml, report.html, playwright-log.txt), but the contents were from different test runs and conflicted at the same paths.

To preserve both without overwriting:
- DELL NODE results → `results/dell-node/`
- DESKTOP NODE results → `results/desktop-node/`

Note: The original `results/final/` and `results/loop_1/` entries at the top of `results/` are leftover copies from the DELL NODE that couldn't be cleaned up during the merge — the canonical copies are in `results/dell-node/`.

#### 5. DELL NODE-only files — included
These files existed only on the DELL NODE and were brought in:
- `CLAUDE.md`
- `README.md`
- `ChangeBitrateLevel.robot`
- `RebootDevice.robot`
- `RebootDeviceWebUI.robot`
- `avio2_manager.py`
- `devices.json`
- `hdmi_gen_test.py`

#### 6. `.venv` and `.git` — not included
Both source folders contained a `.venv` (Python virtual environment) and `.git` (git history). These were intentionally excluded from the merge because:
- `.venv` is machine-specific and must be recreated on the target machine
- `.git` histories from two separate repos cannot be trivially merged
- Both are very large and would bloat the folder unnecessarily

To set up the virtual environment on a new machine, refer to `README.md` or the setup guides (`Avio2_Robot_Framework_Setup_Guide.docx`) in the parent Downloads folder.

---

## Final Folder Structure (source files only)

```
robot-tests/
├── Resource/
│   ├── keywords.robot         # DESKTOP NODE version (superset)
│   └── variables.robot        # DESKTOP NODE version (superset)
├── tests_v1/                  # Older test versions (identical in both sources)
│   ├── connect-disconnect.robot
│   ├── EmptyCredentials.robot
│   ├── EmptyPassword.robot
│   ├── EmptyUsername.robot
│   ├── EnterKeyAsSignIn.robot
│   ├── InvalidPassword.robot
│   ├── InvalidUsername.robot
│   ├── LoginSameUserTwoSessions.robot
│   ├── login_test.robot
│   ├── TabNavigation.robot
│   └── ValidLogin.robot
├── results/
│   ├── dell-node/             # Test run results from DELL NODE
│   └── desktop-node/          # Test run results from DESKTOP NODE
│
│ — From DELL NODE —
├── ChangeBitrateLevel.robot
├── EmptyCredentials.robot
├── EmptyPassword.robot
├── EmptyUsername.robot
├── EnterKeyAsSignIn.robot
├── InvalidPassword.robot
├── InvalidUsername.robot
├── LoginSameUserTwoSessions.robot
├── RebootDevice.robot
├── RebootDeviceWebUI.robot
├── TabNavigation.robot
├── ValidLogin.robot
├── avio2_manager.py
├── connect-disconnect.robot
├── devices.json
├── hdmi_gen_test.py
├── login_test.robot
│
│ — From DESKTOP NODE —
├── Login001_ValidLogin.robot
├── Login002_TabNavigation.robot
├── Login003_LoginSameUserTwoSessions.robot
├── Login004_InvalidUsername.robot
├── Login005_InvalidPassword.robot
├── Login006_EnterKeyAsSignIn.robot
├── Login007_EmptyUsername.robot
├── Login008_EmptyPassword.robot
├── Login009_EmptyCredentials.robot
├── Shortcuts.robot
├── Shortcut001_OSDResetToScrollLockAndSave.robot
├── Shortcut002_OSDResetToScrollLockAndCancel.robot
├── Shortcut003_OSDEditShortcutWithInvalidKey-SaveDisabled.robot
├── Shortcut004_OSDEditShortcutWithValidKeyAndSave.robot
├── Shortcut005_OSDEditShortcutAndCancel.robot
├── Shortcut006_DeviceShortcutsEditWithAltKeysAndSave.robot
├── Shortcut007_DeviceShortcutsEditAndCancel.robot
├── Shortcut008_DeviceShortcutsResetAndSave.robot
├── Shortcut009_DeviceShortcutResetAndCancel.robot
│
│ — Docs (from DELL NODE) —
├── CLAUDE.md
├── README.md
└── MERGE_CONTEXT.md           # This file
```

---

---

## Setting Up on a New Machine

### Python Virtual Environment (`.venv`)

The `.venv` is machine-specific and not included in this folder. You need to create it fresh on each machine. The venv from the DELL NODE used the following packages (with exact versions known to work):

**Step 1 — Create the venv**
```
cd C:\Users\<yourname>\robot-tests
python -m venv .venv
```

**Step 2 — Activate it**
```
.venv\Scripts\activate
```

**Step 3 — Install all dependencies**
```
pip install robotframework==7.4.2
pip install robotframework-browser==19.12.7
pip install robotframework-requests==0.9.7
pip install grpcio==1.78.0
pip install grpcio-tools==1.78.0
pip install requests==2.33.1
pip install customtkinter==5.2.2
pip install psutil==7.2.2
pip install pyyaml==6.0.3
pip install natsort==8.4.0
pip install pyserial==3.5
pip install overrides==7.7.0
pip install protobuf==6.33.5
pip install colorama==0.4.6
pip install wrapt==2.1.2
```

Or install all at once by saving the above to a `requirements.txt` (one `package==version` per line) and running:
```
pip install -r requirements.txt
```

**Step 4 — Initialize the Browser (Playwright) library**

After installing `robotframework-browser`, you must run this once to download the Playwright browser binaries:
```
rfbrowser init
```

This downloads Chromium, Firefox, and WebKit. It requires an internet connection and can take a few minutes.

**Step 5 — Verify the setup**
```
python -m robot --version
```
Should output something like `Robot Framework 7.4.2 (Python 3.x.x ...)`.

---

### Git Setup

The `.git` folder is also not included. To set up version control on the merged folder:

**Option A — Initialize a fresh repo (recommended for the merged folder)**
```
cd C:\Users\<yourname>\robot-tests
git init
git add .
git commit -m "Initial commit — merged from DELL NODE and DESKTOP NODE"
```

If you have a remote (e.g. GitHub/GitLab), add it and push:
```
git remote add origin <your-remote-url>
git push -u origin main
```

**Option B — Clone from an existing remote**

If the project was already pushed to a remote repo from either machine:
```
git clone <your-remote-url> robot-tests
cd robot-tests
```
Then set up the venv inside it as described above.

**Recommended `.gitignore`**

Create a `.gitignore` file in the `robot-tests/` folder to avoid committing the venv, results, and cache files:
```
# Virtual environment
.venv/

# Robot Framework output files
output.xml
log.html
report.html
playwright-log.txt
results/

# Python cache
__pycache__/
*.pyc
*.pyd

# Browser library logs
Browser/rfbrowser.log
```

---

## Original Source Folders

The two original source folders still exist in the same Downloads directory:
- `robot-tests - DELL NODE/`
- `robot-tests - DESKTOP NODE/`

They have not been modified or deleted. You can delete them once you've confirmed the merged `robot-tests/` folder has everything you need.
