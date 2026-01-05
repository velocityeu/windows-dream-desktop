#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Windows Dream Desktop Setup - Zero-Touch Deployment Tool
.DESCRIPTION
    Comprehensive Windows customization toolkit that:
    - Bypasses all first-login Microsoft OOBE questions
    - Configures Microsoft Edge (homepage, search engine, auto-signin)
    - Removes bloatware (with user-selectable options)
    - Configures privacy and telemetry settings
.NOTES
    Version: 1.0.0
    Author: Windows Dream Desktop Setup
    Requires: Administrator privileges, Windows 10/11 Pro, Enterprise, or Education
.LINK
    https://github.com/ChrisTitusTech/winutil
    https://github.com/Raphire/Win11Debloat
#>

[CmdletBinding()]
param(
    [switch]$Silent,
    [switch]$FullSetup,
    [string]$ConfigPath
)

$ErrorActionPreference = "Continue"
$script:ScriptPath = $PSScriptRoot
$script:ModulesPath = Join-Path $script:ScriptPath "Modules"
$script:ConfigPath = Join-Path $script:ScriptPath "Config"
$script:LogPath = Join-Path $env:TEMP "DreamDesktopSetup_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

#region Logging
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"

    # Console output with colors
    $color = switch($Level) {
        "ERROR" { "Red" }
        "WARN" { "Yellow" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    Write-Host $logEntry -ForegroundColor $color

    # File logging
    Add-Content -Path $script:LogPath -Value $logEntry -ErrorAction SilentlyContinue
}
#endregion

#region Module Loading
function Import-DreamModules {
    Write-Log "Loading modules from: $script:ModulesPath"

    $modules = @(
        "OOBE-Bypass.ps1",
        "Edge-Setup.ps1",
        "Debloat.ps1",
        "Privacy.ps1"
    )

    foreach ($module in $modules) {
        $modulePath = Join-Path $script:ModulesPath $module
        if (Test-Path $modulePath) {
            try {
                . $modulePath
                Write-Log "Loaded: $module" -Level "SUCCESS"
            }
            catch {
                Write-Log "Failed to load $module : $_" -Level "ERROR"
            }
        }
        else {
            Write-Log "Module not found: $modulePath" -Level "WARN"
        }
    }
}
#endregion

#region Configuration
function Get-Settings {
    $settingsPath = Join-Path $script:ConfigPath "Settings.json"
    if (Test-Path $settingsPath) {
        try {
            $content = Get-Content -Path $settingsPath -Raw
            return $content | ConvertFrom-Json
        }
        catch {
            Write-Log "Failed to load settings: $_" -Level "ERROR"
        }
    }
    return $null
}

function Get-SystemInfo {
    $os = Get-WmiObject Win32_OperatingSystem
    $build = [Environment]::OSVersion.Version.Build

    return @{
        Caption = $os.Caption
        Version = $os.Version
        Build = $build
        IsWin11 = $build -ge 22000
        IsWin10 = $build -lt 22000 -and $build -ge 10240
        IsEnterprise = $os.Caption -match "Enterprise|Education"
        IsPro = $os.Caption -match "Pro"
        IsHome = $os.Caption -match "Home"
        Architecture = $os.OSArchitecture
        ComputerName = $env:COMPUTERNAME
        UserName = $env:USERNAME
    }
}
#endregion

#region UI Functions
function Show-Banner {
    Clear-Host
    $banner = @"

  ╔═══════════════════════════════════════════════════════════════╗
  ║                                                               ║
  ║   ██████╗ ██████╗ ███████╗ █████╗ ███╗   ███╗                ║
  ║   ██╔══██╗██╔══██╗██╔════╝██╔══██╗████╗ ████║                ║
  ║   ██║  ██║██████╔╝█████╗  ███████║██╔████╔██║                ║
  ║   ██║  ██║██╔══██╗██╔══╝  ██╔══██║██║╚██╔╝██║                ║
  ║   ██████╔╝██║  ██║███████╗██║  ██║██║ ╚═╝ ██║                ║
  ║   ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝                ║
  ║                                                               ║
  ║   ██████╗ ███████╗███████╗██╗  ██╗████████╗ ██████╗ ██████╗  ║
  ║   ██╔══██╗██╔════╝██╔════╝██║ ██╔╝╚══██╔══╝██╔═══██╗██╔══██╗ ║
  ║   ██║  ██║█████╗  ███████╗█████╔╝    ██║   ██║   ██║██████╔╝ ║
  ║   ██║  ██║██╔══╝  ╚════██║██╔═██╗    ██║   ██║   ██║██╔═══╝  ║
  ║   ██████╔╝███████╗███████║██║  ██╗   ██║   ╚██████╔╝██║      ║
  ║   ╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝      ║
  ║                                                               ║
  ║           Windows Zero-Touch Deployment Toolkit               ║
  ║                      Version 1.0.0                            ║
  ╚═══════════════════════════════════════════════════════════════╝

"@
    Write-Host $banner -ForegroundColor Cyan
}

function Show-SystemInfo {
    $info = Get-SystemInfo

    Write-Host "`n  System Information:" -ForegroundColor Yellow
    Write-Host "  ─────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host "  OS:          $($info.Caption)" -ForegroundColor White
    Write-Host "  Build:       $($info.Build)" -ForegroundColor White
    Write-Host "  Edition:     $(if ($info.IsEnterprise) { 'Enterprise/Education' } elseif ($info.IsPro) { 'Pro' } else { 'Home' })" -ForegroundColor White
    Write-Host "  Computer:    $($info.ComputerName)" -ForegroundColor White
    Write-Host "  User:        $($info.UserName)" -ForegroundColor White
    Write-Host "  ─────────────────────────────────────────" -ForegroundColor DarkGray

    if ($info.IsHome) {
        Write-Host "`n  [!] Warning: Some features are limited on Windows Home edition" -ForegroundColor Yellow
    }
}

function Show-MainMenu {
    Write-Host "`n  ╔═══════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║              MAIN MENU                        ║" -ForegroundColor Cyan
    Write-Host "  ╠═══════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "  ║                                               ║" -ForegroundColor Cyan
    Write-Host "  ║  [1] Full Setup (Recommended)                 ║" -ForegroundColor White
    Write-Host "  ║      Apply all optimizations                  ║" -ForegroundColor DarkGray
    Write-Host "  ║                                               ║" -ForegroundColor Cyan
    Write-Host "  ║  [2] OOBE & Wizard Bypass                     ║" -ForegroundColor White
    Write-Host "  ║      Disable setup prompts & reminders        ║" -ForegroundColor DarkGray
    Write-Host "  ║                                               ║" -ForegroundColor Cyan
    Write-Host "  ║  [3] Edge Browser Configuration               ║" -ForegroundColor White
    Write-Host "  ║      Homepage, search engine, auto-signin     ║" -ForegroundColor DarkGray
    Write-Host "  ║                                               ║" -ForegroundColor Cyan
    Write-Host "  ║  [4] Bloatware Removal                        ║" -ForegroundColor White
    Write-Host "  ║      Remove pre-installed apps                ║" -ForegroundColor DarkGray
    Write-Host "  ║                                               ║" -ForegroundColor Cyan
    Write-Host "  ║  [5] Privacy & Telemetry Settings             ║" -ForegroundColor White
    Write-Host "  ║      Disable tracking & AI features           ║" -ForegroundColor DarkGray
    Write-Host "  ║                                               ║" -ForegroundColor Cyan
    Write-Host "  ║  [6] Export Configuration Files               ║" -ForegroundColor White
    Write-Host "  ║      Generate .reg files for manual use       ║" -ForegroundColor DarkGray
    Write-Host "  ║                                               ║" -ForegroundColor Cyan
    Write-Host "  ║  [7] View Bloatware Report                    ║" -ForegroundColor White
    Write-Host "  ║      Scan without removing                    ║" -ForegroundColor DarkGray
    Write-Host "  ║                                               ║" -ForegroundColor Cyan
    Write-Host "  ║  [0] Exit                                     ║" -ForegroundColor White
    Write-Host "  ║                                               ║" -ForegroundColor Cyan
    Write-Host "  ╚═══════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Show-BloatwareMenu {
    Write-Host "`n  ╔═══════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "  ║          BLOATWARE REMOVAL OPTIONS            ║" -ForegroundColor Yellow
    Write-Host "  ╠═══════════════════════════════════════════════╣" -ForegroundColor Yellow
    Write-Host "  ║                                               ║" -ForegroundColor Yellow
    Write-Host "  ║  [A] Remove ALL Bloatware                     ║" -ForegroundColor White
    Write-Host "  ║      Removes everything except protected apps ║" -ForegroundColor DarkGray
    Write-Host "  ║                                               ║" -ForegroundColor Yellow
    Write-Host "  ║  [B] Selective Removal                        ║" -ForegroundColor White
    Write-Host "  ║      Choose categories to remove              ║" -ForegroundColor DarkGray
    Write-Host "  ║                                               ║" -ForegroundColor Yellow
    Write-Host "  ║  [C] Keep Default Apps                        ║" -ForegroundColor White
    Write-Host "  ║      Skip bloatware removal                   ║" -ForegroundColor DarkGray
    Write-Host "  ║                                               ║" -ForegroundColor Yellow
    Write-Host "  ║  [R] Return to Main Menu                      ║" -ForegroundColor White
    Write-Host "  ║                                               ║" -ForegroundColor Yellow
    Write-Host "  ╚═══════════════════════════════════════════════╝" -ForegroundColor Yellow
    Write-Host ""
}
#endregion

#region Action Functions
function Invoke-FullSetup {
    Write-Log "========================================" -Level "INFO"
    Write-Log "Starting Full Setup" -Level "INFO"
    Write-Log "========================================" -Level "INFO"

    $settings = Get-Settings

    # Step 1: OOBE Bypass
    Write-Host "`n  Step 1/4: Applying OOBE & Wizard Bypass..." -ForegroundColor Cyan
    Invoke-OOBEBypass -DisableOffice -DisableTeams -DisableOneDrive

    # Step 2: Edge Configuration
    Write-Host "`n  Step 2/4: Configuring Microsoft Edge..." -ForegroundColor Cyan
    $homepage = if ($settings) { $settings.Edge.Homepage } else { "https://www.velocity-eu.com" }
    Invoke-EdgeSetup -Homepage $homepage -SearchEngine "Google" -EnableAutoSignIn -DisableAnnoyances

    # Step 3: Privacy Settings
    Write-Host "`n  Step 3/4: Applying Privacy Settings..." -ForegroundColor Cyan
    Invoke-PrivacySetup -DisableTelemetry -DisableAds -DisableAI

    # Step 4: Bloatware (prompt user)
    Write-Host "`n  Step 4/4: Bloatware Removal" -ForegroundColor Cyan
    Show-BloatwareMenu
    $bloatChoice = Read-Host "  Select option"

    switch ($bloatChoice.ToUpper()) {
        "A" { Invoke-Debloat -Mode "All" }
        "B" { Invoke-Debloat -Mode "Selective" }
        "C" { Write-Log "Bloatware removal skipped" -Level "INFO" }
        default { Write-Log "Invalid option, skipping bloatware removal" -Level "WARN" }
    }

    Write-Log "========================================" -Level "INFO"
    Write-Log "Full Setup Complete!" -Level "SUCCESS"
    Write-Log "Log saved to: $script:LogPath" -Level "INFO"
    Write-Log "========================================" -Level "INFO"

    Write-Host "`n  [!] A restart is recommended to apply all changes." -ForegroundColor Yellow
    $restart = Read-Host "  Restart now? (Y/N)"
    if ($restart.ToUpper() -eq "Y") {
        Restart-Computer -Force
    }
}

function Invoke-OOBESetup {
    Write-Log "Applying OOBE & Wizard Bypass settings..."
    Invoke-OOBEBypass -DisableOffice -DisableTeams -DisableOneDrive
    Write-Host "`n  Press any key to continue..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Invoke-EdgeConfiguration {
    Write-Log "Configuring Microsoft Edge..."

    $settings = Get-Settings
    $homepage = if ($settings) { $settings.Edge.Homepage } else { "https://www.velocity-eu.com" }

    Write-Host "`n  Current homepage setting: $homepage" -ForegroundColor Cyan
    $customHomepage = Read-Host "  Enter new homepage URL (or press Enter to keep current)"

    if (-not [string]::IsNullOrWhiteSpace($customHomepage)) {
        $homepage = $customHomepage
    }

    Invoke-EdgeSetup -Homepage $homepage -SearchEngine "Google" -EnableAutoSignIn -DisableAnnoyances

    Write-Host "`n  Press any key to continue..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Invoke-BloatwareMenu {
    Show-BloatwareMenu
    $choice = Read-Host "  Select option"

    switch ($choice.ToUpper()) {
        "A" { Invoke-Debloat -Mode "All" }
        "B" { Invoke-Debloat -Mode "Selective" }
        "C" { Write-Log "Bloatware removal skipped" -Level "INFO" }
        "R" { return }
        default { Write-Log "Invalid option" -Level "WARN" }
    }

    Write-Host "`n  Press any key to continue..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Invoke-PrivacyConfiguration {
    Write-Log "Applying Privacy & Telemetry settings..."
    Invoke-PrivacySetup -DisableTelemetry -DisableAds -DisableAI
    Write-Host "`n  Press any key to continue..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Invoke-ExportConfiguration {
    Write-Log "Exporting configuration files..."

    $exportPath = $script:ConfigPath

    # Export Edge policy
    Export-EdgePolicy -OutputPath (Join-Path $exportPath "EdgePolicy.reg")

    # Export Privacy settings
    Export-PrivacySettings -OutputPath (Join-Path $exportPath "PrivacySettings.reg")

    Write-Host "`n  Configuration files exported to: $exportPath" -ForegroundColor Green
    Write-Host "  - EdgePolicy.reg" -ForegroundColor White
    Write-Host "  - PrivacySettings.reg" -ForegroundColor White

    Write-Host "`n  Press any key to continue..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Invoke-BloatwareReport {
    Get-BloatwareReport
    Write-Host "`n  Press any key to continue..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
#endregion

#region Main Loop
function Start-DreamDesktop {
    # Check for admin rights
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Host "This script requires Administrator privileges. Please run as Administrator." -ForegroundColor Red
        exit 1
    }

    # Import modules
    Import-DreamModules

    # Handle silent/automated mode
    if ($FullSetup -or $Silent) {
        Write-Log "Running in automated mode..."
        Invoke-FullSetup
        return
    }

    # Interactive mode
    do {
        Show-Banner
        Show-SystemInfo
        Show-MainMenu

        $choice = Read-Host "  Select option"

        switch ($choice) {
            "1" { Invoke-FullSetup }
            "2" { Invoke-OOBESetup }
            "3" { Invoke-EdgeConfiguration }
            "4" { Invoke-BloatwareMenu }
            "5" { Invoke-PrivacyConfiguration }
            "6" { Invoke-ExportConfiguration }
            "7" { Invoke-BloatwareReport }
            "0" {
                Write-Log "Exiting Dream Desktop Setup"
                Write-Host "`n  Thank you for using Dream Desktop Setup!" -ForegroundColor Cyan
                Write-Host "  Log saved to: $script:LogPath" -ForegroundColor DarkGray
                return
            }
            default {
                Write-Host "`n  Invalid option. Please try again." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    } while ($true)
}

# Entry point
Start-DreamDesktop
#endregion
