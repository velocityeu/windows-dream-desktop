#Requires -RunAsAdministrator
<#
.SYNOPSIS
    OOBE and Wizard Bypass Module for Windows Dream Desktop Setup
.DESCRIPTION
    Disables Windows OOBE prompts, "Let's finish setting up" reminders,
    Office first run wizards, Teams auto-start, and OneDrive popups.
#>

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $(switch($Level) { "ERROR" { "Red" } "WARN" { "Yellow" } "SUCCESS" { "Green" } default { "White" } })
}

function Get-WindowsEdition {
    $edition = (Get-WmiObject Win32_OperatingSystem).Caption
    $build = [Environment]::OSVersion.Version.Build
    return @{
        Caption = $edition
        IsEnterprise = $edition -match "Enterprise|Education"
        IsPro = $edition -match "Pro"
        IsWin11 = $build -ge 22000
        IsWin10 = $build -lt 22000 -and $build -ge 10240
        Build = $build
    }
}

function Set-RegistryValue {
    param(
        [string]$Path,
        [string]$Name,
        [object]$Value,
        [string]$Type = "DWord"
    )
    try {
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force
        return $true
    }
    catch {
        Write-Log "Failed to set $Path\$Name : $_" -Level "ERROR"
        return $false
    }
}

function Disable-FinishSettingUpReminder {
    <#
    .SYNOPSIS
        Disables the "Let's finish setting up your device" reminder
    #>
    Write-Log "Disabling 'Let's finish setting up' reminder..."

    $success = $true

    # Primary method - UserProfileEngagement
    $success = $success -and (Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement" -Name "ScoobeSystemSettingEnabled" -Value 0)

    # Secondary method - ContentDeliveryManager
    $success = $success -and (Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-310093Enabled" -Value 0)

    # Disable additional finish setup prompts
    $success = $success -and (Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338393Enabled" -Value 0)
    $success = $success -and (Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-353698Enabled" -Value 0)

    if ($success) {
        Write-Log "Successfully disabled 'Let's finish setting up' reminder" -Level "SUCCESS"
    }
    return $success
}

function Disable-ConsumerExperience {
    <#
    .SYNOPSIS
        Disables Microsoft Consumer Experiences (sponsored apps, suggestions)
        Note: Only fully effective on Enterprise/Education editions
    #>
    Write-Log "Disabling Microsoft Consumer Experience..."

    $edition = Get-WindowsEdition
    $success = $true

    # This setting only works on Enterprise/Education
    if ($edition.IsEnterprise) {
        $success = $success -and (Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1)
        Write-Log "Consumer Experience disabled (Enterprise/Education edition)" -Level "SUCCESS"
    }
    else {
        Write-Log "Consumer Experience policy only fully supported on Enterprise/Education editions" -Level "WARN"
    }

    # These work on all editions
    $success = $success -and (Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "ContentDeliveryAllowed" -Value 0)
    $success = $success -and (Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "OemPreInstalledAppsEnabled" -Value 0)
    $success = $success -and (Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "PreInstalledAppsEnabled" -Value 0)
    $success = $success -and (Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "PreInstalledAppsEverEnabled" -Value 0)
    $success = $success -and (Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SilentInstalledAppsEnabled" -Value 0)
    $success = $success -and (Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SystemPaneSuggestionsEnabled" -Value 0)

    return $success
}

function Disable-TipsAndSuggestions {
    <#
    .SYNOPSIS
        Disables Windows tips, tricks, and suggestions notifications
    #>
    Write-Log "Disabling tips and suggestions..."

    $success = $true

    # Disable tips in Settings app
    $success = $success -and (Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SoftLandingEnabled" -Value 0)

    # Disable suggestion notifications
    $success = $success -and (Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338389Enabled" -Value 0)

    # Disable "Get tips and suggestions when using Windows"
    $success = $success -and (Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338388Enabled" -Value 0)

    # Disable Start menu suggestions
    $success = $success -and (Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338387Enabled" -Value 0)

    # Disable lock screen tips
    $success = $success -and (Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "RotatingLockScreenEnabled" -Value 0)
    $success = $success -and (Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "RotatingLockScreenOverlayEnabled" -Value 0)

    if ($success) {
        Write-Log "Tips and suggestions disabled" -Level "SUCCESS"
    }
    return $success
}

function Disable-OfficeFirstRun {
    <#
    .SYNOPSIS
        Disables Microsoft Office/365 first run wizard and opt-in screens
    #>
    Write-Log "Disabling Office first run wizard..."

    $success = $true

    # Office 2016/2019/365 (version 16.0)
    $success = $success -and (Set-RegistryValue -Path "HKCU:\Software\Policies\Microsoft\Office\16.0\Common\General" -Name "ShownFirstRunOptin" -Value 1)
    $success = $success -and (Set-RegistryValue -Path "HKCU:\Software\Policies\Microsoft\Office\16.0\Common\General" -Name "DisableFirstRun" -Value 1)
    $success = $success -and (Set-RegistryValue -Path "HKCU:\Software\Microsoft\Office\16.0\Common\General" -Name "ShownFirstRunOptin" -Value 1)

    # Disable Office What's New dialogs
    $success = $success -and (Set-RegistryValue -Path "HKCU:\Software\Policies\Microsoft\Office\16.0\Common" -Name "DisableShowWhatsNew" -Value 1)

    if ($success) {
        Write-Log "Office first run wizard disabled" -Level "SUCCESS"
    }
    return $success
}

function Disable-OutlookSimplifiedSetup {
    <#
    .SYNOPSIS
        Disables Outlook's simplified account creation wizard
    #>
    Write-Log "Disabling Outlook simplified account setup..."

    $success = $true

    # Disable simplified account creation
    $success = $success -and (Set-RegistryValue -Path "HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook\Setup" -Name "DisableOffice365SimplifiedAccountCreation" -Value 1)
    $success = $success -and (Set-RegistryValue -Path "HKCU:\Software\Microsoft\Office\16.0\Outlook\Setup" -Name "DisableOffice365SimplifiedAccountCreation" -Value 1)

    if ($success) {
        Write-Log "Outlook simplified setup disabled" -Level "SUCCESS"
    }
    return $success
}

function Disable-TeamsAutoStart {
    <#
    .SYNOPSIS
        Prevents Microsoft Teams from auto-starting and showing first run popup
    #>
    Write-Log "Disabling Teams auto-start and popup..."

    $success = $true

    # Prevent first launch after install (policy)
    $success = $success -and (Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Office\16.0\Teams" -Name "PreventFirstLaunchAfterInstall" -Value 1)

    # Prevent auto-start for new users
    $success = $success -and (Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "DisableAutomaticRestartSignOn" -Value 1)

    # Remove from current user startup
    $teamsStartupKeys = @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    )

    foreach ($key in $teamsStartupKeys) {
        if (Test-Path $key) {
            $runKeys = Get-ItemProperty -Path $key -ErrorAction SilentlyContinue
            foreach ($prop in $runKeys.PSObject.Properties) {
                if ($prop.Name -match "Teams|com.squirrel") {
                    try {
                        Remove-ItemProperty -Path $key -Name $prop.Name -Force -ErrorAction SilentlyContinue
                        Write-Log "Removed Teams from startup: $($prop.Name)" -Level "SUCCESS"
                    }
                    catch {}
                }
            }
        }
    }

    if ($success) {
        Write-Log "Teams auto-start disabled" -Level "SUCCESS"
    }
    return $success
}

function Disable-OneDrivePopup {
    <#
    .SYNOPSIS
        Disables OneDrive setup popup and optionally removes from startup
    #>
    param([switch]$RemoveFromStartup = $true)

    Write-Log "Disabling OneDrive setup popup..."

    $success = $true

    # Disable OneDrive via Group Policy
    $success = $success -and (Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Name "DisableFileSyncNGSC" -Value 1)

    # Prevent OneDrive from running at startup for current user
    if ($RemoveFromStartup) {
        try {
            Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "OneDrive" -Force -ErrorAction SilentlyContinue
            Write-Log "Removed OneDrive from startup" -Level "SUCCESS"
        }
        catch {}
    }

    # Disable OneDrive toast notifications about backup
    $success = $success -and (Set-RegistryValue -Path "HKCU:\Software\Microsoft\OneDrive" -Name "DisablePersonalSync" -Value 1)

    if ($success) {
        Write-Log "OneDrive popup disabled" -Level "SUCCESS"
    }
    return $success
}

function Disable-WindowsWelcome {
    <#
    .SYNOPSIS
        Disables Windows Welcome Experience after updates
    #>
    Write-Log "Disabling Windows Welcome Experience..."

    $success = $true

    $success = $success -and (Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-310093Enabled" -Value 0)
    $success = $success -and (Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338380Enabled" -Value 0)

    if ($success) {
        Write-Log "Windows Welcome Experience disabled" -Level "SUCCESS"
    }
    return $success
}

function Invoke-OOBEBypass {
    <#
    .SYNOPSIS
        Main function to apply all OOBE bypass settings
    #>
    param(
        [switch]$DisableOffice = $true,
        [switch]$DisableTeams = $true,
        [switch]$DisableOneDrive = $true
    )

    Write-Log "========================================" -Level "INFO"
    Write-Log "Starting OOBE Bypass Configuration" -Level "INFO"
    Write-Log "========================================" -Level "INFO"

    $edition = Get-WindowsEdition
    Write-Log "Detected: $($edition.Caption) (Build $($edition.Build))"

    $results = @{
        FinishSetup = Disable-FinishSettingUpReminder
        ConsumerExp = Disable-ConsumerExperience
        Tips = Disable-TipsAndSuggestions
        Welcome = Disable-WindowsWelcome
    }

    if ($DisableOffice) {
        $results.Office = Disable-OfficeFirstRun
        $results.Outlook = Disable-OutlookSimplifiedSetup
    }

    if ($DisableTeams) {
        $results.Teams = Disable-TeamsAutoStart
    }

    if ($DisableOneDrive) {
        $results.OneDrive = Disable-OneDrivePopup
    }

    $successCount = ($results.Values | Where-Object { $_ -eq $true }).Count
    $totalCount = $results.Count

    Write-Log "========================================" -Level "INFO"
    Write-Log "OOBE Bypass Complete: $successCount/$totalCount successful" -Level $(if ($successCount -eq $totalCount) { "SUCCESS" } else { "WARN" })
    Write-Log "========================================" -Level "INFO"

    return $results
}

# Export functions
Export-ModuleMember -Function @(
    'Get-WindowsEdition',
    'Set-RegistryValue',
    'Disable-FinishSettingUpReminder',
    'Disable-ConsumerExperience',
    'Disable-TipsAndSuggestions',
    'Disable-OfficeFirstRun',
    'Disable-OutlookSimplifiedSetup',
    'Disable-TeamsAutoStart',
    'Disable-OneDrivePopup',
    'Disable-WindowsWelcome',
    'Invoke-OOBEBypass'
)
