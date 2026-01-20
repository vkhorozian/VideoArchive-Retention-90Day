# Video Archive 90-Day Retention Script

This PowerShell script enforces a **90-day retention policy** on video archive folders stored on a Windows server.
It is designed for **camera / VMS environments** where footage is written into dated subfolders and older data must be reviewed or archived without disrupting live recording.

The script is **drive-aware**, **safe for production**, and includes **logging, test mode, progress output, and rollback support**.

---

## 🔍 What This Script Does

For a given drive (one drive per run):

1. Scans a video archive directory:

   ```
   X:\VideoArchives\Archiver-01
   ```
2. Enumerates each camera folder
3. Evaluates **date folders one level deep**
4. Moves folders **older than 90 days** (based on `LastWriteTime`) to:

   ```
   X:\VideoArchives\Archiver-01-Review90
   ```
5. Creates matching camera folders in the review location
6. Logs every action
7. Reports **disk space reclaimed**
8. Supports **test (WhatIf) mode** and **live mode**

⚠️ No files are deleted. Data is only moved.

---

## 📁 Expected Folder Structure

```
X:\VideoArchives
│
├── Archiver-01
│   ├── Camera-A
│   │   ├── 2024-06-01
│   │   └── 2024-12-01
│   │
│   └── Camera-B
│
├── Archiver-01-Review90
│   └── Camera-A
│       └── 2024-06-01
│
└── Logs
```

---

## 🧠 How Folder Age Is Determined

Folder age is calculated using:

```
Folder.LastWriteTime
```

If the `LastWriteTime` is **older than 90 days**, the folder is moved.

> ⚠️ Some VMS platforms may update timestamps during maintenance or indexing.
> Test mode is strongly recommended before live runs.

---

## 🧪 Test Mode vs Live Mode

### Test Mode (Safe – No Changes)

```powershell
$WhatIfMode = $true
```

* Nothing is moved
* All actions are logged
* Console output shows what *would* happen

### Live Mode (Moves Data)

```powershell
$WhatIfMode = $false
```

* Folders older than 90 days are moved
* Same logic as test mode
* Full audit log generated

---

## ▶️ How to Run

1. Copy `Run-Review90.ps1` into:

   ```
   X:\VideoArchives
   ```
2. Open PowerShell (Administrator recommended)
3. Run:

   ```powershell
   cd X:\VideoArchives
   .\Run-Review90.ps1
   ```

Run **one drive at a time** (D:, E:, F:, etc.).

---

## 📄 Logging

Logs are written to:

```
X:\VideoArchives\Logs
```

Example log name:

```
Archiver-01_Review90_Drive-D_2026-01-19.log
```

Logs include:

* Test vs Live mode
* Folders evaluated
* Folders moved
* Folders skipped
* Errors (if any)
* Disk space reclaimed

---

## 📊 Disk Space Reporting

At the end of each run, the script reports:

* Total folders moved
* Total data moved (GB)
* Estimated disk space reclaimed

This is visible:

* In the console
* In the log file

---

## 🔁 Rollback Support

A separate rollback script is provided:

```
Rollback-Review90.ps1
```

Rollback:

* Moves folders back from `Archiver-01-Review90` to `Archiver-01`
* Supports test mode
* Will not overwrite existing folders

⚠️ Rollback assumes folder names were not modified after the move.

---

## 🔐 Safety Features

* Drive-aware path detection
* One-level folder traversal only
* Sequential (one-at-a-time) moves
* No deletes
* No parallel execution
* Progress bar and live console output
* Full audit logging

---

## 🛠️ Requirements

* Windows Server or Windows 10+
* PowerShell 5.1+
* NTFS file system
* Permissions to move folders

---

## 🚀 Future Enhancements (Ideas)

* Folder-name-based date parsing
* CSV or email summary reports
* Scheduled Task deployment
* Multi-retention support (30/60/120 days)
* Disk I/O throttling

---

## ⚠️ Disclaimer

Always run in **TEST mode first** on production systems.

You are responsible for validating retention policies and client requirements before live execution.

---

## 📄 License

MIT License (recommended)
