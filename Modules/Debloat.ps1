#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Bloatware Removal Module for Windows Dream Desktop Setup
.DESCRIPTION
    Provides functions to remove pre-installed Windows apps (bloatware) with
    three modes: Remove All, Selective, and Keep Default.
#>

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $(switch($Level) { "ERROR" { "Red" } "WARN" { "Yellow" } "SUCCESS" { "Green" } default { "White" } })
}

$script:BloatwareListPath = Join-Path $PSScriptRoot "..\Config\BloatwareList.json"

function Get-BloatwareList {
    <#
    .SYNOPSIS
        Loads the bloatware list from JSON configuration
    #>
    if (Test-Path $script:BloatwareListPath) {
        try {
            $content = Get-Content -Path $script:BloatwareListPath -Raw
            return $content | ConvertFrom-Json
        }
        catch {
            Write-Log "Failed to load bloatware list: $_" -Level "ERROR"
            return $null
        }
    }
    else {
        Write-Log "Bloatware list not found at: $script:BloatwareListPath" -Level "WARN"
        return $null
    }
}

function Get-InstalledBloatware {
    <#
    .SYNOPSIS
        Gets list of installed apps that match the bloatware list
    #>
    Write-Log "Scanning for installed bloatware..."

    $bloatwareConfig = Get-BloatwareList
    if (-not $bloatwareConfig) {
        return @()
    }

    $installedApps = Get-AppxPackage -AllUsers | Select-Object Name, PackageFullName
    $provisionedApps = Get-AppxProvisionedPackage -Online | Select-Object DisplayName, PackageName

    $foundBloatware = @()

    foreach ($appName in $bloatwareConfig.RemoveAllList) {
        # Check installed apps
        $installed = $installedApps | Where-Object { $_.Name -like $appName }
        foreach ($app in $installed) {
            $foundBloatware += [PSCustomObject]@{
                Name = $app.Name
                PackageFullName = $app.PackageFullName
                Type = "Installed"
            }
        }

        # Check provisioned apps
        $provisioned = $provisionedApps | Where-Object { $_.DisplayName -like $appName }
        foreach ($app in $provisioned) {
            if ($foundBloatware.Name -notcontains $app.DisplayName) {
                $foundBloatware += [PSCustomObject]@{
                    Name = $app.DisplayName
                    PackageFullName = $app.PackageName
                    Type = "Provisioned"
                }
            }
        }
    }

    Write-Log "Found $($foundBloatware.Count) bloatware apps" -Level "INFO"
    return $foundBloatware
}

function Remove-SingleApp {
    <#
    .SYNOPSIS
        Removes a single app for all users and from provisioned packages
    #>
    param(
        [string]$AppName,
        [switch]$WhatIf
    )

    $success = $true

    # Remove for all users
    $packages = Get-AppxPackage -AllUsers -Name $AppName -ErrorAction SilentlyContinue
    foreach ($package in $packages) {
        if ($WhatIf) {
            Write-Log "[WhatIf] Would remove: $($package.Name)" -Level "INFO"
        }
        else {
            try {
                Remove-AppxPackage -Package $package.PackageFullName -AllUsers -ErrorAction Stop
                Write-Log "Removed: $($package.Name)" -Level "SUCCESS"
            }
            catch {
                Write-Log "Failed to remove $($package.Name): $_" -Level "WARN"
                $success = $false
            }
        }
    }

    # Remove provisioned package (prevents reinstall for new users)
    $provisioned = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like $AppName }
    foreach ($prov in $provisioned) {
        if ($WhatIf) {
            Write-Log "[WhatIf] Would deprovision: $($prov.DisplayName)" -Level "INFO"
        }
        else {
            try {
                Remove-AppxProvisionedPackage -Online -PackageName $prov.PackageName -ErrorAction Stop | Out-Null
                Write-Log "Deprovisioned: $($prov.DisplayName)" -Level "SUCCESS"
            }
            catch {
                Write-Log "Failed to deprovision $($prov.DisplayName): $_" -Level "WARN"
            }
        }
    }

    return $success
}

function Remove-AllBloatware {
    <#
    .SYNOPSIS
        Removes all apps in the bloatware list except protected apps
    #>
    param([switch]$WhatIf)

    Write-Log "========================================" -Level "INFO"
    Write-Log "Starting Full Bloatware Removal" -Level "INFO"
    Write-Log "========================================" -Level "INFO"

    $bloatwareConfig = Get-BloatwareList
    if (-not $bloatwareConfig) {
        Write-Log "Cannot proceed without bloatware configuration" -Level "ERROR"
        return $false
    }

    $protectedApps = $bloatwareConfig.ProtectedApps
    $removeList = $bloatwareConfig.RemoveAllList

    $removed = 0
    $failed = 0

    foreach ($appName in $removeList) {
        if ($protectedApps -contains $appName) {
            Write-Log "Skipping protected app: $appName" -Level "INFO"
            continue
        }

        if (Remove-SingleApp -AppName $appName -WhatIf:$WhatIf) {
            $removed++
        }
        else {
            $failed++
        }
    }

    Write-Log "========================================" -Level "INFO"
    Write-Log "Bloatware Removal Complete: $removed removed, $failed failed" -Level $(if ($failed -eq 0) { "SUCCESS" } else { "WARN" })
    Write-Log "========================================" -Level "INFO"

    return ($failed -eq 0)
}

function Show-BloatwareMenu {
    <#
    .SYNOPSIS
        Displays interactive menu for selective bloatware removal
    #>
    $bloatwareConfig = Get-BloatwareList
    if (-not $bloatwareConfig) {
        Write-Log "Cannot load bloatware configuration" -Level "ERROR"
        return @()
    }

    $categories = $bloatwareConfig.Categories.PSObject.Properties
    $selectedApps = @()

    Clear-Host
    Write-Host "`n  ╔═══════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║     SELECTIVE BLOATWARE REMOVAL               ║" -ForegroundColor Cyan
    Write-Host "  ╠═══════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "  ║  Select categories to remove (Y/N/A):        ║" -ForegroundColor Cyan
    Write-Host "  ║  Y = Remove category, N = Keep, A = Abort    ║" -ForegroundColor Cyan
    Write-Host "  ╚═══════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    foreach ($category in $categories) {
        $catName = $category.Name
        $catData = $category.Value
        $appCount = $catData.Apps.Count

        if ($catData.KeepByDefault) {
            Write-Host "  [$catName] $($catData.Description) ($appCount apps) - SKIPPING (Keep by default)" -ForegroundColor DarkGray
            continue
        }

        Write-Host ""
        Write-Host "  Category: $catName" -ForegroundColor Yellow
        Write-Host "  Description: $($catData.Description)" -ForegroundColor Gray
        Write-Host "  Apps: $($catData.Apps -join ', ')" -ForegroundColor Gray

        $choice = Read-Host "  Remove this category? (Y/N/A)"

        switch ($choice.ToUpper()) {
            "Y" {
                $selectedApps += $catData.Apps
                Write-Host "  -> Marked for removal" -ForegroundColor Green
            }
            "A" {
                Write-Host "  Aborted by user" -ForegroundColor Yellow
                return @()
            }
            default {
                Write-Host "  -> Keeping" -ForegroundColor Cyan
            }
        }
    }

    return $selectedApps
}

function Remove-SelectiveBloatware {
    <#
    .SYNOPSIS
        Removes bloatware based on user selection
    #>
    param([switch]$WhatIf)

    $selectedApps = Show-BloatwareMenu

    if ($selectedApps.Count -eq 0) {
        Write-Log "No apps selected for removal" -Level "INFO"
        return $true
    }

    Write-Log "========================================" -Level "INFO"
    Write-Log "Removing $($selectedApps.Count) selected apps" -Level "INFO"
    Write-Log "========================================" -Level "INFO"

    $removed = 0
    $failed = 0

    foreach ($appName in $selectedApps) {
        if (Remove-SingleApp -AppName $appName -WhatIf:$WhatIf) {
            $removed++
        }
        else {
            $failed++
        }
    }

    Write-Log "========================================" -Level "INFO"
    Write-Log "Selective Removal Complete: $removed removed, $failed failed" -Level $(if ($failed -eq 0) { "SUCCESS" } else { "WARN" })
    Write-Log "========================================" -Level "INFO"

    return ($failed -eq 0)
}

function Get-BloatwareReport {
    <#
    .SYNOPSIS
        Generates a report of installed bloatware without removing
    #>
    Write-Log "Generating bloatware report..."

    $foundBloatware = Get-InstalledBloatware
    $bloatwareConfig = Get-BloatwareList

    Write-Host "`n  ╔═══════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║          BLOATWARE SCAN REPORT                ║" -ForegroundColor Cyan
    Write-Host "  ╚═══════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    if ($foundBloatware.Count -eq 0) {
        Write-Host "  No bloatware found! Your system is clean." -ForegroundColor Green
    }
    else {
        Write-Host "  Found $($foundBloatware.Count) bloatware apps:" -ForegroundColor Yellow
        Write-Host ""

        foreach ($app in $foundBloatware) {
            $typeColor = if ($app.Type -eq "Provisioned") { "DarkYellow" } else { "White" }
            Write-Host "    - $($app.Name) [$($app.Type)]" -ForegroundColor $typeColor
        }
    }

    Write-Host ""
    Write-Host "  Protected apps that will NOT be removed:" -ForegroundColor Cyan
    foreach ($protected in $bloatwareConfig.ProtectedApps) {
        Write-Host "    + $protected" -ForegroundColor DarkCyan
    }

    return $foundBloatware
}

function Invoke-Debloat {
    <#
    .SYNOPSIS
        Main function for bloatware removal with mode selection
    #>
    param(
        [ValidateSet("All", "Selective", "Report", "Skip")]
        [string]$Mode = "Selective",
        [switch]$WhatIf
    )

    switch ($Mode) {
        "All" {
            return Remove-AllBloatware -WhatIf:$WhatIf
        }
        "Selective" {
            return Remove-SelectiveBloatware -WhatIf:$WhatIf
        }
        "Report" {
            Get-BloatwareReport | Out-Null
            return $true
        }
        "Skip" {
            Write-Log "Bloatware removal skipped" -Level "INFO"
            return $true
        }
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Get-BloatwareList',
    'Get-InstalledBloatware',
    'Remove-SingleApp',
    'Remove-AllBloatware',
    'Show-BloatwareMenu',
    'Remove-SelectiveBloatware',
    'Get-BloatwareReport',
    'Invoke-Debloat'
)
