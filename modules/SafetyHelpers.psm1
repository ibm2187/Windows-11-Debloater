#Requires -Version 5.1
<#
.SYNOPSIS
    Safety helper functions for Windows 11 Debloat Script
.DESCRIPTION
    Provides restore point creation, registry backup, logging, and revert capabilities
#>

# Script-level variables for tracking changes
$Script:LogFile = $null
$Script:RegistryChanges = @()
$Script:ServiceChanges = @()
$Script:RemovedApps = @()
$Script:Config = @{}

function Initialize-DebloatEnvironment {
    [CmdletBinding()]
    param(
        [string]$LogPath = "$PSScriptRoot\..\logs",
        [string]$BackupPath = "$PSScriptRoot\..\backups",
        [bool]$DryRun = $false
    )

    $Script:Config = @{
        LogPath = $LogPath
        BackupPath = $BackupPath
        DryRun = $DryRun
    }

    # Ensure directories exist
    @($LogPath, $BackupPath) | ForEach-Object {
        if (-not (Test-Path $_)) {
            New-Item -ItemType Directory -Path $_ -Force | Out-Null
        }
    }

    # Initialize log file
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $Script:LogFile = Join-Path $LogPath "debloat-$timestamp.log"

    Write-Log "Windows 11 Debloat Script initialized"
    Write-Log "Log file: $Script:LogFile"
    Write-Log "Dry Run Mode: $DryRun"
}

function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Message,

        [ValidateSet("Info", "Warning", "Error", "Success", "DryRun")]
        [string]$Level = "Info"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"

    # Console colors
    $colors = @{
        Info    = "White"
        Warning = "Yellow"
        Error   = "Red"
        Success = "Green"
        DryRun  = "Cyan"
    }

    Write-Host $logEntry -ForegroundColor $colors[$Level]

    # File logging
    if ($Script:LogFile) {
        Add-Content -Path $Script:LogFile -Value $logEntry -ErrorAction SilentlyContinue
    }
}

function New-DebloatRestorePoint {
    [CmdletBinding()]
    param(
        [string]$Description = "Before Windows 11 Debloat Script"
    )

    Write-Log "Creating system restore point..."

    if ($Script:Config.DryRun) {
        Write-Log "[DRY RUN] Would create restore point: $Description" -Level DryRun
        return $true
    }

    try {
        # Enable System Restore on system drive if disabled
        $systemDrive = $env:SystemDrive + "\"
        Enable-ComputerRestore -Drive $systemDrive -ErrorAction SilentlyContinue

        # Check for recent restore point (within 24 hours) to avoid duplicates
        $recentPoint = Get-ComputerRestorePoint -ErrorAction SilentlyContinue |
            Where-Object { $_.CreationTime -gt (Get-Date).AddHours(-24) -and $_.Description -like "*Debloat*" } |
            Select-Object -First 1

        if ($recentPoint) {
            Write-Log "Recent debloat restore point exists from $($recentPoint.CreationTime)" -Level Warning
            return $true
        }

        # Create restore point
        Checkpoint-Computer -Description $Description -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-Log "Restore point created successfully" -Level Success
        return $true
    }
    catch {
        Write-Log "Failed to create restore point: $_" -Level Error
        return $false
    }
}

function Backup-RegistryKeys {
    [CmdletBinding()]
    param(
        [string]$BackupPath = $Script:Config.BackupPath
    )

    Write-Log "Backing up registry keys..."

    if ($Script:Config.DryRun) {
        Write-Log "[DRY RUN] Would backup registry keys to $BackupPath" -Level DryRun
        return $true
    }

    $keysToBackup = @(
        "HKLM\SOFTWARE\Policies\Microsoft\Windows",
        "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies",
        "HKCU\Software\Microsoft\Windows\CurrentVersion"
    )

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

    foreach ($key in $keysToBackup) {
        $safeKeyName = $key -replace "\\", "_" -replace ":", ""
        $backupFile = Join-Path $BackupPath "$safeKeyName-$timestamp.reg"

        try {
            $result = reg export $key $backupFile /y 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Backed up: $key"
            }
        }
        catch {
            Write-Log "Could not backup $key (may not exist)" -Level Warning
        }
    }

    Write-Log "Registry backup completed" -Level Success
    return $true
}

function Invoke-DebloatAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Description,

        [Parameter(Mandatory)]
        [scriptblock]$Action
    )

    if ($Script:Config.DryRun) {
        Write-Log "[DRY RUN] Would execute: $Description" -Level DryRun
        return @{
            Success = $true
            DryRun = $true
            Description = $Description
        }
    }

    try {
        Write-Log "Executing: $Description"
        $result = & $Action
        Write-Log "Completed: $Description" -Level Success

        return @{
            Success = $true
            DryRun = $false
            Description = $Description
            Result = $result
        }
    }
    catch {
        Write-Log "Failed: $Description - $_" -Level Error
        return @{
            Success = $false
            DryRun = $false
            Description = $Description
            Error = $_
        }
    }
}

function Add-RegistryChange {
    [CmdletBinding()]
    param(
        [string]$Path,
        [string]$Name,
        $Value,
        [string]$Type,
        $OriginalValue,
        [string]$Description
    )

    $Script:RegistryChanges += @{
        Path = $Path
        Name = $Name
        Value = $Value
        Type = $Type
        OriginalValue = $OriginalValue
        Description = $Description
    }
}

function Add-ServiceChange {
    [CmdletBinding()]
    param(
        [string]$Name,
        [string]$DisplayName,
        [string]$OriginalStartType
    )

    $Script:ServiceChanges += @{
        Name = $Name
        DisplayName = $DisplayName
        OriginalStartType = $OriginalStartType
    }
}

function Add-RemovedApp {
    [CmdletBinding()]
    param(
        [string]$PackageName,
        [string]$DisplayName
    )

    $Script:RemovedApps += @{
        PackageName = $PackageName
        DisplayName = $DisplayName
    }
}

function Export-RevertScript {
    [CmdletBinding()]
    param(
        [string]$OutputPath = (Join-Path $Script:Config.BackupPath "Revert-Debloat.ps1")
    )

    Write-Log "Generating revert script..."

    $revertContent = @"
#Requires -RunAsAdministrator
#Requires -Version 5.1
<#
.SYNOPSIS
    Revert Windows 11 Debloat Changes
.DESCRIPTION
    This script attempts to revert changes made by the debloat script.
    Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
#>

Write-Host "Windows 11 Debloat - Revert Script" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""

`$confirm = Read-Host "This will attempt to revert debloat changes. Continue? (Y/N)"
if (`$confirm -ne 'Y') {
    Write-Host "Cancelled." -ForegroundColor Yellow
    exit
}

Write-Host ""
Write-Host "Reverting registry changes..." -ForegroundColor Yellow

"@

    # Add registry revert commands
    foreach ($entry in $Script:RegistryChanges) {
        if ($null -ne $entry.OriginalValue) {
            $revertContent += @"

# Revert: $($entry.Description)
try {
    Set-ItemProperty -Path "$($entry.Path)" -Name "$($entry.Name)" -Value $($entry.OriginalValue) -Type $($entry.Type) -Force -ErrorAction Stop
    Write-Host "  Reverted: $($entry.Description)" -ForegroundColor Green
} catch {
    Write-Host "  Failed to revert: $($entry.Description)" -ForegroundColor Red
}
"@
        }
        else {
            $revertContent += @"

# Remove: $($entry.Description) (was newly created)
try {
    Remove-ItemProperty -Path "$($entry.Path)" -Name "$($entry.Name)" -Force -ErrorAction Stop
    Write-Host "  Removed: $($entry.Description)" -ForegroundColor Green
} catch {
    Write-Host "  Failed to remove: $($entry.Description)" -ForegroundColor Red
}
"@
        }
    }

    # Add service revert commands
    if ($Script:ServiceChanges.Count -gt 0) {
        $revertContent += @"

Write-Host ""
Write-Host "Reverting service changes..." -ForegroundColor Yellow

"@
        foreach ($service in $Script:ServiceChanges) {
            $revertContent += @"

# Revert service: $($service.DisplayName)
try {
    Set-Service -Name "$($service.Name)" -StartupType $($service.OriginalStartType) -ErrorAction Stop
    Write-Host "  Reverted: $($service.DisplayName) to $($service.OriginalStartType)" -ForegroundColor Green
} catch {
    Write-Host "  Failed to revert: $($service.DisplayName)" -ForegroundColor Red
}
"@
        }
    }

    # Add app reinstall instructions
    if ($Script:RemovedApps.Count -gt 0) {
        $revertContent += @"

Write-Host ""
Write-Host "Apps that were removed (reinstall from Microsoft Store):" -ForegroundColor Yellow

"@
        foreach ($app in $Script:RemovedApps) {
            $revertContent += @"
Write-Host "  - $($app.DisplayName)"
"@
        }

        $revertContent += @"

Write-Host ""
Write-Host "To reinstall apps, open Microsoft Store and search for them." -ForegroundColor Cyan
"@
    }

    $revertContent += @"

Write-Host ""
Write-Host "Revert completed. A restart may be required for all changes to take effect." -ForegroundColor Green
Write-Host "Press any key to exit..."
`$null = `$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
"@

    $revertContent | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Log "Revert script saved to: $OutputPath" -Level Success
    return $OutputPath
}

function Show-Summary {
    [CmdletBinding()]
    param()

    Write-Host ""
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "           DEBLOAT SUMMARY              " -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Registry changes: $($Script:RegistryChanges.Count)" -ForegroundColor White
    Write-Host "Services modified: $($Script:ServiceChanges.Count)" -ForegroundColor White
    Write-Host "Apps removed: $($Script:RemovedApps.Count)" -ForegroundColor White

    Write-Host ""
    Write-Host "Log file: $Script:LogFile" -ForegroundColor Gray

    if (-not $Script:Config.DryRun) {
        Write-Host ""
        Write-Host "A revert script has been generated in the backups folder." -ForegroundColor Yellow
        Write-Host "Restart your computer for all changes to take effect." -ForegroundColor Yellow
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Initialize-DebloatEnvironment',
    'Write-Log',
    'New-DebloatRestorePoint',
    'Backup-RegistryKeys',
    'Invoke-DebloatAction',
    'Add-RegistryChange',
    'Add-ServiceChange',
    'Add-RemovedApp',
    'Export-RevertScript',
    'Show-Summary'
) -Variable @('Config', 'LogFile', 'RegistryChanges', 'ServiceChanges', 'RemovedApps')
