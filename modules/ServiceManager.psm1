#Requires -Version 5.1
<#
.SYNOPSIS
    Service management functions for Windows 11 Debloat Script
.DESCRIPTION
    Provides functions to disable unnecessary Windows services
    Note: Xbox services are kept enabled for gaming compatibility
#>

# Services safe to disable for privacy
$Script:TelemetryServices = @(
    @{ Name = "DiagTrack"; DisplayName = "Connected User Experiences and Telemetry"; Description = "Primary telemetry service" },
    @{ Name = "dmwappushservice"; DisplayName = "Device Management WAP Push"; Description = "WAP push message routing" },
    @{ Name = "diagnosticshub.standardcollector.service"; DisplayName = "Diagnostics Hub Standard Collector"; Description = "Diagnostic data collection" },
    @{ Name = "InventorySvc"; DisplayName = "Inventory and Compatibility Appraisal"; Description = "Hardware/software inventory collection" },
    @{ Name = "whesvc"; DisplayName = "Windows Health and Optimized Experiences"; Description = "Telemetry suggestions" }
)

$Script:PrivacyServices = @(
    @{ Name = "WerSvc"; DisplayName = "Windows Error Reporting"; Description = "Error reporting to Microsoft" },
    @{ Name = "lfsvc"; DisplayName = "Geolocation Service"; Description = "Location tracking" },
    @{ Name = "MapsBroker"; DisplayName = "Downloaded Maps Manager"; Description = "Offline maps service" },
    @{ Name = "DPS"; DisplayName = "Diagnostic Policy Service"; Description = "Problem detection/troubleshooting" },
    @{ Name = "WdiSystemHost"; DisplayName = "Diagnostic System Host"; Description = "Diagnostic host service" }
)

$Script:OptionalServices = @(
    @{ Name = "WSearch"; DisplayName = "Windows Search"; Description = "File indexing (may slow older PCs)" },
    @{ Name = "SysMain"; DisplayName = "Superfetch/SysMain"; Description = "Prefetch optimization (disable for SSD)" },
    @{ Name = "TabletInputService"; DisplayName = "Touch Keyboard and Handwriting"; Description = "Touch/pen input (if not needed)" },
    @{ Name = "wisvc"; DisplayName = "Windows Insider Service"; Description = "Insider program (if not enrolled)" },
    @{ Name = "RetailDemo"; DisplayName = "Retail Demo Service"; Description = "Store demo mode" },
    @{ Name = "WMPNetworkSvc"; DisplayName = "Windows Media Player Network Sharing"; Description = "Media sharing (if not used)" },
    @{ Name = "PhoneSvc"; DisplayName = "Phone Service"; Description = "Phone Link related" }
)

# Print/Fax services (disable if not using printers)
$Script:PrintServices = @(
    @{ Name = "Spooler"; DisplayName = "Print Spooler"; Description = "Print queue management" },
    @{ Name = "Fax"; DisplayName = "Windows Fax"; Description = "Fax service" },
    @{ Name = "PrintNotify"; DisplayName = "Printer Extensions and Notifications"; Description = "Printer notifications" }
)

# Remote/Network services (disable for security if not needed)
$Script:NetworkServices = @(
    @{ Name = "RemoteRegistry"; DisplayName = "Remote Registry"; Description = "Remote registry editing" },
    @{ Name = "SharedAccess"; DisplayName = "Internet Connection Sharing"; Description = "ICS/Mobile hotspot sharing" },
    @{ Name = "lmhosts"; DisplayName = "TCP/IP NetBIOS Helper"; Description = "NetBIOS name resolution" },
    @{ Name = "SSDPSRV"; DisplayName = "SSDP Discovery"; Description = "UPnP device discovery" },
    @{ Name = "upnphost"; DisplayName = "UPnP Device Host"; Description = "UPnP host service" },
    @{ Name = "NetTcpPortSharing"; DisplayName = "Net.Tcp Port Sharing"; Description = "WCF port sharing" }
)

# Bluetooth/Mobile services (disable if not using Bluetooth)
$Script:BluetoothServices = @(
    @{ Name = "BTAGService"; DisplayName = "Bluetooth Audio Gateway"; Description = "Bluetooth audio routing" },
    @{ Name = "bthserv"; DisplayName = "Bluetooth Support Service"; Description = "Core Bluetooth functionality" },
    @{ Name = "BthAvctpSvc"; DisplayName = "AVCTP service"; Description = "Bluetooth A/V control" },
    @{ Name = "icssvc"; DisplayName = "Windows Mobile Hotspot"; Description = "Mobile hotspot service" }
)

function Disable-DebloatService {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ServiceName,

        [string]$DisplayName = $ServiceName,

        [switch]$StopService
    )

    # Check if service exists
    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

    if (-not $service) {
        Write-Log "Service not found: $DisplayName ($ServiceName)" -Level Warning
        return @{ Success = $false; Status = "NotFound" }
    }

    # Get original startup type using WMI (more reliable)
    $wmiService = Get-WmiObject Win32_Service -Filter "Name='$ServiceName'" -ErrorAction SilentlyContinue
    $originalStartType = if ($wmiService) { $wmiService.StartMode } else { "Unknown" }

    # Skip if already disabled
    if ($originalStartType -eq "Disabled") {
        Write-Log "Service already disabled: $DisplayName" -Level Info
        return @{ Success = $true; Status = "AlreadyDisabled" }
    }

    $result = Invoke-DebloatAction -Description "Disable service: $DisplayName" -Action {
        # Stop service if running and requested
        if ($StopService -and $service.Status -eq 'Running') {
            Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
        }

        # Disable service
        Set-Service -Name $ServiceName -StartupType Disabled -ErrorAction Stop
    }

    # Track change for revert
    if ($result.Success -and -not $result.DryRun) {
        Add-ServiceChange -Name $ServiceName -DisplayName $DisplayName -OriginalStartType $originalStartType
    }

    return @{
        Success = $result.Success
        Status = if ($result.Success) { "Disabled" } else { "Failed" }
        OriginalStartType = $originalStartType
    }
}

function Enable-DebloatService {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ServiceName,

        [string]$DisplayName = $ServiceName,

        [ValidateSet("Automatic", "Manual", "Disabled")]
        [string]$StartupType = "Manual"
    )

    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

    if (-not $service) {
        Write-Log "Service not found: $DisplayName ($ServiceName)" -Level Warning
        return @{ Success = $false; Status = "NotFound" }
    }

    $result = Invoke-DebloatAction -Description "Enable service: $DisplayName to $StartupType" -Action {
        Set-Service -Name $ServiceName -StartupType $StartupType -ErrorAction Stop
    }

    return @{
        Success = $result.Success
        Status = if ($result.Success) { "Enabled" } else { "Failed" }
    }
}

function Disable-TelemetryServices {
    [CmdletBinding()]
    param()

    Write-Log "Disabling telemetry services..."

    $results = @{
        Disabled = 0
        Failed = 0
        NotFound = 0
        AlreadyDisabled = 0
    }

    foreach ($svc in $Script:TelemetryServices) {
        $result = Disable-DebloatService -ServiceName $svc.Name -DisplayName $svc.DisplayName -StopService

        switch ($result.Status) {
            "Disabled" { $results.Disabled++ }
            "Failed" { $results.Failed++ }
            "NotFound" { $results.NotFound++ }
            "AlreadyDisabled" { $results.AlreadyDisabled++ }
        }
    }

    Write-Log "Telemetry services: $($results.Disabled) disabled, $($results.AlreadyDisabled) already disabled, $($results.Failed) failed" -Level Success
    return $results
}

function Disable-PrivacyServices {
    [CmdletBinding()]
    param()

    Write-Log "Disabling privacy-related services..."

    $results = @{
        Disabled = 0
        Failed = 0
        NotFound = 0
        AlreadyDisabled = 0
    }

    foreach ($svc in $Script:PrivacyServices) {
        $result = Disable-DebloatService -ServiceName $svc.Name -DisplayName $svc.DisplayName -StopService

        switch ($result.Status) {
            "Disabled" { $results.Disabled++ }
            "Failed" { $results.Failed++ }
            "NotFound" { $results.NotFound++ }
            "AlreadyDisabled" { $results.AlreadyDisabled++ }
        }
    }

    Write-Log "Privacy services: $($results.Disabled) disabled, $($results.AlreadyDisabled) already disabled" -Level Success
    return $results
}

function Disable-OptionalServices {
    [CmdletBinding()]
    param(
        [switch]$DisableSearch,
        [switch]$DisableSuperfetch,
        [switch]$All
    )

    Write-Log "Disabling optional services..."

    $results = @{
        Disabled = 0
        Failed = 0
        NotFound = 0
        AlreadyDisabled = 0
    }

    foreach ($svc in $Script:OptionalServices) {
        # Skip Windows Search unless specifically requested
        if ($svc.Name -eq "WSearch" -and -not $DisableSearch -and -not $All) {
            continue
        }

        # Skip SysMain unless specifically requested
        if ($svc.Name -eq "SysMain" -and -not $DisableSuperfetch -and -not $All) {
            continue
        }

        $result = Disable-DebloatService -ServiceName $svc.Name -DisplayName $svc.DisplayName -StopService

        switch ($result.Status) {
            "Disabled" { $results.Disabled++ }
            "Failed" { $results.Failed++ }
            "NotFound" { $results.NotFound++ }
            "AlreadyDisabled" { $results.AlreadyDisabled++ }
        }
    }

    Write-Log "Optional services: $($results.Disabled) disabled, $($results.AlreadyDisabled) already disabled" -Level Success
    return $results
}

function Disable-PrintServices {
    [CmdletBinding()]
    param()

    Write-Log "Disabling print/fax services..."

    $results = @{
        Disabled = 0
        Failed = 0
        NotFound = 0
        AlreadyDisabled = 0
    }

    foreach ($svc in $Script:PrintServices) {
        $result = Disable-DebloatService -ServiceName $svc.Name -DisplayName $svc.DisplayName -StopService

        switch ($result.Status) {
            "Disabled" { $results.Disabled++ }
            "Failed" { $results.Failed++ }
            "NotFound" { $results.NotFound++ }
            "AlreadyDisabled" { $results.AlreadyDisabled++ }
        }
    }

    Write-Log "Print services: $($results.Disabled) disabled, $($results.AlreadyDisabled) already disabled" -Level Success
    return $results
}

function Disable-NetworkServices {
    [CmdletBinding()]
    param()

    Write-Log "Disabling remote/network services..."

    $results = @{
        Disabled = 0
        Failed = 0
        NotFound = 0
        AlreadyDisabled = 0
    }

    foreach ($svc in $Script:NetworkServices) {
        $result = Disable-DebloatService -ServiceName $svc.Name -DisplayName $svc.DisplayName -StopService

        switch ($result.Status) {
            "Disabled" { $results.Disabled++ }
            "Failed" { $results.Failed++ }
            "NotFound" { $results.NotFound++ }
            "AlreadyDisabled" { $results.AlreadyDisabled++ }
        }
    }

    Write-Log "Network services: $($results.Disabled) disabled, $($results.AlreadyDisabled) already disabled" -Level Success
    return $results
}

function Disable-BluetoothServices {
    [CmdletBinding()]
    param()

    Write-Log "Disabling Bluetooth/mobile services..."

    $results = @{
        Disabled = 0
        Failed = 0
        NotFound = 0
        AlreadyDisabled = 0
    }

    foreach ($svc in $Script:BluetoothServices) {
        $result = Disable-DebloatService -ServiceName $svc.Name -DisplayName $svc.DisplayName -StopService

        switch ($result.Status) {
            "Disabled" { $results.Disabled++ }
            "Failed" { $results.Failed++ }
            "NotFound" { $results.NotFound++ }
            "AlreadyDisabled" { $results.AlreadyDisabled++ }
        }
    }

    Write-Log "Bluetooth services: $($results.Disabled) disabled, $($results.AlreadyDisabled) already disabled" -Level Success
    return $results
}

function Disable-AllDebloatServices {
    [CmdletBinding()]
    param(
        [switch]$IncludeOptional,
        [switch]$IncludePrint,
        [switch]$IncludeNetwork,
        [switch]$IncludeBluetooth
    )

    Write-Log "Disabling all debloat services..."

    $telemetryResults = Disable-TelemetryServices
    $privacyResults = Disable-PrivacyServices

    $optionalResults = @{ Disabled = 0 }
    if ($IncludeOptional) {
        $optionalResults = Disable-OptionalServices -All
    }

    $printResults = @{ Disabled = 0 }
    if ($IncludePrint) {
        $printResults = Disable-PrintServices
    }

    $networkResults = @{ Disabled = 0 }
    if ($IncludeNetwork) {
        $networkResults = Disable-NetworkServices
    }

    $bluetoothResults = @{ Disabled = 0 }
    if ($IncludeBluetooth) {
        $bluetoothResults = Disable-BluetoothServices
    }

    return @{
        Telemetry = $telemetryResults
        Privacy = $privacyResults
        Optional = $optionalResults
        Print = $printResults
        Network = $networkResults
        Bluetooth = $bluetoothResults
        TotalDisabled = $telemetryResults.Disabled + $privacyResults.Disabled + $optionalResults.Disabled + $printResults.Disabled + $networkResults.Disabled + $bluetoothResults.Disabled
    }
}

function Show-ServiceStatus {
    [CmdletBinding()]
    param()

    Write-Host ""
    Write-Host "Service Status Overview" -ForegroundColor Cyan
    Write-Host "=======================" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Telemetry Services:" -ForegroundColor Yellow
    foreach ($svc in $Script:TelemetryServices) {
        $service = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
        if ($service) {
            $status = $service.Status
            $startType = (Get-WmiObject Win32_Service -Filter "Name='$($svc.Name)'" -ErrorAction SilentlyContinue).StartMode
            $color = if ($startType -eq "Disabled") { "Green" } else { "Red" }
            Write-Host "  $($svc.DisplayName): $startType ($status)" -ForegroundColor $color
        }
        else {
            Write-Host "  $($svc.DisplayName): Not Found" -ForegroundColor Gray
        }
    }

    Write-Host ""
    Write-Host "Privacy Services:" -ForegroundColor Yellow
    foreach ($svc in $Script:PrivacyServices) {
        $service = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
        if ($service) {
            $status = $service.Status
            $startType = (Get-WmiObject Win32_Service -Filter "Name='$($svc.Name)'" -ErrorAction SilentlyContinue).StartMode
            $color = if ($startType -eq "Disabled") { "Green" } else { "Red" }
            Write-Host "  $($svc.DisplayName): $startType ($status)" -ForegroundColor $color
        }
        else {
            Write-Host "  $($svc.DisplayName): Not Found" -ForegroundColor Gray
        }
    }

    Write-Host ""
    Write-Host "Optional Services:" -ForegroundColor Yellow
    foreach ($svc in $Script:OptionalServices) {
        $service = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
        if ($service) {
            $status = $service.Status
            $startType = (Get-WmiObject Win32_Service -Filter "Name='$($svc.Name)'" -ErrorAction SilentlyContinue).StartMode
            $color = if ($startType -eq "Disabled") { "Green" } elseif ($startType -eq "Manual") { "Yellow" } else { "White" }
            Write-Host "  $($svc.DisplayName): $startType ($status)" -ForegroundColor $color
        }
        else {
            Write-Host "  $($svc.DisplayName): Not Found" -ForegroundColor Gray
        }
    }

    Write-Host ""
    Write-Host "Print/Fax Services:" -ForegroundColor Yellow
    foreach ($svc in $Script:PrintServices) {
        $service = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
        if ($service) {
            $status = $service.Status
            $startType = (Get-WmiObject Win32_Service -Filter "Name='$($svc.Name)'" -ErrorAction SilentlyContinue).StartMode
            $color = if ($startType -eq "Disabled") { "Green" } elseif ($startType -eq "Manual") { "Yellow" } else { "White" }
            Write-Host "  $($svc.DisplayName): $startType ($status)" -ForegroundColor $color
        }
        else {
            Write-Host "  $($svc.DisplayName): Not Found" -ForegroundColor Gray
        }
    }

    Write-Host ""
    Write-Host "Remote/Network Services:" -ForegroundColor Yellow
    foreach ($svc in $Script:NetworkServices) {
        $service = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
        if ($service) {
            $status = $service.Status
            $startType = (Get-WmiObject Win32_Service -Filter "Name='$($svc.Name)'" -ErrorAction SilentlyContinue).StartMode
            $color = if ($startType -eq "Disabled") { "Green" } elseif ($startType -eq "Manual") { "Yellow" } else { "White" }
            Write-Host "  $($svc.DisplayName): $startType ($status)" -ForegroundColor $color
        }
        else {
            Write-Host "  $($svc.DisplayName): Not Found" -ForegroundColor Gray
        }
    }

    Write-Host ""
    Write-Host "Bluetooth/Mobile Services:" -ForegroundColor Yellow
    foreach ($svc in $Script:BluetoothServices) {
        $service = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
        if ($service) {
            $status = $service.Status
            $startType = (Get-WmiObject Win32_Service -Filter "Name='$($svc.Name)'" -ErrorAction SilentlyContinue).StartMode
            $color = if ($startType -eq "Disabled") { "Green" } elseif ($startType -eq "Manual") { "Yellow" } else { "White" }
            Write-Host "  $($svc.DisplayName): $startType ($status)" -ForegroundColor $color
        }
        else {
            Write-Host "  $($svc.DisplayName): Not Found" -ForegroundColor Gray
        }
    }

    Write-Host ""
    Write-Host "Note: Xbox services are kept enabled for gaming compatibility." -ForegroundColor Cyan
    Write-Host ""
}

# Export functions
Export-ModuleMember -Function @(
    'Disable-DebloatService',
    'Enable-DebloatService',
    'Disable-TelemetryServices',
    'Disable-PrivacyServices',
    'Disable-OptionalServices',
    'Disable-PrintServices',
    'Disable-NetworkServices',
    'Disable-BluetoothServices',
    'Disable-AllDebloatServices',
    'Show-ServiceStatus'
)
