#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Privacy and Telemetry Module for Windows Dream Desktop Setup
.DESCRIPTION
    Configures Windows privacy settings, disables telemetry, and removes
    AI features like Copilot and Windows Recall.
#>

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $(switch($Level) { "ERROR" { "Red" } "WARN" { "Yellow" } "SUCCESS" { "Green" } default { "White" } })
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

function Get-WindowsEdition {
    $edition = (Get-WmiObject Win32_OperatingSystem).Caption
    $build = [Environment]::OSVersion.Version.Build
    return @{
        Caption = $edition
        IsEnterprise = $edition -match "Enterprise|Education"
        IsPro = $edition -match "Pro"
        IsWin11 = $build -ge 22000
        Build = $build
    }
}

function Disable-Telemetry {
    <#
    .SYNOPSIS
        Disables Windows telemetry to the maximum extent allowed by edition
    #>
    Write-Log "Configuring telemetry settings..."

    $edition = Get-WindowsEdition
    $success = $true

    # Telemetry level: 0=Security (Enterprise only), 1=Basic (minimum for Pro/Home)
    $telemetryLevel = if ($edition.IsEnterprise) { 0 } else { 1 }

    Write-Log "Setting telemetry level to $telemetryLevel (Edition: $($edition.Caption))"

    # Set telemetry level via policy
    $success = $success -and (Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value $telemetryLevel)
    $success = $success -and (Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Value $telemetryLevel)

    # Disable telemetry components
    $success = $success -and (Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "DoNotShowFeedbackNotifications" -Value 1)
    $success = $success -and (Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "DisableTelemetryOptInChangeNotification" -Value 1)

    # Disable CEIP (Customer Experience Improvement Program)
    $success = $success -and (Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\SQMClient\Windows" -Name "CEIPEnable" -Value 0)

    # Disable Application Telemetry
    $success = $success -and (Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" -Name "AITEnable" -Value 0)

    # Disable Inventory Collector
    $success = $success -and (Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" -Name "DisableInventory" -Value 1)

    if ($success) {
        Write-Log "Telemetry configured (Level: $telemetryLevel)" -Level "SUCCESS"
    }
    return $success
}

function Disable-AdvertisingID {
    <#
    .SYNOPSIS
        Disables the Windows Advertising ID
    #>
    Write-Log "Disabling Advertising ID..."

    $success = $true

    # Disable Advertising ID for current user
    $success = $success -and (Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0)

    # Disable via policy (machine-wide)
    $success = $success -and (Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -Name "DisabledByGroupPolicy" -Value 1)

    if ($success) {
        Write-Log "Advertising ID disabled" -Level "SUCCESS"
    }
    return $success
}

function Disable-ActivityHistory {
    <#
    .SYNOPSIS
        Disables Windows Activity History and Timeline features
    #>
    Write-Log "Disabling Activity History..."

    $success = $true

    # Disable Activity Feed
    $success = $success -and (Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Value 0)

    # Disable publishing user activities
    $success = $success -and (Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Value 0)

    # Disable uploading user activities
    $success = $success -and (Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "UploadUserActivities" -Value 0)

    if ($success) {
        Write-Log "Activity History disabled" -Level "SUCCESS"
    }
    return $success
}

function Disable-Cortana {
    <#
    .SYNOPSIS
        Disables Cortana
    #>
    Write-Log "Disabling Cortana..."

    $success = $true

    # Disable Cortana
    $success = $success -and (Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0)
    $success = $success -and (Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortanaAboveLock" -Value 0)

    # Disable Cortana in search
    $success = $success -and (Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "DisableWebSearch" -Value 1)
    $success = $success -and (Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "ConnectedSearchUseWeb" -Value 0)

    # Disable Bing in Start Menu search
    $success = $success -and (Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value 0)
    $success = $success -and (Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "CortanaConsent" -Value 0)

    if ($success) {
        Write-Log "Cortana disabled" -Level "SUCCESS"
    }
    return $success
}

function Disable-Copilot {
    <#
    .SYNOPSIS
        Disables Microsoft Copilot (Windows 11 AI assistant)
    #>
    Write-Log "Disabling Windows Copilot..."

    $edition = Get-WindowsEdition
    if (-not $edition.IsWin11) {
        Write-Log "Copilot is Windows 11 only - skipping" -Level "INFO"
        return $true
    }

    $success = $true

    # Disable Windows Copilot
    $success = $success -and (Set-RegistryValue -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Value 1)
    $success = $success -and (Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Value 1)

    # Hide Copilot button from taskbar
    $success = $success -and (Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowCopilotButton" -Value 0)

    if ($success) {
        Write-Log "Windows Copilot disabled" -Level "SUCCESS"
    }
    return $success
}

function Disable-WindowsRecall {
    <#
    .SYNOPSIS
        Disables Windows Recall (AI screenshot memory feature in Windows 11 24H2+)
    #>
    Write-Log "Disabling Windows Recall..."

    $edition = Get-WindowsEdition
    if ($edition.Build -lt 26100) {
        Write-Log "Windows Recall is only available on Build 26100+ - skipping" -Level "INFO"
        return $true
    }

    $success = $true

    # Disable AI Data Analysis (Recall)
    $success = $success -and (Set-RegistryValue -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsAI" -Name "DisableAIDataAnalysis" -Value 1)
    $success = $success -and (Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" -Name "DisableAIDataAnalysis" -Value 1)

    # Disable Click to Do (another AI feature)
    $success = $success -and (Set-RegistryValue -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsAI" -Name "DisableClickToDo" -Value 1)

    if ($success) {
        Write-Log "Windows Recall disabled" -Level "SUCCESS"
    }
    return $success
}

function Disable-TailoredExperiences {
    <#
    .SYNOPSIS
        Disables tailored experiences based on diagnostic data
    #>
    Write-Log "Disabling Tailored Experiences..."

    $success = $true

    $success = $success -and (Set-RegistryValue -Path "HKCU:\Software\Policies\Microsoft\Windows\CloudContent" -Name "DisableTailoredExperiencesWithDiagnosticData" -Value 1)
    $success = $success -and (Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" -Name "TailoredExperiencesWithDiagnosticDataEnabled" -Value 0)

    if ($success) {
        Write-Log "Tailored Experiences disabled" -Level "SUCCESS"
    }
    return $success
}

function Disable-AppLaunchTracking {
    <#
    .SYNOPSIS
        Disables app launch tracking for Start menu improvement
    #>
    Write-Log "Disabling App Launch Tracking..."

    $success = Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackProgs" -Value 0

    if ($success) {
        Write-Log "App Launch Tracking disabled" -Level "SUCCESS"
    }
    return $success
}

function Disable-LocationTracking {
    <#
    .SYNOPSIS
        Disables location tracking
    #>
    Write-Log "Disabling Location Tracking..."

    $success = $true

    # Disable location for the device
    $success = $success -and (Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name "DisableLocation" -Value 1)

    # Disable location for the user
    $success = $success -and (Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -Value "Deny" -Type "String")

    if ($success) {
        Write-Log "Location Tracking disabled" -Level "SUCCESS"
    }
    return $success
}

function Disable-DiagnosticDataViewer {
    <#
    .SYNOPSIS
        Disables Diagnostic Data Viewer
    #>
    Write-Log "Disabling Diagnostic Data Viewer..."

    $success = Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "DisableDiagnosticDataViewer" -Value 1

    if ($success) {
        Write-Log "Diagnostic Data Viewer disabled" -Level "SUCCESS"
    }
    return $success
}

function Invoke-PrivacySetup {
    <#
    .SYNOPSIS
        Main function to apply all privacy settings
    #>
    param(
        [switch]$DisableTelemetry = $true,
        [switch]$DisableAds = $true,
        [switch]$DisableAI = $true,
        [switch]$DisableLocation = $false  # Off by default as it may break apps
    )

    Write-Log "========================================" -Level "INFO"
    Write-Log "Starting Privacy Configuration" -Level "INFO"
    Write-Log "========================================" -Level "INFO"

    $edition = Get-WindowsEdition
    Write-Log "Detected: $($edition.Caption) (Build $($edition.Build))"

    $results = @{}

    if ($DisableTelemetry) {
        $results.Telemetry = Disable-Telemetry
        $results.ActivityHistory = Disable-ActivityHistory
        $results.DiagnosticViewer = Disable-DiagnosticDataViewer
        $results.AppTracking = Disable-AppLaunchTracking
    }

    if ($DisableAds) {
        $results.AdvertisingID = Disable-AdvertisingID
        $results.TailoredExp = Disable-TailoredExperiences
    }

    if ($DisableAI) {
        $results.Cortana = Disable-Cortana
        $results.Copilot = Disable-Copilot
        $results.Recall = Disable-WindowsRecall
    }

    if ($DisableLocation) {
        $results.Location = Disable-LocationTracking
    }

    $successCount = ($results.Values | Where-Object { $_ -eq $true }).Count
    $totalCount = $results.Count

    Write-Log "========================================" -Level "INFO"
    Write-Log "Privacy Configuration Complete: $successCount/$totalCount successful" -Level $(if ($successCount -eq $totalCount) { "SUCCESS" } else { "WARN" })
    Write-Log "========================================" -Level "INFO"

    return $results
}

function Export-PrivacySettings {
    <#
    .SYNOPSIS
        Exports privacy settings as a .reg file
    #>
    param(
        [string]$OutputPath = ".\Config\PrivacySettings.reg"
    )

    Write-Log "Exporting privacy settings to: $OutputPath"

    $edition = Get-WindowsEdition
    $telemetryLevel = if ($edition.IsEnterprise) { 0 } else { 1 }

    $regContent = @"
Windows Registry Editor Version 5.00

; Windows Privacy Settings
; Generated by Windows Dream Desktop Setup

; Telemetry Settings
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\DataCollection]
"AllowTelemetry"=dword:0000000$telemetryLevel
"DoNotShowFeedbackNotifications"=dword:00000001
"DisableTelemetryOptInChangeNotification"=dword:00000001

; Advertising ID
[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo]
"Enabled"=dword:00000000

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo]
"DisabledByGroupPolicy"=dword:00000001

; Activity History
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\System]
"EnableActivityFeed"=dword:00000000
"PublishUserActivities"=dword:00000000
"UploadUserActivities"=dword:00000000

; Cortana
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Windows Search]
"AllowCortana"=dword:00000000
"AllowCortanaAboveLock"=dword:00000000
"DisableWebSearch"=dword:00000001
"ConnectedSearchUseWeb"=dword:00000000

[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Search]
"BingSearchEnabled"=dword:00000000
"CortanaConsent"=dword:00000000

; Windows Copilot
[HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\WindowsCopilot]
"TurnOffWindowsCopilot"=dword:00000001

[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced]
"ShowCopilotButton"=dword:00000000

; Windows Recall / AI
[HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\WindowsAI]
"DisableAIDataAnalysis"=dword:00000001
"DisableClickToDo"=dword:00000001

; Tailored Experiences
[HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\CloudContent]
"DisableTailoredExperiencesWithDiagnosticData"=dword:00000001

; App Launch Tracking
[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced]
"Start_TrackProgs"=dword:00000000
"@

    try {
        $regContent | Out-File -FilePath $OutputPath -Encoding ASCII -Force
        Write-Log "Privacy settings exported successfully" -Level "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Failed to export privacy settings: $_" -Level "ERROR"
        return $false
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Get-WindowsEdition',
    'Disable-Telemetry',
    'Disable-AdvertisingID',
    'Disable-ActivityHistory',
    'Disable-Cortana',
    'Disable-Copilot',
    'Disable-WindowsRecall',
    'Disable-TailoredExperiences',
    'Disable-AppLaunchTracking',
    'Disable-LocationTracking',
    'Invoke-PrivacySetup',
    'Export-PrivacySettings'
)
