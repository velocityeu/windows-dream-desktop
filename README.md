# Windows Dream Desktop Setup

A comprehensive Windows customization toolkit for zero-touch deployments. Bypasses all first-login Microsoft prompts, configures Edge browser defaults, removes bloatware, and hardens privacy settings.

## Features

- **OOBE Bypass**: Skip all Windows setup prompts, "Let's finish setting up" reminders, and consent dialogs
- **Edge Configuration**: Set homepage, Google search, auto sign-in with domain account
- **Bloatware Removal**: Remove pre-installed apps with three modes (All, Selective, Keep)
- **Privacy Hardening**: Disable telemetry, Copilot, Recall, Cortana, and tracking features
- **Multi-Edition Support**: Works on Windows 10/11 Pro, Enterprise, and Education

## Quick Start

### Method 1: PowerShell Script (Recommended)

```powershell
# Run as Administrator
.\SetupDreamDesktop.ps1
```

### Method 2: Silent/Automated Mode

```powershell
# Apply all settings without prompts
.\SetupDreamDesktop.ps1 -FullSetup
```

### Method 3: Clean Install with AutoUnattend

1. Copy `autounattend.xml` to the root of your Windows installation USB
2. Boot from USB and install Windows
3. OOBE will be automatically bypassed

### Method 4: Registry Files (Manual)

Import the `.reg` files from the `Config` folder:
- `EdgePolicy.reg` - Edge browser configuration
- `PrivacySettings.reg` - Privacy and telemetry settings

## Directory Structure

```
SetupDreamWindowsDesktop/
├── SetupDreamDesktop.ps1      # Main interactive script
├── autounattend.xml           # OOBE bypass for clean install
├── Config/
│   ├── Settings.json          # User configuration
│   ├── BloatwareList.json     # App removal definitions
│   ├── EdgePolicy.reg         # Edge registry settings
│   └── PrivacySettings.reg    # Privacy registry settings
├── Modules/
│   ├── OOBE-Bypass.ps1        # OOBE/wizard functions
│   ├── Edge-Setup.ps1         # Edge configuration
│   ├── Debloat.ps1            # Bloatware removal
│   └── Privacy.ps1            # Privacy/telemetry settings
└── README.md
```

## Configuration

### Edge Settings (`Config/Settings.json`)

```json
{
  "Edge": {
    "Homepage": "https://www.velocity-eu.com",
    "SearchEngine": {
      "Name": "Google",
      "SearchURL": "https://www.google.com/search?q={searchTerms}"
    },
    "AutoSignIn": {
      "Enabled": true,
      "UseADAccount": true
    }
  }
}
```

### Bloatware Modes

| Mode | Description |
|------|-------------|
| **Remove All** | Removes all bloatware except protected system apps |
| **Selective** | Interactive category-based selection |
| **Keep Default** | Skip bloatware removal |

### Protected Apps (Never Removed)

- Microsoft Store
- Calculator, Photos, Notepad, Paint
- Windows Terminal
- Media codecs and extensions

## What Gets Disabled

### Windows Prompts
- "Let's finish setting up your device"
- Privacy consent dialogs
- Microsoft account prompts
- Windows Welcome screens

### Application Wizards
- Edge first run experience
- Office/Outlook first run wizard
- Teams auto-start popup
- OneDrive setup popup

### AI Features (Windows 11)
- Windows Copilot
- Windows Recall
- Click to Do

### Telemetry & Tracking
- Diagnostic data (set to Basic/Security)
- Advertising ID
- Activity History
- App launch tracking
- Cortana/Bing search

## Requirements

- Windows 10 or 11 (Pro, Enterprise, or Education recommended)
- Administrator privileges
- PowerShell 5.1 or later

> **Note**: Some features are limited on Windows Home edition due to lack of Group Policy support.

## AutoUnattend.xml

The included `autounattend.xml` file:

1. **Bypasses hardware requirements** (TPM, Secure Boot, RAM) for Windows 11
2. **Creates local admin account** (Username: Admin, Password: P@ssw0rd)
3. **Skips OOBE screens** (EULA, privacy, network, account)
4. **Applies registry settings** on first login

> **Security Note**: Change the default password in `autounattend.xml` before deployment!

## References

### GitHub Projects
- [Chris Titus WinUtil](https://github.com/ChrisTitusTech/winutil)
- [Win11Debloat](https://github.com/Raphire/Win11Debloat)
- [MediaCreationTool.bat](https://github.com/AveYo/MediaCreationTool.bat)

### Microsoft Documentation
- [Edge Enterprise Policies](https://learn.microsoft.com/en-us/deployedge/microsoft-edge-browser-policies)
- [Windows Provisioning Packages](https://learn.microsoft.com/en-us/windows/configuration/provisioning-packages/provisioning-packages)
- [Unattend.xml Reference](https://learn.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/)

## License

MIT License - Feel free to use, modify, and distribute.

## Disclaimer

This toolkit modifies Windows system settings. Always test in a non-production environment first. The authors are not responsible for any issues that may arise from using this toolkit.
