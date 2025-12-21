#Requires -RunAsAdministrator
#Requires -Version 5.1
<#
.SYNOPSIS
    Windows 11 Debloat Script - Remove bloatware, disable telemetry, optimize privacy
.DESCRIPTION
    A comprehensive, modular script to debloat Windows 11 with safety features including
    restore points, dry-run mode, logging, and revert capabilities.
.PARAMETER DryRun
    Preview changes without applying them
.PARAMETER Silent
    Run silently with default settings (no user prompts)
.PARAMETER SkipRestorePoint
    Skip creating a system restore point (not recommended)
.EXAMPLE
    .\Win11Debloat.ps1
    .\Win11Debloat.ps1 -DryRun
    .\Win11Debloat.ps1 -Silent
.NOTES
    Author: Windows 11 Debloat Script
    Version: 1.0.0
    Xbox services and apps are kept for gaming compatibility.
#>

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Silent,
    [switch]$SkipRestorePoint
)

# Script configuration
$Script:Version = "1.2.0"
$Script:MinWindowsBuild = 22000  # Windows 11 minimum

# Custom Mode options with safe defaults
$Script:CustomOptions = [ordered]@{
    # APPS
    "RemoveMicrosoftApps"    = @{ Enabled = $true;  Name = "Remove Microsoft bloatware"; Category = "Apps"; Description = "Cortana, Bing, Tips, Solitaire, etc." }
    "RemoveThirdPartyApps"   = @{ Enabled = $true;  Name = "Remove third-party bloatware"; Category = "Apps"; Description = "Candy Crush, Spotify, Disney+, etc." }

    # WINDOWS FEATURES
    "DisableWidgets"         = @{ Enabled = $true;  Name = "Disable Widgets"; Category = "Features"; Description = "Remove Widgets from taskbar" }
    "DisableCopilot"         = @{ Enabled = $true;  Name = "Disable Copilot"; Category = "Features"; Description = "Remove Copilot from Windows" }
    "DisableChatIcon"        = @{ Enabled = $true;  Name = "Disable Chat icon"; Category = "Features"; Description = "Remove Teams chat from taskbar" }
    "DisableNewsFeed"        = @{ Enabled = $true;  Name = "Disable News feed"; Category = "Features"; Description = "Remove news/interests from taskbar" }
    "DisableRecall"          = @{ Enabled = $true;  Name = "Disable Recall"; Category = "Features"; Description = "Disable Windows Recall (24H2)" }

    # PRIVACY
    "DisableTelemetry"       = @{ Enabled = $true;  Name = "Disable telemetry"; Category = "Privacy"; Description = "Stop diagnostic data collection" }
    "DisableAdvertisingId"   = @{ Enabled = $true;  Name = "Disable advertising ID"; Category = "Privacy"; Description = "Block ad tracking and suggestions" }
    "DisableActivityHistory" = @{ Enabled = $true;  Name = "Disable activity history"; Category = "Privacy"; Description = "Stop activity tracking and sync" }
    "DisableLocation"        = @{ Enabled = $false; Name = "Disable location"; Category = "Privacy"; Description = "May break weather/maps apps" }
    "DisableWebSearch"       = @{ Enabled = $true;  Name = "Disable web search"; Category = "Privacy"; Description = "Remove Bing from Start menu" }
    "DisableCortana"         = @{ Enabled = $false; Name = "Disable Cortana"; Category = "Privacy"; Description = "May affect some search features" }
    "DisableErrorReporting"  = @{ Enabled = $false; Name = "Disable error reporting"; Category = "Privacy"; Description = "Stop sending crash reports" }

    # UI/UX
    "DisableLockScreenAds"   = @{ Enabled = $true;  Name = "Disable lock screen ads"; Category = "UI/UX"; Description = "Remove Spotlight ads" }
    "DisableStartSuggestions"= @{ Enabled = $true;  Name = "Disable Start suggestions"; Category = "UI/UX"; Description = "Remove app suggestions" }
    "DisableAnimations"      = @{ Enabled = $false; Name = "Disable animations"; Category = "UI/UX"; Description = "Faster but less pretty" }
    "DisableTransparency"    = @{ Enabled = $false; Name = "Disable transparency"; Category = "UI/UX"; Description = "Reduce GPU usage" }
    "ClassicContextMenu"     = @{ Enabled = $false; Name = "Classic context menu"; Category = "UI/UX"; Description = "Windows 10 style menu" }

    # PERFORMANCE
    "DisableBackgroundApps"  = @{ Enabled = $true;  Name = "Disable background apps"; Category = "Performance"; Description = "Stop apps in background" }
    "DisableStartupDelay"    = @{ Enabled = $true;  Name = "Disable startup delay"; Category = "Performance"; Description = "Faster boot time" }
    "DisableGameDVR"         = @{ Enabled = $false; Name = "Disable Game DVR"; Category = "Performance"; Description = "Xbox game recording" }

    # SERVICES
    "DisableTelemetrySvc"    = @{ Enabled = $true;  Name = "Disable telemetry services"; Category = "Services"; Description = "DiagTrack, WAP Push" }
    "DisablePrivacySvc"      = @{ Enabled = $false; Name = "Disable privacy services"; Category = "Services"; Description = "Geolocation, Maps" }
    "DisableOptionalSvc"     = @{ Enabled = $false; Name = "Disable optional services"; Category = "Services"; Description = "Search, Superfetch" }
}

# Import modules
$modulesPath = Join-Path $PSScriptRoot "modules"
Get-ChildItem -Path $modulesPath -Filter "*.psm1" -ErrorAction SilentlyContinue | ForEach-Object {
    Import-Module $_.FullName -Force -DisableNameChecking
}

function Test-WindowsVersion {
    $build = [System.Environment]::OSVersion.Version.Build

    if ($build -lt $Script:MinWindowsBuild) {
        Write-Host "ERROR: This script requires Windows 11 (Build $Script:MinWindowsBuild+)" -ForegroundColor Red
        Write-Host "Current build: $build" -ForegroundColor Red
        return $false
    }

    $versionName = switch ($true) {
        ($build -ge 26100) { "24H2" }
        ($build -ge 22631) { "23H2" }
        ($build -ge 22621) { "22H2" }
        default { "21H2" }
    }

    Write-Host "Detected Windows 11 $versionName (Build $build)" -ForegroundColor Green
    return $true
}

function Show-Banner {
    Clear-Host
    $title = "WINDOWS 11 DEBLOAT SCRIPT v$Script:Version"
    $subtitle = "Remove bloatware, disable telemetry, improve privacy"
    $width = 60

    # Center the title and subtitle
    $titlePad = [math]::Floor(($width - $title.Length) / 2)
    $titleLine = $title.PadLeft($title.Length + $titlePad).PadRight($width)

    $subPad = [math]::Floor(($width - $subtitle.Length) / 2)
    $subLine = $subtitle.PadLeft($subtitle.Length + $subPad).PadRight($width)

    $emptyLine = "".PadRight($width)
    $border = "═" * $width

    Write-Host ""
    Write-Host "  ╔$border╗" -ForegroundColor Cyan
    Write-Host "  ║$emptyLine║" -ForegroundColor Cyan
    Write-Host "  ║$titleLine║" -ForegroundColor Cyan
    Write-Host "  ║$emptyLine║" -ForegroundColor Cyan
    Write-Host "  ║$subLine║" -ForegroundColor Cyan
    Write-Host "  ║$emptyLine║" -ForegroundColor Cyan
    Write-Host "  ╚$border╝" -ForegroundColor Cyan
    Write-Host ""

    if ($DryRun) {
        Write-Host "  [DRY RUN MODE - No changes will be made]" -ForegroundColor Yellow
        Write-Host ""
    }
}

function Show-MainMenu {
    Write-Host "  Main Menu:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    [1] Quick Debloat (Recommended defaults)" -ForegroundColor White
    Write-Host "    [2] Remove Bloatware Apps" -ForegroundColor White
    Write-Host "    [3] Disable Telemetry & Privacy Settings" -ForegroundColor White
    Write-Host "    [4] Disable Unnecessary Services" -ForegroundColor White
    Write-Host "    [5] Full Debloat (All of the above)" -ForegroundColor White
    Write-Host ""
    Write-Host "    [C] Custom Debloat (Pick and choose)" -ForegroundColor Green
    Write-Host ""
    Write-Host "    [6] View Installed Bloatware" -ForegroundColor Gray
    Write-Host "    [7] View Service Status" -ForegroundColor Gray
    Write-Host "    [8] Generate Revert Script" -ForegroundColor Gray
    Write-Host ""
    Write-Host "    [Q] Quit" -ForegroundColor Gray
    Write-Host ""

    $choice = Read-Host "  Select option"
    return $choice
}

function Show-AppRemovalMenu {
    Write-Host ""
    Write-Host "  App Removal Options:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    [1] Remove Microsoft Bloatware" -ForegroundColor White
    Write-Host "    [2] Remove Third-Party Bloatware" -ForegroundColor White
    Write-Host "    [3] Remove All Bloatware" -ForegroundColor White
    Write-Host "    [4] View Installed Bloatware" -ForegroundColor White
    Write-Host ""
    Write-Host "    [B] Back to Main Menu" -ForegroundColor Gray
    Write-Host ""

    $choice = Read-Host "  Select option"
    return $choice
}

function Show-ServiceMenu {
    Write-Host ""
    Write-Host "  Service Options:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    [1] Disable Telemetry Services" -ForegroundColor White
    Write-Host "    [2] Disable Privacy-Related Services" -ForegroundColor White
    Write-Host "    [3] Disable All Recommended Services" -ForegroundColor White
    Write-Host "    [4] View Current Service Status" -ForegroundColor White
    Write-Host ""
    Write-Host "    [B] Back to Main Menu" -ForegroundColor Gray
    Write-Host ""

    $choice = Read-Host "  Select option"
    return $choice
}

function Show-CustomMenu {
    $keys = @($Script:CustomOptions.Keys)

    Write-Host ""
    Write-Host "  Custom Debloat - Toggle options ON/OFF:" -ForegroundColor Yellow
    Write-Host ""

    $currentCategory = ""
    $index = 1

    foreach ($key in $keys) {
        $option = $Script:CustomOptions[$key]

        # Print category header
        if ($option.Category -ne $currentCategory) {
            $currentCategory = $option.Category
            Write-Host ""
            Write-Host "  $($currentCategory.ToUpper())" -ForegroundColor Cyan
        }

        # Print option with checkbox
        $checkbox = if ($option.Enabled) { "[X]" } else { "[ ]" }
        $color = if ($option.Enabled) { "Green" } else { "Gray" }
        $num = $index.ToString().PadLeft(2)

        Write-Host "    $checkbox " -ForegroundColor $color -NoNewline
        Write-Host "$num. $($option.Name)" -ForegroundColor White -NoNewline
        Write-Host " - $($option.Description)" -ForegroundColor DarkGray

        $index++
    }

    Write-Host ""
    Write-Host "  ─────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host "  Commands:" -ForegroundColor Yellow
    Write-Host "    [1-25] Toggle option    [A] All ON    [N] All OFF" -ForegroundColor White
    Write-Host "    [D] Reset defaults      [R] RUN       [B] Back" -ForegroundColor White
    Write-Host ""

    $choice = Read-Host "  Enter command"
    return $choice
}

function Reset-CustomDefaults {
    # Apps
    $Script:CustomOptions["RemoveMicrosoftApps"].Enabled = $true
    $Script:CustomOptions["RemoveThirdPartyApps"].Enabled = $true

    # Features
    $Script:CustomOptions["DisableWidgets"].Enabled = $true
    $Script:CustomOptions["DisableCopilot"].Enabled = $true
    $Script:CustomOptions["DisableChatIcon"].Enabled = $true
    $Script:CustomOptions["DisableNewsFeed"].Enabled = $true
    $Script:CustomOptions["DisableRecall"].Enabled = $true

    # Privacy
    $Script:CustomOptions["DisableTelemetry"].Enabled = $true
    $Script:CustomOptions["DisableAdvertisingId"].Enabled = $true
    $Script:CustomOptions["DisableActivityHistory"].Enabled = $true
    $Script:CustomOptions["DisableLocation"].Enabled = $false
    $Script:CustomOptions["DisableWebSearch"].Enabled = $true
    $Script:CustomOptions["DisableCortana"].Enabled = $false
    $Script:CustomOptions["DisableErrorReporting"].Enabled = $false

    # UI/UX
    $Script:CustomOptions["DisableLockScreenAds"].Enabled = $true
    $Script:CustomOptions["DisableStartSuggestions"].Enabled = $true
    $Script:CustomOptions["DisableAnimations"].Enabled = $false
    $Script:CustomOptions["DisableTransparency"].Enabled = $false
    $Script:CustomOptions["ClassicContextMenu"].Enabled = $false

    # Performance
    $Script:CustomOptions["DisableBackgroundApps"].Enabled = $true
    $Script:CustomOptions["DisableStartupDelay"].Enabled = $true
    $Script:CustomOptions["DisableGameDVR"].Enabled = $false

    # Services
    $Script:CustomOptions["DisableTelemetrySvc"].Enabled = $true
    $Script:CustomOptions["DisablePrivacySvc"].Enabled = $false
    $Script:CustomOptions["DisableOptionalSvc"].Enabled = $false
}

function Invoke-CustomDebloat {
    $selectedCount = ($Script:CustomOptions.Values | Where-Object { $_.Enabled }).Count

    if ($selectedCount -eq 0) {
        Write-Host ""
        Write-Host "  No options selected!" -ForegroundColor Yellow
        return
    }

    Write-Host ""
    Write-Host "  Selected $selectedCount option(s) to apply:" -ForegroundColor Yellow

    foreach ($key in $Script:CustomOptions.Keys) {
        if ($Script:CustomOptions[$key].Enabled) {
            Write-Host "    - $($Script:CustomOptions[$key].Name)" -ForegroundColor White
        }
    }

    Write-Host ""
    $confirm = Read-Host "  Proceed? (Y/N)"
    if ($confirm -ne 'Y' -and $confirm -ne 'y') {
        Write-Host "  Cancelled." -ForegroundColor Yellow
        return
    }

    Write-Host ""

    # APPS
    if ($Script:CustomOptions["RemoveMicrosoftApps"].Enabled) {
        Remove-MicrosoftBloatware -RemoveProvisioned
    }

    if ($Script:CustomOptions["RemoveThirdPartyApps"].Enabled) {
        Remove-ThirdPartyBloatware -RemoveProvisioned
    }

    # WINDOWS FEATURES
    if ($Script:CustomOptions["DisableWidgets"].Enabled) {
        Disable-Widgets
    }

    if ($Script:CustomOptions["DisableCopilot"].Enabled) {
        Disable-Copilot
    }

    if ($Script:CustomOptions["DisableChatIcon"].Enabled) {
        Disable-ChatIcon
    }

    if ($Script:CustomOptions["DisableNewsFeed"].Enabled) {
        Disable-NewsFeed
    }

    if ($Script:CustomOptions["DisableRecall"].Enabled) {
        Disable-Recall
    }

    # PRIVACY
    if ($Script:CustomOptions["DisableTelemetry"].Enabled) {
        Disable-Telemetry
    }

    if ($Script:CustomOptions["DisableAdvertisingId"].Enabled) {
        Disable-AdvertisingId
    }

    if ($Script:CustomOptions["DisableActivityHistory"].Enabled) {
        Disable-ActivityHistory
    }

    if ($Script:CustomOptions["DisableLocation"].Enabled) {
        Disable-LocationTracking
    }

    if ($Script:CustomOptions["DisableWebSearch"].Enabled) {
        Disable-WebSearch
    }

    if ($Script:CustomOptions["DisableCortana"].Enabled) {
        Disable-Cortana
    }

    if ($Script:CustomOptions["DisableErrorReporting"].Enabled) {
        Disable-ErrorReporting
    }

    # UI/UX
    if ($Script:CustomOptions["DisableLockScreenAds"].Enabled) {
        Disable-LockScreenAds
    }

    if ($Script:CustomOptions["DisableStartSuggestions"].Enabled) {
        Disable-StartSuggestions
    }

    if ($Script:CustomOptions["DisableAnimations"].Enabled) {
        Disable-Animations
    }

    if ($Script:CustomOptions["DisableTransparency"].Enabled) {
        Disable-Transparency
    }

    if ($Script:CustomOptions["ClassicContextMenu"].Enabled) {
        Enable-ClassicContextMenu
    }

    # PERFORMANCE
    if ($Script:CustomOptions["DisableBackgroundApps"].Enabled) {
        Disable-BackgroundApps
    }

    if ($Script:CustomOptions["DisableStartupDelay"].Enabled) {
        Disable-StartupDelay
    }

    if ($Script:CustomOptions["DisableGameDVR"].Enabled) {
        Disable-GameDVR
    }

    # SERVICES
    if ($Script:CustomOptions["DisableTelemetrySvc"].Enabled) {
        Disable-TelemetryServices
    }

    if ($Script:CustomOptions["DisablePrivacySvc"].Enabled) {
        Disable-PrivacyServices
    }

    if ($Script:CustomOptions["DisableOptionalSvc"].Enabled) {
        Disable-OptionalServices -All
    }

    Write-Host ""
    Write-Host "  Custom debloat completed!" -ForegroundColor Green
}

function Start-CustomMode {
    $customRunning = $true
    $keys = @($Script:CustomOptions.Keys)

    while ($customRunning) {
        Show-Banner
        $choice = Show-CustomMenu

        # Check if it's a number (toggle)
        if ($choice -match '^\d+$') {
            $num = [int]$choice
            if ($num -ge 1 -and $num -le $keys.Count) {
                $key = $keys[$num - 1]
                $Script:CustomOptions[$key].Enabled = -not $Script:CustomOptions[$key].Enabled
            }
            else {
                Write-Host "  Invalid number" -ForegroundColor Red
                Start-Sleep -Milliseconds 500
            }
        }
        else {
            switch ($choice.ToUpper()) {
                "A" {
                    # All ON
                    foreach ($key in $keys) {
                        $Script:CustomOptions[$key].Enabled = $true
                    }
                }
                "N" {
                    # All OFF
                    foreach ($key in $keys) {
                        $Script:CustomOptions[$key].Enabled = $false
                    }
                }
                "D" {
                    # Reset defaults
                    Reset-CustomDefaults
                }
                "R" {
                    # Run
                    Invoke-CustomDebloat
                    Pause-Script
                }
                "B" {
                    $customRunning = $false
                }
                default {
                    Write-Host "  Invalid command" -ForegroundColor Red
                    Start-Sleep -Milliseconds 500
                }
            }
        }
    }
}

function Invoke-QuickDebloat {
    Write-Host ""
    Write-Host "  Quick Debloat will:" -ForegroundColor Yellow
    Write-Host "    - Remove common Microsoft and third-party bloatware" -ForegroundColor White
    Write-Host "    - Disable telemetry and advertising ID" -ForegroundColor White
    Write-Host "    - Disable activity history and location tracking" -ForegroundColor White
    Write-Host "    - Disable telemetry services" -ForegroundColor White
    Write-Host ""
    Write-Host "  Note: Xbox apps/services are kept for gaming." -ForegroundColor Cyan
    Write-Host ""

    $confirm = Read-Host "  Proceed with Quick Debloat? (Y/N)"
    if ($confirm -ne 'Y' -and $confirm -ne 'y') {
        Write-Host "  Cancelled." -ForegroundColor Yellow
        return
    }

    Write-Host ""

    # Remove bloatware
    Remove-AllBloatware -RemoveProvisioned

    # Disable telemetry
    Disable-Telemetry
    Disable-AdvertisingId
    Disable-ActivityHistory
    Disable-LocationTracking
    Disable-WebSearch

    # Disable services
    Disable-TelemetryServices
    Disable-PrivacyServices

    Write-Host ""
    Write-Host "  Quick Debloat completed!" -ForegroundColor Green
    Pause-Script
}

function Invoke-FullDebloat {
    Write-Host ""
    Write-Host "  Full Debloat will apply ALL debloating options:" -ForegroundColor Yellow
    Write-Host "    - Remove all bloatware (Microsoft + Third-party)" -ForegroundColor White
    Write-Host "    - Disable all telemetry and privacy settings" -ForegroundColor White
    Write-Host "    - Disable all recommended services" -ForegroundColor White
    Write-Host "    - Disable Cortana and web search" -ForegroundColor White
    Write-Host ""
    Write-Host "  Note: Xbox apps/services are kept for gaming." -ForegroundColor Cyan
    Write-Host ""

    $confirm = Read-Host "  Proceed with Full Debloat? (Y/N)"
    if ($confirm -ne 'Y' -and $confirm -ne 'y') {
        Write-Host "  Cancelled." -ForegroundColor Yellow
        return
    }

    Write-Host ""

    # Remove all bloatware
    Remove-AllBloatware -RemoveProvisioned

    # Apply all telemetry settings
    Disable-AllTelemetry

    # Disable all services
    Disable-AllDebloatServices

    Write-Host ""
    Write-Host "  Full Debloat completed!" -ForegroundColor Green
    Pause-Script
}

function Pause-Script {
    Write-Host ""
    Write-Host "  Press any key to continue..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Start-InteractiveMode {
    $running = $true

    while ($running) {
        Show-Banner
        $choice = Show-MainMenu

        switch ($choice.ToUpper()) {
            "1" {
                Invoke-QuickDebloat
            }
            "2" {
                $appMenuRunning = $true
                while ($appMenuRunning) {
                    Show-Banner
                    $appChoice = Show-AppRemovalMenu

                    switch ($appChoice.ToUpper()) {
                        "1" {
                            Write-Host ""
                            Remove-MicrosoftBloatware -RemoveProvisioned
                            Pause-Script
                        }
                        "2" {
                            Write-Host ""
                            Remove-ThirdPartyBloatware -RemoveProvisioned
                            Pause-Script
                        }
                        "3" {
                            Write-Host ""
                            Remove-AllBloatware -RemoveProvisioned
                            Pause-Script
                        }
                        "4" {
                            Show-InstalledBloatware
                            Pause-Script
                        }
                        "B" {
                            $appMenuRunning = $false
                        }
                        default {
                            Write-Host "  Invalid option" -ForegroundColor Red
                            Start-Sleep -Seconds 1
                        }
                    }
                }
            }
            "3" {
                Write-Host ""
                Disable-AllTelemetry
                Pause-Script
            }
            "4" {
                $svcMenuRunning = $true
                while ($svcMenuRunning) {
                    Show-Banner
                    $svcChoice = Show-ServiceMenu

                    switch ($svcChoice.ToUpper()) {
                        "1" {
                            Write-Host ""
                            Disable-TelemetryServices
                            Pause-Script
                        }
                        "2" {
                            Write-Host ""
                            Disable-PrivacyServices
                            Pause-Script
                        }
                        "3" {
                            Write-Host ""
                            Disable-AllDebloatServices
                            Pause-Script
                        }
                        "4" {
                            Show-ServiceStatus
                            Pause-Script
                        }
                        "B" {
                            $svcMenuRunning = $false
                        }
                        default {
                            Write-Host "  Invalid option" -ForegroundColor Red
                            Start-Sleep -Seconds 1
                        }
                    }
                }
            }
            "5" {
                Invoke-FullDebloat
            }
            "C" {
                Start-CustomMode
            }
            "6" {
                Show-InstalledBloatware
                Pause-Script
            }
            "7" {
                Show-ServiceStatus
                Pause-Script
            }
            "8" {
                Write-Host ""
                $revertPath = Export-RevertScript
                Write-Host "  Revert script saved to: $revertPath" -ForegroundColor Green
                Pause-Script
            }
            "Q" {
                $running = $false
            }
            default {
                Write-Host "  Invalid option" -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    }
}

function Start-SilentMode {
    Write-Log "Running in silent mode with default settings..."

    # Apply quick debloat settings
    Remove-AllBloatware -RemoveProvisioned
    Disable-AllTelemetry
    Disable-AllDebloatServices

    Write-Log "Silent debloat completed" -Level Success
}

# ============================================
# MAIN EXECUTION
# ============================================

# Verify Windows version
if (-not (Test-WindowsVersion)) {
    exit 1
}

# Initialize environment
Initialize-DebloatEnvironment -DryRun $DryRun

# Create restore point (unless skipped)
if (-not $SkipRestorePoint) {
    $restoreResult = New-DebloatRestorePoint
    if (-not $restoreResult -and -not $DryRun) {
        Write-Host ""
        Write-Host "WARNING: Could not create restore point." -ForegroundColor Yellow
        $continue = Read-Host "Continue anyway? (Y/N)"
        if ($continue -ne 'Y' -and $continue -ne 'y') {
            Write-Host "Cancelled." -ForegroundColor Yellow
            exit 0
        }
    }
}

# Backup registry
Backup-RegistryKeys

# Run appropriate mode
if ($Silent) {
    Start-SilentMode
}
else {
    Start-InteractiveMode
}

# Generate revert script and show summary
if (-not $DryRun) {
    Export-RevertScript | Out-Null
}

Show-Summary

Write-Host ""
Write-Host "Thank you for using Windows 11 Debloat Script!" -ForegroundColor Cyan
Write-Host "A system restart is recommended for all changes to take effect." -ForegroundColor Yellow
Write-Host ""
