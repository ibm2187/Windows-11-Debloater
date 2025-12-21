#Requires -Version 5.1
<#
.SYNOPSIS
    Telemetry and privacy control functions for Windows 11 Debloat Script
.DESCRIPTION
    Provides functions to disable telemetry, advertising, activity history, and location tracking
#>

function Set-RegistryValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        $Value,

        [Parameter(Mandatory)]
        [ValidateSet("String", "DWord", "QWord", "Binary", "MultiString", "ExpandString")]
        [string]$Type,

        [string]$Description = ""
    )

    # Get original value for revert capability
    $originalValue = $null
    if (Test-Path $Path) {
        $existing = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
        if ($existing) {
            $originalValue = $existing.$Name
        }
    }

    $desc = if ($Description) { $Description } else { "Set $Path\$Name = $Value" }

    $result = Invoke-DebloatAction -Description $desc -Action {
        # Create path if it doesn't exist
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }

        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force
    }

    # Track change for revert script
    if ($result.Success -and -not $result.DryRun) {
        Add-RegistryChange -Path $Path -Name $Name -Value $Value -Type $Type -OriginalValue $originalValue -Description $desc
    }

    return $result
}

function Disable-Telemetry {
    [CmdletBinding()]
    param()

    Write-Log "Disabling Windows telemetry..."

    # Main telemetry settings
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" `
        -Name "AllowTelemetry" -Value 0 -Type "DWord" `
        -Description "Disable diagnostic data collection"

    Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" `
        -Name "AllowDeviceNameInTelemetry" -Value 0 -Type "DWord" `
        -Description "Prevent device name in telemetry"

    Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" `
        -Name "DoNotShowFeedbackNotifications" -Value 1 -Type "DWord" `
        -Description "Disable feedback notifications"

    Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" `
        -Name "LimitDiagnosticLogCollection" -Value 1 -Type "DWord" `
        -Description "Limit diagnostic log collection"

    Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" `
        -Name "DisableOneSettingsDownloads" -Value 1 -Type "DWord" `
        -Description "Disable OneSettings downloads"

    # Secondary telemetry location
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" `
        -Name "AllowTelemetry" -Value 0 -Type "DWord" `
        -Description "Disable telemetry (secondary)"

    Write-Log "Telemetry settings applied" -Level Success
}

function Disable-AdvertisingId {
    [CmdletBinding()]
    param()

    Write-Log "Disabling advertising ID..."

    # System-wide advertising ID
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" `
        -Name "DisabledByGroupPolicy" -Value 1 -Type "DWord" `
        -Description "Disable advertising ID (system-wide)"

    # Per-user advertising ID
    Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" `
        -Name "Enabled" -Value 0 -Type "DWord" `
        -Description "Disable advertising ID (current user)"

    # Disable suggested content
    Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
        -Name "SubscribedContent-338388Enabled" -Value 0 -Type "DWord" `
        -Description "Disable suggested content in Settings"

    Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
        -Name "SubscribedContent-338389Enabled" -Value 0 -Type "DWord" `
        -Description "Disable Windows tips"

    Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
        -Name "SubscribedContent-310093Enabled" -Value 0 -Type "DWord" `
        -Description "Disable suggested content in Settings app"

    Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
        -Name "SubscribedContent-338393Enabled" -Value 0 -Type "DWord" `
        -Description "Disable suggested content in Start menu"

    Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
        -Name "SubscribedContent-353694Enabled" -Value 0 -Type "DWord" `
        -Description "Disable suggested content in Settings"

    Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
        -Name "SubscribedContent-353696Enabled" -Value 0 -Type "DWord" `
        -Description "Disable suggested content in Settings"

    # Disable silent app installation
    Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
        -Name "SilentInstalledAppsEnabled" -Value 0 -Type "DWord" `
        -Description "Disable silent app installation"

    Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
        -Name "ContentDeliveryAllowed" -Value 0 -Type "DWord" `
        -Description "Disable content delivery"

    Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
        -Name "OemPreInstalledAppsEnabled" -Value 0 -Type "DWord" `
        -Description "Disable OEM pre-installed apps"

    Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
        -Name "PreInstalledAppsEnabled" -Value 0 -Type "DWord" `
        -Description "Disable pre-installed apps"

    Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
        -Name "PreInstalledAppsEverEnabled" -Value 0 -Type "DWord" `
        -Description "Disable pre-installed apps ever"

    Write-Log "Advertising ID and suggestions disabled" -Level Success
}

function Disable-ActivityHistory {
    [CmdletBinding()]
    param()

    Write-Log "Disabling activity history..."

    Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" `
        -Name "EnableActivityFeed" -Value 0 -Type "DWord" `
        -Description "Disable activity feed"

    Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" `
        -Name "PublishUserActivities" -Value 0 -Type "DWord" `
        -Description "Disable publishing user activities"

    Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" `
        -Name "UploadUserActivities" -Value 0 -Type "DWord" `
        -Description "Disable uploading user activities"

    Write-Log "Activity history disabled" -Level Success
}

function Disable-LocationTracking {
    [CmdletBinding()]
    param()

    Write-Log "Disabling location tracking..."

    Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" `
        -Name "DisableLocation" -Value 1 -Type "DWord" `
        -Description "Disable location services"

    Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" `
        -Name "DisableWindowsLocationProvider" -Value 1 -Type "DWord" `
        -Description "Disable Windows location provider"

    Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" `
        -Name "DisableLocationScripting" -Value 1 -Type "DWord" `
        -Description "Disable location scripting"

    Write-Log "Location tracking disabled" -Level Success
}

function Disable-ErrorReporting {
    [CmdletBinding()]
    param()

    Write-Log "Disabling Windows Error Reporting..."

    Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" `
        -Name "Disabled" -Value 1 -Type "DWord" `
        -Description "Disable Windows Error Reporting"

    Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" `
        -Name "DontSendAdditionalData" -Value 1 -Type "DWord" `
        -Description "Don't send additional error data"

    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" `
        -Name "Disabled" -Value 1 -Type "DWord" `
        -Description "Disable WER (secondary)"

    Write-Log "Error reporting disabled" -Level Success
}

function Disable-AppTracking {
    [CmdletBinding()]
    param()

    Write-Log "Disabling app launch tracking..."

    Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
        -Name "Start_TrackProgs" -Value 0 -Type "DWord" `
        -Description "Disable app launch tracking for Start menu"

    Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
        -Name "Start_TrackDocs" -Value 0 -Type "DWord" `
        -Description "Disable recent documents tracking"

    # Disable personalization data collection
    Set-RegistryValue -Path "HKCU:\Software\Microsoft\Personalization\Settings" `
        -Name "AcceptedPrivacyPolicy" -Value 0 -Type "DWord" `
        -Description "Disable personalization data collection"

    Set-RegistryValue -Path "HKCU:\Software\Microsoft\InputPersonalization" `
        -Name "RestrictImplicitTextCollection" -Value 1 -Type "DWord" `
        -Description "Restrict implicit text collection"

    Set-RegistryValue -Path "HKCU:\Software\Microsoft\InputPersonalization" `
        -Name "RestrictImplicitInkCollection" -Value 1 -Type "DWord" `
        -Description "Restrict implicit ink collection"

    Set-RegistryValue -Path "HKCU:\Software\Microsoft\InputPersonalization\TrainedDataStore" `
        -Name "HarvestContacts" -Value 0 -Type "DWord" `
        -Description "Disable contact harvesting"

    Write-Log "App tracking disabled" -Level Success
}

function Disable-WebSearch {
    [CmdletBinding()]
    param()

    Write-Log "Disabling web search in Start menu..."

    Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" `
        -Name "DisableWebSearch" -Value 1 -Type "DWord" `
        -Description "Disable web search in Start menu"

    Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" `
        -Name "ConnectedSearchUseWeb" -Value 0 -Type "DWord" `
        -Description "Disable web results in search"

    Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" `
        -Name "BingSearchEnabled" -Value 0 -Type "DWord" `
        -Description "Disable Bing search"

    Set-RegistryValue -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" `
        -Name "DisableSearchBoxSuggestions" -Value 1 -Type "DWord" `
        -Description "Disable search box suggestions"

    Write-Log "Web search disabled" -Level Success
}

function Disable-Cortana {
    [CmdletBinding()]
    param()

    Write-Log "Disabling Cortana..."

    Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" `
        -Name "AllowCortana" -Value 0 -Type "DWord" `
        -Description "Disable Cortana"

    Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" `
        -Name "AllowCortanaAboveLock" -Value 0 -Type "DWord" `
        -Description "Disable Cortana above lock screen"

    Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" `
        -Name "AllowSearchToUseLocation" -Value 0 -Type "DWord" `
        -Description "Disable search location access"

    Write-Log "Cortana disabled" -Level Success
}

function Disable-AllTelemetry {
    [CmdletBinding()]
    param()

    Write-Log "Applying all privacy settings..."

    Disable-Telemetry
    Disable-AdvertisingId
    Disable-ActivityHistory
    Disable-LocationTracking
    Disable-ErrorReporting
    Disable-AppTracking
    Disable-WebSearch
    Disable-Cortana

    Write-Log "All telemetry and privacy settings applied" -Level Success
}

# ============================================
# WINDOWS FEATURES
# ============================================

function Disable-Widgets {
    [CmdletBinding()]
    param()

    Write-Log "Disabling Widgets..."

    Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
        -Name "TaskbarDa" -Value 0 -Type "DWord" `
        -Description "Disable Widgets on taskbar"

    Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" `
        -Name "AllowNewsAndInterests" -Value 0 -Type "DWord" `
        -Description "Disable Widgets (policy)"

    Write-Log "Widgets disabled" -Level Success
}

function Disable-Copilot {
    [CmdletBinding()]
    param()

    Write-Log "Disabling Windows Copilot..."

    Set-RegistryValue -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" `
        -Name "TurnOffWindowsCopilot" -Value 1 -Type "DWord" `
        -Description "Disable Windows Copilot"

    Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" `
        -Name "TurnOffWindowsCopilot" -Value 1 -Type "DWord" `
        -Description "Disable Windows Copilot (system)"

    Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
        -Name "ShowCopilotButton" -Value 0 -Type "DWord" `
        -Description "Hide Copilot button"

    Write-Log "Windows Copilot disabled" -Level Success
}

function Disable-ChatIcon {
    [CmdletBinding()]
    param()

    Write-Log "Disabling Chat icon..."

    Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
        -Name "TaskbarMn" -Value 0 -Type "DWord" `
        -Description "Disable Chat icon on taskbar"

    Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Chat" `
        -Name "ChatIcon" -Value 3 -Type "DWord" `
        -Description "Hide Chat icon (policy)"

    Write-Log "Chat icon disabled" -Level Success
}

function Disable-NewsFeed {
    [CmdletBinding()]
    param()

    Write-Log "Disabling News feed..."

    Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" `
        -Name "EnableFeeds" -Value 0 -Type "DWord" `
        -Description "Disable News and Interests"

    Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds" `
        -Name "ShellFeedsTaskbarViewMode" -Value 2 -Type "DWord" `
        -Description "Hide News feed from taskbar"

    Write-Log "News feed disabled" -Level Success
}

function Disable-Recall {
    [CmdletBinding()]
    param()

    Write-Log "Disabling Windows Recall..."

    Set-RegistryValue -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsAI" `
        -Name "DisableAIDataAnalysis" -Value 1 -Type "DWord" `
        -Description "Disable Windows Recall"

    Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" `
        -Name "DisableAIDataAnalysis" -Value 1 -Type "DWord" `
        -Description "Disable Windows Recall (system)"

    Write-Log "Windows Recall disabled" -Level Success
}

# ============================================
# UI/UX TWEAKS
# ============================================

function Disable-LockScreenAds {
    [CmdletBinding()]
    param()

    Write-Log "Disabling lock screen ads..."

    Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
        -Name "RotatingLockScreenOverlayEnabled" -Value 0 -Type "DWord" `
        -Description "Disable lock screen Spotlight ads"

    Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
        -Name "RotatingLockScreenEnabled" -Value 0 -Type "DWord" `
        -Description "Disable rotating lock screen"

    Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
        -Name "SubscribedContent-338387Enabled" -Value 0 -Type "DWord" `
        -Description "Disable lock screen suggestions"

    Write-Log "Lock screen ads disabled" -Level Success
}

function Disable-StartSuggestions {
    [CmdletBinding()]
    param()

    Write-Log "Disabling Start menu suggestions..."

    Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
        -Name "SystemPaneSuggestionsEnabled" -Value 0 -Type "DWord" `
        -Description "Disable Start menu suggestions"

    Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
        -Name "SubscribedContent-338388Enabled" -Value 0 -Type "DWord" `
        -Description "Disable suggested content"

    Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
        -Name "Start_IrisRecommendations" -Value 0 -Type "DWord" `
        -Description "Disable Start recommendations"

    Write-Log "Start menu suggestions disabled" -Level Success
}

function Disable-Animations {
    [CmdletBinding()]
    param()

    Write-Log "Disabling UI animations..."

    Set-RegistryValue -Path "HKCU:\Control Panel\Desktop" `
        -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) -Type "Binary" `
        -Description "Disable animations"

    Set-RegistryValue -Path "HKCU:\Control Panel\Desktop\WindowMetrics" `
        -Name "MinAnimate" -Value "0" -Type "String" `
        -Description "Disable minimize/maximize animations"

    Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
        -Name "TaskbarAnimations" -Value 0 -Type "DWord" `
        -Description "Disable taskbar animations"

    Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" `
        -Name "VisualFXSetting" -Value 2 -Type "DWord" `
        -Description "Set visual effects to performance"

    Write-Log "UI animations disabled" -Level Success
}

function Disable-Transparency {
    [CmdletBinding()]
    param()

    Write-Log "Disabling transparency effects..."

    Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" `
        -Name "EnableTransparency" -Value 0 -Type "DWord" `
        -Description "Disable transparency effects"

    Write-Log "Transparency effects disabled" -Level Success
}

function Enable-ClassicContextMenu {
    [CmdletBinding()]
    param()

    Write-Log "Enabling classic context menu..."

    # Create the registry key to restore Windows 10 style context menu
    $regPath = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"

    Invoke-DebloatAction -Description "Enable classic context menu" -Action {
        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }
        Set-ItemProperty -Path $regPath -Name "(Default)" -Value "" -Force
    }

    Write-Log "Classic context menu enabled (restart Explorer to apply)" -Level Success
}

# ============================================
# PERFORMANCE TWEAKS
# ============================================

function Disable-BackgroundApps {
    [CmdletBinding()]
    param()

    Write-Log "Disabling background apps..."

    Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" `
        -Name "GlobalUserDisabled" -Value 1 -Type "DWord" `
        -Description "Disable background apps globally"

    Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" `
        -Name "BackgroundAppGlobalToggle" -Value 0 -Type "DWord" `
        -Description "Disable background apps toggle"

    Write-Log "Background apps disabled" -Level Success
}

function Disable-StartupDelay {
    [CmdletBinding()]
    param()

    Write-Log "Disabling startup delay..."

    Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" `
        -Name "StartupDelayInMSec" -Value 0 -Type "DWord" `
        -Description "Remove startup delay"

    Write-Log "Startup delay disabled" -Level Success
}

function Disable-GameDVR {
    [CmdletBinding()]
    param()

    Write-Log "Disabling Game DVR..."

    Set-RegistryValue -Path "HKCU:\System\GameConfigStore" `
        -Name "GameDVR_Enabled" -Value 0 -Type "DWord" `
        -Description "Disable Game DVR"

    Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" `
        -Name "AppCaptureEnabled" -Value 0 -Type "DWord" `
        -Description "Disable app capture"

    Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" `
        -Name "AllowGameDVR" -Value 0 -Type "DWord" `
        -Description "Disable Game DVR (policy)"

    Write-Log "Game DVR disabled" -Level Success
}

# Export functions
Export-ModuleMember -Function @(
    'Set-RegistryValue',
    'Disable-Telemetry',
    'Disable-AdvertisingId',
    'Disable-ActivityHistory',
    'Disable-LocationTracking',
    'Disable-ErrorReporting',
    'Disable-AppTracking',
    'Disable-WebSearch',
    'Disable-Cortana',
    'Disable-AllTelemetry',
    'Disable-Widgets',
    'Disable-Copilot',
    'Disable-ChatIcon',
    'Disable-NewsFeed',
    'Disable-Recall',
    'Disable-LockScreenAds',
    'Disable-StartSuggestions',
    'Disable-Animations',
    'Disable-Transparency',
    'Enable-ClassicContextMenu',
    'Disable-BackgroundApps',
    'Disable-StartupDelay',
    'Disable-GameDVR'
)
