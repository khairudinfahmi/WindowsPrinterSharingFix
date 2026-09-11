# Windows Printer Sharing Fix

[![Windows Compatibility](https://img.shields.io/badge/Windows-10%20%7C%2011%20(24H2%2F25H2%2F26H2)%20%7C%20Server%202025-0078D6?logo=windows&logoColor=white)](https://github.com/khairudinfahmi/WindowsPrinterSharingFix/releases)
[![Version](https://img.shields.io/badge/version-2.4.0-emerald.svg?style=flat)](https://github.com/khairudinfahmi/WindowsPrinterSharingFix/releases/tag/v2.4.0)
[![License](https://img.shields.io/badge/license-GPL--3.0-blue.svg)](LICENSE)
[![Architecture](https://img.shields.io/badge/architecture-x64%20%7C%20ARM64-orange.svg)](https://github.com/khairudinfahmi/WindowsPrinterSharingFix)
[![Language](https://img.shields.io/badge/language-English%20%7C%20Indonesian-purple.svg)](https://github.com/khairudinfahmi/WindowsPrinterSharingFix)

**Windows Printer Sharing Fix** is a fully automated PowerShell utility that diagnoses and fixes printer sharing and network printing failures on Windows networks (Workgroups and Active Directory domains).

Simple enough for general office use, but ships with detailed diagnostics and targeted fix modules for IT admins, sysadmins, and field engineers.

Fully supports **Windows 10**, **Windows 11 (including 24H2, 25H2, 26H2+)**, **ARM64**, and **Windows Server 2016 / 2019 / 2022 / 2025**.

---

## What's New in Version 2.4.0

1. **Native Bilingual Engine (English & Indonesian)**:
   - Toggle the interface language dynamically on the fly by pressing **`[L]`** at any menu or prompt.
   - User language preference is persisted across sessions in the registry (`HKCU:\Software\WindowsPrinterSharingFix\Language`).
2. **Real-Time System Health Banner**:
   - The console header checks and displays the live status of the four core Windows printer sharing components every time a menu renders:
     ```text
     SYSTEM HEALTH: Spooler [ACTIVE] | Network [PRIVATE] | SMB Signing [MATCHED] | Password Sharing [OFF]
     ```
   - Lets you spot network misconfigurations at a glance.
3. **Reorganized Console Layout (Human-Friendly UI)**:
   - Replaced the old single-screen menu with **8 categorized submenus + 1 interactive help system**, sized for standard 86-column console buffers.
4. **Role-Based Optimization Playbooks**:
   - **Printer Host / Server Playbook (`[3]` in Submenu 1)**: Tailored for machines with direct USB or local printer attachments.
   - **Client Workstation Playbook (`[4]` in Submenu 1)**: Tailored for employee PCs connecting across the LAN.
5. **Modern Windows 11 Security Mitigations**:
   - Works around modern RPC over Named Pipes restrictions (`RpcOverNamedPipes`, `RegisterSpoolerRemoteRpcEndPoint`).
   - Mitigates mandatory SMB Signing enforcement introduced in Windows 11 24H2.
   - Configures NTLMv2 fallback for non-domain Workgroup topologies.
6. **Direct Action Shortcuts**:
   - Execute any classic module directly from the Main Menu (e.g., enter `84` for ALLFIX, `83` for Extreme Path, `86` for UNC Port Mapping, `31` for Spooler Reset) without drilling into submenus.

---

## Quick Start Guide

### Option 1: Official Windows Installer (Recommended)
1. Download `WindowsPrinterSharingFix_Installer.exe` from the latest [GitHub Release](https://github.com/khairudinfahmi/WindowsPrinterSharingFix/releases).
2. Run the installer wizard (includes Start Menu shortcuts, Desktop launcher, and automated uninstaller).
3. Launch **Windows Printer Sharing Fix** from your Desktop (automatically elevates to Administrator).

### Option 2: Portable Executable (.EXE)
1. Download `WindowsPrinterSharingFix.exe` from [GitHub Releases](https://github.com/khairudinfahmi/WindowsPrinterSharingFix/releases).
2. Right-click the file and select **Run as Administrator**.

### Option 3: Direct PowerShell Execution
Launch an elevated PowerShell prompt (Run as Administrator) and run:
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
& ".\src\WindowsPrinterSharingFix.ps1"
```

### Option 4: Unattended CLI Switches (Automation & RMM)
Execute specialized playbooks directly via command line:
```powershell
# Run the complete 50-step ALLFIX playbook unattended
.\WindowsPrinterSharingFix.exe -AllFix

# Run ALLFIX silently and automatically reboot the system upon completion
.\WindowsPrinterSharingFix.exe -SilentAllFix

# Execute the modern Windows 11 24H2/25H2/26H2 remediation playbook
.\WindowsPrinterSharingFix.exe -ExtremePath

# Run full system diagnostics and export an interactive HTML report
.\WindowsPrinterSharingFix.exe -Diagnose

# Launch in English explicitly
.\WindowsPrinterSharingFix.exe -Language EN
```

---

## Menu & Submenu Reference (v2.4.0)

The main console organizes all 89 remediation modules into 8 dedicated categories plus an interactive help engine:

```text
======================================================================================
   WINDOWS PRINTER SHARING FIX  |  Windows Printer Sharing Solution
   Version: 2.4.0  |  OS: WINDOWS 11 PRO 26200 64-BIT
   Computer: WORKSTATION-01  |  User: Administrator
   SYSTEM HEALTH: Spooler [ACTIVE] | Network [PRIVATE] | SMB Signing [MATCHED] | Password Sharing [OFF]
======================================================================================

  [1] Quick & Automated Solutions (ALLFIX & Modern Windows 11)
  [2] Fix by Specific Error Code (Error 0x...)
  [3] Network Configuration, Sharing (SMB) & Firewall
  [4] Spooler Service & Print Queue Management
  [5] Printer Driver Handling & Compatibility
  [6] Credentials, Permissions & Windows Security
  [7] Port Mapping & Manual Connections (UNC / TCP-IP)
  [8] Backup, Diagnostics & System Recovery
  [9] Module Help System

  [L] Switch Language (English / Indonesia)
  [?] Display Module Help (e.g., ? 84 or help 86)
  [0] Exit Application
```

---

### Submenu 1: Quick & Automated Solutions (ALLFIX & Modern Windows 11)
One-click fix routines that cover the most common and complex sharing failures.

| # | Solution / Module Name | Code | Technical Description & Scope |
| :---: | :--- | :---: | :--- |
| **1** | **ALLFIX - 50 Automated Repairs in Sequence** | `[84]` | **Primary Recommendation**: Runs 50 successive repair steps across registry, Group Policy, RPC, SMB, firewall, and spooler. Resolves 98% of office network printing issues. |
| **2** | **Extreme Path (Windows 11 24H2/25H2/26H2 & ARM64)** | `[83]` | Deploys deep hardening mitigations for recent Windows 11 builds: enables RPC over Named Pipes, relaxes strict SMB signing, and configures non-domain Kerberos fallback. |
| **3** | **Printer Host / Server Tuning Playbook** | `[87]` | Dedicated playbook for the PC physically connected to the printer: enables remote RPC spooler endpoint, sets Private network, opens guest access, configures firewall/WSD, and deploys Watchdog. |
| **4** | **Client Workstation Tuning Playbook** | `[88]` | Dedicated playbook for client PCs connecting to shared printers: enables RPC Named Pipes, bypasses Point & Print elevation, disables client SMB signing, and flushes DNS. |
| **5** | **Silent ALLFIX (Automated + Immediate Reboot)** | `[85]` | Executes the 50-step ALLFIX routine without interactive prompts and immediately reboots the computer upon completion (ideal for sysadmins and unattended deployment). |
| **6** | **Manage Windows Updates & Problematic Updates** | `[69]` | Pauses updates for 35 days, provides tools to roll back breaking cumulative updates, or toggles Windows Update services to protect working print configurations. |

---

### Submenu 2: Fix by Specific Error Code (Error 0x...)
Targeted fix modules mapped to specific hexadecimal Windows network print error codes.

| # | Error Code | Code | Root Cause & Technical Fix |
| :---: | :--- | :---: | :--- |
| **1** | **0x0000011b** | `[01]` | Mitigates CVE-2021-1678 RPC authentication requirements by setting `RpcAuthnLevelPrivacyEnabled = 0` under `Control\Print`. |
| **2** | **0x00000709 / 0x7c** | `[02]` | Resolves printer name/driver binding failures by setting `CopyFilesPolicy = 1`, `ForceLegacyPrintDriver = 1`, and standardizing multi-layer RPC protocol bindings. |
| **3** | **0x00000bc4** | `[03]` | Fixes "No printers were found" by forcing `RpcUseNamedPipeProtocol = 1` and `RpcProtocols = 7` under Group Policy Printer overrides. |
| **4** | **0x80070035** | `[04]` | Fixes "The network path was not found" by automating and starting Discovery services (`fdPHost`, `FDResPub`, `SSDPSRV`, `upnphost`). |
| **5** | **0x000006d1** | `[05]` | Fixes Client-Side Rendering (CSR) spooling crashes by setting `DisableClientSideRendering = 1`, shifting rendering directly to the host spooler. |
| **6** | **0x80070005** | `[06]` | Resolves "Access Denied" on print queues by granting Full Control ACL permissions to universal `Everyone` (`S-1-1-0`) on `C:\Windows\System32\Spool\Printers`. |
| **7** | **0x00000040** | `[07]` | Fixes "The specified network name is no longer available" by setting SMB `KeepConn = 1`, disabling NetBIOS multi-channel conflicts, and clearing stale sessions. |
| **8** | **0x00000002** | `[08]` | Resolves driver file copy errors during client connection by enabling `UseSharedSpooler = 1`. |
| **9** | **0x0000007e** | `[09]` | Fixes 32-bit and 64-bit cross-architecture driver mismatch errors by injecting RPC bitness compatibility registry keys. |

---

### Submenu 3: Network Configuration, Sharing (SMB) & Firewall
Ensures underlying network connectivity, protocol compatibility, and firewall port clearance.

| # | Menu Option | Code | Details & Technical Benefit |
| :---: | :--- | :---: | :--- |
| **1** | **Switch Network Profile to Private** | `[11]` | Changes current network connection profile from Public to Private, enabling Windows sharing and file/printer discovery. |
| **2** | **Enable Passwordless Sharing & Guest Auth** | `[12]` | Sets `AllowInsecureGuestAuth = 1`, `everyoneincludesanonymous = 1`, and `LimitBlankPasswordUse = 0` for local LAN access. |
| **3** | **Disable Mandatory SMB Signing Requirement** | `[16]` | Disables `RequireSecuritySignature` on LanmanWorkstation and LanmanServer to resolve connection refusals on Windows 11 24H2+. |
| **4** | **Manage SMB Protocols (SMB2/SMB3 & SMB 1.0)** | `[15] & [17]` | Manages modern SMB2/SMB3 protocol engines and provides an emergency toggle for legacy SMBv1 for vintage print equipment. |
| **5** | **Open Firewall Ports for File & Printer Sharing** | `[14] & [21]` | Authorizes inbound TCP 445, 139, 135 and UDP 137, 138, 3702 (WSD), 5353 (mDNS) through Windows Defender Firewall. |
| **6** | **Enable Network Discovery & WSD Stack** | `[20] & [30]` | Starts the complete Windows discovery stack to ensure network printers appear in Windows Explorer and setup dialogs. |
| **7** | **Network Priority & Virtual Adapter Conflicts** | `[18] & [23]` | Prioritizes physical network adapters over virtual interfaces (Hyper-V, WSL, VMware, VPNs) to prevent routing confusion. |
| **8** | **Full Network & Socket Stack Reset** | `[10] & [27]` | Flushes DNS cache, resets Winsock catalog, resets TCP/IP stack (`netsh int ip reset`), and purges NetBIOS tables (`nbtstat -RR`). |
| **9** | **Disable IPv6 Protocol Binding** | `[19]` | Disables IPv6 binding on network adapters in pure IPv4 environments, preventing link-local resolution timeouts. |
| **10** | **Configure IPP / Mopria & LPR Port Support** | `[22] & [24]` | Enables Internet Printing Protocol (IPP) and Unix LPR legacy port support for modern multi-function devices and industrial copiers. |

---

### Submenu 4: Spooler Service & Print Queue Management
Resolves Print Spooler service crashes, clears jammed documents, and establishes automated self-healing.

| # | Menu Option | Code | Details & Technical Benefit |
| :---: | :--- | :---: | :--- |
| **1** | **Reset Spooler & Purge Jammed Queues** | `[31] & [37]` | Terminates hung spooler processes, deletes all corrupted print artifacts (`.spl` and `.shd`) from `PRINTERS`, and performs a clean restart. |
| **2** | **Configure Automatic Crash Recovery** | `[34]` | Configures Windows Service Controller to automatically restart the Print Spooler on first, second, and subsequent service failures. |
| **3** | **Install Spooler Watchdog (5-Minute Health Polling)** | `[36]` | Registers a scheduled task that audits Spooler service health every 5 minutes and auto-starts it if terminated unexpectedly. |
| **4** | **Reset Spooler Registry Dependencies** | `[35] & [38]` | Restores factory spooler dependencies (`RPCSS` and `http`), stripping corrupted third-party dependencies that prevent startup. |
| **5** | **Restart Core RPC & DCOM Subsystems** | `[32]` | Audits and verifies core RPC foundation services (`RpcSs`, `DcomLaunch`) to eliminate *"The RPC server is unavailable"* errors. |
| **6** | **Remote Spooler Restart via Network** | `[33]` | Issues a remote spooler restart command across the network via PowerShell remoting/DCOM without requiring physical access. |

---

### Submenu 5: Printer Driver Handling & Compatibility
Manages driver locks, uninstalls legacy driver packages cleanly, and mitigates Windows 11 driver isolation issues.

| # | Menu Option | Code | Details & Technical Benefit |
| :---: | :--- | :---: | :--- |
| **1** | **Force-Kill Driver Locking Processes** | `[44]` | Forcefully kills `splwow64.exe`, `printfilterpipelinesvc.exe`, and driver isolation wrappers holding open handles to driver DLLs. |
| **2** | **Disable Printer Driver Isolation** | `[40]` | Sets `IsolationPolicy = 0` to run drivers within the primary spooler process, preventing isolation process communication crashes. |
| **3** | **Orphaned Driver Sweeper (Clean Purge)** | `[43]` | Scans and uninstalls orphaned OEM print driver packages from the Windows Driver Store using native `pnputil`. |
| **4** | **Purge Ghost Printers & Stale USB Ports** | `[45] & [46]` | Removes duplicate printer queues ("Copy 1", "Copy 2") and cleans dead USB virtual printer ports left by physical re-plugging. |
| **5** | **Universal V4 Driver Sharing & Render Mode** | `[41] & [42]` | Enables network sharing for Windows 11 V4 Class Drivers and allows toggling render data types between RAW, PCL, and PostScript. |
| **6** | **Repair Browser & UWP Print Dialogs** | `[47] & [49]` | Resolves blank, frozen, or crashing print dialogs in Google Chrome, Microsoft Edge, and modern Windows Store applications. |
| **7** | **Reinstall Windows Default Virtual Printers** | `[48]` | Reinstalls missing virtual printers including *Microsoft Print to PDF* and *Microsoft XPS Document Writer*. |
| **8** | **Lock Permanent Default Printer in Registry** | `[50] & [51]` | Explicitly locks your preferred default printer in HKCU and disables Windows automatic default printer switching behavior. |
| **9** | **Sanitize Share Names (Strip Illegal Characters)** | `[53]` | Scans all shared printer names and replaces spaces or illegal symbols (`!@#$%^&*`) with underscores to prevent SMB rejection. |
| **10** | **Open Print Management & Driver Properties** | `[39]` | Launches the native Windows Print Management MMC snap-in (`printmanagement.msc` or `printui`) for full driver inspection. |

---

### Submenu 6: Credentials, Permissions & Windows Security
Manages multi-machine authentication, Windows Vault credentials, and Windows 11 security policies.

| # | Menu Option | Code | Details & Technical Benefit |
| :---: | :--- | :---: | :--- |
| **1** | **Store Target Machine Credentials in Vault** | `[60]` | Writes target machine credentials directly into the *Windows Credential Manager* (`cmdkey`) for permanent access. |
| **2** | **Purge Stale Credentials from Windows Vault** | `[61]` | Scans and deletes expired or conflicting target machine credentials stored in Vault that cause persistent access denied errors. |
| **3** | **Deploy Credentials Across All Local Profiles** | `[63]` | Injects printer credentials across all user profiles on the workstation via multi-user RunOnce deployment with automatic self-cleanup. |
| **4** | **Bypass Local Administrator UAC Token Filter** | `[57]` | Enables `LocalAccountTokenFilterPolicy = 1` to prevent Windows from stripping administrative tokens during remote network access. |
| **5** | **Standardize NTLMv2 Authentication Level** | `[58]` | Aligns NTLM authentication (`LmCompatibilityLevel = 2` or `3`) to ensure interoperability across heterogeneous Windows editions. |
| **6** | **Bypass Strict Security (LSA, SAC, Credential Guard)** | `[54], [55], [62]` | Adapts strict Windows 11 enterprise mitigations that block legacy network authentication tokens on Workgroup LANs. |
| **7** | **Manage Windows Protected Print (WPP)** | `[59]` | Configures Windows 11 *Windows Protected Print* mode to prevent unilateral disabling of third-party V3 print drivers. |
| **8** | **Bypass Point and Print Elevation Prompts** | `[56]` | Eliminates Administrator elevation UAC prompts when client workstations automatically download drivers from the host printer PC. |
| **9** | **Repair Remote Desktop (RDP) Printer Redirection** | `[52]` | Fixes client printer redirection inside Remote Desktop sessions by re-enabling Terminal Services registry redirection keys. |

---

### Submenu 7: Port Mapping & Manual Connections (UNC / TCP-IP)
Direct connection methods when standard Windows Network Discovery fails.

| # | Menu Option | Code | Details & Technical Benefit |
| :---: | :--- | :---: | :--- |
| **1** | **Map Local Port to UNC Path (Ultimate 0x709 Bypass)** | `[86]` | Creates a local port mapped directly to a host UNC path (e.g., `\\192.168.1.50\PRINTER`). Bypasses all client-side Point & Print driver restrictions. |
| **2** | **Remove Injected Local UNC Port** | `[87]` | Removes previously injected UNC local ports cleanly from the spooler and registry port enumeration keys. |
| **3** | **Convert WSD Port to Standard TCP/IP Port** | `[26]` | Converts unreliable WSD ports (which frequently display printers as *Offline*) to stable static TCP/IP raw ports. |
| **4** | **Add Standard TCP/IP Port Manually** | `[29]` | Creates a direct Raw TCP/IP printing port (Port 9100) via WMI using the printer's static IP address. |
| **5** | **Scan Shared Printers on Target Host** | `[25]` | Interrogates the target network computer and displays all currently exposed printer shares. |

---

### Submenu 8: Backup, Diagnostics & System Recovery
Safety mechanisms to back up system state prior to modifications and deep diagnostic analysis tools.

| # | Menu Option | Code | Details & Technical Benefit |
| :---: | :--- | :---: | :--- |
| **1** | **Back Up 5 Critical Printer & Network Registry Hives** | `[64]` | Exports 5 vital hives (Print, PrintersPolicy, LanmanWorkstation, LanmanServer, Lsa) to `C:\WindowsPrinterSharingFixBackup`. |
| **2** | **Restore Registry from Backup (Rollback)** | `[65]` | Re-imports the backup `.reg` hives to restore original system state whenever needed. |
| **3** | **Create Windows System Restore Point** | `[66]` | Creates an immediate Windows System Restore Point with automatic frequency-limit bypass. |
| **4** | **Check & Repair System Integrity (SFC & DISM)** | `[67]` | Executes `sfc /scannow` and `dism /online /cleanup-image /restorehealth` to repair corrupted Windows core components. |
| **5** | **Network Reachability & Port Connectivity Test** | `[74]` | Performs raw TCP socket handshakes on Port 445 (SMB) and Port 135 (RPC) to verify firewall clearance to the target host. |
| **6** | **Analyze Print Service Event Logs (PrintService/Admin)** | `[76] & [78]` | Inspects Windows Event Logs for print service errors and provides actionable diagnostic guidance based on event IDs. |
| **7** | **Generate Interactive HTML Diagnostic Report** | `[79]` | Collects system configuration, spooler health, ports, and registry states into a single interactive HTML report. |
| **8** | **Audit Active Directory / Domain GPO Interventions** | `[80]` | Detects whether domain Group Policies are actively overriding local printer sharing registry configurations. |
| **9** | **Printer Migration Utility (PrintBRM Export/Import)** | `[81]` | Backs up or restores complete printer queues, driver packages, and ports across machines using native Windows PrintBRM. |
| **10** | **Force Stalled Printer to Online State** | `[71]` | Sends WMI instructions to the print queue to clear hung error flags and force offline printers back to *Online*. |
| **11** | **Open Services Console & Execution Log** | `[72] & [75]` | Launches `services.msc` or immediately displays the execution log file (`C:\WindowsPrinterSharingFixLog.txt`). |

---

### Submenu 9: Module Help System
Built-in technical reference and usage guidance for every module.
- Type **`? <module_code>`** or **`help <module_code>`** directly from the Main Menu (e.g., `? 84` or `help 86`) for instant console documentation.
- Opens offline documentation in your default browser.

---

## Under the Hood: Resilience and Persistence

When automated playbooks (**ALLFIX [84]** or **Extreme Path [83]**) are executed, the engine applies multiple safety and persistence mechanisms:

1. **Group Policy Synchronization (`gpupdate /force`)**: Refreshes local Group Policy before writing registry overrides to prevent immediate policy rollback.
2. **Pre-Change Registry Backup**: Backs up 5 critical registry hives to `C:\WindowsPrinterSharingFixBackup` before making any modifications.
3. **Resilient Scheduled Tasks**:
   - `PrinterFixPostUpdate` (triggered at system boot) & `PrinterFixDaily` (daily at 10:00 AM): Re-applies critical sharing parameters if monthly Windows Updates (*Patch Tuesday*) revert configurations.
   - `SpoolerWatchdog` (runs every 5 minutes): Actively monitors the Print Spooler service and restarts it if terminated by buggy third-party drivers.
   - *Configured to bypass laptop battery restrictions so background protection remains active on DC power.*
4. **Clean Session & Ticket Eviction**: Executes `klist purge`, `ipconfig /flushdns`, and `nbtstat -RR` to flush stale NetBIOS names, expired Kerberos tickets, and cached DNS entries.

---

## Building and Compiling from Source

### Prerequisites
- Windows 10 / 11 / Server (x64 or ARM64)
- PowerShell 5.1+
- Inno Setup 6 (for building the installer)

### Compile Portable Executable
```powershell
powershell -ExecutionPolicy Bypass -File build\Compile-ToExe.ps1
```
This builds `release\WindowsPrinterSharingFix.exe` embedded with application metadata, an administrator manifest, icon resources, and Authenticode digital signatures.

### Compile Windows Setup Installer
```powershell
& "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" build\installer.iss
powershell -ExecutionPolicy Bypass -File scratch\sign_installer.ps1
```
This compiles `release\WindowsPrinterSharingFix_Installer.exe` and applies a trusted Authenticode signature.

---

## License and Contribution

This project is licensed under the **GNU General Public License v3.0 (GPL-3.0)**. Free to use, modify, and distribute for both personal and enterprise environments.

Contributions and feedback are welcome! Please submit bug reports or feature requests via [GitHub Issues](https://github.com/khairudinfahmi/WindowsPrinterSharingFix/issues) or submit a Pull Request following our [CONTRIBUTING.md](CONTRIBUTING.md).

