#Requires -Version 5.1
<#
.SYNOPSIS
    App removal functions for Windows 11 Debloat Script
.DESCRIPTION
    Provides functions to identify and remove bloatware apps
#>

# Default bloatware lists
$Script:MicrosoftBloatware = @(
    @{ PackageName = "Microsoft.549981C3F5F10"; DisplayName = "Cortana" },
    @{ PackageName = "Microsoft.BingNews"; DisplayName = "Bing News" },
    @{ PackageName = "Microsoft.BingWeather"; DisplayName = "Bing Weather" },
    @{ PackageName = "Microsoft.BingFinance"; DisplayName = "Bing Finance" },
    @{ PackageName = "Microsoft.BingSports"; DisplayName = "Bing Sports" },
    @{ PackageName = "Microsoft.BingTranslator"; DisplayName = "Bing Translator" },
    @{ PackageName = "Microsoft.BingSearch"; DisplayName = "Bing Search" },
    @{ PackageName = "Microsoft.Copilot"; DisplayName = "Microsoft Copilot" },
    @{ PackageName = "Microsoft.GetHelp"; DisplayName = "Get Help" },
    @{ PackageName = "Microsoft.Getstarted"; DisplayName = "Tips" },
    @{ PackageName = "Microsoft.Microsoft3DViewer"; DisplayName = "3D Viewer" },
    @{ PackageName = "Microsoft.MicrosoftOfficeHub"; DisplayName = "Office Hub" },
    @{ PackageName = "Microsoft.MicrosoftSolitaireCollection"; DisplayName = "Solitaire Collection" },
    @{ PackageName = "Microsoft.MixedReality.Portal"; DisplayName = "Mixed Reality Portal" },
    @{ PackageName = "Microsoft.OneConnect"; DisplayName = "Paid WiFi & Cellular" },
    @{ PackageName = "Microsoft.People"; DisplayName = "People" },
    @{ PackageName = "Microsoft.Print3D"; DisplayName = "Print 3D" },
    @{ PackageName = "Microsoft.SkypeApp"; DisplayName = "Skype" },
    @{ PackageName = "Microsoft.Wallet"; DisplayName = "Microsoft Pay" },
    @{ PackageName = "Microsoft.WindowsFeedbackHub"; DisplayName = "Feedback Hub" },
    @{ PackageName = "Microsoft.WindowsMaps"; DisplayName = "Windows Maps" },
    @{ PackageName = "Microsoft.YourPhone"; DisplayName = "Phone Link" },
    @{ PackageName = "Microsoft.ZuneMusic"; DisplayName = "Groove Music" },
    @{ PackageName = "Microsoft.ZuneVideo"; DisplayName = "Movies & TV" },
    @{ PackageName = "Clipchamp.Clipchamp"; DisplayName = "Clipchamp" },
    @{ PackageName = "Microsoft.PowerAutomateDesktop"; DisplayName = "Power Automate" },
    @{ PackageName = "MicrosoftCorporationII.QuickAssist"; DisplayName = "Quick Assist" },
    @{ PackageName = "Microsoft.WindowsCommunicationsApps"; DisplayName = "Mail and Calendar" },
    @{ PackageName = "MicrosoftTeams"; DisplayName = "Microsoft Teams" },
    @{ PackageName = "MSTeams"; DisplayName = "Microsoft Teams (New)" },
    @{ PackageName = "Microsoft.OutlookForWindows"; DisplayName = "New Outlook" },
    @{ PackageName = "Microsoft.DevHome"; DisplayName = "Dev Home" },
    @{ PackageName = "Microsoft.Todos"; DisplayName = "Microsoft To Do" },
    @{ PackageName = "Microsoft.WindowsAlarms"; DisplayName = "Alarms & Clock" },
    @{ PackageName = "Microsoft.WindowsSoundRecorder"; DisplayName = "Voice Recorder" }
)

$Script:ThirdPartyBloatware = @(
    @{ PackageName = "SpotifyAB.SpotifyMusic"; DisplayName = "Spotify" },
    @{ PackageName = "Disney.37853FC22B2CE"; DisplayName = "Disney+" },
    @{ PackageName = "AmazonVideo.PrimeVideo"; DisplayName = "Prime Video" },
    @{ PackageName = "king.com.BubbleWitch3Saga"; DisplayName = "Bubble Witch 3 Saga" },
    @{ PackageName = "king.com.CandyCrushSaga"; DisplayName = "Candy Crush Saga" },
    @{ PackageName = "king.com.CandyCrushSodaSaga"; DisplayName = "Candy Crush Soda Saga" },
    @{ PackageName = "king.com.CandyCrushFriends"; DisplayName = "Candy Crush Friends" },
    @{ PackageName = "king.com.FarmHeroesSaga"; DisplayName = "Farm Heroes Saga" },
    @{ PackageName = "Facebook.Instagram"; DisplayName = "Instagram" },
    @{ PackageName = "Facebook.Facebook"; DisplayName = "Facebook" },
    @{ PackageName = "ByteDancePte.Ltd.TikTok"; DisplayName = "TikTok" },
    @{ PackageName = "5A894077.McAfeeSecurity"; DisplayName = "McAfee Security" },
    @{ PackageName = "4DF9E0F8.Netflix"; DisplayName = "Netflix" },
    @{ PackageName = "CAF9E577.Plex"; DisplayName = "Plex" },
    @{ PackageName = "NORDVPN.NORDVPN"; DisplayName = "NordVPN" },
    @{ PackageName = "A278AB0D.DisneyMagicKingdoms"; DisplayName = "Disney Magic Kingdoms" },
    @{ PackageName = "A278AB0D.MarchofEmpires"; DisplayName = "March of Empires" },
    @{ PackageName = "Zynga.FarmVille2CountryEscape"; DisplayName = "FarmVille 2" },
    @{ PackageName = "GAMELOFTSA.Asphalt8Airborne"; DisplayName = "Asphalt 8" },
    @{ PackageName = "flaregamesGmbH.RoyalRevolt2"; DisplayName = "Royal Revolt 2" },
    @{ PackageName = "Playtika.CaesarsSlotsFreeCasino"; DisplayName = "Caesars Slots" },
    @{ PackageName = "D5EA27B7.Duolingo-LearnLanguagesforFree"; DisplayName = "Duolingo" },
    @{ PackageName = "AdobeSystemsIncorporated.AdobePhotoshopExpress"; DisplayName = "Adobe Photoshop Express" },
    @{ PackageName = "WinZipComputing.WinZipUniversal"; DisplayName = "WinZip" },
    @{ PackageName = "2FE3CB00.PicsArt-PhotoStudio"; DisplayName = "PicsArt" },
    @{ PackageName = "7EE7776C.LinkedInforWindows"; DisplayName = "LinkedIn" },
    @{ PackageName = "Drawboard.DrawboardPDF"; DisplayName = "Drawboard PDF" }
)

# Apps to never remove
$Script:Whitelist = @(
    "Microsoft.WindowsStore",
    "Microsoft.WindowsTerminal",
    "Microsoft.WindowsCalculator",
    "Microsoft.Windows.Photos",
    "Microsoft.WindowsNotepad",
    "Microsoft.ScreenSketch",
    "Microsoft.WindowsCamera",
    "Microsoft.Paint",
    "Microsoft.MSPaint",
    "Microsoft.Xbox*"  # Keep Xbox for gaming
)

function Get-InstalledBloatware {
    [CmdletBinding()]
    param(
        [ValidateSet("Microsoft", "ThirdParty", "All")]
        [string]$Category = "All"
    )

    $bloatwareList = @()

    if ($Category -eq "Microsoft" -or $Category -eq "All") {
        $bloatwareList += $Script:MicrosoftBloatware
    }

    if ($Category -eq "ThirdParty" -or $Category -eq "All") {
        $bloatwareList += $Script:ThirdPartyBloatware
    }

    $installedBloatware = @()
    $allPackages = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue

    foreach ($bloat in $bloatwareList) {
        $match = $allPackages | Where-Object { $_.Name -like "*$($bloat.PackageName)*" }
        if ($match) {
            $installedBloatware += @{
                PackageName = $match.Name
                DisplayName = $bloat.DisplayName
                Version = $match.Version
                PackageFullName = $match.PackageFullName
            }
        }
    }

    return $installedBloatware
}

function Test-AppWhitelisted {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$PackageName
    )

    foreach ($pattern in $Script:Whitelist) {
        if ($PackageName -like $pattern) {
            return $true
        }
    }
    return $false
}

function Remove-BloatwareApp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$PackageName,

        [string]$DisplayName = $PackageName,

        [switch]$RemoveProvisioned
    )

    # Check whitelist
    if (Test-AppWhitelisted -PackageName $PackageName) {
        Write-Log "Skipping whitelisted app: $DisplayName" -Level Warning
        return @{ Success = $false; Status = "Whitelisted" }
    }

    # Find package
    $package = Get-AppxPackage -Name "*$PackageName*" -AllUsers -ErrorAction SilentlyContinue

    if (-not $package) {
        Write-Log "App not found: $DisplayName" -Level Warning
        return @{ Success = $false; Status = "NotFound" }
    }

    # Remove app
    $result = Invoke-DebloatAction -Description "Remove app: $DisplayName" -Action {
        Get-AppxPackage -Name "*$PackageName*" -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction Stop
    }

    if ($result.Success -and -not $result.DryRun) {
        Add-RemovedApp -PackageName $PackageName -DisplayName $DisplayName
    }

    # Remove provisioned package (prevents reinstall for new users)
    if ($RemoveProvisioned -and $result.Success) {
        $provisioned = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
            Where-Object DisplayName -like "*$PackageName*"

        if ($provisioned) {
            Invoke-DebloatAction -Description "Remove provisioned: $DisplayName" -Action {
                $provisioned | Remove-AppxProvisionedPackage -Online -ErrorAction Stop
            }
        }
    }

    return @{ Success = $result.Success; Status = if ($result.Success) { "Removed" } else { "Failed" } }
}

function Remove-MicrosoftBloatware {
    [CmdletBinding()]
    param(
        [switch]$RemoveProvisioned
    )

    Write-Log "Removing Microsoft bloatware..."

    $results = @{
        Removed = 0
        Failed = 0
        NotFound = 0
        Skipped = 0
    }

    $total = $Script:MicrosoftBloatware.Count
    $current = 0

    foreach ($app in $Script:MicrosoftBloatware) {
        $current++
        $percent = [math]::Round(($current / $total) * 100)
        Write-Progress -Activity "Removing Microsoft Bloatware" -Status $app.DisplayName -PercentComplete $percent

        $result = Remove-BloatwareApp -PackageName $app.PackageName -DisplayName $app.DisplayName -RemoveProvisioned:$RemoveProvisioned

        switch ($result.Status) {
            "Removed" { $results.Removed++ }
            "Failed" { $results.Failed++ }
            "NotFound" { $results.NotFound++ }
            "Whitelisted" { $results.Skipped++ }
        }
    }

    Write-Progress -Activity "Removing Microsoft Bloatware" -Completed

    Write-Log "Microsoft bloatware removal complete: $($results.Removed) removed, $($results.Failed) failed, $($results.NotFound) not found, $($results.Skipped) skipped" -Level Success
    return $results
}

function Remove-ThirdPartyBloatware {
    [CmdletBinding()]
    param(
        [switch]$RemoveProvisioned
    )

    Write-Log "Removing third-party bloatware..."

    $results = @{
        Removed = 0
        Failed = 0
        NotFound = 0
        Skipped = 0
    }

    $total = $Script:ThirdPartyBloatware.Count
    $current = 0

    foreach ($app in $Script:ThirdPartyBloatware) {
        $current++
        $percent = [math]::Round(($current / $total) * 100)
        Write-Progress -Activity "Removing Third-Party Bloatware" -Status $app.DisplayName -PercentComplete $percent

        $result = Remove-BloatwareApp -PackageName $app.PackageName -DisplayName $app.DisplayName -RemoveProvisioned:$RemoveProvisioned

        switch ($result.Status) {
            "Removed" { $results.Removed++ }
            "Failed" { $results.Failed++ }
            "NotFound" { $results.NotFound++ }
            "Whitelisted" { $results.Skipped++ }
        }
    }

    Write-Progress -Activity "Removing Third-Party Bloatware" -Completed

    Write-Log "Third-party bloatware removal complete: $($results.Removed) removed, $($results.Failed) failed, $($results.NotFound) not found" -Level Success
    return $results
}

function Remove-AllBloatware {
    [CmdletBinding()]
    param(
        [switch]$RemoveProvisioned
    )

    Write-Log "Removing all bloatware..."

    $msResults = Remove-MicrosoftBloatware -RemoveProvisioned:$RemoveProvisioned
    $tpResults = Remove-ThirdPartyBloatware -RemoveProvisioned:$RemoveProvisioned

    return @{
        Microsoft = $msResults
        ThirdParty = $tpResults
        TotalRemoved = $msResults.Removed + $tpResults.Removed
    }
}

function Show-InstalledBloatware {
    [CmdletBinding()]
    param()

    Write-Host ""
    Write-Host "Scanning for installed bloatware..." -ForegroundColor Yellow
    Write-Host ""

    $installed = Get-InstalledBloatware -Category All

    if ($installed.Count -eq 0) {
        Write-Host "No bloatware found! Your system is clean." -ForegroundColor Green
        return
    }

    Write-Host "Found $($installed.Count) bloatware apps:" -ForegroundColor Cyan
    Write-Host ""

    $index = 1
    foreach ($app in $installed) {
        $whitelisted = if (Test-AppWhitelisted -PackageName $app.PackageName) { " [WHITELISTED]" } else { "" }
        Write-Host "  [$index] $($app.DisplayName)$whitelisted" -ForegroundColor White
        Write-Host "      Package: $($app.PackageName)" -ForegroundColor Gray
        $index++
    }

    Write-Host ""
}

# Export functions
Export-ModuleMember -Function @(
    'Get-InstalledBloatware',
    'Remove-BloatwareApp',
    'Remove-MicrosoftBloatware',
    'Remove-ThirdPartyBloatware',
    'Remove-AllBloatware',
    'Show-InstalledBloatware',
    'Test-AppWhitelisted'
)
