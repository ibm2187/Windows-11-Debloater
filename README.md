# Windows 11 Debloat Script

A comprehensive, modular PowerShell script to debloat Windows 11 by removing bloatware apps, disabling telemetry, and optimizing privacy settings.

## Features

- Remove pre-installed Microsoft and third-party bloatware
- Disable telemetry and data collection
- Disable Windows features like Copilot, Widgets, and Recall
- Manage unnecessary Windows services
- Interactive menu or silent mode
- Dry-run mode to preview changes
- Automatic system restore point creation
- Registry backup before changes
- Auto-generated revert script to undo changes

## Requirements

- Windows 11 (Build 22000 or later)
- PowerShell 5.1 or later
- **Administrator privileges required**

## Usage

> **Important:** You must run PowerShell or Windows Terminal **as Administrator**. Right-click on the terminal and select "Run as administrator" before executing the script.

### Interactive Mode (Recommended)

```powershell
# Run in an Administrator terminal
.\Win11Debloat.ps1
```

This opens an interactive menu with the following options:

| Option | Description |
|--------|-------------|
| **1** | Quick Debloat - Apply recommended defaults |
| **2** | Remove Bloatware Apps - Choose which apps to remove |
| **3** | Disable Telemetry & Privacy Settings |
| **4** | Disable Unnecessary Services |
| **5** | Full Debloat - Apply all options |
| **C** | Custom Debloat - Pick and choose individual options |
| **6** | View Installed Bloatware |
| **7** | View Service Status |
| **8** | Generate Revert Script |

### Dry Run Mode

Preview all changes without applying them:

```powershell
.\Win11Debloat.ps1 -DryRun
```

### Silent Mode

Run with default settings without prompts:

```powershell
.\Win11Debloat.ps1 -Silent
```

### Skip Restore Point

Skip creating a system restore point (not recommended):

```powershell
.\Win11Debloat.ps1 -SkipRestorePoint
```

---

## What Gets Disabled/Removed

### Microsoft Apps Removed

| App | Package Name |
|-----|--------------|
| Cortana | Microsoft.549981C3F5F10 |
| Bing News | Microsoft.BingNews |
| Bing Weather | Microsoft.BingWeather |
| Bing Finance | Microsoft.BingFinance |
| Bing Sports | Microsoft.BingSports |
| Bing Translator | Microsoft.BingTranslator |
| Bing Search | Microsoft.BingSearch |
| Microsoft Copilot | Microsoft.Copilot |
| Get Help | Microsoft.GetHelp |
| Tips | Microsoft.Getstarted |
| 3D Viewer | Microsoft.Microsoft3DViewer |
| Office Hub | Microsoft.MicrosoftOfficeHub |
| Solitaire Collection | Microsoft.MicrosoftSolitaireCollection |
| Mixed Reality Portal | Microsoft.MixedReality.Portal |
| Paid WiFi & Cellular | Microsoft.OneConnect |
| People | Microsoft.People |
| Print 3D | Microsoft.Print3D |
| Skype | Microsoft.SkypeApp |
| Microsoft Pay | Microsoft.Wallet |
| Feedback Hub | Microsoft.WindowsFeedbackHub |
| Windows Maps | Microsoft.WindowsMaps |
| Phone Link | Microsoft.YourPhone |
| Groove Music | Microsoft.ZuneMusic |
| Movies & TV | Microsoft.ZuneVideo |
| Clipchamp | Clipchamp.Clipchamp |
| Power Automate | Microsoft.PowerAutomateDesktop |
| Quick Assist | MicrosoftCorporationII.QuickAssist |
| Mail and Calendar | Microsoft.WindowsCommunicationsApps |
| Microsoft Teams | MicrosoftTeams / MSTeams |
| New Outlook | Microsoft.OutlookForWindows |
| Dev Home | Microsoft.DevHome |
| Microsoft To Do | Microsoft.Todos |
| Alarms & Clock | Microsoft.WindowsAlarms |
| Voice Recorder | Microsoft.WindowsSoundRecorder |
| AI Experience (24H2) | MicrosoftWindows.Client.AIX |
| Copilot System (24H2) | Microsoft.Windows.Ai.Copilot |

### Third-Party Bloatware Removed

| App | Package Name |
|-----|--------------|
| Spotify | SpotifyAB.SpotifyMusic |
| Disney+ | Disney.37853FC22B2CE |
| Prime Video | AmazonVideo.PrimeVideo |
| Netflix | 4DF9E0F8.Netflix |
| Bubble Witch 3 Saga | king.com.BubbleWitch3Saga |
| Candy Crush Saga | king.com.CandyCrushSaga |
| Candy Crush Soda Saga | king.com.CandyCrushSodaSaga |
| Candy Crush Friends | king.com.CandyCrushFriends |
| Farm Heroes Saga | king.com.FarmHeroesSaga |
| Instagram | Facebook.Instagram |
| Facebook | Facebook.Facebook |
| TikTok | ByteDancePte.Ltd.TikTok |
| McAfee Security | 5A894077.McAfeeSecurity |
| Plex | CAF9E577.Plex |
| NordVPN | NORDVPN.NORDVPN |
| Disney Magic Kingdoms | A278AB0D.DisneyMagicKingdoms |
| March of Empires | A278AB0D.MarchofEmpires |
| FarmVille 2 | Zynga.FarmVille2CountryEscape |
| Asphalt 8 | GAMELOFTSA.Asphalt8Airborne |
| Royal Revolt 2 | flaregamesGmbH.RoyalRevolt2 |
| Caesars Slots | Playtika.CaesarsSlotsFreeCasino |
| Duolingo | D5EA27B7.Duolingo-LearnLanguagesforFree |
| Adobe Photoshop Express | AdobeSystemsIncorporated.AdobePhotoshopExpress |
| WinZip | WinZipComputing.WinZipUniversal |
| PicsArt | 2FE3CB00.PicsArt-PhotoStudio |
| LinkedIn | 7EE7776C.LinkedInforWindows |
| Drawboard PDF | Drawboard.DrawboardPDF |

### Apps Preserved (Whitelist)

The following apps are **never removed** to ensure system stability:

- Windows Store
- Windows Terminal
- Calculator
- Photos
- Notepad
- Snipping Tool (Screen Sketch)
- Camera
- Paint
- **All Xbox apps** (for gaming compatibility)

---

### Windows Services Disabled

#### Telemetry Services

| Service | Display Name | Description |
|---------|--------------|-------------|
| DiagTrack | Connected User Experiences and Telemetry | Primary telemetry service |
| dmwappushservice | Device Management WAP Push | WAP push message routing |
| diagnosticshub.standardcollector.service | Diagnostics Hub Standard Collector | Diagnostic data collection |
| InventorySvc | Inventory and Compatibility Appraisal | Hardware/software inventory |
| whesvc | Windows Health and Optimized Experiences | Telemetry suggestions |

#### Privacy Services

| Service | Display Name | Description |
|---------|--------------|-------------|
| WerSvc | Windows Error Reporting | Error reporting to Microsoft |
| lfsvc | Geolocation Service | Location tracking |
| MapsBroker | Downloaded Maps Manager | Offline maps service |
| DPS | Diagnostic Policy Service | Problem detection |
| WdiSystemHost | Diagnostic System Host | Diagnostic host service |

#### AI Services

| Service | Display Name | Description |
|---------|--------------|-------------|
| WSService | Windows AI Fabric Service | Windows AI infrastructure |
| WpcMonSvc | Parental Controls (AI-linked) | Family safety AI features |

#### Optional Services (User Choice)

| Service | Display Name | Description |
|---------|--------------|-------------|
| WSearch | Windows Search | File indexing |
| SysMain | Superfetch/SysMain | Prefetch optimization |
| TabletInputService | Touch Keyboard and Handwriting | Touch/pen input |
| wisvc | Windows Insider Service | Insider program |
| RetailDemo | Retail Demo Service | Store demo mode |
| WMPNetworkSvc | Windows Media Player Network Sharing | Media sharing |
| PhoneSvc | Phone Service | Phone Link related |

#### Print/Fax Services (Optional)

| Service | Display Name | Description |
|---------|--------------|-------------|
| Spooler | Print Spooler | Print queue management |
| Fax | Windows Fax | Fax service |
| PrintNotify | Printer Extensions and Notifications | Printer notifications |

#### Network Services (Optional)

| Service | Display Name | Description |
|---------|--------------|-------------|
| RemoteRegistry | Remote Registry | Remote registry editing |
| SharedAccess | Internet Connection Sharing | ICS/Mobile hotspot |
| lmhosts | TCP/IP NetBIOS Helper | NetBIOS resolution |
| SSDPSRV | SSDP Discovery | UPnP device discovery |
| upnphost | UPnP Device Host | UPnP host service |
| NetTcpPortSharing | Net.Tcp Port Sharing | WCF port sharing |

#### Bluetooth/Mobile Services (Optional)

| Service | Display Name | Description |
|---------|--------------|-------------|
| BTAGService | Bluetooth Audio Gateway | Bluetooth audio routing |
| bthserv | Bluetooth Support Service | Core Bluetooth |
| BthAvctpSvc | AVCTP service | Bluetooth A/V control |
| icssvc | Windows Mobile Hotspot | Mobile hotspot service |

---

### Telemetry & Privacy Settings Disabled

#### Data Collection
- Diagnostic data collection (AllowTelemetry = 0)
- Device name in telemetry
- Feedback notifications
- Diagnostic log collection
- OneSettings downloads

#### Advertising & Tracking
- Advertising ID (system-wide and per-user)
- Suggested content in Settings
- Windows tips and suggestions
- Silent app installation
- Content delivery
- OEM and pre-installed apps auto-install

#### Activity History
- Activity feed
- Publishing user activities
- Uploading user activities to cloud

#### Location
- Location services
- Windows location provider
- Location scripting

#### Search & Cortana
- Web search in Start menu
- Bing search integration
- Search box suggestions
- Cortana
- Cortana above lock screen
- Search location access

#### Error Reporting
- Windows Error Reporting
- Additional error data sending

#### App Tracking
- App launch tracking for Start menu
- Recent documents tracking
- Personalization data collection
- Implicit text/ink collection
- Contact harvesting

---

### Windows Features Disabled

| Feature | Description |
|---------|-------------|
| **Widgets** | Removes Widgets from taskbar |
| **Copilot** | Disables Windows Copilot completely |
| **Chat Icon** | Removes Teams chat from taskbar |
| **News Feed** | Removes news/interests from taskbar |
| **Recall** | Disables Windows Recall (24H2) |
| **Lock Screen Ads** | Removes Spotlight ads from lock screen |
| **Start Suggestions** | Removes app suggestions from Start menu |

### Optional UI/UX Tweaks

| Feature | Description |
|---------|-------------|
| Disable Animations | Faster but less visually appealing |
| Disable Transparency | Reduces GPU usage |
| Classic Context Menu | Windows 10 style right-click menu |

### Performance Tweaks

| Feature | Description |
|---------|-------------|
| Disable Background Apps | Stops apps from running in background |
| Disable Startup Delay | Faster boot time |
| Disable Game DVR | Xbox game recording (optional) |

---

## Safety Features

### Before Running

1. **System Restore Point** - Automatically created before any changes
2. **Registry Backup** - Key registry hives are exported to `backups/` folder
3. **Dry Run Mode** - Preview all changes without applying them

### After Running

1. **Revert Script** - Auto-generated `Revert-Debloat.ps1` in `backups/` folder
2. **Log Files** - Detailed logs saved to `logs/` folder
3. **Summary Report** - Shows all changes made

### Reverting Changes

To undo all changes:

```powershell
.\backups\Revert-Debloat.ps1
```

For removed apps, reinstall them from the Microsoft Store.

---

## Project Structure

```
Win11Debloat/
├── Win11Debloat.ps1          # Main script
├── config/
│   └── apps-bloatware.json   # App configuration
├── modules/
│   ├── AppRemoval.psm1       # App removal functions
│   ├── SafetyHelpers.psm1    # Backup/restore functions
│   ├── ServiceManager.psm1   # Service management
│   └── TelemetryControl.psm1 # Privacy/telemetry settings
├── backups/                  # Registry backups & revert script
└── logs/                     # Execution logs
```

---

## Notes

- **Xbox apps and services are preserved** for gaming compatibility
- A system restart is recommended after running the script
- Some changes may require signing out and back in to take effect
- The script only works on Windows 11 (Build 22000+)

## License

This project is provided as-is for personal use. Use at your own risk.

## Version

Current version: **1.4.0**
