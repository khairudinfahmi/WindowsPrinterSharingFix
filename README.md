# Windows Printer Sharing Fix

[![GitHub Stars](https://img.shields.io/github/stars/khairudinfahmi/WindowsPrinterSharingFix?style=flat&logo=github&color=gold)](https://github.com/khairudinfahmi/WindowsPrinterSharingFix/stargazers)
[![GitHub Forks](https://img.shields.io/github/forks/khairudinfahmi/WindowsPrinterSharingFix?style=flat&logo=github&color=blue)](https://github.com/khairudinfahmi/WindowsPrinterSharingFix/network/members)
[![GitHub Issues](https://img.shields.io/github/issues/khairudinfahmi/WindowsPrinterSharingFix?style=flat&color=red)](https://github.com/khairudinfahmi/WindowsPrinterSharingFix/issues)
[![Windows Compatibility](https://img.shields.io/badge/Windows-10%20%7C%2011%20(24H2%2F25H2%2F26H2)%20%7C%20Server%202025-0078D6?logo=windows&logoColor=white)](https://github.com/khairudinfahmi/WindowsPrinterSharingFix/releases)
[![Version](https://img.shields.io/badge/version-2.4.0-emerald.svg?style=flat)](https://github.com/khairudinfahmi/WindowsPrinterSharingFix/releases/tag/v2.4.0)
[![License](https://img.shields.io/badge/license-GPL--3.0-blue.svg)](LICENSE)
[![Architecture](https://img.shields.io/badge/architecture-x64%20%7C%20ARM64-orange.svg)](https://github.com/khairudinfahmi/WindowsPrinterSharingFix)
[![Language](https://img.shields.io/badge/language-English%20%7C%20Indonesian-purple.svg)](https://github.com/khairudinfahmi/WindowsPrinterSharingFix)

> ⭐ **Found this helpful?** If this utility fixed your office printer sharing or saved you hours of troubleshooting, please **give this repository a Star**! It helps more sysadmins, IT technicians, and home office users discover this project.

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
   - **Printer Host / Server Playbook (`[3]` in Submenu 1)**: Configured for host PCs with direct USB or local printer connections.
   - **Client Workstation Playbook (`[4]` in Submenu 1)**: Configured for client PCs connecting over the local network.
5. **Modern Windows 11 Security Mitigations**:
   - Works around modern RPC over Named Pipes restrictions (`RpcOverNamedPipes`, `RegisterSpoolerRemoteRpcEndPoint`).
   - Mitigates mandatory SMB Signing enforcement introduced in Windows 11 24H2.
   - Configures NTLMv2 fallback for non-domain Workgroup topologies.
6. **Direct Action Shortcuts**:
   - Execute any classic module directly from the Main Menu (e.g., enter `84` for ALLFIX, `83` for Extreme Path, `86` for UNC Port Mapping, `31` for Spooler Reset) without drilling into submenus.

---

## Quick Start Guide

### Option 0: One-Liner Web Launch (Instant - No Download Required)
Open PowerShell as Administrator (`Win + X` -> **Terminal (Admin)** or **Windows PowerShell (Admin)**) and paste:
```powershell
irm https://raw.githubusercontent.com/khairudinfahmi/WindowsPrinterSharingFix/main/src/WindowsPrinterSharingFix.ps1 | iex
```
*This streams and executes the latest signed release directly in memory without modifying your disk.*

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

## Instant Error Code Quick-Lookup Matrix

Quickly identify your Windows network printer error code and match it to its root cause, security policy, and direct resolution:

| Error Code / Symptom | Exact Windows Error Message | Root Cause & Security Policy | Recommended Action / CLI Switch |
| :--- | :--- | :--- | :--- |
| **0x0000011b** | *Operation failed with error 0x0000011b* | RPC authentication level requirement (`CVE-2021-1678`) introduced by Windows security updates. | Run `[01]` or `.\WindowsPrinterSharingFix.exe -AllFix` |
| **0x00000709** / **0x7c** | *Operation could not be completed (error 0x00000709)* | Point and Print driver elevation requirement or RPC named pipes binding refusal. | Run `[02]`, `[56]`, or UNC Port Mapping `[86]` |
| **0x00000bc4** | *No printers were found* | Windows 11 default RPC connection protocol restricted to TCP rather than Named Pipes. | Run `[03]` (Forces `RpcUseNamedPipeProtocol = 1`) |
| **0x00000040** | *The specified network name is no longer available* | Stale SMB keep-alive sessions, socket timeout, or driver provider disconnection. | Run `[07]` (Sets `KeepConn=65535` & extends timeouts) |
| **SMB Signing Refusal** | *You can't access this shared folder because your organization's security policies block unauthenticated guest access* | Windows 11 24H2/25H2 mandatory SMB signing requirement (`RequireSecuritySignature`). | Run `[16]` or `.\WindowsPrinterSharingFix.exe -ExtremePath` |
| **0x80070035** | *The network path was not found* | Function Discovery Resource Publication (`FDResPub`) or SSDP discovery services disabled. | Run `[04]` or `[20]` (Starts discovery stack) |
| **0x000006d1** | *Windows cannot connect to the printer (0x000006d1)* | Client-Side Rendering (CSR) crash during spooling over network. | Run `[05]` (Sets `DisableClientSideRendering = 1`) |
| **0x80070005** | *Access is denied* | Insufficient NTFS / Spooler ACL permissions on `System32\Spool\Printers`. | Run `[06]` (Grants universal `Everyone` queue ACL) |
| **0x00000002** | *The system cannot find the file specified* | Point & Print CopyFilesPolicy ingestion restriction blocking remote driver transfer. | Run `[08]` (Enables `UseSharedSpooler = 1`) |
| **0x0000007e** | *The specified module could not be found* | Cross-architecture (32-bit client to 64-bit server) driver bitness mismatch. | Run `[09]` (Injects architecture compatibility keys) |

---

## Menu & Submenu Reference (v2.4.0)

The main console provides 89 direct execution module codes (`1`–`89`), structured into 8 dedicated categories (73 interactive submenu options) plus an interactive help engine:

```text
======================================================================================
   WINDOWS PRINTER SHARING FIX  |  Windows Printer Sharing Solution
   Version: 2.4.0  |  OS: WINDOWS 11 PRO 26200 64-BIT
   Computer: WORKSTATION-01  |  User: Administrator
   SYSTEM HEALTH: Spooler [ACTIVE] | Network [PRIVATE] | SMB Signing [MATCHED] | Password Sharing [OFF]
======================================================================================

  [1] Quick & Automated Solutions (ALLFIX & Modern Win 11)
  [2] Fix Specific Error Codes (0x11b, 0x709, 0xbc4, 0x040, etc.)
  [3] Network, File & Printer Sharing (SMB) & Firewall
  [4] Print Spooler Service & Print Queue Maintenance
  [5] Driver Management & Ghost / USB Printer Cleanup
  [6] Credentials, Access Rights & Security (Vault, LSA, UAC)
  [7] Port Mapping & Manual Connections (UNC Port Map & TCP/IP)
  [8] Backup, System Diagnostics & Recovery
  [9] Help & Usage Guide

  [L] Switch Language (English / Indonesia)
  [?] Display Module Help (e.g., ? 84 or help 86)
  [0] Exit Application
```

---

### Submenu 1: Quick & Automated Solutions (ALLFIX & Modern Win 11)
One-click fix routines that cover the most common and complex sharing failures.

| # | Menu Option (Exact Console String) | Code | Technical Description & Scope |
| :---: | :--- | :---: | :--- |
| **1** | **ALLFIX - Run 50 Automated Fixes Simultaneously** | `[84]` | **Primary Recommendation**: Runs 50 successive repair steps across registry, Group Policy, RPC, SMB, firewall, and spooler. Resolves 98% of office network printing issues. |
| **2** | **Extreme Path for Modern Windows 11 (24H2 / 25H2 / 26H2 & ARM64)** | `[83]` | Deploys deep hardening mitigations for recent Windows 11 builds: enables RPC over Named Pipes, relaxes strict SMB signing, and configures non-domain Kerberos fallback. |
| **3** | **Optimize Host / Print Server PC (Connected directly to printer)** | `Playbook` | Dedicated playbook for the PC physically connected to the printer: enables remote RPC spooler endpoint, sets Private network, opens guest access, configures firewall/WSD, and deploys Watchdog. |
| **4** | **Optimize Client PC (Connecting to shared printer over network)** | `Playbook` | Dedicated playbook for client PCs connecting to shared printers: enables RPC Named Pipes, bypasses Point & Print elevation, disables client SMB signing, and flushes DNS. |
| **5** | **Silent ALLFIX (Automated Fixes + Immediate Reboot)** | `[85]` | Executes the 50-step ALLFIX routine without interactive prompts and immediately reboots the computer upon completion (ideal for sysadmins and unattended deployment). |
| **6** | **Manage Windows Updates & Block Printer-Breaking Patches** | `[69]` | Pauses updates for 35 days, provides tools to roll back breaking cumulative updates, or toggles Windows Update services to protect working print configurations. |

---

### Submenu 2: Fix Specific Error Codes (0x11b, 0x709, 0xbc4, 0x040, etc.)
Targeted fix modules mapped to specific hexadecimal Windows network print error codes.

| # | Menu Option (Exact Console String) | Code | Root Cause & Technical Fix |
| :---: | :--- | :---: | :--- |
| **1** | **Error 0x0000011b - Patch RPC Authentication Block (RpcAuthnLevelPrivacy)** | `[01]` | Mitigates CVE-2021-1678 RPC authentication requirements by setting `RpcAuthnLevelPrivacyEnabled = 0` under `Control\Print`. |
| **2** | **Error 0x00000709 / 0x7c - Network Printer Connection Failure (Point and Print / RPC)** | `[02]` | Resolves printer name/driver binding failures by setting `CopyFilesPolicy = 1`, `ForceLegacyPrintDriver = 1`, and standardizing multi-layer RPC protocol bindings. |
| **3** | **Error 0x00000bc4 - No Printers Were Found (Enforce RPC Named Pipes)** | `[03]` | Fixes "No printers were found" by forcing `RpcUseNamedPipeProtocol = 1` and `RpcProtocols = 7` under Group Policy Printer overrides. |
| **4** | **Error 0x80070035 - Network Path Not Found (Initialize Discovery Services)** | `[04]` | Fixes "The network path was not found" by automating and starting Discovery services (`fdPHost`, `FDResPub`, `SSDPSRV`, `upnphost`). |
| **5** | **Error 0x000006d1 - Disable Client-Side Rendering (CSR)** | `[05]` | Fixes Client-Side Rendering (CSR) spooling crashes by setting `DisableClientSideRendering = 1`, shifting rendering directly to the host spooler. |
| **6** | **Error 0x80070005 - Access Denied to Spooler Folder (Reset Universal ACL Permissions)** | `[06]` | Resolves "Access Denied" on print queues by granting Full Control ACL permissions to universal `Everyone` (`S-1-1-0`) on `C:\Windows\System32\Spool\Printers`. |
| **7** | **Error 0x00000040 - Network Name Is No Longer Available (KeepConn & Ports)** | `[07]` | Fixes "The specified network name is no longer available" by configuring SMB `KeepConn = 65535`, extending session timeout to 300s, verifying print provider integrity, and clearing stale sessions without service disruption. |
| **8** | **Error 0x00000002 - Driver File Copy Policy Block (CopyFilesPolicy Ingestion)** | `[08]` | Resolves driver file copy errors during client connection by enabling `UseSharedSpooler = 1`. |
| **9** | **Error 0x0000007e - RPC Driver Bitness Mismatch (32-bit & 64-bit Systems)** | `[09]` | Fixes 32-bit and 64-bit cross-architecture driver mismatch errors by injecting RPC bitness compatibility registry keys. |

---

### Submenu 3: Network, File & Printer Sharing (SMB) & Firewall
Ensures underlying network connectivity, protocol compatibility, and firewall port clearance.

| # | Menu Option (Exact Console String) | Code | Details & Technical Benefit |
| :---: | :--- | :---: | :--- |
| **1** | **Switch Network Profile to Private (Required for printer sharing)** | `[11]` | Changes current network connection profile from Public to Private, enabling Windows sharing and file/printer discovery. |
| **2** | **Open Passwordless Sharing (Guest Access & Anonymous Sharing)** | `[12]` | Sets `AllowInsecureGuestAuth = 1`, `everyoneincludesanonymous = 1`, and `LimitBlankPasswordUse = 0` for local LAN access. |
| **3** | **Disable SMB Signing Requirement (Fix Win 11 connection to Printer/NAS)** | `[16]` | Disables `RequireSecuritySignature` on LanmanWorkstation and LanmanServer to resolve connection refusals on Windows 11 24H2+. |
| **4** | **Manage SMB Protocols (Ensure Modern SMB2/SMB3 & SMB 1.0 Settings)** | `[15] & [17]` | Manages modern SMB2/SMB3 protocol engines and provides an emergency toggle for legacy SMBv1 for vintage print equipment. |
| **5** | **Open Windows Firewall Rules for File & Printer Sharing (Including WSD Port 3702)** | `[14] & [21]` | Authorizes inbound TCP 445, 139, 135 and UDP 137, 138, 3702 (WSD), 5353 (mDNS) through Windows Defender Firewall. |
| **6** | **Enable Automatic Device Discovery (mDNS, LLMNR, and WSD Discovery)** | `[20] & [30]` | Starts the complete Windows discovery stack to ensure network printers appear in Windows Explorer and setup dialogs. |
| **7** | **Set Network Provider Order & Resolve Virtual Hyper-V/WSL Conflicts** | `[18] & [23]` | Prioritizes physical network adapters over virtual interfaces (Hyper-V, WSL, VMware, VPNs) to prevent routing confusion. |
| **8** | **Total Network & DNS Cache Refresh (Flush DNS, NetBIOS & SMB Session Purge)** | `[10] & [27]` | Safely flushes DNS cache, re-registers DNS, purges NetBIOS tables (`nbtstat -RR`), and clears stale SMB sessions without kernel-level stack resets. |
| **9** | **Disable IPv6 Protocol Stack (Use if office LAN is pure IPv4)** | `[19]` | Disables IPv6 binding on network adapters in pure IPv4 environments, preventing link-local resolution timeouts. |
| **10** | **Install IPP / Mopria Sharing Foundation & Legacy LPR/LPD Protocols** | `[22] & [24]` | Enables Internet Printing Protocol (IPP) and Unix LPR legacy port support for modern multi-function devices and industrial copiers. |

---

### Submenu 4: Print Spooler Service & Print Queue Maintenance
Resolves Print Spooler service crashes, clears jammed documents, and establishes automated self-healing.

| # | Menu Option (Exact Console String) | Code | Details & Technical Benefit |
| :---: | :--- | :---: | :--- |
| **1** | **Clean Spooler Reset & Purge Jammed Print Queue Files (.spl/.shd)** | `[31] & [37]` | Terminates hung spooler processes, deletes all corrupted print artifacts (`.spl` and `.shd`) from `PRINTERS`, and performs a clean restart. |
| **2** | **Configure Automatic Spooler Recovery on Crash (Auto-Restart)** | `[34]` | Configures Windows Service Controller to automatically restart the Print Spooler on first, second, and subsequent service failures. |
| **3** | **Deploy Spooler Watchdog Scheduled Task (Monitors every 5 minutes)** | `[36]` | Registers a scheduled task that audits Spooler service health every 5 minutes and auto-starts it if terminated unexpectedly. |
| **4** | **Repair & Reset Spooler Registry Dependencies (RPCSS & HTTP)** | `[35] & [38]` | Restores factory spooler dependencies (`RPCSS` and `http`), stripping corrupted third-party dependencies that prevent startup. |
| **5** | **Restart Core System RPC & DCOM Services** | `[32]` | Audits and verifies core RPC foundation services (`RpcSs`, `DcomLaunch`) to eliminate *"The RPC server is unavailable"* errors. |
| **6** | **Restart Remote Spooler Service on Target Computer** | `[33]` | Issues a remote spooler restart command across the network via PowerShell remoting/DCOM without requiring physical access. |

---

### Submenu 5: Driver Management & Ghost / USB Printer Cleanup
Manages driver locks, uninstalls legacy driver packages cleanly, and mitigates Windows 11 driver isolation issues.

| # | Menu Option (Exact Console String) | Code | Details & Technical Benefit |
| :---: | :--- | :---: | :--- |
| **1** | **Force-Kill Locking Driver Processes ('Driver is in use')** | `[44]` | Forcefully terminates `splwow64.exe`, `printfilterpipelinesvc.exe`, and driver isolation host processes holding locks on driver DLLs. |
| **2** | **Disable Print Driver Isolation (Prevent separate process crashes)** | `[40]` | Sets `IsolationPolicy = 0` under `Control\Print` to prevent driver isolation sandboxes from crashing during inter-process RPC calls. |
| **3** | **Clean Stale & Corrupted Drivers (Driver Sweeper via pnputil)** | `[43]` | Scans and uninstalls orphaned OEM print driver packages from the Windows Driver Store using native `pnputil`. |
| **4** | **Remove Ghost & Duplicate USB Printers (Copy 1, Copy 2, dead ports)** | `[45] & [46]` | Purges ghost printer instances ("Copy 1", "Copy 2") and unbinds stale virtual USB printer ports left by physical re-plugging. |
| **5** | **Repair Universal V4 Print Class Drivers & Switch PCL / PostScript Mode** | `[41] & [42]` | Reconfigures modern V4 print class drivers for network sharing and toggles driver rendering mode between RAW, PCL, and PostScript. |
| **6** | **Fix Web Browser Printing (Chrome/Edge Sandbox & Modern UWP Apps)** | `[47] & [49]` | Resolves blank or frozen print dialogs in Google Chrome, Microsoft Edge sandbox, and Windows Store UWP applications. |
| **7** | **Reinstall Windows Virtual Built-in Printers (Microsoft Print to PDF / XPS)** | `[48]` | Reinstalls missing system virtual print devices (*Microsoft Print to PDF* and *Microsoft XPS Document Writer*). |
| **8** | **Lock Default Printer Permanently (Prevent automatic location switching)** | `[50] & [51]` | Permanently locks preferred default printer in HKCU registry and disables automatic Windows default printer reassignment. |
| **9** | **Sanitize Printer Share Names (Strip spaces and illegal characters)** | `[53]` | Scans shared printer names and automatically strips spaces and illegal characters (`!@#$%^&*`) to prevent SMB network rejection. |
| **10** | **Open Print Server Properties Management Console** | `[39]` | Launches the native Windows Print Server Properties MMC management interface (`printui.exe /s2`) for advanced driver and form control. |
| **11** | **Force-Uninstall Specific Problematic Printer** | `[46]` | Interactive utility to force-remove a specific locked printer queue, clearing spooler locks and registry registrations. |

---

### Submenu 6: Credentials, Access Rights & Security (Vault, LSA, UAC)
Manages multi-machine authentication, Windows Vault credentials, and Windows 11 security policies.

| # | Menu Option (Exact Console String) | Code | Details & Technical Benefit |
| :---: | :--- | :---: | :--- |
| **1** | **Save Printer Credentials (Username & Password) to Windows Vault** | `[60]` | Writes target printer host credentials directly into the Windows Credential Manager (`cmdkey`) for persistent non-interactive access. |
| **2** | **Clean Stale/Outdated Printer Credentials from Windows Vault** | `[61]` | Scans and deletes expired or invalid printer host credentials stored in Windows Vault to resolve persistent "Access Denied" errors. |
| **3** | **Deploy Login Credentials to All User Profiles on This Machine** | `[63]` | Replicates network printer authentication tokens across all user profiles on the workstation via multi-user RunOnce deployment. |
| **4** | **Bypass Administrator UAC Network Token Filter for Workgroups** | `[57]` | Sets `LocalAccountTokenFilterPolicy = 1` to prevent Windows from stripping administrative tokens during remote network access in Workgroups. |
| **5** | **Align NTLMv2 Authentication Response (LmCompatibilityLevel)** | `[58]` | Configures `LmCompatibilityLevel = 2` or `3` to align NTLM authentication across heterogeneous Windows versions. |
| **6** | **Relax Strict Security Protections (LSA Protection, Smart App Control, Credential Guard)** | `[54], [55], [62]` | Relaxes strict enterprise security mitigations (LSA RunAsPPL, SAC, and Credential Guard) that block legacy NTLM authentication on Workgroups. |
| **7** | **Manage Windows Protected Print / WPP (Win 11 Driver Mode)** | `[59]` | Configures Windows 11 Windows Protected Print (WPP) mode to prevent blocking legacy third-party V3 printer drivers. |
| **8** | **Bypass Point and Print Driver Restrictions (Elevation Override)** | `[56]` | Bypasses Point and Print driver installation elevation requirements (CVE-2021-34527 PrintNightmare mitigations) without disabling driver validation. |
| **9** | **Fix Printer Redirection on Remote Desktop Connections (RDP)** | `[52]` | Restores client printer redirection inside Remote Desktop sessions by correcting Terminal Services registry configuration keys. |

---

### Submenu 7: Port Mapping & Manual Connections (UNC Port Map & TCP/IP)
Direct connection methods when standard Windows Network Discovery fails.

| # | Menu Option (Exact Console String) | Code | Details & Technical Benefit |
| :---: | :--- | :---: | :--- |
| **1** | **Map Local Port to UNC Share (Ultimate Bypass for Error 0x00000709)** | `[86]` | Direct local port redirect that maps a local printer port directly to a remote host UNC path (`\\HOST\PRINTER`), bypassing Point & Print entirely. |
| **2** | **Remove Previously Created Local UNC Port Mapping** | `[87]` | Cleans up and unbinds previously created local UNC port mappings from the print spooler. |
| **3** | **Convert WSD Printer Port to Stable Standard TCP/IP Socket** | `[26]` | Converts unreliable WSD (Web Services on Devices) ports to standard Raw TCP/IP ports (Port 9100) to eliminate phantom offline status. |
| **4** | **Add Standard TCP/IP Printer Port Manually** | `[29]` | Creates a direct Raw TCP/IP printing port (Port 9100) using the target printer's static IP address via WMI. |
| **5** | **Scan & Discover Shared Printers on Remote Network Host** | `[25]` | Scans a remote host IP or computer name via WMI and net view to discover all exposed printer shares and their operational states. |

---

### Submenu 8: Backup, System Diagnostics & Recovery
Safety mechanisms to back up system state prior to modifications and deep diagnostic analysis tools.

| # | Menu Option (Exact Console String) | Code | Details & Technical Benefit |
| :---: | :--- | :---: | :--- |
| **1** | **Backup Printer & Network Registry (Always Recommended Before Fixes)** | `[64]` | Exports 5 critical registry hives (`Print`, `PrintersPolicy`, `LanmanWorkstation`, `LanmanServer`, `Lsa`) to `C:\WindowsPrinterSharingFixBackup`. |
| **2** | **Rollback Registry from Previous Backup Snapshot** | `[65]` | Re-imports the backup `.reg` hives to restore original system state whenever needed. |
| **3** | **Create System Restore Point for System Rollback** | `[66]` | Generates an immediate Windows System Restore Point with automatic frequency-limit bypass. |
| **4** | **Scan & Repair System Files (SFC /scannow & DISM)** | `[67]` | Runs `sfc /scannow` and `dism /online /cleanup-image /restorehealth` to repair corrupted Windows core components. |
| **5** | **Test Network Connectivity & Scan Ports (Ping & Port 135/445)** | `[74]` | Performs raw ICMP echo and TCP socket handshakes on Port 445 (SMB) and Port 135 (RPC) to verify network route and firewall clearance. |
| **6** | **Audit & Analyze Print Service Event Logs (Event Log Parser)** | `[76] & [78]` | Inspects Windows Event Logs for print service errors and maps event IDs to specific recommended fixes. |
| **7** | **Generate Interactive HTML Diagnostic Report** | `[79]` | Compiles hardware, network, spooler, driver, and registry status into a standalone interactive HTML diagnostic report. |
| **8** | **Scan Active Directory Domain Policy / GPO Intervention** | `[80]` | Detects whether active Domain Group Policy Objects (GPO) are overriding local printer sharing registry configurations. |
| **9** | **Backup & Migrate Printers to Another Computer (PrintBRM)** | `[81]` | Backs up or migrates complete printer queues, driver packages, and ports across computers using native Windows `PrintBRM.exe`. |
| **10** | **Force Printer Status to 'Online' (If stuck offline)** | `[71]` | Sends WMI instructions to clear hung error flags on print queues and force offline printers back to *Online* state. |
| **11** | **Open Windows Services Console (services.msc)** | `[72]` | Launches the native Windows Services Management Console (`services.msc`) for manual service management. |
| **12** | **Open Repair Execution Log File (Log Manager)** | `[75]` | Opens the live execution audit log (`C:\WindowsPrinterSharingFixLog.txt`) in Notepad for review. |
| **13** | **Quick System Diagnostics Audit** | `[77]` | Runs a rapid health audit covering Spooler state, network profile, SMB signing status, and password sharing configuration. |

---

### Submenu 9: Help & Usage Guide
Built-in technical reference, diagnostic tools, and usage guidance for every module.

| # | Menu Option (Exact Console String) | Code | Details & Technical Benefit |
| :---: | :--- | :---: | :--- |
| **1** | **Show Quick Guide & Office Troubleshooting Flow** | `[Help]` | Displays an interactive terminal guide detailing standard operating procedures for resolving office printer sharing problems. |
| **2** | **Open Offline HTML Documentation in Browser** | `[HTML]` | Launches the complete interactive offline HTML documentation (`docs/documentation.html`) in your default web browser. |
| **3** | **Detect Current Windows Version & Architecture** | `[73]` | Audits and displays Windows version, build number, architecture (x64/ARM64), and feature update release code. |
| **4** | **Run Windows Built-in Printer Troubleshooter (msdt)** | `[70]` | Launches the native Microsoft Support Diagnostic Tool (`msdt.exe`) printer troubleshooting wizard. |

---

## Under the Hood: Resilience and Persistence

When automated playbooks (**ALLFIX [84]** or **Extreme Path [83]**) are executed, the engine applies multiple safety and persistence mechanisms:

1. **Group Policy Synchronization (`gpupdate /force`)**: Refreshes local Group Policy before writing registry overrides to prevent immediate policy rollback.
2. **Pre-Change Registry Backup**: Backs up 5 critical registry hives to `C:\WindowsPrinterSharingFixBackup` before making any modifications.
3. **Resilient Scheduled Tasks**:
   - `PrinterFixPostUpdate` (triggered on system boot with a 30-second polling retry loop): Re-applies critical RPC, SMB guest, and Point & Print policies if monthly Windows Updates (*Patch Tuesday*) revert configurations, without disruptive mid-day restarts.
   - `PrinterFixNetworkWatchdog` (runs every 15 minutes): Automatically detects and restores network profiles to `Private` if adapter reconnections or router reboots temporarily drop them to `Public`.
   - `SpoolerWatchdog` (runs every 5 minutes): Actively monitors the Print Spooler service and restarts it if terminated by unstable third-party drivers.
   - *The legacy daily 10:00 AM task (`PrinterFixDaily`) has been completely removed to eliminate mid-day workflow interruptions.*
   - *All scheduled tasks are configured with battery exemption (`AllowStartIfOnBatteries`, `DontStopIfGoingOnBatteries`) to maintain protection on laptops.*
4. **Clean Session & Ticket Eviction**: Executes `klist purge`, `ipconfig /flushdns`, and `nbtstat -RR` to flush stale NetBIOS names, expired Kerberos tickets, and cached DNS entries.

---

## Frequently Asked Questions (FAQ & Troubleshooting)

### Why does Windows 11 24H2 refuse to connect to my Windows 10 shared printer?
Starting with Windows 11 Version 24H2, Microsoft enforced mandatory **SMB Signing** (`RequireSecuritySignature`) by default on all client editions and blocked unauthenticated guest logons. When connecting to a Windows 10 host or older NAS that does not require SMB signing, Windows 11 drops the connection with errors such as *"The specified network name is no longer available"* or *"Your organization's security policies block unauthenticated guest access"*. Executing **Extreme Path `[83]`** or **Option 3 in Submenu 3 `[16]`** relaxes client signing requirements and restores transparent Workgroup printer connectivity.

### Do I need to run this tool on the Host PC, the Client PC, or both?
- **Host PC (physically connected to the printer)**: Run **Submenu 1 -> Option [3] (Printer Host Playbook)**. This opens RPC spooler endpoints, sets your network profile to Private, configures firewall rules, and starts discovery services.
- **Client PC (connecting over the network)**: Run **Submenu 1 -> Option [4] (Client Workstation Playbook)**. This forces RPC over Named Pipes (`0x00000bc4` fix), bypasses Point and Print driver elevation requirements (`0x00000709` fix), and disables client SMB signing restrictions.
- **Whole Office / Workgroup**: Running **ALLFIX `[84]`** on both host and client machines guarantees complete configuration alignment and resolves 98% of office network printing issues.

### Will my printer sharing settings survive monthly Windows Updates (Patch Tuesday)?
Yes. Windows Printer Sharing Fix registers the lightweight `PrinterFixPostUpdate` boot verification trigger. Whenever cumulative Windows Updates (e.g., KB5005565, KB5005568, KB5006670, or subsequent patches) replace system DLLs or reset registry keys, the trigger re-applies critical sharing configurations automatically on system restart without disruptive mid-day restarts.

### How does this utility compare to older 2021 PrintNightmare batch scripts?
Legacy batch scripts from 2021 typically only set a single registry key (`RpcAuthnLevelPrivacyEnabled = 0`) which was patched and superseded by newer Windows cumulative updates. They cannot resolve modern Windows 11 24H2/25H2 SMB Signing restrictions, RPC Named Pipes overrides (`0x00000bc4`), Point and Print driver copy policy blocks (`0x00000002`), or socket keep-alive resets (`0x00000040`). This utility contains 89 specialized repair modules designed for current Windows 10, 11, and Server 2025 releases.

---

## Building and Compiling from Source

### Prerequisites
- Windows 10 / 11 / Server (x64 or ARM64)
- PowerShell 5.1+
- Inno Setup 6 (for building the installer)

### Compile Portable Executable & Setup Installer
```powershell
powershell -ExecutionPolicy Bypass -File build\Compile-ToExe.ps1
```
This builds `release\WindowsPrinterSharingFix.exe`, generates `release\WindowsPrinterSharingFix_Installer.exe` using Inno Setup, bundles the latest offline documentation, and applies Authenticode digital signatures to both executables.

---

## License and Contribution

This project is licensed under the **GNU General Public License v3.0 (GPL-3.0)**. Free to use, modify, and distribute for both personal and enterprise environments.

Contributions and feedback are welcome! Please submit bug reports or feature requests via [GitHub Issues](https://github.com/khairudinfahmi/WindowsPrinterSharingFix/issues) or submit a Pull Request following our [CONTRIBUTING.md](CONTRIBUTING.md).

