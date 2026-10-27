# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.4.2] - 2026-10-27

### Fixed

- **Persistent Printer Connections**:
  - Resolved regression in boot (`PrinterFixPostUpdate`) and logon (`PrinterFixLogonReconnect`) scheduled tasks that inadvertently purged `HKCU:\Printers\Connections\*` and user default `Device` registry values on every system reboot and user login.
- **Orphaned Driver Sweeper**:
  - Hardened `Sweep-OrphanedDrivers` (Module 43) to cross-reference active printer drivers (`Get-Printer` / `Get-PrinterDriver`), protecting installed hardware drivers from accidental deletion and implementing language-neutral ClassGuid `{4d36e979-e325-11ce-bfc1-08002be10318}` driver discovery.
- **User Hive Lock Prevention**:
  - Hardened `reg.exe load` and `reg.exe unload` operations across `Set-PostPatchTuesdayTask` and `Inject-CrossUserCredentials` with mounted hive detection and garbage collection (`[GC]::Collect(); [GC]::WaitForPendingFinalizers()`), eliminating temporary profile creation risks.
- **CLI Language Override**:
  - Fixed parameter precedence where `-Language EN` / `-Language ID` from CLI was overwritten by hardcoded default assignments.
- **Safe Registry Proxy**:
  - Integrated `Set-ItemProperty` proxy wrapper to route all registry operations through `Set-SafeReg`, enabling verified readback comparison under `-Debug`, simulated execution under `-Plan`, and read-only protections under `-ReadOnlyMode`.
- **Audit Mode Detailed Snapshot**:
  - Upgraded `Invoke-AuditMode` (`-Audit`) to record complete path-level registry item snapshots (`Details`) into audit report logs instead of summary-only metrics.
- **Clean Rollback & Backup Retention**:
  - Hardened `Backup-Registry` to preserve original configuration snapshots (`*.orig.reg`), track initially missing policy hives, purge script-generated policies on rollback, and stop scheduled tasks before rolling back.
- **Submenu Polish**:
  - Removed double-reset invocations in Submenu 4 (Option 1 & 4), removed redundant interactive prompts in Submenu 5 (Option 5 & 8), enforced `LegacyDefaultPrinterMode = 1` in `Manage-DefaultPrinter`, and included `NetworkProfileWatchdog` in `Remove-SpoolerWatchdog`.

## [2.4.1] - 2026-09-22

### Fixed

- **Error 0x00000006 (ERROR_INVALID_HANDLE) & Ghost Connection Purge**:
  - Enhanced `Fix-Deep0x00000709`, `PrinterFixReapply.ps1`, and `PrinterFixLogon.ps1` to automatically purge stale network printer connection keys under `HKCU:\Printers\Connections` and `HKU\*\Printers\Connections`, breaking the `0x709` $\leftrightarrow$ `0x00000006` credential loop and clearing hanging SMB sessions (`net use * /delete /y`).
- **Morning Connection Drops After Cold Boot**:
  - Boot script (`PrinterFixReapply.ps1`) now forces a clean restart of the Spooler service (`Restart-Service spooler -Force`) during startup so boot-time RPC policies take effect immediately.
  - Added an `ONLOGON` task (`PrinterFixLogonReconnect`) that wakes up the network session (`\\Host\IPC$`) and refreshes Spooler when the user logs in in the morning before Wi-Fi/LAN is fully connected.
  - Purged temporary `SessionDefaultDevices` registry key and locked `UserSelectedDefault = 1` alongside `LegacyDefaultPrinterMode = 1` across all local user profiles (`HKU\S-1-5-21-*`).
  - Enabled NetBIOS over TCP/IP (`NetbiosOptions = 1`) on active network adapters in `Fix-Network0x00000040`.
  - Disabled network card power saving (Energy Efficient Ethernet / Green Ethernet) and USB Selective Suspend so idle computers don't drop printer connections overnight.
  - Stored printer credentials in both the user account and the `SYSTEM` vault (binding IP and hostname together) so background print jobs don't get authentication errors.
  - Set the network watchdog task duration (`/du 9999:59`) so Windows 11 doesn't automatically stop it after 24 hours.
  - Added explicit exit in silent AllFix (`-SilentAllFix` / `-nuke`) so it reboots immediately without waiting for user input.
  - Added CLI parameters `-Debug`, `-Analyze`, `-Audit`, `-Plan`, and `-Verify` with automated switch forwarding in `Restart-Elevated` and non-elevated read-only inspection support.
- **Startup Crash When Run Without Admin Rights**:
  - Moved helper functions (`Pause-User`, `Clear-Screen`) before the admin check so the script doesn't throw an error when asking for elevation.
- **Date Format Parsing in Session Logs**:
  - Normalized date parsing in `AllFix-Core` post-run log inspection to accept both dot (`.`) and colon (`:`) time separators across different Windows regional settings.
- **Auto-Restore Missing mscms.dll (Error 0x0000007e)**:
  - Extended `Fix-RpcBitness0x0000007e` to automatically copy missing `mscms.dll` from `System32`/`SysWOW64` into printer driver directories (`x64\3` and `W32X86\3`), fixing driver load errors on mixed 32-bit and 64-bit networks.
- **ARM64 V4 Print Class Drivers**:
  - Expanded `Fix-V4ClassDriver` to check and fix corrupted Version-4 driver keys under `Windows ARM64\Drivers\Version-4`.
- **User Credential Injection (Bypass Locked NTUSER.DAT)**:
  - Enhanced `Inject-CrossUserCredentials` to detect the currently active user SID and directly inject credentials via `cmdkey.exe`, bypassing file lock conflicts on the user's `NTUSER.DAT`.
- **Documentation Cards Coverage**:
  - Added reference cards for modules 13 (`Fix-NamedPipes`), 28 (`Rescue-NetworkProfile`), 68 (`Manage-BITS`), and 82 (`Enable-SMBGuest`) in `docs/documentation.html`.
- **Scheduled Task Argument Escaping**:
  - Fixed quotation escaping in `schtasks.exe` arguments for `PrinterFixNetworkWatchdog` to prevent syntax errors.
- **Immediate Spooler Restart on Policy Changes**:
  - Added Spooler restart (`Restart-Service spooler -Force`) to `Fix-Discovery0x00000bc4`, `Fix-CSR` (0x000006d1), and `Fix-NamedPipes` so registry modifications take effect immediately without a manual reboot.
- **Offline Documentation Auto-Fetch**:
  - Option `[9] -> [2]` now automatically downloads and opens the HTML documentation in your browser when running via the one-liner command (`irm | iex`).
- **Clean Console Output & Warning Cleanup**:
  - Removed duplicate log lines across companion fix routines.
  - Suppressed non-critical DISM and service restart warnings (`3>$null`).
  - Standardized `-NoBanner` on automated sequence sub-routines.
  - Isolated event log parsing to errors that happened during the current session, ignoring old historical errors.

### Changed

- **Consolidated ALLFIX to 50 Steps**:
  - Cleaned up ALLFIX into 50 distinct steps, removing redundant spooler restarts and duplicate 0x709 passes.

### Added

- **Spooler Crash Auto-Recovery via Windows SCM**:
  - Configured Windows Service Control Manager (`sc.exe failure spooler`) to automatically restart Spooler in 2 seconds if it crashes, with zero background CPU overhead.
  - Added boot persistence for SCM recovery in `PrinterFixReapply.ps1` so Windows Updates don't overwrite it.
- **Spooler Watchdog Toggle**:
  - Added option `[90]` and updated menu `[4] -> [3]` to easily remove or toggle the 5-minute watchdog task.
- **Donations & QRIS Support**:
  - Added QRIS barcode and cryptocurrency donation addresses (BTC, ETH/EVM, SOL) in README and documentation.
- **Unattended CLI Automation & Exit Code Support**:
  - Added `-NoPause` switch across all operational modes (`-Verify`, `-Plan`, `-Analyze`, `-Audit`, `-AllFix`, `-ExtremePath`).
  - Implemented exit codes for automated network monitoring (`exit 0` if all policies are compliant, `exit 1` if drift/failed/missing detected).
  - Dynamically formatted executable invocation syntax in `-Plan`, `-Analyze`, and `-Audit` (`.exe` vs `.ps1` auto-detection).
  - Suppressed duplicate `VERIFY MODE` banner when `-Analyze` or `-Audit` is executed.
- **Bilingual Message Cleanup**:
  - Standardized console output across discovery and network services to respect active language preference (`$script:lang`).

---

## [2.4.0] - 2026-09-16

### Added

- **Real-Time Remote Printer Scanner & 1-Click Clipboard UNC Port Mapping (Submenu 7, Options [1] & [5])**:
  - **Anti-Hang Socket Probe**: Implemented non-blocking asynchronous TCP probe (`Test-TargetPortFast`) on SMB (445) and RPC (135) with a strict 1000ms timeout, completely eliminating 20–30s console hangs when remote computers are offline.
  - **Real-Time Printer Discovery**: Added `Find-RemoteSharedPrinters` supporting dual-tier discovery (SMB share enumeration via `net view` with process timeout fallback + RPC/WMI query), bypassing modern Windows 11 remote RPC spooler restrictions.
  - **Interactive Numbered Table & Clipboard Injection**: Discovered printers are rendered in a clean numbered table with real-time `[ONLINE]` status indicators. Selecting a printer number automatically copies the complete UNC path (`\\HOST\PRINTER`) to the Windows Clipboard (`Copy-ToClipboard` via `Set-Clipboard` / `clip.exe`) ready for instant pasting (`Ctrl+V`).
  - **1-Click Local Port Mapping (0x00000709 Bypass)**: Users can directly map the selected printer to a local port in 1-click without any manual typing.
  - **LAN Active Host Detection**: Added fast neighborhood discovery (`Get-LANActiveHosts`) querying the IPv4 ARP cache in < 50ms to help users find printer servers even without memorizing IP addresses.
- **Role-Based Optimization Playbooks (Submenu 1)**: Added dedicated one-click repair flows:
  - **Host / Print Server PC** (Option [3]): Enforces spooler remote RPC endpoint, sets network profile to Private, enables guest sharing, opens firewall & WSD ports, disables server SMB signing enforcement, sanitizes share names, and deploys Spooler Watchdog.
  - **Client PC** (Option [4]): Enforces RPC Named Pipes, applies Point & Print driver elevation bypass, disables client SMB signing requirement, repairs HKCU registry permissions, activates device discovery (mDNS/WSD), and flushes DNS cache.
- **Bilingual Interface Engine (English & Indonesian)**: Dynamic language switching via `[L]` key on any menu or submenu, with preferences persistently saved to `HKCU:\Software\WindowsPrinterSharingFix\Language`.
- **Real-Time System Health Banner**: Audits and displays live operational status directly in the console header: Spooler (Running/Stopped), Network Profile (Private/Public), SMB Signing, and Password Protected Sharing.
- **Categorized Console Layout**: Restructured the 180-column layout into 8 intuitive core categories formatted for standard 86-column console buffers.
- **Persistent Local Subnet Firewall Rule**: Automatically injects an inbound rule (`WinPrinterSharingFix-LocalSubnet`) allowing TCP 135 and 445 exclusively for `LocalSubnet` across any profile state.
- **Instant Web Launch & Quick-Lookup Error Matrix**: Added an instant one-liner PowerShell execution method, an error code quick-lookup matrix, and a troubleshooting FAQ section to documentation.

### Fixed

- **Registry Rollback & Safety Hardening**:
  - Differentiated between genuine restoration and zero-file restoration failure in `Rollback-Registry` to eliminate false-positive success notifications.
  - Automatically restarts the Print Spooler service upon successful registry rollback to reload restored policies immediately.
  - Integrated automated pre-change registry backup into `Extreme-25H2`.
  - Added bilingual console status feedback across all backup, rollback, restore point, and migration modules.
- **Kernel BSOD Bugcheck Elimination (Error 0x00000040 & Socket Reset)**:
  - Completely eliminated forced restarts of `LanmanWorkstation` and `LanmanServer` services across `Fix-Network0x00000040` and `Reset-NetworkSockets`.
  - Resolved kernel bugchecks (`RDBSS_FILE_SYSTEM` 0x27 / `KERNEL_SECURITY_CHECK_FAILURE` 0x139) caused by tearing down kernel redirector drivers (`rdbss.sys`, `mrxsmb.sys`) while active network handles were open.
  - Resolved subsequent Windows Startup Repair update rollbacks triggered by unexpected kernel halts.
  - Configured `KeepConn = 65535`, extended `SessTimeout = 300`, and validated `LanMan Print Services` (`win32spl.dll`) non-destructively.
- **Safe Network Stack Refresh**:
  - Replaced destructive kernel-level `netsh int ip reset` and `netsh winsock reset` calls in `Reset-Network` with safe user-mode cache flushes (`Clear-DnsClientCache`, `ipconfig /flushdns`, `ipconfig /registerdns`, `nbtstat -RR`, and `net use * /delete /y`).
- **Permanent Removal of Disruptive Daily 10:00 AM Scheduled Task**:
  - Completely deleted the legacy daily 10:00 AM task (`PrinterFixDaily`) via `schtasks /delete /tn "PrinterFixDaily" /f`.
  - Replaced it with a lightweight boot-time task (`PrinterFixPostUpdate`, `/sc onstart`) with a 30-second network polling retry loop to handle delayed Wi-Fi/DHCP initialization.
  - Deployed `PrinterFixNetworkWatchdog` (15-minute interval) to ensure network profiles stay `Private` without disruptive spooler restarts or connection drops.
- **Daily Sharing Drops & Fast Startup Mitigation**:
  - Integrated `Disable-FastStartup` (`HiberbootEnabled = 0`) across all automated routines (`AllFix`, `Extreme`, `HostServerRole`, `ClientWorkstationRole`, `Set-NetworkPrivate`) to stop Windows from hibernating stale network sockets and drivers overnight.
- **Windows 11 24H2/25H2 & Server 2025 Policy Alignment**:
  - Injected `RegisterSpoolerRemoteRpcEndPoint = 1` on print server policies to resolve silent remote RPC blocks.
  - Configured `ForceKerberosForRpc = 0` to enable non-domain Workgroup fallback to NTLMv2.
  - Unified SMB Signing across Group Policy, service parameters, and PowerShell configuration.
- **Submenu 7 Loop & Control Flow Architecture**:
  - Converted Submenu 7 from `do { ... } while` to standard `while ($true)` loop structure with explicit `return` transitions, eliminating Language Server recursion artifacts on large script files.
  - Expanded `switch` default handler block with explicit bilingual fallback messages and pause guards for unrecognized inputs.
- **Static Analysis & Code Quality Hardening**:
  - Configured repository-level `PSScriptAnalyzerSettings.psd1` rules, achieving 0 AST parser errors and 0 linter violations across all 4,654 lines of code.
  - Cleaned non-ASCII characters to guarantee universal UTF-8 console output.
  - Trimmed all trailing whitespace across the entire codebase.

---

## [2.3.2] - 2026-06-16

### Security & Reliability Fixes

- **Printer Name Error Prevention**: Fixed a crash (`WQL syntax error`) that frequently occurred when printer names contained a single quote (e.g., "Bob's Office") in the `Force-PrinterOnline` and `Manage-DefaultPrinter` features.
- **Typo Crash Protection**: Added automatic protections to the menu selection. Accidentally typing letters instead of numbers will no longer crash the script.
- **HTML Report Fix**: Updated the logging system so that special characters (`<`, `>`, `&`) no longer break the HTML diagnostic report's layout.
- **IP Input Validation**: Fixed an issue in `Test-Connectivity` that caused the tool to crash if you pressed Enter without typing an IP address.
- **Stronger Registry Backup**: The Backup function now backs up 5 full registry hives, ensuring all critical system configurations are safely saved before AllFix runs.
- **Flawless Registry Rollback**: Tightened the registry restore system. The Rollback feature now validates each restored file individually, preventing it from falsely reporting success if a file fails to restore.
- **Accurate Credential Validation**: The `Add-Credential` feature can now accurately detect and report failures from `cmdkey` instead of always displaying a "Success" message.
- **Improved Password Security**: Revamped the `Inject-CrossUserCredentials` system. Passwords are no longer stored permanently as plaintext in the Registry. It now uses a single-use script that automatically deletes itself immediately after execution.

---

## [2.3.1] - 2026-06-14

### Fixed

- Task Scheduler battery restriction: Disabled default AC power constraints (`AllowStartIfOnBatteries`, `DontStopIfGoingOnBatteries`) for all registered tasks (`PrinterFixPostUpdate`, `PrinterFixDaily`, `SpoolerWatchdog`, and `NetworkProfileWatchdog`). This resolves execution failure `0x800710E0` on laptop computers running on battery power.

---

## [2.3.0] - 2026-06-12

### Added

- GPO intervention scanner (Option 80) now performs active domain membership queries, suppressing Domain Controller overwrite warnings and gpresult logs for Workgroup users.
- Introduced recommended configuration mapping in GPO diagnostics, formatting matching parameters as `[Active Fix]` in Green and only flagging mismatches as `[!] Policy Override (Restricted)` in Red.
- Added direct HKLM Print spooler configuration keys (`RpcOverNamedPipes`, `RpcOverTcp`) inside Option 2 and Option 13 to enforce RPC pathways under Windows 11 24H2+.
- Renamed Menu 83 to explicitly indicate compatibility with `26H2+` platforms.
- Universal localization permissions: modified Option 6 and Option 7 to resolve security descriptors using the generic World SID (`S-1-1-0`) instead of the English-bound string `"Everyone"`.
- Added target IP and username validation check inside `Add-Credential` (Option 60).
- Refactored Option 69 to "Windows Update & Blocker Management" sub-menu, offering a quality/feature update pause for 35 days (using InvariantCulture date strings to avoid localized character substitution issues), specific KB uninstallation via DISM, and a permanent update blocker targeting core services (wuauserv, UsoSvc, bits, and a WaaSMedicSvc self-healing bypass) along with a restore option.
- Hardened the auto-reapply scheduled task in `Set-PostPatchTuesdayTask` (Option 5) to directly force `RpcOverNamedPipes` and `RpcOverTcp` under the printer control parameters registry on boot.

### Fixed

- Force-DefaultPrinterRegistry: Removed trailing colon from Device string that caused printer assignment failures.
- Fix-CrossSignedDriverPolicy: Changed SilentlyContinue to Stop with post-write verification for registry operations.
- Fix-AdvancedPointAndPrint: Filled empty catch blocks with proper error logging.
- Inject-CrossUserCredentials: Fixed race condition with registry unload retry loop.
- Manage-WindowsUpdate: Hardened DISM package name parsing with regex and null guard.
- Sweep-OrphanedDrivers: Rewrote pnputil output parsing for Win10/Win11 compatibility.
- Fix-Deep0x00000709: Device key write now verified post-set to confirm success.
- Convert-WSDtoTCPIP: Now migrates all WSD printers instead of only the first match.
- Reset-SpoolerDependencyReg: Added post-write SCM verification via Get-Service.
- Parse-PrintEventLog: Unified EventID map and verified all menu references.
- Nuke-PrintQueue / Reset-Spooler: Replaced static sleep with status polling loop.
- AllFix-Core gpupdate: Now runs with 30-second timeout via background job.
- Map-LocalPortUNC: Added input sanitization for UNC path validation.
- Watchdog & Post-Update Tasks: Rewrote triggers using `schtasks.exe` instead of `New-ScheduledTaskTrigger` to bypass critical Interval property crashes natively found in Windows 11 Home (Build 26100).
- Fix-mDNS: Added dynamic path creation (`New-Item`) for `DNSClient` and `Dnscache` registries to prevent "Cannot find path" errors during `-ErrorAction Stop` strict enforcement.

### Improved

- Added security warnings for credential injection and Point-and-Print operations.
- Disable-PasswordSharing: Documented everyoneincludesanonymous security implications.
- NTLMv2 conflict with Deep0x00000709 documented; NtlmMinClientSec aligned.
- Reset-Network: Removed manual $LASTEXITCODE assignment; uses actual exit codes.
- Sanitize-PrinterShareName: Added empty-name guard.
- Fix-V4ClassDriver: Added DriverPath null guard to prevent exception on missing paths.
- Create-RestorePoint: 24-hour throttle now reports as WARNING instead of ERROR.
- Fix-PrintToPDF: Added reboot advisory to user output.
- $silentNuke flag now resets to $false after AllFix-Core completes.
- Extreme-25H2: Backup-Registry called at start before any modifications.
- Write-Log: Added fallback log path detection (TEMP/UserProfile) when C:\ is not writable.

### Changed

- Renamed "AUTOMATED REPAIR SEQUENCES" to "AUTOMATED FIXES" across all UI and documentation.
- Removed all external attribution from script header and console footer.
- Cleaned up script synopsis to minimal project metadata only.

---

## [2.2.9] - 2026-05-17

### Added

- Smarter suggestions for Event ID 372 error messages (identifying credential or network blockages).

---

## [2.2.8] - 2026-05-17

### Added

- Added wusa.exe fallback for update uninstalls (Option [69]). If DISM fails, it will try wusa automatically.

### Changed

- Reorganized and aligned the 89-option menu for a cleaner look.
- Cleaned up code.
- Improved error messages for the update uninstaller.

---

## [2.2.7] - 2026-05-17

### Added

- **Remove Injected Port (Option [87])**: Added `Remove-LocalPortUNC` function to safely delete custom ports created by the UNC Port Mapping Bypass (Option [86]). Includes a Registry Purge fallback if standard removal is blocked by Windows security policies.
- **UNC Port Mapping Bypass Polish**: Optimized `Map-LocalPortUNC` with improved diagnostic logging and direct registry injection verification.

### Changed

- **Global ID Re-indexing**: Reorganized features into an 89-option architecture.
  - `[87]` Remove Injected Local Port (UNC)
  - `[88]` Reboot System
  - `[89]` EXIT SCRIPT
- **UI Enhancement**: Standardized "UNC Bypass" nomenclature across all diagnostic modules for better clarity.

---

## [2.2.6] - 2026-05-17

### Added

- **Registry Bypass for Local Ports**: Significantly enhanced `Map-LocalPortUNC` (Option [86]) with a fallback mechanism. If the standard Windows API for port creation is blocked by RPC security policies, the tool now injects the UNC path directly into the registry and restarts the spooler to force availability.

### Changed

- **Standardized Error Codes**: Expanded all hex error codes to their full 10-character format (e.g., 0x0000011b, 0x00000709) across the entire UI, console logs, and documentation for maximum clarity and enterprise compliance.
- **Professional Language Polish**: Replaced "stiff" or AI-centric terminology (e.g., "mutated", "transmitted", "numerals") with natural, professional technical language ("updated", "issued", "numbers") to ensure a polished user experience.
- **Function Standardization**: Renamed core repair functions to include their corresponding error codes (e.g., Fix-11b -> Fix-RpcAuthn0x0000011b) for better developer traceability and maintenance.
- **Code Refactoring**: Cleaned up internal documentation and removed redundant debug comments to improve script readability and performance.
- **Improved Spooler Management**: Optimized the spooler refresh logic to ensure a cleaner state transition between service stop and start operations.

---

## [2.2.5] - 2026-05-17

### Added

- **UNC Port Bypass (Option [86])**: Added `Map-LocalPortUNC` function. This allows users to map a local port directly to a UNC path (`\\TargetIP\ShareName`), effectively bypassing persistent RPC "Check printer name" or "0x709" errors when standard sharing protocols fail.
- **Enhanced PrintNightmare Bypasses**: Expanded `Fix-AdvancedPointAndPrint` (Option [56]) with critical registry overrides (`RestrictDriverInstallationToAdministrators = 0`, `NoWarningNoElevationOnInstall = 1`, etc.). This enables silent driver downloads from host machines even under strict modern security policies.
- **AllFix Sequence Markers**: Added visual menu-mapping hints (e.g., `(Menu 64)`) to each step in the `AllFix-Core` sequence, allowing users to trace which individual fix corresponds to each automated step.

### Fixed

- **Spooler Resilience**: Added explicit `Set-Service spooler -StartupType Automatic` during the Spooler Hard Reset (Option [31]) to ensure the service persists after a reboot.
- **SMB Mutual Auth**: Added `RequireMutualAuthentication = 0` to `Fix-SMBSigning` (Option [16]) to ensure smooth NTLM fallback for workgroup environments.
- **Network Discovery Hardening**: Integrated `nlasvc` (Network List Service) and `Dnscache` into `Fix-NetworkServices` (Option [04]) to ensure reliable profile detection.
- **Directory ACL**: Expanded `Reset-SpoolerPerm` (Option [06]) to grant "Everyone" FullControl on the spooler directory, resolving persistent permission-based sharing blocks.
- **UI & Feature Expansion**: Updated the toolkit to **88 options**. Reindexed "Reboot" and "Exit" to options [87] and [88] respectively.

---

## [2.2.3] - 2026-05-16

### Fixed

- **GPO Synchronization**: Moved `gpupdate /force` to the beginning of the `AllFix-Core` and `Extreme-25H2` sequences. This prevents domain-joined machines from reverting registry fixes immediately after script execution.
- **Sequence Integrity**: Standardized the `AllFix-Core` sequence to a consistent 50-step repair flow, correcting duplicate numbering and inconsistent step labels.
- **Error 0x00000709 (HKCU Permissions)**: Added `Fix-HKCU-PrinterKeyPerms` to grant FullControl to the printer registry key. This resolves "Access Denied" errors when writing to the Device key during printer assignment.
- **Print Migration (Home Edition Compatibility)**: Added validation for `PrintBrm.exe` existence. The tool now correctly identifies when the utility is missing (common in Windows Home editions) and provides a clear informative message instead of a CLI error.
- **Code Optimization**: Removed the legacy `Fix-709` dead code function, fully transitioning to the multi-layered `Fix-709-Deep` implementation.

### Added

- **KB5089549 Driver Bypass**: Implemented `Fix-CrossSignedDriverPolicy` to disable the new cross-signed driver enforcement (Audit Mode) introduced in the May 2026 patch.
- **Post-Update Automation**: Integrated `Set-PostPatchTuesdayTask`, which deploys a scheduled task (`PrinterFixPostUpdate`) to automatically re-apply critical registry fixes after Windows Updates or reboots.
- **Enhanced KB List**: Updated `Manage-WindowsUpdate` with a curated list of known printer-breaking KBs from 2025-2026.

## [2.2.2] - 2026-05-16

### Added

- **Deep Fix 0x00000709**: Integrated a new multi-layered repair logic (Option [02]) targeting persistent 0x00000709 errors. Includes RPC Named Pipe enforcement, Kerberos disabling (`ForceKerberosForRpc=0`), and HKCU device key sanitation.
- **Automated Deep Fix**: Integrated `Fix-709-Deep` into the `AllFix-Core` [84] and `Extreme-25H2` [83] sequences.

## [2.2.1] - 2026-05-16

### Fixed

- **PrintBRM Migration**: Improved the launch logic for `PrintBrm.exe` (Option [81]) to open in a persistent CMD window with the help manual (`/?`) automatically displayed.
- **DISM Capture**: Enhanced DISM uninstallation modules to correctly capture and report exit codes (0/3010) for verification.
- **Windows Update Compliance**: Added registry keys (`PauseFeatureUpdatesStartTime`, `PauseUpdatesExpiryTime`) to ensure Windows 11 respects update pauses.
- **WUSA Compatibility**: Removed silent flags from `wusa.exe` uninstalls to resolve security-driven interface blocks on modern builds.
- **UI Alignment**: Standardized console headers for better readability in 80-column terminals.

## [2.2.0] - 2026-05-15

### Changed

- **Feature Optimization**: Removed the non-essential "Auto-Inject F4/Folio Paper Size" feature (previously Option [50]) to streamline the toolkit.
- **Global ID Re-indexing**: Reorganized all features into a strictly sequential 87-option architecture (down from 88).
- **UX Improvement**: Renamed "Case 2" troubleshooting to "STILL DENIED? (Persistent)" for better user clarity. Added strategic tips for manual credential injection (Option [60]) when automated fixes are blocked by modern Windows 11 security policies.
- **AllFix Sequence**: Adjusted automated repair sequence from 50 to 49 steps.

### Fixed

- **Redundant Code**: Purged legacy F4 injection logic and registry manipulation to reduce script footprint and potential security surface.

---

## [2.1.1] - 2026-05-13

### Fixed

- **F4 Paper Size Injection**: Resolved `System.Byte[]` type mismatch bug in `Inject-F4PaperSize` by refactoring array construction to a flat byte array.
- **NTLMv2 Compatibility**: Upgraded `Fix-NTLMv2` to enforce Value 3 (Strict NTLMv2) for improved network storage (NAS) and modern print sharing compatibility.

---

## [2.1.0] - 2026-05-10

### Changed

- **Global ID Migration**: All 88 features have been reorganized into a strictly sequential, logical 3-column architecture for improved usability and consistency.
  - **Column 1 [01-30]**: Core Fixes & Network Services (Error codes, DNS, SMB, WSD, IPP, Firewall).
  - **Column 2 [31-60]**: Spooler, Drivers & Policies (Spooler management, V4 drivers, LSA, SAC, UAC).
  - **Column 3 [61-88]**: Diagnostics & Automation (Credentials, Backup, SFC, Troubleshooter, ALLFIX, Exit).
- **Key ID Changes**:
  - `[65]` Registry Backup (was `[13]`)
  - `[84]` Extreme Path (was `[24]`)
  - `[85]` ALLFIX (was `[25]`)
  - `[85]` Silent AllFix (was `[37]`)
  - `[88]` EXIT SCRIPT (was `[31]`)
- **UI Overhaul**: Feature text color standardized to Green for consistency. Special operations `[84]`, `[85]`, `[86]` highlighted in Red for visibility.
- **Console Layout**: Dynamic buffer/window sizing (180 columns) with proportional column widths (`62/55/58`) prevents text wrapping on any console size.
- **Help System**: All 88 help entries remapped to match new sequential IDs. Guide workflow references updated.
- **Termination Logic**: Fixed bypass IDs from old `31/30/37` to correct `88/87/86`.
- **AllFix**: Expanded from 42 to 50 automated repair steps.

### Fixed

- `$colWidth` undefined variable causing PadRight crash in Show-Menu column 3.
- BufferSize not set before WindowSize causing silent console resize failure.
- 18 switch cases referencing non-existent function names (e.g., `Uninstall-KBUpdate` → `Manage-WindowsUpdate`).
- ISS installer source path corrected from `Output/` to `release/`.
- Stale old-ID references in help guide text.
- Windows 11 misidentification bug caused by legacy `ProductName` registry strings (now actively checks Build >= 22000).

---

## [2.0.0] - 2026-05-10

### Added

- 18 new advanced diagnostic and repair modules, expanding total features from 70 to 88.
- **Driver & Windows Update**: Universal Print V4 Fix, PCL/PostScript Toggle, KB Uninstall & Pause, Orphaned Driver Sweeper, Force-Kill Driver Process.
- **Network & Port**: WSD to TCP/IP Converter, Network Socket Re-init, Rescue Network Profile (Watchdog), Ghost USB Port Eliminator.
- **Spooler & Queue**: Force Purge Print Queue (.shd/.spl purge), Spooler Dependency Registry Reset.
- **Credentials**: Cross-User Credential Mapping, Force-Set Default Printer (Registry Bypass).
- **Third-Party Integration**: Auto-Sanitize Printer Share Name, Browser Print Sandbox Fix (Chromium), Auto-Inject F4/Folio Paper Size.
- **Advanced Diagnostics**: GPO Intervention Detection (Policy Scan), PrintService Event Log Parser (Top 5).

### Changed

- AllFix expanded from 42 to 50 automated repair steps with 8 new safe integrations.
- Extreme Path (Win 11 24H2/25H2) enhanced with V4 Driver Fix, Spooler Dependency Reset, and Share Name Sanitization.
- Menu system updated: dynamic row rendering supports variable-length columns.
- Help system expanded: full `? <number>` support for all 88 features.

---

## [1.0.1] - 2026-05-04

### Changed

- UI Enhancement: Highlighted primary operation modes in the CLI menu for better visibility.
- Documentation: Updated OS Support requirements to clarify Legacy OS (Windows 7/8/8.1) as "Partial/Registry Support only".
- Documentation: Replaced all emojis in the HTML manual with professional Lucide icons.
- Documentation: Corrected typo in log and backup directory paths.
- Features: Explicitly mapped error code `0x80070005` (Access Denied) into option descriptor for easier troubleshooting discovery.

---

## [1.0.0] - 2026-05-03

### Added

- 70 comprehensive printer sharing diagnostic and repair options for Windows 10/11/Server environments.
- Native support for Windows 11 24H2, 25H2, 26H2, and ARM64 (Snapdragon) architectures.
- Native support for Windows Server 2019, 2022, and 2025.
- AllFix: 42 automated repair steps executed sequentially via a single command.
- Extreme Path tailored specifically for Windows 11 Build 26000+.
- Silent AllFix mode (zero-interaction, unattended execution with forced auto-restart).
- Interactive contextual help system (`?`, `? <number>`, `? all`).
- Comprehensive offline HTML documentation with built-in search functionality.
- Inno Setup compiler integration with automated code signing certificate generation.
- Build automation script (`Compile-ToExe.ps1`) to compile PS1 source into standalone EXE.
- Advanced system diagnostics (Print Spooler state, RPC, Windows Defender Firewall, Network Profile).
- Remote network printer management utilities (Ping test, Port 445/135 Scan, Remote Target Spooler Reset).
- PrintBRM (Printer Backup/Restore Migration) native integration.
- Spooler Watchdog scheduled task implementation for high-availability environments.
- System Restore Point native integration for secure pre-execution rollback.
- Detailed operational logging with HTML export capabilities.
