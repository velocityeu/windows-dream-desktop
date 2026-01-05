#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Microsoft Edge Configuration Module for Windows Dream Desktop Setup
.DESCRIPTION
    Configures Microsoft Edge browser settings including homepage, search engine,
    first run bypass, and automatic sign-in for domain-joined machines.
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

$script:EdgePolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
$script:EdgePolicyPathUser = "HKCU:\Software\Policies\Microsoft\Edge"

function Disable-EdgeFirstRun {
    <#
    .SYNOPSIS
        Disables Edge first run experience and splash screen
    #>
    Write-Log "Disabling Edge first run experience..."

    $success = $true

    # Hide first run experience (machine-wide policy)
    $success = $success -and (Set-RegistryValue -Path $script:EdgePolicyPath -Name "HideFirstRunExperience" -Value 1)

    # Prevent first run page
    $success = $success -and (Set-RegistryValue -Path $script:EdgePolicyPath -Name "PreventFirstRunPage" -Value 1)

    # Disable import wizard
    $success = $success -and (Set-RegistryValue -Path $script:EdgePolicyPath -Name "AutoImportAtFirstRun" -Value 4)  # 4 = Disable

    # Disable Edge "Welcome" and "What's New" pages
    $success = $success -and (Set-RegistryValue -Path $script:EdgePolicyPath -Name "ShowRecommendationsEnabled" -Value 0)
    $success = $success -and (Set-RegistryValue -Path $script:EdgePolicyPath -Name "SpotlightExperiencesAndRecommendationsEnabled" -Value 0)
    $success = $success -and (Set-RegistryValue -Path $script:EdgePolicyPath -Name "EdgeShoppingAssistantEnabled" -Value 0)

    # Disable personalization prompts
    $success = $success -and (Set-RegistryValue -Path $script:EdgePolicyPath -Name "PersonalizationReportingEnabled" -Value 0)

    if ($success) {
        Write-Log "Edge first run experience disabled" -Level "SUCCESS"
    }
    return $success
}

function Set-EdgeHomepage {
    <#
    .SYNOPSIS
        Sets Edge homepage URL and startup behavior
    #>
    param(
        [string]$HomepageURL = "https://www.velocity-eu.com"
    )

    Write-Log "Setting Edge homepage to: $HomepageURL"

    $success = $true

    # Set homepage location
    $success = $success -and (Set-RegistryValue -Path $script:EdgePolicyPath -Name "HomepageLocation" -Value $HomepageURL -Type "String")

    # Homepage is not new tab page
    $success = $success -and (Set-RegistryValue -Path $script:EdgePolicyPath -Name "HomepageIsNewTabPage" -Value 0)

    # Show home button
    $success = $success -and (Set-RegistryValue -Path $script:EdgePolicyPath -Name "ShowHomeButton" -Value 1)

    # Set startup behavior (4 = Open specific pages)
    $success = $success -and (Set-RegistryValue -Path $script:EdgePolicyPath -Name "RestoreOnStartup" -Value 4)

    # Set startup URLs
    $startupURLsPath = "$script:EdgePolicyPath\RestoreOnStartupURLs"
    if (-not (Test-Path $startupURLsPath)) {
        New-Item -Path $startupURLsPath -Force | Out-Null
    }
    $success = $success -and (Set-RegistryValue -Path $startupURLsPath -Name "1" -Value $HomepageURL -Type "String")

    if ($success) {
        Write-Log "Edge homepage configured" -Level "SUCCESS"
    }
    return $success
}

function Set-EdgeSearchEngine {
    <#
    .SYNOPSIS
        Sets Edge default search engine to Google (or custom)
    #>
    param(
        [string]$SearchEngineName = "Google",
        [string]$SearchURL = "https://www.google.com/search?q={searchTerms}",
        [string]$SuggestURL = "https://www.google.com/complete/search?q={searchTerms}&client=chrome",
        [string]$IconURL = "https://www.google.com/favicon.ico"
    )

    Write-Log "Setting Edge search engine to: $SearchEngineName"

    $success = $true

    # Enable default search provider management
    $success = $success -and (Set-RegistryValue -Path $script:EdgePolicyPath -Name "DefaultSearchProviderEnabled" -Value 1)

    # Set search provider name
    $success = $success -and (Set-RegistryValue -Path $script:EdgePolicyPath -Name "DefaultSearchProviderName" -Value $SearchEngineName -Type "String")

    # Set search URL
    $success = $success -and (Set-RegistryValue -Path $script:EdgePolicyPath -Name "DefaultSearchProviderSearchURL" -Value $SearchURL -Type "String")

    # Set suggest URL for autocomplete
    $success = $success -and (Set-RegistryValue -Path $script:EdgePolicyPath -Name "DefaultSearchProviderSuggestURL" -Value $SuggestURL -Type "String")

    # Set search provider icon
    $success = $success -and (Set-RegistryValue -Path $script:EdgePolicyPath -Name "DefaultSearchProviderIconURL" -Value $IconURL -Type "String")

    # Set keyword (for address bar shortcuts)
    $success = $success -and (Set-RegistryValue -Path $script:EdgePolicyPath -Name "DefaultSearchProviderKeyword" -Value $SearchEngineName.ToLower() -Type "String")

    if ($success) {
        Write-Log "Edge search engine set to $SearchEngineName" -Level "SUCCESS"
    }
    return $success
}

function Enable-EdgeAutoSignIn {
    <#
    .SYNOPSIS
        Enables automatic sign-in with domain account for Edge
    #>
    param(
        [switch]$UseADAccount = $true,
        [switch]$NonRemovableProfile = $true,
        [switch]$ForceSync = $false
    )

    Write-Log "Configuring Edge automatic sign-in..."

    $success = $true

    # Enable browser sign-in (1 = Enable, 0 = Disable)
    $success = $success -and (Set-RegistryValue -Path $script:EdgePolicyPath -Name "BrowserSignin" -Value 1)

    # Enable implicit sign-in (required for auto sign-in)
    $success = $success -and (Set-RegistryValue -Path $script:EdgePolicyPath -Name "ImplicitSignInEnabled" -Value 1)

    if ($UseADAccount) {
        # Configure on-premises (AD) account auto sign-in
        # 0 = Disabled, 1 = SignInAndMakeDomainAccountNonRemovable
        $success = $success -and (Set-RegistryValue -Path $script:EdgePolicyPath -Name "ConfigureOnPremisesAccountAutoSignIn" -Value 1)
        Write-Log "AD account auto sign-in enabled" -Level "SUCCESS"
    }

    if ($NonRemovableProfile) {
        # Make the profile non-removable
        $success = $success -and (Set-RegistryValue -Path $script:EdgePolicyPath -Name "NonRemovableProfileEnabled" -Value 1)
    }

    if ($ForceSync) {
        # Force sync without prompting
        $success = $success -and (Set-RegistryValue -Path $script:EdgePolicyPath -Name "ForceSync" -Value 1)
        $success = $success -and (Set-RegistryValue -Path $script:EdgePolicyPath -Name "SyncDisabled" -Value 0)
    }

    # Disable sync consent prompt
    $success = $success -and (Set-RegistryValue -Path $script:EdgePolicyPath -Name "HideFirstRunExperience" -Value 1)

    if ($success) {
        Write-Log "Edge auto sign-in configured" -Level "SUCCESS"
    }
    return $success
}

function Disable-EdgeAnnoyances {
    <#
    .SYNOPSIS
        Disables various Edge annoyances and promotional features
    #>
    Write-Log "Disabling Edge promotional features..."

    $success = $true

    # Disable Edge Collections
    $success = $success -and (Set-RegistryValue -Path $script:EdgePolicyPath -Name "EdgeCollectionsEnabled" -Value 0)

    # Disable Shopping features
    $success = $success -and (Set-RegistryValue -Path $script:EdgePolicyPath -Name "EdgeShoppingAssistantEnabled" -Value 0)

    # Disable sidebar (Edge bar)
    $success = $success -and (Set-RegistryValue -Path $script:EdgePolicyPath -Name "HubsSidebarEnabled" -Value 0)

    # Disable Bing Chat / Copilot in sidebar
    $success = $success -and (Set-RegistryValue -Path $script:EdgePolicyPath -Name "CopilotCDPPageContext" -Value 0)

    # Disable Edge Wallet
    $success = $success -and (Set-RegistryValue -Path $script:EdgePolicyPath -Name "EdgeWalletCheckoutEnabled" -Value 0)
    $success = $success -and (Set-RegistryValue -Path $script:EdgePolicyPath -Name "EdgeWalletEtreeEnabled" -Value 0)

    # Disable "Enhance images in Microsoft Edge"
    $success = $success -and (Set-RegistryValue -Path $script:EdgePolicyPath -Name "EdgeEnhanceImagesEnabled" -Value 0)

    # Disable "Follow creators" feature
    $success = $success -and (Set-RegistryValue -Path $script:EdgePolicyPath -Name "EdgeFollowEnabled" -Value 0)

    # Disable promotional tabs
    $success = $success -and (Set-RegistryValue -Path $script:EdgePolicyPath -Name "PromotionalTabsEnabled" -Value 0)

    # Disable "Suggest similar sites" when navigation fails
    $success = $success -and (Set-RegistryValue -Path $script:EdgePolicyPath -Name "AlternateErrorPagesEnabled" -Value 0)

    # Disable MSN feed on new tab page (show blank instead)
    $success = $success -and (Set-RegistryValue -Path $script:EdgePolicyPath -Name "NewTabPageContentEnabled" -Value 0)
    $success = $success -and (Set-RegistryValue -Path $script:EdgePolicyPath -Name "NewTabPageQuickLinksEnabled" -Value 0)

    if ($success) {
        Write-Log "Edge promotional features disabled" -Level "SUCCESS"
    }
    return $success
}

function Set-EdgePrivacySettings {
    <#
    .SYNOPSIS
        Configures Edge privacy settings
    #>
    Write-Log "Configuring Edge privacy settings..."

    $success = $true

    # Disable sending browsing history to Microsoft
    $success = $success -and (Set-RegistryValue -Path $script:EdgePolicyPath -Name "SendSiteInfoToImproveServices" -Value 0)

    # Disable personalization
    $success = $success -and (Set-RegistryValue -Path $script:EdgePolicyPath -Name "PersonalizationReportingEnabled" -Value 0)

    # Disable diagnostic data beyond required
    $success = $success -and (Set-RegistryValue -Path $script:EdgePolicyPath -Name "DiagnosticData" -Value 0)

    # Disable "Sites can check if you have payment methods saved"
    $success = $success -and (Set-RegistryValue -Path $script:EdgePolicyPath -Name "PaymentMethodQueryEnabled" -Value 0)

    if ($success) {
        Write-Log "Edge privacy settings configured" -Level "SUCCESS"
    }
    return $success
}

function Invoke-EdgeSetup {
    <#
    .SYNOPSIS
        Main function to apply all Edge configuration settings
    #>
    param(
        [string]$Homepage = "https://www.velocity-eu.com",
        [string]$SearchEngine = "Google",
        [string]$SearchURL = "https://www.google.com/search?q={searchTerms}",
        [switch]$EnableAutoSignIn = $true,
        [switch]$DisableAnnoyances = $true
    )

    Write-Log "========================================" -Level "INFO"
    Write-Log "Starting Edge Browser Configuration" -Level "INFO"
    Write-Log "========================================" -Level "INFO"

    $results = @{
        FirstRun = Disable-EdgeFirstRun
        Homepage = Set-EdgeHomepage -HomepageURL $Homepage
        SearchEngine = Set-EdgeSearchEngine -SearchEngineName $SearchEngine -SearchURL $SearchURL
        Privacy = Set-EdgePrivacySettings
    }

    if ($EnableAutoSignIn) {
        $results.AutoSignIn = Enable-EdgeAutoSignIn -UseADAccount -NonRemovableProfile
    }

    if ($DisableAnnoyances) {
        $results.Annoyances = Disable-EdgeAnnoyances
    }

    $successCount = ($results.Values | Where-Object { $_ -eq $true }).Count
    $totalCount = $results.Count

    Write-Log "========================================" -Level "INFO"
    Write-Log "Edge Configuration Complete: $successCount/$totalCount successful" -Level $(if ($successCount -eq $totalCount) { "SUCCESS" } else { "WARN" })
    Write-Log "========================================" -Level "INFO"

    return $results
}

function Export-EdgePolicy {
    <#
    .SYNOPSIS
        Exports Edge configuration as a .reg file
    #>
    param(
        [string]$OutputPath = ".\Config\EdgePolicy.reg"
    )

    Write-Log "Exporting Edge policies to: $OutputPath"

    $regContent = @"
Windows Registry Editor Version 5.00

; Microsoft Edge Policy Configuration
; Generated by Windows Dream Desktop Setup

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge]
"HideFirstRunExperience"=dword:00000001
"PreventFirstRunPage"=dword:00000001
"HomepageLocation"="https://www.velocity-eu.com"
"HomepageIsNewTabPage"=dword:00000000
"ShowHomeButton"=dword:00000001
"RestoreOnStartup"=dword:00000004
"DefaultSearchProviderEnabled"=dword:00000001
"DefaultSearchProviderName"="Google"
"DefaultSearchProviderSearchURL"="https://www.google.com/search?q={searchTerms}"
"DefaultSearchProviderSuggestURL"="https://www.google.com/complete/search?q={searchTerms}&client=chrome"
"BrowserSignin"=dword:00000001
"ImplicitSignInEnabled"=dword:00000001
"ConfigureOnPremisesAccountAutoSignIn"=dword:00000001
"NonRemovableProfileEnabled"=dword:00000001
"ShowRecommendationsEnabled"=dword:00000000
"SpotlightExperiencesAndRecommendationsEnabled"=dword:00000000
"EdgeShoppingAssistantEnabled"=dword:00000000
"HubsSidebarEnabled"=dword:00000000
"NewTabPageContentEnabled"=dword:00000000

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge\RestoreOnStartupURLs]
"1"="https://www.velocity-eu.com"
"@

    try {
        $regContent | Out-File -FilePath $OutputPath -Encoding ASCII -Force
        Write-Log "Edge policy exported successfully" -Level "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Failed to export Edge policy: $_" -Level "ERROR"
        return $false
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Disable-EdgeFirstRun',
    'Set-EdgeHomepage',
    'Set-EdgeSearchEngine',
    'Enable-EdgeAutoSignIn',
    'Disable-EdgeAnnoyances',
    'Set-EdgePrivacySettings',
    'Invoke-EdgeSetup',
    'Export-EdgePolicy'
)
