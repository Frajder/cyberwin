# Cyberwin

Cyberwin adds an unattended configuration for a clean installation from official Windows 11 x64 media. Setup still asks you to select the destination disk; this answer file does not partition or erase a disk automatically. Activation uses your normal Windows license.

## Build on Linux

Download a current [Windows 11 x64 ISO from Microsoft](https://www.microsoft.com/software-download/windows11), select **Slovenian** as the product language, verify its published SHA-256, and save it as `~/Downloads/Windows11.iso`. Use Windows Pro or Enterprise on a supported release with Microsoft Store and App Installer; LTSC editions can lack these components. Allow free space for the extracted files and output ISO, about twice the input ISO size beyond the downloaded file.

On Debian 13 or Ubuntu 24.04 and newer, run this one line from a directory where `cyberwin` does not already exist:

```bash
sudo apt-get update && sudo apt-get install -y git xorriso 7zip python3 && git clone --branch codex/linux-iso-and-required-apps --depth 1 https://github.com/Frajder/cyberwin.git cyberwin && bash cyberwin/build-iso.sh "$HOME/Downloads/Windows11.iso" "$HOME/cyberwin.iso"
```

The builder asks for the administrator username, default `rr`, then reads its password without displaying it. Setup creates that account and disables the built-in Administrator account. The Windows sign-in screen asks for a username and password. Enter `rr` at sign-in or `.\rr` when an elevation dialog needs the local account name. Automatic sign-in is not configured.

The result is `~/cyberwin.iso` and `~/cyberwin.iso.sha256`. Windows Setup and the installed desktop use Slovenian, with the Slovenian keyboard, regional formats and Ljubljana time zone. Both the source language files and XML settings matter: the builder rejects an ISO without `sl-SI`, so an English-only ISO cannot silently produce English Windows. The script runs as your ordinary Linux user, extracts UDF media with 7-Zip, and builds BIOS and UEFI El Torito boot entries with xorriso. ISO level 3 supports installation images larger than 4 GiB. It checks both boot entries and exact answer-file readback, refuses to overwrite existing output, and cleans up temporary files.

The ISO contains the locally supplied account password. Keep it private and change the password after deployment. The public template contains placeholders; use the builder to fill them.

For an existing checkout with dependencies installed:

```bash
bash ./build-iso.sh /path/to/Windows11.iso /path/to/cyberwin.iso
```

On Arch Linux, install `git xorriso 7zip python` with pacman. Other distributions need Bash, Python 3, coreutils, xorriso, and either `7z` or `7zz`. The username prompt accepts 1–20 ASCII letters, digits, underscores, dots or hyphens, beginning with a letter or digit; built-in account names are rejected. For automation, `CYBERWIN_ADMIN_USER` selects the name and standard input supplies one password line. Keep passwords out of shell history and command arguments.

## Install and finish setup

Boot the ISO directly in a VM. For physical USB installation, use a Windows-compatible tool such as Ventoy or WoeUSB-ng. El Torito optical boot support does not make a Windows ISO a USB disk image.

Choose the edition and destination disk, complete the remaining regional/OOBE prompts, then sign in to the declared account. Setup creates that account, so a second manual account declaration is unnecessary. OOBE screens vary by Windows release.

At the first sign-in for each new profile, Cyberwin keeps or installs these apps:

| App | Behavior |
| --- | --- |
| Paint | Preserved during debloating; installed from Microsoft Store if absent. |
| Microsoft Photos | Preserved during debloating; the reduced inbox viewer is upgraded to the full Microsoft Store app. |
| Microsoft Edge | Retained from the source ISO; installed with WinGet if absent. |
| OneDrive | Existing installation is uninstalled if present; setup stubs and startup entries are removed on a clean install. User documents are preserved. Photos can still show its own cloud sign-in links. |

Missing or reduced apps need internet access and working Microsoft Store/App Installer. The script first updates the inbox App Installer client through WinGet, preserving Store certificate validation, then checks the installed result. Its runtime dependency may ask for normal UAC approval. If anything is missing or incomplete, it leaves a `Finish Cyberwin setup` desktop shortcut and shows a warning. Connect to the internet and run that shortcut. Logs are in `%LOCALAPPDATA%\Cyberwin\apps.log`.

UAC stays enabled with normal administrator approval on the secure desktop. ODOS+ is a desktop URL shortcut; this project does not need an application-specific elevation workaround.

Windows quality/security updates are enabled without a deferral. Optional previews are disabled and feature upgrades are deferred for 365 days. Plan an upgrade before the installed release leaves support; Windows Home does not support all enterprise update policies. The Windows 10 22H2 target pin is removed. Windows service defaults, including Update, Store and Edge update services, are retained. Security fixes arrive as cumulative quality updates, which can also contain reliability fixes; there is no separate security-only update channel configured here.

## What the configuration does

During `windowsPE`, the original hardware-check bypasses remain. Supported hardware is preferred because unsupported installations can affect Microsoft support and update eligibility.

During `specialize`, embedded files are extracted to `C:\Windows\Setup\Scripts`. The removal script deletes apps from its explicit list and selected optional capabilities, while retaining Paint, Photos, Store and App Installer. The system scripts enable .NET Framework 3.5, remove OneDrive/Teams, configure UAC and updates, disable the built-in Administrator by its SID, and apply the existing privacy, Start menu, telemetry, power and registry tweaks. The context-menu file adds Take Ownership. Protected user policies are applied to the loaded Default user hive before profile creation, so RunOnce can run with normal UAC. The default user profile receives a RunOnce entry for the remaining user settings.

During `oobeSystem`, Setup creates the locally configured administrator account and applies OOBE preferences. After sign-in, the user script applies the existing taskbar, Explorer, dark-theme, privacy and visual settings, then verifies Paint, Photos and Edge. It no longer forces legacy Windows Photo Viewer associations or reboots during app installation. Administrative file-system settings run during `specialize`, so the user script works with UAC enabled.

Existing tweaks also disable automatic device encryption, remove several standard apps/capabilities, suppress selected telemetry tasks, and change the power plan. Review `autounattend.xml` before deployment if these choices differ from your requirements.

## Validation and troubleshooting

Run `python3 -m unittest discover -s tests -v` for account-generation tests and `shellcheck build-iso.sh` for shell checks. See [VALIDATION.md](VALIDATION.md) for the real installation test and its limits.

If Setup does not apply the configuration, verify `autounattend.xml` is at the ISO root and inspect `C:\Windows\Panther\setupact.log` and `setuperr.log`. System-tweak logs are in `C:\Windows\Setup\Scripts`. The template is x64-only.

If Paint/Photos are missing or Photos asks for the full experience, inspect the app log, internet access and App Installer registration. Microsoft documents [WinGet registration and installation](https://learn.microsoft.com/windows/package-manager/winget/) and [App Installer updates](https://learn.microsoft.com/windows/msix/app-installer/install-update-app-installer). App sources are [Paint](https://apps.microsoft.com/detail/9pcfs5b6t72h), [Photos](https://apps.microsoft.com/detail/9wzdncrfjbh4) and Microsoft.Edge in the WinGet repository.

The original file credits Memory's Tech Tips, [Schneegans' generator](https://schneegans.de/windows/unattend-generator/) and [Chris Titus Tech's WinUtil](https://github.com/ChrisTitusTech/winutil). Platform references: [UAC](https://learn.microsoft.com/windows/security/application-security/application-control/user-account-control/settings-and-configuration), [Windows Update policies](https://learn.microsoft.com/windows/deployment/update/windows-update-client-policies), [xorriso](https://www.gnu.org/software/xorriso/man_1_xorriso.html).
