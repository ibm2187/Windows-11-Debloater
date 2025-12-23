# Windows 11 Debloat Script

Remove bloatware, disable telemetry, and optimize privacy on Windows 11.

## Quick Start

```powershell
# Run PowerShell as Administrator, then:
.\Win11Debloat.ps1
```

| Flag | Description |
|------|-------------|
| `-DryRun` | Preview changes without applying |
| `-Silent` | Run with defaults, no prompts |
| `-SkipRestorePoint` | Skip restore point creation |

## Requirements

- Windows 11 (Build 22000+)
- PowerShell 5.1+
- **Run as Administrator**

## What It Does

| Category | Action |
|----------|--------|
| [Apps](#apps-removed) | Removes 60+ bloatware apps |
| [Services](#services-disabled) | Disables telemetry & tracking services |
| [Privacy](#privacy-settings) | Blocks data collection & ads |
| [Features](#features-disabled) | Disables Copilot, Widgets, Recall |

## Safety Features

- Creates system restore point before changes
- Backs up registry to `backups/` folder
- Generates `Revert-Debloat.ps1` to undo changes
- Logs all actions to `logs/` folder

---

## Apps Removed

<details>
<summary><strong>Microsoft Apps (35+)</strong></summary>

| App | App |
|-----|-----|
| Cortana | Bing News/Weather/Finance/Sports |
| Microsoft Copilot | Get Help / Tips |
| Office Hub | Solitaire Collection |
| Mixed Reality Portal | Skype |
| Microsoft Pay | Feedback Hub |
| Windows Maps | Phone Link |
| Groove Music | Movies & TV |
| Clipchamp | Power Automate |
| Mail and Calendar | Microsoft Teams |
| New Outlook | Dev Home |
| Microsoft To Do | Alarms & Clock |
| Voice Recorder | 3D Viewer / Print 3D |
| AI Experience (24H2) | Copilot System (24H2) |

</details>

<details>
<summary><strong>Third-Party Bloatware (27)</strong></summary>

| App | App |
|-----|-----|
| Spotify | Disney+ |
| Netflix | Prime Video |
| Candy Crush (all) | Farm Heroes Saga |
| Instagram | Facebook |
| TikTok | McAfee Security |
| LinkedIn | Duolingo |
| Plex | NordVPN |
| Adobe Photoshop Express | WinZip |
| PicsArt | Drawboard PDF |

</details>

<details>
<summary><strong>Preserved Apps (Never Removed)</strong></summary>

- Windows Store, Calculator, Photos, Notepad
- Camera, Paint, Snipping Tool, Terminal
- **All Xbox apps** (gaming compatibility)

</details>

---

## Services Disabled

<details>
<summary><strong>Telemetry Services</strong></summary>

| Service | Description |
|---------|-------------|
| DiagTrack | Connected User Experiences and Telemetry |
| dmwappushservice | WAP Push Message Routing |
| diagnosticshub.standardcollector.service | Diagnostic Data Collection |
| InventorySvc | Hardware/Software Inventory |

</details>

<details>
<summary><strong>Privacy Services</strong></summary>

| Service | Description |
|---------|-------------|
| WerSvc | Windows Error Reporting |
| lfsvc | Geolocation Service |
| MapsBroker | Downloaded Maps Manager |
| DPS | Diagnostic Policy Service |

</details>

<details>
<summary><strong>AI Services</strong></summary>

| Service | Description |
|---------|-------------|
| WSService | Windows AI Fabric Service |
| WpcMonSvc | Parental Controls (AI-linked) |

</details>

<details>
<summary><strong>Optional Services</strong></summary>

Disabled only if you choose:
- Print Spooler, Fax (if no printer)
- Remote Registry, UPnP (security)
- Bluetooth services (if not used)
- Windows Search, Superfetch

</details>

---

## Privacy Settings

| Setting | What It Disables |
|---------|------------------|
| Telemetry | Diagnostic data collection |
| Advertising ID | Ad tracking across apps |
| Activity History | Timeline & cloud sync |
| Location | System-wide location access |
| Web Search | Bing in Start menu |
| Cortana | Voice assistant |
| Error Reporting | Crash reports to Microsoft |
| App Tracking | Launch/document tracking |

---

## Features Disabled

| Feature | Description |
|---------|-------------|
| Widgets | Taskbar widgets panel |
| Copilot | Windows AI assistant |
| Chat Icon | Teams chat in taskbar |
| News Feed | News and interests |
| Recall | Windows Recall (24H2) |
| Lock Screen Ads | Spotlight advertisements |
| Start Suggestions | App suggestions in Start |

---

## Reverting Changes

```powershell
.\backups\Revert-Debloat.ps1
```

For removed apps, reinstall from the Microsoft Store.

---

## Project Structure

```
├── Win11Debloat.ps1       # Main script
├── modules/               # PowerShell modules
├── config/                # App configuration
├── backups/               # Registry backups & revert script
└── logs/                  # Execution logs
```

---

**Version:** 1.4.0 | **License:** Use at your own risk
