# Windows Dream Desktop Setup

<p align="center">
  <img src="https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6?style=for-the-badge&logo=windows&logoColor=white" alt="Windows 10/11">
  <img src="https://img.shields.io/badge/PowerShell-5.1+-5391FE?style=for-the-badge&logo=powershell&logoColor=white" alt="PowerShell">
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="MIT License">
</p>

<p align="center">
  <b>Zero-touch Windows deployment toolkit for IT professionals</b><br>
  Bypass OOBE | Configure Edge | Remove Bloatware | Harden Privacy
</p>

---

## Why Use This Tool?

### The Problem

Every new Windows computer comes with a frustrating first-login experience:

- **15+ setup screens** asking for Microsoft account, privacy settings, Cortana, etc.
- **Edge browser** opens with first-run wizard, Bing search, and MSN news feed
- **Pre-installed bloatware** like Candy Crush, TikTok, Spotify, Xbox apps
- **Constant prompts** - "Let's finish setting up", "Try Microsoft 365", "Back up with OneDrive"
- **Privacy-invasive defaults** - telemetry, advertising ID, activity tracking enabled

For IT departments deploying dozens or hundreds of machines, this wastes hours of time and creates an inconsistent user experience.

### The Solution

**Windows Dream Desktop Setup** automates all of this:

| Before | After |
|--------|-------|
| 15+ OOBE screens to click through | Direct to desktop |
| Edge opens with setup wizard | Opens to your company homepage |
| Bing as default search | Google (or your choice) |
| Bloatware installed | Clean system |
| Telemetry at maximum | Minimal data collection |
| "Finish setup" reminders | Never appears |

---

## Key Benefits

### For IT Administrators

- **Save 15-30 minutes per deployment** - No manual clicking through setup screens
- **Consistent configuration** - Every machine configured identically
- **Multiple deployment methods** - PowerShell, USB, Group Policy, MDM/Intune
- **Customizable** - Edit JSON configs to match your organization's needs
- **No licensing costs** - 100% free and open source

### For End Users

- **Immediate productivity** - Boot straight to desktop, browser opens to company portal
- **Cleaner system** - No unwanted apps cluttering Start menu
- **Better privacy** - Reduced data collection and tracking
- **Faster performance** - Less background processes from removed bloatware

### For MSPs and Consultants

- **Standardized deployments** - Same setup across all client machines
- **Professional appearance** - No "Candy Crush" on client computers
- **Time savings** - Deploy 10 machines in the time it takes to manually configure 1
- **Documentation included** - Easy to explain what was changed

---

## Features

### 1. OOBE Bypass (Out-of-Box Experience)

Completely skip the Windows first-login experience:

| Prompt | Status |
|--------|--------|
| Region/Keyboard selection | Skipped |
| Network connection requirement | Bypassed |
| Microsoft account sign-in | Skipped (local account created) |
| Privacy settings (6 toggles) | Auto-configured |
| Cortana setup | Skipped |
| Device name prompt | Auto-generated |
| "Let's finish setting up your device" | Permanently disabled |
| Windows Welcome experience | Disabled |

### 2. Microsoft Edge Configuration

Transform Edge from an ad-filled browser to a clean work tool:

| Setting | Configuration |
|---------|---------------|
| Homepage | Your company URL (default: velocity-eu.com) |
| Startup behavior | Opens homepage directly |
| Default search engine | Google |
| First-run experience | Disabled |
| MSN news feed | Disabled |
| Shopping assistant | Disabled |
| Copilot sidebar | Disabled |
| Collections | Disabled |
| Recommendations | Disabled |
| Auto sign-in | Enabled (uses domain account) |

### 3. Bloatware Removal

Remove unwanted pre-installed apps with three modes:

#### Mode A: Remove All
Removes 40+ apps including:
- **Bing Apps**: News, Weather, Finance, Search
- **Entertainment**: Solitaire, Spotify, Disney+, Clipchamp
- **Communication**: Teams (consumer), Mail, People
- **Gaming**: Xbox apps, Gaming overlay
- **AI**: Copilot, Cortana
- **Promotional**: Candy Crush, TikTok, Instagram, Facebook

#### Mode B: Selective
Interactive menu to choose categories:
```
Category: Xbox Apps
Description: Xbox and gaming apps (7 apps)
Remove this category? (Y/N/A): _
```

#### Mode C: Keep Default
Skip bloatware removal entirely.

#### Protected Apps (Never Removed)
- Microsoft Store
- Calculator, Photos, Notepad, Paint
- Windows Terminal
- Media codecs (HEIF, VP9, WebP)
- Security Center

### 4. Privacy & Telemetry

Reduce Windows data collection to the minimum allowed by your edition:

| Setting | Windows Pro | Windows Enterprise |
|---------|-------------|-------------------|
| Telemetry Level | Basic (1) | Security (0) |
| Advertising ID | Disabled | Disabled |
| Activity History | Disabled | Disabled |
| Location tracking | Disabled | Disabled |
| Cortana | Disabled | Disabled |
| Copilot | Disabled | Disabled |
| Windows Recall | Disabled | Disabled |
| Tips & suggestions | Disabled | Disabled |
| Tailored experiences | Disabled | Disabled |
| App launch tracking | Disabled | Disabled |

### 5. Application Wizard Bypass

Disable first-run experiences for common applications:

| Application | What's Disabled |
|-------------|-----------------|
| Microsoft Edge | First run wizard, import prompt |
| Microsoft Office | First run opt-in wizard |
| Outlook | Simplified account creation |
| Teams | Auto-start, first launch popup |
| OneDrive | Setup popup, backup prompts |

---

## Installation

### Option 1: Clone Repository

```powershell
git clone https://github.com/velocityeu/windows-dream-desktop.git
cd windows-dream-desktop
```

### Option 2: Download ZIP

1. Go to [Releases](https://github.com/velocityeu/windows-dream-desktop/releases)
2. Download the latest ZIP
3. Extract to desired location

### Option 3: One-Line Install

```powershell
irm https://raw.githubusercontent.com/velocityeu/windows-dream-desktop/master/SetupDreamDesktop.ps1 | iex
```

---

## Usage

### Interactive Mode (Recommended)

```powershell
# Run as Administrator
.\SetupDreamDesktop.ps1
```

Displays an interactive menu:
```
╔═══════════════════════════════════════════════╗
║              MAIN MENU                        ║
╠═══════════════════════════════════════════════╣
║  [1] Full Setup (Recommended)                 ║
║  [2] OOBE & Wizard Bypass Only                ║
║  [3] Edge Browser Configuration Only          ║
║  [4] Bloatware Removal                        ║
║  [5] Privacy & Telemetry Settings             ║
║  [6] Export Configuration Files               ║
║  [7] View Bloatware Report                    ║
║  [0] Exit                                     ║
╚═══════════════════════════════════════════════╝
```

### Silent Mode (Automated Deployment)

```powershell
# Apply all settings without prompts
.\SetupDreamDesktop.ps1 -FullSetup
```

### Clean Install (New Computer)

1. Download Windows ISO from Microsoft
2. Create bootable USB with [Rufus](https://rufus.ie/) or similar
3. Copy `autounattend.xml` to USB root
4. Boot from USB and install Windows
5. OOBE is automatically bypassed, local admin account created

### Registry Files (Manual/GPO)

Import `.reg` files for specific configurations:

```cmd
:: Edge configuration
regedit /s Config\EdgePolicy.reg

:: Privacy settings
regedit /s Config\PrivacySettings.reg
```

### Group Policy Deployment

1. Copy registry files to SYSVOL
2. Create GPO with startup script:
```batch
regedit /s \\domain\SYSVOL\domain\scripts\EdgePolicy.reg
regedit /s \\domain\SYSVOL\domain\scripts\PrivacySettings.reg
```

---

## Configuration

### Customizing Settings

Edit `Config/Settings.json` to customize:

```json
{
  "Edge": {
    "Homepage": "https://your-company.com",
    "SearchEngine": {
      "Name": "Google",
      "SearchURL": "https://www.google.com/search?q={searchTerms}"
    }
  },
  "Privacy": {
    "DisableTelemetry": true,
    "DisableCopilot": true,
    "DisableRecall": true
  }
}
```

### Customizing Bloatware List

Edit `Config/BloatwareList.json` to add/remove apps:

```json
{
  "RemoveAllList": [
    "Microsoft.BingNews",
    "Microsoft.XboxApp",
    "YourCustomApp.ToRemove"
  ],
  "ProtectedApps": [
    "Microsoft.WindowsStore",
    "AppYouWantToKeep"
  ]
}
```

### AutoUnattend.xml Customization

Before deployment, update these values in `autounattend.xml`:

| Setting | Default | Change To |
|---------|---------|-----------|
| Admin Password | `P@ssw0rd` | Your secure password |
| Computer Name | `*` (auto) | Your naming convention |
| Time Zone | `UTC` | Your time zone |
| Locale | `en-US` | Your locale |
| Homepage | `velocity-eu.com` | Your company URL |

---

## Directory Structure

```
windows-dream-desktop/
├── SetupDreamDesktop.ps1      # Main interactive script (18KB)
├── autounattend.xml           # OOBE bypass for USB install (11KB)
├── LICENSE                    # MIT License
├── README.md                  # This documentation
│
├── Config/
│   ├── Settings.json          # User-configurable settings
│   ├── BloatwareList.json     # Apps to remove/protect
│   ├── EdgePolicy.reg         # Edge registry export
│   └── PrivacySettings.reg    # Privacy registry export
│
├── Modules/
│   ├── OOBE-Bypass.ps1        # OOBE/wizard disable functions
│   ├── Edge-Setup.ps1         # Edge configuration functions
│   ├── Debloat.ps1            # Bloatware removal functions
│   └── Privacy.ps1            # Privacy/telemetry functions
│
└── PPKG/                      # (Future) Provisioning packages
```

---

## System Requirements

| Requirement | Minimum |
|-------------|---------|
| Operating System | Windows 10 1903+ or Windows 11 |
| Edition | Pro, Enterprise, or Education (Home has limited GPO support) |
| PowerShell | 5.1 or later |
| Privileges | Administrator |
| Disk Space | < 1 MB |

### Edition Compatibility

| Feature | Home | Pro | Enterprise/Education |
|---------|------|-----|---------------------|
| OOBE Bypass | Yes | Yes | Yes |
| Edge Configuration | Yes | Yes | Yes |
| Bloatware Removal | Yes | Yes | Yes |
| Telemetry (Basic) | Yes | Yes | Yes |
| Telemetry (Security/0) | No | No | Yes |
| Consumer Experience Block | No | Partial | Yes |
| Full GPO Support | No | Yes | Yes |

---

## Troubleshooting

### Script won't run - Execution Policy

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
.\SetupDreamDesktop.ps1
```

### "Access Denied" errors

Ensure you're running PowerShell as Administrator:
1. Right-click PowerShell
2. Select "Run as administrator"

### Some settings don't apply

- **Windows Home**: Some GPO-based settings only work on Pro/Enterprise
- **Managed devices**: Intune/SCCM policies may override local settings
- **Updates**: Windows updates may reset some settings

### Edge settings not applying

Edge must be restarted after applying settings. If using a domain account, ensure `ImplicitSignInEnabled` policy is not disabled by your organization.

### Bloatware reinstalls after removal

Some apps reinstall via Windows Update. To prevent:
1. Use "Remove All" mode (removes provisioned packages)
2. Apply Consumer Experience block (Enterprise only)
3. Consider using WUFB or WSUS to control feature updates

---

## Security Considerations

### What This Tool Does NOT Do

- Does not disable Windows Update
- Does not disable Windows Defender
- Does not disable Windows Firewall
- Does not remove system-critical components
- Does not "crack" or pirate Windows

### Password Security

The `autounattend.xml` contains a default password (`P@ssw0rd`). **Always change this before deployment**:

```xml
<Password>
  <Value>YourSecurePassword</Value>
  <PlainText>true</PlainText>
</Password>
```

For production use, consider:
- Using encoded passwords
- Removing auto-logon after first boot
- Implementing LAPS for local admin passwords

---

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Areas for Contribution

- Additional language support (localization)
- PPKG (Provisioning Package) generation
- Additional browser support (Chrome, Firefox)
- Intune/SCCM integration scripts
- GUI wrapper application

---

## References & Inspiration

### Similar Projects

- [Chris Titus WinUtil](https://github.com/ChrisTitusTech/winutil) - Comprehensive Windows utility
- [Win11Debloat](https://github.com/Raphire/Win11Debloat) - Lightweight debloat script
- [MediaCreationTool.bat](https://github.com/AveYo/MediaCreationTool.bat) - AutoUnattend templates
- [Windows-Optimize-Debloat](https://github.com/simeononsecurity/Windows-Optimize-Debloat) - Enterprise optimization

### Microsoft Documentation

- [Edge Browser Policies](https://learn.microsoft.com/en-us/deployedge/microsoft-edge-browser-policies)
- [Windows Provisioning](https://learn.microsoft.com/en-us/windows/configuration/provisioning-packages/provisioning-packages)
- [Unattend.xml Reference](https://learn.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/)
- [Windows ADK](https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install)

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Disclaimer

This toolkit modifies Windows system settings and removes pre-installed applications. While designed to be safe:

- **Always test in a non-production environment first**
- **Create a system restore point before running**
- **Review the code before executing on production systems**
- **Some settings may conflict with organizational policies**

The authors are not responsible for any issues that may arise from using this toolkit. Use at your own risk.

---

<p align="center">
  Made with ❤️ by <a href="https://github.com/velocityeu">Velocity EU</a>
</p>
