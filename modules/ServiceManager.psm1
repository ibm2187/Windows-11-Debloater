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
    @{ Name = "diagnosticshub.standardcollector.service"; DisplayName = "Diagnostics Hub Standard Collector"; Description = "Diagnostic data collection" }
)

$Script:PrivacyServices = @(
    @{ Name = "WerSvc"; DisplayName = "Windows Error Reporting"; Description = "Error reporting to Microsoft" },
    @{ Name = "lfsvc"; DisplayName = "Geolocation Service"; Description = "Location tracking" },
    @{ Name = "MapsBroker"; DisplayName = "Downloaded Maps Manager"; Description = "Offline maps service" }
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

function Disable-AllDebloatServices {
    [CmdletBinding()]
    param(
        [switch]$IncludeOptional
    )

    Write-Log "Disabling all debloat services..."

    $telemetryResults = Disable-TelemetryServices
    $privacyResults = Disable-PrivacyServices

    $optionalResults = @{ Disabled = 0 }
    if ($IncludeOptional) {
        $optionalResults = Disable-OptionalServices -All
    }

    return @{
        Telemetry = $telemetryResults
        Privacy = $privacyResults
        Optional = $optionalResults
        TotalDisabled = $telemetryResults.Disabled + $privacyResults.Disabled + $optionalResults.Disabled
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
    'Disable-AllDebloatServices',
    'Show-ServiceStatus'
)
