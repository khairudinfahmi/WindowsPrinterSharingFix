# Windows Printer Sharing Fix v2.4.1

Automated PowerShell utility designed to diagnose and fix network printer sharing errors on Windows networks (Workgroups and Active Directory domains).

Supports **Windows 10**, **Windows 11 (including 24H2, 25H2, 26H2+)**, **ARM64**, and **Windows Server 2016 / 2019 / 2022 / 2025**.

---

## What's New in v2.4.1

### 1. Native SCM Print Spooler Crash Recovery (2s Delay, 0% CPU Overhead)
- Upgraded `Set-SpoolerRecovery` to configure Windows Service Control Manager (`sc.exe failure spooler`) with an instant 2-second restart delay (`actions= restart/2000/restart/5000/restart/10000`), 24-hour reset period (`reset= 86400`), and `failureflag 1` for zero-overhead, kernel-level crash recovery that distinguishes crashes from normal administrative shutdowns.
- Added boot-time persistence for Native SCM recovery inside `PrinterFixReapply.ps1` to withstand cumulative updates such as KB5129195 (Build 26200.9457).

### 2. Spooler Watchdog Clean Removal & Smart Toggle
- Added `Remove-SpoolerWatchdog` function (`schtasks.exe /delete /tn "SpoolerWatchdog" /f`) and Direct Action shortcut `[90]`.
- Implemented smart detection in Submenu 4 Option `[3]` to dynamically toggle between deploying and cleanly removing the 5-minute watchdog task.

### 3. Scheduled Task Execution & Quotation Escaping Fix
- Resolved argument splitting issue in `PrinterFixNetworkWatchdog` scheduled task creation (`schtasks.exe /tr`), properly escaping inner quotation marks to eliminate `-EA` parsing error and guarantee continuous 15-minute network profile monitoring.

### 4. Print Spooler Policy Lifecycle Triggers
- Integrated automated Print Spooler restart (`Restart-Service spooler -Force`) into `Fix-Discovery0x00000bc4`, `Fix-CSR` (Error 0x000006d1), and `Fix-NamedPipes` ensuring registry policy modifications take effect immediately without requiring a full system reboot.

### 5. Web Stream Documentation Auto-Fetch
- Automatically downloads and opens latest HTML documentation in Submenu 9 Option [2] when executing via one-line web stream (`irm | iex`).

### 6. Support & Donations
- Added QRIS barcode and multi-chain cryptocurrency donation addresses (BTC, ETH/EVM, SOL) in README and documentation.

### 7. Bilingual Message Standardization
- Standardized console output across discovery and network services to respect active language preference (`$script:lang`).

---

## Release Downloads

| File | Description | Signature |
| :--- | :--- | :--- |
| **WindowsPrinterSharingFix_Installer.exe** | Setup Installer (Start Menu, Desktop shortcut, uninstaller) | Authenticode Signed |
| **WindowsPrinterSharingFix.exe** | Standalone Portable Executable | Authenticode Signed |
| **documentation.html** | Offline Interactive Web Documentation | HTML5 / Vanilla CSS |
