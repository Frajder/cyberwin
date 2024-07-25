# Cyberwin

This repository contains tools and instructions for creating a bootable Windows 11 ISO with an `autounattend.xml` file on a Linux system.

## Prerequisites
1. **Windows 11 ISO**: Download the official Windows 11 ISO from the [Microsoft website](https://www.microsoft.com/software-download/windows11).
2. **genisoimage and mkisofs**: Install these tools on your Linux system.
3. **autounattend.xml**: Copy `autounattend.xml` file from the repository.

## Steps

### 1. Install Necessary Tools
Open a terminal and install `genisoimage` and `mkisofs`:

```bash
sudo apt update
sudo apt install genisoimage mkisofs git
```

### 2. Mount the Windows 11 ISO
Create a mount point and mount the Windows 11 ISO:

```bash
mkdir /mnt/cyberwin
sudo mount -o loop ~/Downloads/Win11_23H2_EnglishInternational_x64v2.iso /mnt/cyberwin
```

### 3. Clone Cyberwin Repository and Copy the Contents of the ISO to a Working Directory
Create a working directory and copy the contents of the mounted ISO:

```bash
cd $HOME
git clone git@github.com:Frajder/cyberwin.git
mkdir ~/cyberwin/win11iso
cp -rp /mnt/cyberwin/* ~/cyberwin/win11iso/
```

### 4. Add Your autounattend.xml File
Copy your custom `autounattend.xml` file to the root of the working directory:

```bash
cp ~/cyberwin/autounattend.xml ~/cyberwin/win11iso/
```

### 5. Create the Bootable ISO
Use `mkisofs` to create the bootable ISO:

```bash
cd ~/cyberwin/win11iso
sudo mkisofs -iso-level 3 -udf -D -b boot/etfsboot.com -no-emul-boot -boot-load-seg 0x07C0 -boot-load-size 8 -allow-limited-size -o ~/win11_bootable.iso -m boot.catalog -relaxed-filenames -volid "WIN11" .
```

### 6. Verify the ISO
You can verify the contents of the newly created ISO to ensure it includes the `autounattend.xml` file:

```bash
mkdir /mnt/cyberwin
sudo mount -o loop ~/win11_bootable.iso /mnt/cyberwin
ls /mnt/cyberwin
```

Ensure that `autounattend.xml` is present in the root directory.

### 7. Create a Bootable USB
Replace `/dev/sdX` with the appropriate USB drive identifier. Be very careful with this command, as selecting **the wrong device can result in data loss**.

```bash
sudo dd if=~/win11_bootable.iso of=/dev/sdX bs=4M status=progress
```

That's it! You've created a bootable Windows 11 ISO with an `autounattend.xml` file on Linux.

## Actions list in autounattend.xml

List of the actions that the `autounattend.xml` file performs:

### General Information
- The XML file is designed for unattended installation of Windows 10 and 11 with various customizations, debloating actions, and tweaks.
- It contains credit to Memory's Tech Tips, Schneegans.de, and Chris Titus Tech for the base file and tweaks.

### Pass: `offlineServicing`
- No specific actions defined.

### Pass: `windowsPE`
- **Product Key Configuration**
  - Set the Windows product key.
  - Automatically accept the EULA.

- **Bypass Windows 11 System Requirements**
  - Add registry entries to bypass TPM, Secure Boot, Storage, CPU, RAM, and Disk checks.
  - Force Windows Setup to show all available editions during setup.

### Pass: `generalize`
- No specific actions defined.

### Pass: `specialize`
- **Run Synchronous Commands**
  - Extract and execute scripts defined within the XML file.
  - Execute a PowerShell script to remove pre-installed packages.
  - Run Chris Titus Tech's WinUtil Tweaks.
  - Execute a script for HKLM registry entries.
  - Add items to the right-click context menu.
  - Load and unload the default user registry hive for modifications.
  - Add registry entries to execute a script the first time a new user logs in.

### Pass: `auditSystem`
- No specific actions defined.

### Pass: `auditUser`
- No specific actions defined.

### Pass: `oobeSystem`
- **OOBE Configuration**
  - Hide EULA, OEM registration, online account, and wireless setup screens during OOBE.
  - Set network location to "Work".
  - Set Windows Update protection level to 3.

### Extensions
- **Scripts and Customizations**
  - **ExtractScript:** Extracts and executes embedded scripts.
  - **remove-packages.ps1:** Removes pre-installed bloatware apps and Windows capabilities.
  - **wintweaks.ps1:** Various system tweaks including enabling .NET Framework, setting execution policies, disabling telemetry, removing OneDrive and Teams, and adjusting system services.
  - **localmachine.cmd:** Sets features and policies for the local machine, including bypassing Microsoft account creation, disabling UAC, customizing start menu, and applying various registry tweaks.
  - **contextmenu.reg:** Adds "Take Ownership" to the right-click context menu.
  - **currentuser.cmd:** Applies customizations and privacy settings for the current user, such as disabling telemetry, ads, and background apps, and customizing the taskbar and start menu.
  - **LayoutModification.xml:** Defines a start menu template layout for new user profiles.

### Detailed Actions
- **Bypass Windows 11 System Requirements:**
  - Bypass TPM, Secure Boot, Storage, CPU, RAM, and Disk checks via registry entries.
  - Modify Windows Setup to show all editions.

- **HKLM Registry Entries:**
  - Disable UAC.
  - Customize Windows Spotlight and lock screen settings.
  - Set desktop wallpaper.
  - Disable various Windows features and telemetry.
  - Optimize performance settings.

- **HKCU Registry Entries:**
  - Disable personalized content and ads.
  - Remove OneDrive setup.
  - Align taskbar and customize start menu.
  - Set performance and gaming optimizations.

This list highlights the extensive customization and optimization actions performed by the `autounattend.xml` file during the unattended installation of Windows.