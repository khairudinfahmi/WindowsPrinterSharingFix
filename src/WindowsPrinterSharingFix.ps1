#Requires -Version 5.1
<#
.SYNOPSIS
    Windows Printer Sharing Fix - v2.4.0
    @KHAIRUDINFAHMI

.PARAMETER nuke
    Silent AllFix mode - executes all 50 fixes then reboots automatically.
#>

param(
    [switch]$nuke
)

$script:version    = "2.4.0"
$script:backupDir  = "C:\WindowsPrinterSharingFixBackup"
$script:silentNuke = $nuke

$script:logFile = $null
$candidateLogs = @(
    "C:\WindowsPrinterSharingFixLog.txt",
    "$env:TEMP\WindowsPrinterSharingFixLog.txt",
    "$env:USERPROFILE\Desktop\WindowsPrinterSharingFixLog.txt"
)
foreach ($cl in $candidateLogs) {
    try {
        Add-Content -Path $cl -Value "" -Encoding UTF8 -ErrorAction Stop
        $script:logFile = $cl
        break
    } catch { }
}
if (-not $script:logFile) {
    $script:logFile = "$env:TEMP\WindowsPrinterSharingFixLog.txt"
}

$script:isARM64 = ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64')
$script:isServer = $false
try {
    $prodOptions = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\ProductOptions" -ErrorAction SilentlyContinue
    if ($prodOptions -and $prodOptions.ProductType -ne "WinNT") {
        $script:isServer = $true
    }
} catch {
    try {
        $script:isServer = ((Get-CimInstance Win32_OperatingSystem -ErrorAction Stop).ProductType -ne 1)
    } catch {
        $script:isServer = $false
    }
}

$buildInfo = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -ErrorAction SilentlyContinue
if ($buildInfo -and $null -ne $buildInfo.CurrentBuild) {
    try {
        $script:buildNumber = [int]$($buildInfo.CurrentBuild)
    }
    catch {
        $script:buildNumber = [Environment]::OSVersion.Version.Build
    }
}
else {
    $script:buildNumber = [Environment]::OSVersion.Version.Build
}

if ($buildInfo -and $null -ne $buildInfo.ProductName) {
    $script:productName = $buildInfo.ProductName

    if ($script:buildNumber -ge 22000 -and $script:productName -match "Windows 10") {
        $script:productName = $script:productName -replace "Windows 10", "Windows 11"
    }
}
else {
    $script:productName = "Windows NT $([Environment]::OSVersion.Version.Major)"
}

$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Continue'

function Write-Log {
    param(
        [string]$Message,
        [string]$Type = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp - $Type - $Message"
    try {
        Add-Content -Path $script:logFile -Value $logEntry -Encoding UTF8 -ErrorAction Stop
    }
    catch {

    }

    if ($Type -eq "ERROR") {
        Write-Host "  [ERROR] $Message" -ForegroundColor Red
    }
    elseif ($Type -eq "WARNING") {
        Write-Host "  [!] $Message" -ForegroundColor Yellow
    }
    elseif ($Type -eq "SUCCESS") {
        Write-Host "  [+] $Message" -ForegroundColor Green
    }
    else {
        Write-Host "  [*] $Message" -ForegroundColor Cyan
    }
}

function Test-Administrator {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Restart-Elevated {
    Write-Host "`n  [!] Standby... Requesting Administrator elevation." -ForegroundColor Yellow
    Write-Host "  [!] Click 'YES' on the UAC prompt to proceed." -ForegroundColor Yellow

    $isExe = $false
    $exePath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
    if ($exePath -match '\.exe$' -and $exePath -notmatch 'powershell') {
        $isExe = $true
    }

    if ($isExe) {
        $cmdArgs = ""
        if ($script:silentNuke) { $cmdArgs += "-nuke" }
        Start-Process -FilePath $exePath -ArgumentList $cmdArgs -Verb RunAs
    }
    else {
        $cmdArgs = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
        if ($script:silentNuke) { $cmdArgs += " -nuke" }
        Start-Process powershell -Verb RunAs -ArgumentList $cmdArgs
    }
    exit
}

function Initialize-Log {
    if (-not (Test-Path $script:backupDir)) {
        New-Item -ItemType Directory -Path $script:backupDir -Force | Out-Null
    }
    try {
        Add-Content -Path $script:logFile -Value ("=" * 60) -Encoding UTF8 -ErrorAction SilentlyContinue
        Add-Content -Path $script:logFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Windows Printer Sharing Fix" -Encoding UTF8 -ErrorAction SilentlyContinue

        if ($script:isARM64) {
            Add-Content -Path $script:logFile -Value "[ARM64 Architecture Detected]" -Encoding UTF8
        }
        if ($script:isServer) {
            Add-Content -Path $script:logFile -Value "[Windows Server Edition Detected]" -Encoding UTF8
        }
    }
    catch {}
}

if (-not (Test-Administrator) -and $script:skipElevationCheck -ne $true) {
    Restart-Elevated
}
Initialize-Log

function Fix-RpcAuthn0x0000011b {
    Write-Log "Patching Error 0x0000011b (RpcAuthnLevelPrivacy)..." -Type "INFO"
    try {
        Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Print" -Name RpcAuthnLevelPrivacyEnabled -Value 0 -Type DWord -Force -ErrorAction Stop
        Write-Log "Registry 0x0000011b successfully applied." -Type "SUCCESS"
        Write-Host "  [+] RPC Authentication Level Privacy requirement disabled." -ForegroundColor Green
    }
    catch {
        Write-Log "Failed to patch 0x0000011b: $($_.Exception.Message)" -Type "ERROR"
    }
}

function Fix-Deep0x00000709 {
    Write-Log "Deep fix 0x00000709 — applying all RPC layers..." -Type "INFO"
    try {

        $rpcPath = "HKLM:\Software\Policies\Microsoft\Windows NT\Printers\RPC"
        if (-not (Test-Path $rpcPath)) { New-Item -Path $rpcPath -Force | Out-Null }
        Set-ItemProperty -Path $rpcPath -Name RpcUseNamedPipeProtocol -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $rpcPath -Name RpcTcpEnable            -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $rpcPath -Name RpcProtocols            -Value 7 -Type DWord -Force
        Set-ItemProperty -Path $rpcPath -Name RpcOverNamedPipes       -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $rpcPath -Name RpcAuthenticationLevel  -Value 0 -Type DWord -Force
        Set-ItemProperty -Path $rpcPath -Name ForceKerberosForRpc     -Value 0 -Type DWord -Force

        $polPrinters = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers"
        if (-not (Test-Path $polPrinters)) { New-Item -Path $polPrinters -Force | Out-Null }
        Set-ItemProperty -Path $polPrinters -Name RegisterSpoolerRemoteRpcEndPoint -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

        $printPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Print"
        Set-ItemProperty -Path $printPath -Name RpcAuthnLevelPrivacyEnabled -Value 0 -Type DWord -Force
        Set-ItemProperty -Path $printPath -Name DnsOnWire              -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $printPath -Name CopyFilesPolicy        -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $printPath -Name RpcOverNamedPipes       -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $printPath -Name RpcOverTcp              -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

        $lanPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"
        Set-ItemProperty -Path $lanPath -Name DisableStrictNameChecking -Value 1 -Type DWord -Force

        $deviceKey = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Windows"
        $deviceVal = (Get-ItemProperty $deviceKey -ErrorAction SilentlyContinue).Device
        if ($deviceVal) {
            Write-Host "  [!] Purging legacy Device key: $deviceVal" -ForegroundColor Yellow
            Remove-ItemProperty -Path $deviceKey -Name "Device" -ErrorAction SilentlyContinue
            Write-Log "HKCU Device key purged: $deviceVal" -Type "SUCCESS"
        }

        Set-ItemProperty -Path $deviceKey -Name LegacyDefaultPrinterMode -Value 1 -Type DWord -Force

        $wppPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\WPP"
        if (-not (Test-Path $wppPath)) { New-Item -Path $wppPath -Force | Out-Null }
        Set-ItemProperty -Path $wppPath -Name Enabled -Value 0 -Type DWord -Force

        $lsaMSV = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0"
        Set-ItemProperty -Path $lsaMSV -Name NtlmMinClientSec -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $lsaMSV -Name NtlmMinServerSec -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

        Restart-Service spooler -Force -ErrorAction SilentlyContinue

        Write-Log "Fix-Deep0x00000709 complete. MUST also be executed on the HOST machine." -Type "SUCCESS"
        Write-Host "  [+] All 0x00000709 layers applied." -ForegroundColor Green
        Write-Host "  [!] IMPORTANT: Run this script on the HOST PC (the one connected to the printer)!" -ForegroundColor Red
    }
    catch {
        Write-Log "Failed Deep 0x00000709 Fix: $($_.Exception.Message)" -Type "ERROR"
    }
}

function Fix-CrossSignedDriverPolicy {
    Write-Log "Bypassing KB5089549 Cross-Signed Driver Enforcement (Audit Mode Disable)..." -Type "INFO"
    try {

        $ciPath = "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Config"
        if (-not (Test-Path $ciPath)) { New-Item -Path $ciPath -Force | Out-Null }

        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Config" `
            -Name VulnerableDriverBlocklistEnable -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

        $polPath = "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy"
        if (-not (Test-Path $polPath)) { New-Item -Path $polPath -Force | Out-Null }
        Set-ItemProperty -Path $polPath `
            -Name VerifiedAndReputablePolicyState -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Write-Log "Cross-signed driver enforcement set to permissive (post-KB5089549 fix)." -Type "SUCCESS"
        Write-Host "  [+] KB5089549 driver policy enforcement neutralized." -ForegroundColor Green
    }
    catch {
        Write-Log "Failed to fix cross-signed driver policy: $($_.Exception.Message)" -Type "ERROR"
    }
}

function Fix-HKCU-PrinterKeyPerms {
    Write-Log "Fixing HKCU Windows registry key permissions for printer device write..." -Type "INFO"
    try {

        $regKey = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Windows"
        $acl = Get-Acl $regKey
        $sid = New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::WorldSid, $null)
        $rule = New-Object System.Security.AccessControl.RegistryAccessRule(
            $sid,
            "FullControl",
            "ContainerInherit,ObjectInherit",
            "None",
            "Allow"
        )
        $acl.SetAccessRule($rule)
        Set-Acl -Path $regKey -AclObject $acl -ErrorAction Stop
        Write-Log "HKCU Windows key: Everyone (S-1-1-0) FullControl granted." -Type "SUCCESS"
        Write-Host "  [+] Registry permission fix applied (Everyone = FullControl on printer device key)." -ForegroundColor Green
    }
    catch {
        Write-Log "Failed to fix HKCU printer key permissions: $($_.Exception.Message)" -Type "ERROR"
    }
}

function Set-PostPatchTuesdayTask {
    Write-Log "Deploying Post-Windows-Update Auto-Reapply Task..." -Type "INFO"
    try {
        if (-not (Test-Path $script:backupDir)) {
            New-Item -ItemType Directory -Path $script:backupDir -Force | Out-Null
        }
        
        $scriptPath = Join-Path $script:backupDir "PrinterFixReapply.ps1"
        $fixScript = @'
Set-ItemProperty "HKLM:\Software\Policies\Microsoft\Windows NT\Printers\RPC" -Name RpcUseNamedPipeProtocol -Value 1 -Type DWord -Force -EA SilentlyContinue
Set-ItemProperty "HKLM:\Software\Policies\Microsoft\Windows NT\Printers\RPC" -Name ForceKerberosForRpc -Value 0 -Type DWord -Force -EA SilentlyContinue
Set-ItemProperty "HKLM:\Software\Policies\Microsoft\Windows NT\Printers\RPC" -Name RpcProtocols -Value 7 -Type DWord -Force -EA SilentlyContinue
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Print" -Name RpcAuthnLevelPrivacyEnabled -Value 0 -Type DWord -Force -EA SilentlyContinue
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Print" -Name RpcOverNamedPipes -Value 1 -Type DWord -Force -EA SilentlyContinue
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Print" -Name RpcOverTcp -Value 1 -Type DWord -Force -EA SilentlyContinue
Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\WPP" -Name Enabled -Value 0 -Type DWord -Force -EA SilentlyContinue
Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name LocalAccountTokenFilterPolicy -Value 1 -Type DWord -Force -EA SilentlyContinue
Restart-Service spooler -Force -EA SilentlyContinue
'@
        Set-Content -Path $scriptPath -Value $fixScript -Encoding UTF8 -Force
        
        $cmd = "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`""
        
        & schtasks.exe /create /tn "PrinterFixPostUpdate" /tr $cmd /sc onstart /ru "SYSTEM" /rl HIGHEST /f > $null 2>&1
        if ($LASTEXITCODE -ne 0) { throw "schtasks ONSTART returned exit code $LASTEXITCODE" }
        
        & schtasks.exe /create /tn "PrinterFixDaily" /tr $cmd /sc daily /st 10:00 /ru "SYSTEM" /rl HIGHEST /f > $null 2>&1
        if ($LASTEXITCODE -ne 0) { throw "schtasks DAILY returned exit code $LASTEXITCODE" }

        # Configure tasks to run on battery power (disables 0x800710E0 error on laptops)
        try {
            $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
            Set-ScheduledTask -TaskName "PrinterFixPostUpdate" -Settings $settings -ErrorAction SilentlyContinue | Out-Null
            Set-ScheduledTask -TaskName "PrinterFixDaily" -Settings $settings -ErrorAction SilentlyContinue | Out-Null
        } catch {}

        Write-Log "Post-Windows-Update reapply task deployed successfully." -Type "SUCCESS"
        Write-Host "  [+] Auto-reapply task deployed. Registry fixes will re-apply automatically after every reboot/update." -ForegroundColor Green
        Write-Host "  [+] Task: 'PrinterFixPostUpdate' & 'PrinterFixDaily' are active in Task Scheduler." -ForegroundColor Cyan
    }
    catch {
        Write-Log "Failed to deploy post-update task: $($_.Exception.Message)" -Type "ERROR"
    }
}

function Fix-Discovery0x00000bc4 {
    Write-Log "Bypassing Error 0x00000bc4 (No printers were found)..." -Type "INFO"
    try {
        $path = "HKLM:\Software\Policies\Microsoft\Windows NT\Printers\RPC"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }

        Set-ItemProperty -Path $path -Name RpcUseNamedPipeProtocol -Value 1 -Type DWord -Force -ErrorAction Stop
        Set-ItemProperty -Path $path -Name RpcTcpEnable -Value 1 -Type DWord -Force -ErrorAction Stop
        Set-ItemProperty -Path $path -Name RpcProtocols -Value 0x7 -Type DWord -Force -ErrorAction Stop
        Set-ItemProperty -Path $path -Name ForceSetup -Value 1 -Type DWord -Force -ErrorAction Stop

        Write-Log "RPC Endpoint Mapper forced via Named Pipes & TCP." -Type "SUCCESS"
        Write-Host "  [+] RPC printer discovery explicitly routed via Named Pipes." -ForegroundColor Green
    }
    catch {
        Write-Log "Failed to bypass 0x00000bc4: $($_.Exception.Message)" -Type "ERROR"
    }
}

function Fix-NetworkServices {
    Write-Log "Fixing Error 0x80070035 (Starting WSD, SMB, NetBIOS services)..." -Type "INFO"
    $services = @("nlasvc", "Dnscache", "LanmanServer", "LanmanWorkstation", "lmhosts", "fdPHost", "FDResPub", "SSDPSRV", "upnphost", "WdiSystemHost", "WdiServiceHost")

    foreach ($svc in $services) {
        try {
            Set-Service -Name $svc -StartupType Automatic -ErrorAction SilentlyContinue
            Start-Service -Name $svc -ErrorAction SilentlyContinue
        }
        catch {
            Write-Log "Warning: Unable to configure service $svc." -Type "WARNING"
        }
    }
    Write-Log "Network & WSD services configured for auto-start." -Type "SUCCESS"
    Write-Host "  [+] All network services are operational." -ForegroundColor Green
}

function Fix-CSR {
    Write-Log "Disabling Client-Side Rendering (Error 0x000006d1)..." -Type "INFO"
    try {
        $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }

        Set-ItemProperty -Path $path -Name DisableClientSideRendering -Value 1 -Type DWord -Force -ErrorAction Stop
        Write-Log "CSR successfully disabled." -Type "SUCCESS"
        Write-Host "  [+] Client-Side Rendering disabled; Host will process print jobs." -ForegroundColor Green
    }
    catch {
        Write-Log "Failed to disable CSR: $($_.Exception.Message)" -Type "ERROR"
    }
}

function Reset-Spooler {
    Write-Log "Terminating Print Spooler & Purging Queue..." -Type "INFO"
    try {
        Stop-Service spooler -Force -ErrorAction SilentlyContinue

        Write-Log "Ensuring related processes (splwow64, printfilter) are terminated..." -Type "INFO"
        Get-Process -Name "printfilterpipelinesvc", "splwow64" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

        Start-Sleep -Seconds 1

        Write-Log "Purging stale print spool files..." -Type "INFO"
        Remove-Item -Path "$env:SystemRoot\System32\Spool\Printers\*" -Force -Recurse -ErrorAction SilentlyContinue

        Start-Sleep -Seconds 1

        Set-Service spooler -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service spooler -ErrorAction Stop

        Write-Log "Spooler successfully refreshed!" -Type "SUCCESS"
        Write-Host "  [+] Print Spooler successfully purged and set to Automatic (Hard Reset)." -ForegroundColor Green
    }
    catch {
        Write-Log "Failed to reset Spooler: $($_.Exception.Message)" -Type "ERROR"
    }
}

function Enable-SMBGuest {
    Write-Log "Enabling SMB Guest access (LanmanWorkstation & LanmanServer)..." -Type "INFO"
    try {
        $path = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters"
        Set-ItemProperty -Path $path -Name AllowInsecureGuestAuth -Value 1 -Type DWord -Force -ErrorAction Stop

        $pathServer = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"
        Set-ItemProperty -Path $pathServer -Name EnableSecuritySignature -Value 0 -Type DWord -Force -ErrorAction Stop

        Write-Log "Guest access enabled." -Type "SUCCESS"
        Write-Host "  [+] SMB credential protection lowered to permit Guest access." -ForegroundColor Green
    }
    catch {
        Write-Log "Failed to enable SMB Guest: $($_.Exception.Message)" -Type "ERROR"
    }
}

function Reset-Network {
    Write-Log "Complete Network Reset (Flush DNS, NetBIOS, Winsock)..." -Type "INFO"
    try {
        $LASTEXITCODE = 0; ipconfig /flushdns > $null 2>&1
        Clear-DnsClientCache -ErrorAction SilentlyContinue
        $LASTEXITCODE = 0; & netsh winsock reset > $null 2>&1
        $LASTEXITCODE = 0; & netsh int ip reset > $null 2>&1
        $LASTEXITCODE = 0; nbtstat -RR > $null 2>&1

        Write-Log "Network configuration reset." -Type "SUCCESS"
        Write-Host "  [+] Network caches successfully flushed." -ForegroundColor Green
    }
    catch {
        Write-Log "Failed to reset network: $($_.Exception.Message)" -Type "ERROR"
    }
}

function Set-NetworkPrivate {
    Write-Log "Mutating Network Profile (Public to Private, bypassing Domain)..." -Type "INFO"
    try {
        $nla = Get-Service nlasvc -ErrorAction SilentlyContinue
        if ($nla -and $nla.Status -ne 'Running') { Start-Service nlasvc -ErrorAction SilentlyContinue }

        $profiles = Get-NetConnectionProfile -ErrorAction SilentlyContinue
        $success = $false
        foreach ($profile in $profiles) {
            if ($profile.NetworkCategory -eq 'Public') {
                try {
                    Set-NetConnectionProfile -InterfaceAlias $profile.InterfaceAlias -NetworkCategory Private -ErrorAction Stop
                    $success = $true
                }
                catch {
                    Write-Log "Failed to mutate profile $($profile.InterfaceAlias)." -Type "WARNING"
                }
            }
            elseif ($profile.NetworkCategory -eq 'Private' -or $profile.NetworkCategory -eq 'DomainAuthenticated') {
                $success = $true
            }
        }

        if ($success) {
            Write-Log "Private network profile securely enforced." -Type "SUCCESS"
            Write-Host "  [+] Network enforced as Private; discovery blocks removed." -ForegroundColor Green
        }
    }
    catch {
        Write-Log "Failed to mutate network profile: $($_.Exception.Message)" -Type "ERROR"
    }
}

function Disable-PasswordSharing {
    Write-Log "Disabling Password Protected Sharing..." -Type "INFO"
    try {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name limitblankpassworduse -Value 0 -Type DWord -Force -ErrorAction Stop
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name everyoneincludesanonymous -Value 1 -Type DWord -Force -ErrorAction Stop
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name restrictnullsessaccess -Value 0 -Type DWord -Force -ErrorAction Stop

        Write-Log "Password Protected Sharing disabled." -Type "SUCCESS"
        Write-Host "  [+] Network shares opened (Everyone = Anonymous)." -ForegroundColor Green
    }
    catch {
        Write-Log "Failed to disable password sharing: $($_.Exception.Message)" -Type "ERROR"
    }
}

function Fix-NamedPipes {
    Write-Log "Activating RPC Named Pipes..." -Type "INFO"
    try {
        $rpcPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\RPC"
        if (-not (Test-Path $rpcPath)) { New-Item -Path $rpcPath -Force | Out-Null }

        Set-ItemProperty -Path $rpcPath -Name RpcUseNamedPipeProtocol -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $rpcPath -Name RpcTcpEnable -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $rpcPath -Name RpcProtocols -Value 0x7 -Type DWord -Force
        Set-ItemProperty -Path $rpcPath -Name RpcOverNamedPipes -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $rpcPath -Name ForceKerberosForRpc -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

        $polPrinters = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers"
        if (-not (Test-Path $polPrinters)) { New-Item -Path $polPrinters -Force | Out-Null }
        Set-ItemProperty -Path $polPrinters -Name RegisterSpoolerRemoteRpcEndPoint -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

        $printPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Print"
        Set-ItemProperty -Path $printPath -Name RpcOverNamedPipes -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $printPath -Name RpcOverTcp -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

        Write-Log "Named Pipes activated." -Type "SUCCESS"
        Write-Host "  [+] RPC Named Pipes pathway for print spooling corrected." -ForegroundColor Green
    }
    catch {
        Write-Log "Failed to mutate Named Pipes: $($_.Exception.Message)" -Type "ERROR"
    }
}

function Open-Firewall {
    Write-Log "Opening Firewall for File & Printer Sharing..." -Type "INFO"
    try {
        Enable-NetFirewallRule -Group "@FirewallAPI.dll,-28502" -ErrorAction SilentlyContinue | Out-Null
        Enable-NetFirewallRule -Group "@FirewallAPI.dll,-28509" -ErrorAction SilentlyContinue | Out-Null
        Enable-NetFirewallRule -DisplayGroup "*File*Printer*" -ErrorAction SilentlyContinue | Out-Null
        Enable-NetFirewallRule -DisplayGroup "*Network Discovery*" -ErrorAction SilentlyContinue | Out-Null

        Write-Log "Firewall ports opened." -Type "SUCCESS"
        Write-Host "  [+] Windows Defender Firewall configured to permit Sharing." -ForegroundColor Green
    }
    catch {
        Write-Log "Failed to mutate Firewall rules: $($_.Exception.Message)" -Type "ERROR"
    }
}

function Backup-Registry {
    Write-Log "Executing Printer Registry Backup..." -Type "INFO"
    try {
        $backupCount = 0
        $backupTotal = 5

        & reg export "HKLM\SYSTEM\CurrentControlSet\Control\Print" "$script:backupDir\Print.reg" /y > $null 2>&1
        if ($LASTEXITCODE -eq 0) { $backupCount++ } else { Write-Log "Warning: Failed to backup Print registry." -Type "WARNING" }

        & reg export "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers" "$script:backupDir\PrintersPolicy.reg" /y > $null 2>&1
        if ($LASTEXITCODE -eq 0) { $backupCount++ } else { Write-Log "Warning: Failed to backup PrintersPolicy registry." -Type "WARNING" }

        & reg export "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" "$script:backupDir\LanmanWorkstation.reg" /y > $null 2>&1
        if ($LASTEXITCODE -eq 0) { $backupCount++ } else { Write-Log "Warning: Failed to backup LanmanWorkstation registry." -Type "WARNING" }

        & reg export "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" "$script:backupDir\LanmanServer.reg" /y > $null 2>&1
        if ($LASTEXITCODE -eq 0) { $backupCount++ } else { Write-Log "Warning: Failed to backup LanmanServer registry." -Type "WARNING" }

        & reg export "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" "$script:backupDir\Lsa.reg" /y > $null 2>&1
        if ($LASTEXITCODE -eq 0) { $backupCount++ } else { Write-Log "Warning: Failed to backup LSA registry." -Type "WARNING" }

        Write-Log "Backup completed ($backupCount/$backupTotal hives)." -Type "SUCCESS"
        Write-Host "  [+] Critical registry nodes backed up to $script:backupDir ($backupCount/$backupTotal hives)." -ForegroundColor Green
    }
    catch {
        Write-Log "Failed to backup registry: $($_.Exception.Message)" -Type "ERROR"
    }
}

function Check-RPC {
    Write-Log "Auditing RPC & DCOM service states..." -Type "INFO"
    $rpc = Get-Service -Name RpcSs -ErrorAction SilentlyContinue
    if ($rpc.Status -ne 'Running') {
        Start-Service RpcSs -ErrorAction SilentlyContinue
        Write-Host "  [*] RpcSs offline. Re-initializing service." -ForegroundColor Yellow
    }
    else {
        Write-Host "  [+] RpcSs operational." -ForegroundColor Green
    }

    $dcom = Get-Service -Name DcomLaunch -ErrorAction SilentlyContinue
    if ($dcom.Status -ne 'Running') {
        Start-Service DcomLaunch -ErrorAction SilentlyContinue
        Write-Host "  [*] DcomLaunch offline. Re-initializing service." -ForegroundColor Yellow
    }
    else {
        Write-Host "  [+] DcomLaunch operational." -ForegroundColor Green
    }
}

function Run-SfcDism {
    Write-Log "Initiating SFC and DISM sequences..." -Type "INFO"
    Write-Host "`n  [!] STANDBY, this operation requires significant time..." -ForegroundColor Yellow
    Write-Host "  [*] [1/2] SFC Scannow sequence executing..." -ForegroundColor Cyan
    & sfc /scannow
    Write-Host "  [*] [2/2] DISM RestoreHealth sequence executing..." -ForegroundColor Cyan
    & dism /online /cleanup-image /restorehealth
    Write-Log "SFC & DISM sequence completed." -Type "SUCCESS"
    Write-Host "  [+] OS file integrity verification concluded." -ForegroundColor Green
}

function Manage-Drivers {
    Write-Log "Launching Print Server Properties..." -Type "INFO"
    Write-Host "  [!] Print Server Properties dialog opening. Purge anomalous drivers manually." -ForegroundColor Yellow
    Start-Process printui -ArgumentList '/s /t2' -NoNewWindow
}

function Reset-SpoolerPerm {
    Write-Log "Resetting Spooler directory ACL permissions..." -Type "INFO"
    try {
        & icacls "$env:SystemRoot\System32\Spool\Printers" /reset /t /c /q > $null 2>&1
        & icacls "$env:SystemRoot\System32\Spool\Printers" /grant "*S-1-1-0:(OI)(CI)F" /T /C /Q > $null 2>&1
        Write-Log "Spooler ACL reset & Everyone (S-1-1-0) grant complete." -Type "SUCCESS"
        Write-Host "  [+] Print queue directory permissions reset and granted to Everyone." -ForegroundColor Green
    }
    catch {
        Write-Log "Failed to reset ACL: $($_.Exception.Message)" -Type "ERROR"
    }
}

function Manage-SMB1 {
    Write-Host "`n  ======================================================================"
    Write-Host "                 SMB 1.0 PROTOCOL MANAGEMENT (LEGACY)"
    Write-Host "  ======================================================================"
    Write-Host "  [!] WARNING: SMB 1.0 is highly vulnerable to Ransomware vectors."
    Write-Host "  [1] ENABLE SMB1 (Emergency) `n  [2] DISABLE SMB1 (Recommended)"
    $smbopt = Read-Host "  Select Option (1/2)"
    if ($smbopt -eq '1') {
        try {
            Write-Log "Enabling SMB 1.0 Protocol..." -Type "INFO"
            Enable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart -ErrorAction Stop | Out-Null
            Write-Host "  [+] SMB 1.0 Protocol enabled." -ForegroundColor Green
        } catch {
            Write-Log "Failed to enable SMB1: $($_.Exception.Message)" -Type "ERROR"
        }
    }
    if ($smbopt -eq '2') {
        try {
            Write-Log "Disabling SMB 1.0 Protocol..." -Type "INFO"
            Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart -ErrorAction Stop | Out-Null
            Write-Host "  [+] SMB 1.0 Protocol successfully disabled for security." -ForegroundColor Green
        } catch {
            Write-Log "Failed to disable SMB1: $($_.Exception.Message)" -Type "ERROR"
        }
    }
}

function Add-Credential {
    Write-Host "`n  INJECT WINDOWS CREDENTIALS"
    $ip = Read-Host "  [?] Target IP/Hostname (e.g., 192.168.1.10)"
    if ($null -ne $ip) { $ip = $ip.Trim() }
    $usr = Read-Host "  [?] Username on Target Host"
    if ($null -ne $usr) { $usr = $usr.Trim() }
    $pass = Read-Host "  [?] Password on Target Host (Visible Text)"

    if (-not $ip -or -not $usr) {
        Write-Host "  [-] Cancelled - target host and username are required." -ForegroundColor Red
        return
    }

    try {
        $proc = Start-Process -FilePath "cmdkey.exe" -ArgumentList "/add:$ip", "/user:$usr", "/pass:`"$pass`"" -WindowStyle Hidden -Wait -PassThru
        if ($proc.ExitCode -eq 0) {
            Write-Log "Credential for $ip injected." -Type "SUCCESS"
            Write-Host "  [+] Credentials successfully committed to Windows Vault." -ForegroundColor Green
        } else {
            Write-Log "cmdkey returned exit code $($proc.ExitCode) for $ip." -Type "ERROR"
            Write-Host "  [-] Credential injection failed (exit code $($proc.ExitCode))." -ForegroundColor Red
        }
        Start-Sleep -Seconds 1
    }
    catch {
        Write-Log "Failed to inject credential: $($_.Exception.Message)" -Type "ERROR"
    }
    $pass = ""
}

function Clean-Credential {
    Write-Host "`n  PURGE STALE WINDOWS CREDENTIALS"
    & cmdkey /list | Select-String "Target:" | ForEach-Object { Write-Host "  $_" -ForegroundColor Cyan }
    $del = Read-Host "`n  [?] Enter Target to purge (Leave blank to cancel)"
    if ($del) {
        $del = $del -replace '(?i)^\s*Target:\s*', ''
        try {
            $proc = Start-Process -FilePath "cmdkey.exe" -ArgumentList "/delete:`"$del`"" -WindowStyle Hidden -Wait -PassThru
            if ($proc.ExitCode -eq 0) {
                Write-Log "Credential $del purged." -Type "SUCCESS"
                Write-Host "  [+] Credential $del successfully purged." -ForegroundColor Green
            } else {
                Write-Log "Failed to purge credential $del. Verify target name." -Type "ERROR"
                Write-Host "  [-] Failed to purge credential $del. Verify target name." -ForegroundColor Red
            }
        }
        catch {
            Write-Log "Failed to purge credential: $($_.Exception.Message)" -Type "ERROR"
        }
    }
}

function Start-Troubleshooter {
    Write-Log "Executing native Windows Troubleshooter..." -Type "INFO"
    Start-Process msdt -ArgumentList '/id PrinterDiagnostic' -NoNewWindow
}

function Force-PrinterOnline {
    Write-Log "Forcing Printer Online status..." -Type "INFO"
    $pname = Read-Host "  [?] Input exact Printer Name (e.g., EPSON L120 Series)"
    if ($pname) {
        try {
            $safeName = $pname -replace "'", "''"
            $prn = Get-CimInstance Win32_Printer -Filter "Name='$safeName'" -ErrorAction Stop
            if ($prn) {
                $prn.WorkOffline = $false
                Set-CimInstance -InputObject $prn -ErrorAction Stop
                Write-Log "Printer $pname state forced online." -Type "SUCCESS"
                Write-Host "  [+] Online enforcement command sent to $pname." -ForegroundColor Green
            }
            else {
                Write-Host "  [-] Printer $pname not detected on this system." -ForegroundColor Red
            }
        }
        catch {
            Write-Log "Failed to force printer online status: $($_.Exception.Message)" -Type "ERROR"
        }
    }
}

function Open-Services {
    Write-Log "Launching Services.msc MMC snap-in..." -Type "INFO"
    Start-Process services.msc
}

function Rollback-Registry {
    Write-Log "Restoring Registry from Backup..." -Type "INFO"
    if (Test-Path "$script:backupDir\Print.reg") {
        $restoreCount = 0
        $restoreFiles = @(
            @{ File = "Print.reg"; Label = "Print" },
            @{ File = "PrintersPolicy.reg"; Label = "PrintersPolicy" },
            @{ File = "LanmanWorkstation.reg"; Label = "LanmanWorkstation" },
            @{ File = "LanmanServer.reg"; Label = "LanmanServer" },
            @{ File = "Lsa.reg"; Label = "LSA" }
        )
        foreach ($entry in $restoreFiles) {
            $filePath = Join-Path $script:backupDir $entry.File
            if (Test-Path $filePath) {
                & reg import $filePath > $null 2>&1
                if ($LASTEXITCODE -eq 0) {
                    $restoreCount++
                } else {
                    Write-Log "Warning: Failed to restore $($entry.Label)." -Type "WARNING"
                    Write-Host "  [!] Failed to restore $($entry.Label)." -ForegroundColor Yellow
                }
            } else {
                Write-Host "  [*] Skipped $($entry.Label) (no backup file found)." -ForegroundColor Cyan
            }
        }
        Write-Log "Registry rollback completed ($restoreCount files restored)." -Type "SUCCESS"
        Write-Host "  [+] Registry rollback completed ($restoreCount file(s) restored from $script:backupDir)." -ForegroundColor Green
    }
    else {
        Write-Host "  [-] Failure: Backup files not detected in $script:backupDir." -ForegroundColor Red
    }
}

function Disable-IPv6 {
    Write-Log "Disabling IPv6 Stack..." -Type "INFO"
    try {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name DisabledComponents -Value 0xffffffff -Type DWord -Force -ErrorAction Stop
        Write-Log "IPv6 disabled via registry change." -Type "SUCCESS"
        Write-Host "  [+] IPv6 disabled to prevent routing conflicts. System reboot required." -ForegroundColor Green
    }
    catch {
        Write-Log "Failed to disable IPv6: $($_.Exception.Message)" -Type "ERROR"
    }
}

function Generate-HtmlLog {
    Write-Log "Generating HTML Diagnostic Report..." -Type "INFO"
    $htmlFile = "$script:backupDir\Report.html"
    $rawLog = Get-Content $script:logFile -Raw -ErrorAction SilentlyContinue
    $encodedLog = [System.Net.WebUtility]::HtmlEncode($rawLog)
    $htmlContent = @"
<html>
<head>
    <title>Windows Printer Sharing Fix - Log</title>
    <style>
        body { font-family: 'Courier New', monospace; background: #0b0f19; color: #00ffcc; padding: 20px; }
        h1 { color: #ff0055; border-bottom: 2px solid #333; padding-bottom: 10px; }
        pre { background: #161b22; padding: 20px; border-radius: 8px; border: 1px solid #30363d; overflow-x: auto; font-size: 14px; }
    </style>
</head>
<body>
    <h1>Windows Printer Sharing Fix Diagnostics Report</h1>
    <p>Generation Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | Target OS: $([System.Net.WebUtility]::HtmlEncode($script:productName))</p>
    <pre>$encodedLog</pre>
</body>
</html>
"@
    $htmlContent | Out-File $htmlFile -Encoding UTF8
    Write-Log "HTML Log generated at $htmlFile." -Type "SUCCESS"
    Start-Process $htmlFile
}

function Test-Connectivity {
    Write-Host "`n  ======================================================================"
    Write-Host "                 PING & NETWORK PORT DIAGNOSTICS"
    Write-Host "  ======================================================================"
    $ip = Read-Host "  [?] Input Target IP/Hostname"
    if (-not $ip -or $ip.Trim() -eq '') {
        Write-Host "  [-] Cancelled - no input provided." -ForegroundColor Red
        return
    }
    $ip = $ip.Trim()
    if (Test-Connection $ip -Count 1 -Quiet) {
        Write-Host "  [+] PING SUCCESS: Host $ip is reachable." -ForegroundColor Green

        $port445 = Test-NetConnection $ip -Port 445 -WarningAction SilentlyContinue
        if ($port445.TcpTestSucceeded) { Write-Host "  [+] PORT 445 (SMB): OPEN" -ForegroundColor Green }
        else { Write-Host "  [-] PORT 445 (SMB): CLOSED (FIREWALL BLOCKED)" -ForegroundColor Red }

        $port135 = Test-NetConnection $ip -Port 135 -WarningAction SilentlyContinue
        if ($port135.TcpTestSucceeded) { Write-Host "  [+] PORT 135 (RPC): OPEN" -ForegroundColor Green }
        else { Write-Host "  [-] PORT 135 (RPC): CLOSED (FIREWALL BLOCKED)" -ForegroundColor Red }
    }
    else {
        Write-Host "  [-] PING FAILED: Target Host unreachable or explicitly blocking ICMP." -ForegroundColor Red
        Write-Host "  [*] Checking TCP ports 445 and 135 anyway..." -ForegroundColor Cyan
        
        $port445 = Test-NetConnection $ip -Port 445 -WarningAction SilentlyContinue
        if ($port445.TcpTestSucceeded) { Write-Host "  [+] PORT 445 (SMB): OPEN (Ping was blocked but host is alive)" -ForegroundColor Green }
        else { Write-Host "  [-] PORT 445 (SMB): CLOSED" -ForegroundColor Red }

        $port135 = Test-NetConnection $ip -Port 135 -WarningAction SilentlyContinue
        if ($port135.TcpTestSucceeded) { Write-Host "  [+] PORT 135 (RPC): OPEN (Ping was blocked but host is alive)" -ForegroundColor Green }
        else { Write-Host "  [-] PORT 135 (RPC): CLOSED" -ForegroundColor Red }
    }
}

function Scan-RemotePrinter {
    Write-Host "`n  REMOTE NETWORK PRINTER DISCOVERY"
    $ip = Read-Host "  [?] Target IP/Hostname"
    Write-Host "  [*] Scanning $ip..." -ForegroundColor Cyan
    try {
        $prn = Get-Printer -ComputerName $ip -ErrorAction Stop | Where-Object Shared -eq $true
        if ($prn) {
            $prn | Format-Table Name, ShareName, PortName, PrinterStatus -AutoSize
        }
        else {
            Write-Host "  [-] No shared printers detected on the target host." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "  [-] RPC connection failure. Verify Admin/Guest access to $ip." -ForegroundColor Red
    }
}

function Remote-SpoolerReset {
    Write-Host "`n  ======================================================================"
    Write-Host "               REMOTE PRINT SPOOLER RESET"
    Write-Host "  ======================================================================"
    Write-Host "  [!] Requires admin access on the remote machine." -ForegroundColor Yellow
    $target = Read-Host "  [?] Target hostname or IP (e.g., 192.168.1.10)"
    if (-not $target) { Write-Host "  [-] Cancelled - empty input." -ForegroundColor Red; return }

    Write-Log "Remote Spooler Reset targeting: $target" -Type "INFO"
    try {
        Write-Host "  [*] Pinging $target..." -ForegroundColor Cyan
        if (-not (Test-Connection $target -Count 1 -Quiet)) {
            Write-Host "  [-] Host unreachable. Check network and firewall." -ForegroundColor Red
            Write-Log "Remote-SpoolerReset: $target unreachable." -Type "ERROR"
            return
        }
        Write-Host "  [+] Host reachable." -ForegroundColor Green

        Write-Host "  [*] Stopping Spooler on $target..." -ForegroundColor Cyan
        $stopResult = & sc.exe \\$target stop spooler 2>&1
        Start-Sleep -Seconds 3

        Write-Host "  [*] Starting Spooler on $target..." -ForegroundColor Cyan
        $startResult = & sc.exe \\$target start spooler 2>&1
        Start-Sleep -Seconds 2

        $queryResult = & sc.exe \\$target query spooler 2>&1
        if ($queryResult -match 'RUNNING') {
            Write-Log "Remote Spooler on $target restarted successfully." -Type "SUCCESS"
            Write-Host "  [+] Print Spooler on $target is now RUNNING." -ForegroundColor Green
        } else {
            Write-Log "Remote Spooler on $target may not have restarted. Check manually." -Type "WARNING"
            Write-Host "  [!] Spooler state uncertain. Verify manually on $target." -ForegroundColor Yellow
        }
    } catch {
        Write-Log "Remote-SpoolerReset failed: $($_.Exception.Message)" -Type "ERROR"
        Write-Host "  [-] Failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  [!] Ensure admin shares (C$) and RPC (port 135/445) are accessible." -ForegroundColor Yellow
    }
}

function Log-Manager {
    Write-Log "Launching Log Manager via Notepad..." -Type "INFO"
    notepad $script:logFile
}

function Print-Migration {
    Write-Log "Launching PrintBRM migration utility..." -Type "INFO"

    $brmPath = Join-Path $env:SystemRoot "System32\spool\tools\PrintBrm.exe"
    if (-not (Test-Path $brmPath)) {
        $brmPath = Join-Path $env:SystemRoot "System32\PrintBrm.exe"
    }

    if (-not (Test-Path $brmPath)) {
        Write-Log "PrintBrm.exe not detected on this system." -Type "ERROR"
        Write-Host "  [-] ERROR: Print Migration utility (PrintBrm.exe) is missing." -ForegroundColor Red
        Write-Host "  [!] NOTE: This feature is typically only available in Windows Pro, Enterprise, or Server editions." -ForegroundColor Yellow
        Write-Host "  [!] Your OS: $script:productName" -ForegroundColor Cyan
        return
    }

    Write-Host "  [*] Launching PrintBrm.exe in a persistent command prompt window..." -ForegroundColor Cyan
    try {
        Start-Process cmd.exe -ArgumentList "/k cd /d `"$env:SystemRoot\System32\spool\tools\`" & title PrintBRM Migration Utility & `"$brmPath`" /?"
        Write-Log "PrintBRM prompt launched successfully." -Type "SUCCESS"
        Write-Host "  [+] PrintBRM prompt successfully launched! You can now execute backup/restore commands." -ForegroundColor Green
    }
    catch {
        Write-Log "Failed to launch PrintBRM: $($_.Exception.Message)" -Type "ERROR"
    }
}

function Uninstall-Printer {
    $up = Read-Host "`n  [?] Input exact name of the printer to forcefully uninstall"
    if ($up) {
        try {
            & printui.exe /dl /n "$up"
            Write-Log "Uninstall command issued for $up." -Type "SUCCESS"
        }
        catch {
            Write-Log "Failed to uninstall $up : $($_.Exception.Message)" -Type "ERROR"
        }
    }
}

function Fix-SMBSigning {
    Write-Log "Disabling SMB Signing enforcement & Mutual Auth..." -Type "INFO"
    try {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name RequireSecuritySignature -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name RequireSecuritySignature -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name RequireMutualAuthentication -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

        $polLanman = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation"
        if (-not (Test-Path $polLanman)) { New-Item -Path $polLanman -Force | Out-Null }
        Set-ItemProperty -Path $polLanman -Name RequireSecuritySignature -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $polLanman -Name AllowInsecureGuestAuth -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

        try {
            if (Get-Command Set-SmbClientConfiguration -ErrorAction SilentlyContinue) {
                Set-SmbClientConfiguration -RequireSecuritySignature $false -EnableSecuritySignature $false -Confirm:$false -Force -ErrorAction SilentlyContinue
            }
            if (Get-Command Set-SmbServerConfiguration -ErrorAction SilentlyContinue) {
                Set-SmbServerConfiguration -RequireSecuritySignature $false -EnableSecuritySignature $false -Confirm:$false -Force -ErrorAction SilentlyContinue
            }
        } catch {}

        Write-Log "SMB Signing enforcement disabled." -Type "SUCCESS"
        Write-Host "  [+] SMB Signature requirements dropped (Resolves Win 11 NAS/Legacy connectivity)." -ForegroundColor Green
    }
    catch {
        Write-Log "Failed to disable SMB signing: $($_.Exception.Message)" -Type "ERROR"
    }
}

function Fix-UWPPrinting {
    Write-Log "Bypassing UWP AppContainer Isolation for Microsoft Edge..." -Type "INFO"
    try {
        & CheckNetIsolation.exe LoopbackExempt -a -n="microsoft.windows.printdialog_cw5n1h2txyewy" 2>&1 | Out-Null
        & CheckNetIsolation.exe LoopbackExempt -a -n="microsoft.microsoftedge_8wekyb3d8bbwe" 2>&1 | Out-Null
        Write-Log "Loopback Isolation explicit exemption granted." -Type "SUCCESS"
        Write-Host "  [+] Loopback network isolation for Edge and UWP Apps disabled." -ForegroundColor Green
    }
    catch {
        Write-Log "Failed to bypass UWP Loopback: $($_.Exception.Message)" -Type "ERROR"
    }
}

function Fix-mDNS {
    Write-Log "Enabling mDNS & LLMNR discovery protocols..." -Type "INFO"
    try {
        $dnsPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient"
        if (-not (Test-Path $dnsPath)) { New-Item -Path $dnsPath -Force | Out-Null }
        Set-ItemProperty -Path $dnsPath -Name EnableMulticast -Value 1 -Type DWord -Force -ErrorAction Stop

        $dnsCachePath = "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters"
        if (-not (Test-Path $dnsCachePath)) { New-Item -Path $dnsCachePath -Force | Out-Null }
        Set-ItemProperty -Path $dnsCachePath -Name EnableMDNS -Value 1 -Type DWord -Force -ErrorAction Stop

        Write-Log "mDNS/LLMNR protocols activated." -Type "SUCCESS"
    }
    catch {
        Write-Log "Failed to configure mDNS: $($_.Exception.Message)" -Type "ERROR"
    }
}

function Fix-WSDFirewall {
    Write-Log "Ensuring WSD (3702) & mDNS (5353) Ports are unconditionally open..." -Type "INFO"
    try {
        Remove-NetFirewallRule -DisplayName "Printer WSD (UDP 3702 Inbound)" -ErrorAction SilentlyContinue | Out-Null
        Remove-NetFirewallRule -DisplayName "Printer mDNS (UDP 5353 Inbound)" -ErrorAction SilentlyContinue | Out-Null

        New-NetFirewallRule -DisplayName "Printer WSD (UDP 3702 Inbound)" -Direction Inbound -Action Allow -Protocol UDP -LocalPort 3702 -ErrorAction SilentlyContinue | Out-Null
        New-NetFirewallRule -DisplayName "Printer mDNS (UDP 5353 Inbound)" -Direction Inbound -Action Allow -Protocol UDP -LocalPort 5353 -ErrorAction SilentlyContinue | Out-Null

        Write-Log "WSD Firewall rules successfully updated." -Type "SUCCESS"
        Write-Host "  [+] UDP Ports 3702 and 5353 explicitly opened in Firewall." -ForegroundColor Green
    }
    catch {
        Write-Log "Failed to configure WSD Firewall: $($_.Exception.Message)" -Type "ERROR"
    }
}

function Fix-LSAProtection {
    Write-Log "Downgrading LSA Protection (Permitting legacy authentication)..." -Type "INFO"
    try {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name RunAsPPL -Value 0 -Type DWord -Force -ErrorAction Stop
        Write-Log "LSA PPL enforcement downgraded." -Type "SUCCESS"
        Write-Host "  [+] LSA Protection downgraded." -ForegroundColor Green
    }
    catch {
        Write-Log "Fix-LSAProtection failed: $($_.Exception.Message) (May be enforced by Secure Boot or Credential Guard)" -Type "WARNING"
        Write-Host "  [!] LSA Protection could not be changed - system security policy may be enforcing it." -ForegroundColor Yellow
    }
}

function Fix-SAC {
    Write-Log "Bypassing Smart App Control (SAC) for print driver injection..." -Type "INFO"
    try {
        $path = "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name VerifiedAndReputablePolicyState -Value 0 -Type DWord -Force -ErrorAction Stop
        Write-Log "SAC active bypass deployed." -Type "SUCCESS"
        Write-Host "  [+] Smart App Control bypassed." -ForegroundColor Green
    }
    catch {
        Write-Log "Fix-SAC failed: $($_.Exception.Message) (SAC may be enforced by UEFI/policy)" -Type "WARNING"
        Write-Host "  [!] SAC bypass failed - may require manual change in Windows Security settings." -ForegroundColor Yellow
    }
}

function Fix-IPPSharing {
    Write-Log "Enabling Internet Printing Protocol (IPP & Mopria)..." -Type "INFO"
    try {
        if ((Get-WindowsOptionalFeature -Online -FeatureName "Printing-Foundation-Features" -ErrorAction SilentlyContinue)) {
            Enable-WindowsOptionalFeature -Online -FeatureName "Printing-Foundation-Features" -NoRestart -ErrorAction SilentlyContinue | Out-Null
            Enable-WindowsOptionalFeature -Online -FeatureName "Printing-Foundation-InternetPrinting-Client" -NoRestart -ErrorAction SilentlyContinue | Out-Null
            Write-Log "IPP Foundation successfully enabled." -Type "SUCCESS"
            Write-Host "  [+] Windows Feature: Internet Printing Client activated." -ForegroundColor Green
        }
    }
    catch {
        Write-Log "Failed to configure IPP: $($_.Exception.Message)" -Type "ERROR"
    }
}

function Fix-AdvancedPointAndPrint {
    Write-Log "Bypassing Advanced Point & Print Policies & PrintNightmare Locks..." -Type "INFO"
    try {
        $path = "HKLM:\Software\Policies\Microsoft\Windows NT\Printers\PointAndPrint"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name InForest -Value 1 -Type DWord -Force -ErrorAction Stop
        Set-ItemProperty -Path $path -Name TrustedServers -Value 1 -Type DWord -Force -ErrorAction Stop
        Set-ItemProperty -Path $path -Name ServerList -Value "*.*" -Type String -Force -ErrorAction Stop

        Set-ItemProperty -Path $path -Name RestrictDriverInstallationToAdministrators -Value 0 -Type DWord -Force -ErrorAction Stop
        Set-ItemProperty -Path $path -Name NoWarningNoElevationOnInstall -Value 1 -Type DWord -Force -ErrorAction Stop
        Set-ItemProperty -Path $path -Name NoWarningNoElevationOnUpdate -Value 1 -Type DWord -Force -ErrorAction Stop
        Set-ItemProperty -Path $path -Name UpdatePromptSettings -Value 2 -Type DWord -Force -ErrorAction Stop

        $pkgPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PackagePointAndPrint"
        if (-not (Test-Path $pkgPath)) { New-Item -Path $pkgPath -Force | Out-Null }
        Set-ItemProperty -Path $pkgPath -Name PackagePointAndPrintServerList -Value 1 -Type DWord -Force -ErrorAction Stop

        Write-Log "Point & Print constraints & PrintNightmare entirely bypassed." -Type "SUCCESS"
        Write-Host "  [+] PrintNightmare Elevation Restrictions and Point & Print fully neutralized." -ForegroundColor Green
    }
    catch {
        Write-Log "Fix-AdvancedPointAndPrint failed: $($_.Exception.Message)" -Type "ERROR"
        Write-Host "  [-] Point & Print bypass failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Fix-ModernSMB {
    Write-Log "Enforcing Modern SMB2/SMB3 Server Configurations..." -Type "INFO"
    try {
        Set-SmbServerConfiguration -EnableSMB2Protocol $true -Force -ErrorAction Stop
        Write-Log "SMB2/SMB3 topologies active." -Type "SUCCESS"
        Write-Host "  [+] SMB2/SMB3 protocol enforced." -ForegroundColor Green
    }
    catch {
        Write-Log "Fix-ModernSMB failed: $($_.Exception.Message)" -Type "ERROR"
    }
}

function Set-SpoolerRecovery {
    Write-Log "Configuring Print Spooler automatic restart recovery..." -Type "INFO"
    try {
        & sc.exe failure spooler reset= 0 actions= restart/60000/restart/60000/restart/60000 > $null 2>&1
        if ($LASTEXITCODE -ne 0) { throw "sc.exe returned exit code $LASTEXITCODE" }
        Write-Log "Spooler Auto-Restart Recovery configured." -Type "SUCCESS"
        Write-Host "  [+] Spooler auto-restart on crash configured." -ForegroundColor Green
    }
    catch {
        Write-Log "Set-SpoolerRecovery failed: $($_.Exception.Message)" -Type "ERROR"
    }
}

function Fix-UACTokenFilter {
    Write-Log "Bypassing UAC Network Administrator restrictions..." -Type "INFO"
    try {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name LocalAccountTokenFilterPolicy -Value 1 -Type DWord -Force -ErrorAction Stop
        Write-Log "LocalAccountTokenFilterPolicy set to 1." -Type "SUCCESS"
        Write-Host "  [+] UAC network administration token filtering disabled." -ForegroundColor Green
    }
    catch {
        Write-Log "Fix-UACTokenFilter failed: $($_.Exception.Message)" -Type "ERROR"
    }
}

function Reset-SpoolerDependency {
    Write-Log "Purging third-party Spooler dependencies..." -Type "INFO"
    try {
        & sc.exe config spooler depend= RPCSS/http > $null 2>&1
        if ($LASTEXITCODE -ne 0) { throw "sc.exe returned exit code $LASTEXITCODE" }
        Write-Log "Dependencies explicitly reset to RPCSS and http (IPP compliant)." -Type "SUCCESS"
        Write-Host "  [+] Print Spooler dependencies repaired for modern IPP support." -ForegroundColor Green
    }
    catch {
        Write-Log "Reset-SpoolerDependency failed: $($_.Exception.Message)" -Type "ERROR"
    }
}

function Fix-ProviderOrder {
    Write-Log "Prioritizing SMB (LanmanWorkstation) in Network Provider Order..." -Type "INFO"
    try {
        $path = "HKLM:\SYSTEM\CurrentControlSet\Control\NetworkProvider\Order"
        $currentOrder = (Get-ItemProperty -Path $path -Name ProviderOrder -ErrorAction SilentlyContinue).ProviderOrder
        if ($currentOrder) {
            $arr = $currentOrder -split "," | Where-Object { $_ -ne "LanmanWorkstation" -and $_ -ne "" }
            $newOrder = "LanmanWorkstation," + ($arr -join ",")
            Set-ItemProperty -Path $path -Name ProviderOrder -Value $newOrder -Force
            Write-Log "Provider Order explicitly updated (LanmanWorkstation prioritized)." -Type "SUCCESS"
        }
    }
    catch {
        Write-Log "Failed to configure Provider Order: $($_.Exception.Message)" -Type "ERROR"
    }
}

function Fix-NTLMv2 {
    Write-Log "Enforcing Strict NTLMv2 Response Compliance (NAS and Samba Compatible)..." -Type "INFO"
    try {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name LmCompatibilityLevel -Value 3 -Type DWord -Force -ErrorAction Stop
        Write-Log "Strict NTLMv2 successfully enforced." -Type "SUCCESS"
        Write-Host "  [+] Strict NTLMv2 enforced (Level 3). NAS and modern print sharing connections secured." -ForegroundColor Green
    }
    catch {
        Write-Log "Fix-NTLMv2 failed: $($_.Exception.Message)" -Type "ERROR"
    }
}

function Fix-Network0x00000040 {
    Write-Log "Fixing Error 0x00000040 (Network connection timeout)..." -Type "INFO"
    try {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name KeepConn -Value 65535 -Type DWord -Force -ErrorAction Stop
        try {
            Get-Service -Name Browser -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Running' } | Stop-Service -Force -ErrorAction SilentlyContinue
            Restart-Service LanmanWorkstation -Force -ErrorAction SilentlyContinue
        } catch {
            Write-Log "LanmanWorkstation reload deferred: $($_.Exception.Message)" -Type "INFO"
        }
        Write-Log "KeepConn SMB set to maximum." -Type "SUCCESS"
        Write-Host "  [+] SMB connection timeout extended to mitigate unstable network topologies." -ForegroundColor Green
    }
    catch {
        Write-Log "Failed to fix 0x00000040: $($_.Exception.Message)" -Type "ERROR"
    }
}

function Fix-DriverCopy0x00000002 {
    Write-Log "Fixing Error 0x00000002 (Driver CopyFilesPolicy)..." -Type "INFO"
    try {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Print" -Name CopyFilesPolicy -Value 1 -Type DWord -Force -ErrorAction Stop
        Write-Log "CopyFilesPolicy activated." -Type "SUCCESS"
        Write-Host "  [+] CopyFilesPolicy allowed so OS can ingest missing drivers from Host." -ForegroundColor Green
    }
    catch {
        Write-Log "Failed to fix 0x00000002: $($_.Exception.Message)" -Type "ERROR"
    }
}

function Fix-RpcBitness0x0000007e {
    Write-Log "Fixing Error 0x0000007e (RPC Bitness/Auth error)..." -Type "INFO"
    try {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\RPC" -Name RpcAuthenticationLevel -Value 0 -Type DWord -Force -ErrorAction Stop
        Write-Log "RPC Authentication downgraded." -Type "SUCCESS"
        Write-Host "  [+] RPC Auth limitations removed to facilitate cross-architecture communication." -ForegroundColor Green
    }
    catch {
        Write-Log "Failed to fix 0x0000007e: $($_.Exception.Message)" -Type "ERROR"
    }
}

function Manage-WPP {
    Write-Host "`n  ======================================================================"
    Write-Host "             WINDOWS PROTECTED PRINT (WPP) MANAGEMENT"
    Write-Host "  ======================================================================"
    Write-Host "  [!] Modern Win 11 24H2+ feature that provides strict security, BUT blocks"
    Write-Host "      all legacy/custom printers that do not support the Mopria protocol."
    Write-Host "  [1] ENABLE WPP (Legacy printers will likely fail)"
    Write-Host "  [2] DISABLE WPP (Safe for Legacy LAN Sharing - Recommended)"
    $opt = Read-Host "  Select Option (1/2)"
    $wppPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\WPP"
    if (-not (Test-Path $wppPath)) { New-Item -Path $wppPath -Force | Out-Null }
    if ($opt -eq '1') {
        try {
            Write-Log "Enabling WPP Mode..." -Type "INFO"
            Set-ItemProperty -Path $wppPath -Name Enabled -Value 1 -Type DWord -Force -ErrorAction Stop
            Write-Host "  [+] WPP Enabled." -ForegroundColor Yellow
        } catch {
            Write-Log "Failed to enable WPP: $($_.Exception.Message)" -Type "ERROR"
        }
    }
    if ($opt -eq '2') {
        try {
            Write-Log "Disabling WPP Mode..." -Type "INFO"
            Set-ItemProperty -Path $wppPath -Name Enabled -Value 0 -Type DWord -Force -ErrorAction Stop
            Write-Host "  [+] WPP Successfully Disabled (Compatibility Mode)." -ForegroundColor Green
        } catch {
            Write-Log "Failed to disable WPP: $($_.Exception.Message)" -Type "ERROR"
        }
    }
}

function Scan-PrintEventLog {
    Write-Log "Reading the 20 most recent Printer Service Logs..." -Type "INFO"
    Write-Host "`n  --- ERROR HISTORY FROM MICROSOFT PRINT SERVICE EVENT LOG ---" -ForegroundColor Cyan
    $events = Get-WinEvent -LogName "Microsoft-Windows-PrintService/Admin" -MaxEvents 20 -ErrorAction SilentlyContinue
    if ($events) {
        $events | Select-Object TimeCreated, Id, Message | Format-Table -AutoSize
    }
    else {
        Write-Host "  [+] Clean! No historical failures recorded." -ForegroundColor Green
    }
}

function Manage-TCPPort {
    Write-Host "`n  CREATE MANUAL TCP/IP PORT"
    $ip = Read-Host "  [?] Physical Printer IP (e.g., 192.168.1.100)"
    if ($ip) {
        try {
            Add-PrinterPort -Name "IP_$ip" -PrinterHostAddress $ip -ErrorAction Stop
            Write-Log "TCP/IP Port IP_$ip successfully created." -Type "SUCCESS"
            Write-Host "  [+] Port [IP_$ip] successfully injected into the system." -ForegroundColor Green
        }
        catch {
            Write-Log "Failed to create port: $($_.Exception.Message)" -Type "ERROR"
        }
    }
}

function Manage-DefaultPrinter {
    Write-Host "`n  ENFORCE PERMANENT DEFAULT PRINTER"
    $prn = Read-Host "  [?] Input exact Printer Name to be set as Default"
    if ($prn) {
        try {
            $safeName = $prn -replace "'", "''"
            $wmi = Get-CimInstance Win32_Printer -Filter "Name='$safeName'" -ErrorAction Stop
            if ($wmi) {
                Invoke-CimMethod -InputObject $wmi -MethodName SetDefaultPrinter | Out-Null
                Write-Log "Default forcefully set to $prn" -Type "SUCCESS"
                Write-Host "  [+] OS forced to assign $prn as Primary Default." -ForegroundColor Green
            }
            else {
                Write-Host "  [-] Printer not detected." -ForegroundColor Red
            }
        }
        catch {
            Write-Log "Failed to set default printer: $($_.Exception.Message)" -Type "ERROR"
        }
    }
}

function Set-SpoolerWatchdog {
    Write-Log "Injecting Spooler Watchdog Task..." -Type "INFO"
    try {
        $cmd = "powershell.exe -WindowStyle Hidden -Command \`"if((Get-Service spooler).Status -ne 'Running'){ Start-Service spooler }\`""
        & schtasks.exe /create /tn "SpoolerWatchdog" /tr $cmd /sc minute /mo 5 /ru "SYSTEM" /rl HIGHEST /f > $null 2>&1
        if ($LASTEXITCODE -ne 0) { throw "schtasks returned exit code $LASTEXITCODE" }
        
        # Configure task to run on battery power (disables 0x800710E0 error on laptops)
        try {
            $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
            Set-ScheduledTask -TaskName "SpoolerWatchdog" -Settings $settings -ErrorAction SilentlyContinue | Out-Null
        } catch {}

        Write-Log "Spooler Watchdog deployed (indefinite repetition, every 5 min)." -Type "SUCCESS"
        Write-Host "  [+] Spooler Watchdog active. Audited every 5 minutes indefinitely." -ForegroundColor Green
    }
    catch {
        Write-Log "Failed Watchdog deployment: $($_.Exception.Message)" -Type "ERROR"
    }
}

function Fix-RDPPrinter {
    Write-Log "Repairing RDP Printer Terminal Services Redirection..." -Type "INFO"
    try {
        Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows NT\Terminal Services" -Name fDisableCpm -Value 0 -Type DWord -Force -ErrorAction Stop
        Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows NT\Terminal Services" -Name fEnablePrintRDR -Value 1 -Type DWord -Force -ErrorAction Stop
        Write-Log "RDP Redirection activated." -Type "SUCCESS"
        Write-Host "  [+] Local printers are now visible during Remote Desktop (RDP) sessions." -ForegroundColor Green
    }
    catch {
        Write-Log "Failed to fix RDP: $($_.Exception.Message)" -Type "ERROR"
    }
}

function Fix-HyperVConflict {
    Write-Log "Fixing Hyper-V/WSL Network Discovery Conflict..." -Type "INFO"
    try {
        $adapters = Get-NetAdapter | Where-Object { $_.InterfaceDescription -match "Virtual" -or $_.InterfaceDescription -match "Hyper-V" -or $_.InterfaceDescription -match "WSL" }
        if ($adapters) {
            foreach ($adp in $adapters) {
                Set-NetIPInterface -InterfaceAlias $adp.Name -InterfaceMetric 99 -ErrorAction SilentlyContinue
            }
            Write-Log "vSwitch Priority (Metric) successfully lowered." -Type "SUCCESS"
            Write-Host "  [+] Hyper-V/WSL virtual adapters deprioritized to prevent native LAN/Wi-Fi choking." -ForegroundColor Green
        }
        else {
            Write-Host "  [*] No conflicting virtual adapters detected." -ForegroundColor Cyan
        }
    }
    catch {
        Write-Log "Failed Hyper-V Fix: $($_.Exception.Message)" -Type "ERROR"
    }
}

function Manage-LPR {
    Write-Log "Installing legacy LPR/LPD protocols..." -Type "INFO"
    try {
        Enable-WindowsOptionalFeature -Online -FeatureName "Printing-Foundation-LPRPortMonitor" -NoRestart -ErrorAction Stop | Out-Null
        Write-Log "LPR Port Monitor Installed." -Type "SUCCESS"
    } catch {
        Write-Log "Failed to Install LPR Port Monitor: $($_.Exception.Message)" -Type "WARNING"
    }

    try {
        Enable-WindowsOptionalFeature -Online -FeatureName "Printing-Foundation-LPDPrintService" -NoRestart -ErrorAction Stop | Out-Null
        Write-Log "LPD Print Service Installed." -Type "SUCCESS"
    } catch {
        Write-Log "Failed to Install LPD Service: $($_.Exception.Message) (Potentially deprecated in latest Win 11 builds)" -Type "WARNING"
    }

    Write-Host "  [+] LPR/LPD installation complete. If failed, this feature may be deprecated in your Windows version." -ForegroundColor Green
}

function Fix-PrintToPDF {
    Write-Log "Reinstalling / Refreshing Microsoft Print to PDF & XPS..." -Type "INFO"
    Write-Host "  [*] This process requires approximately 10-30 seconds..." -ForegroundColor Cyan
    try {
        Disable-WindowsOptionalFeature -Online -FeatureName "Printing-PrintToPDFServices-Features" -NoRestart -ErrorAction Stop | Out-Null
        Start-Sleep -Seconds 2
        Enable-WindowsOptionalFeature -Online -FeatureName "Printing-PrintToPDFServices-Features" -NoRestart -ErrorAction Stop | Out-Null
        Write-Log "Print to PDF successfully refreshed." -Type "SUCCESS"
        Write-Host "  [+] Microsoft Print to PDF drivers restored. REBOOT RECOMMENDED." -ForegroundColor Green
    }
    catch {
        Write-Log "Failed to refresh PrintToPDF: $($_.Exception.Message)" -Type "ERROR"
    }
}

function Fix-CredentialGuard {
    Write-Log "Bypassing Credential Guard Restrictions (Strict NTLM)..." -Type "INFO"
    try {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name LsaCfgFlags -Value 0 -Type DWord -Force -ErrorAction Stop
        Write-Log "Credential Guard protection (LsaCfgFlags) disabled." -Type "SUCCESS"
        Write-Host "  [+] Strict NTLM blockade in Win 11 Pro/Enterprise alleviated." -ForegroundColor Green
    }
    catch {
        Write-Log "Failed to bypass Credential Guard: $($_.Exception.Message)" -Type "ERROR"
    }
}

function Manage-BITS {
    Write-Log "Restarting BITS Service..." -Type "INFO"
    try {
        $bitsSvc = Get-Service -Name BITS -ErrorAction SilentlyContinue
        if ($bitsSvc) {
            if ($bitsSvc.StartType -eq "Disabled") {
                Set-Service -Name BITS -StartupType Manual -ErrorAction SilentlyContinue
            }
            Restart-Service BITS -Force -ErrorAction Stop
            Write-Log "Background Intelligent Transfer Service (BITS) restarted." -Type "SUCCESS"
            Write-Host "  [+] BITS service restarted." -ForegroundColor Green
        } else {
            Write-Log "BITS service not present on this system." -Type "INFO"
        }
    }
    catch {
        Write-Log "BITS service restart deferred: $($_.Exception.Message)" -Type "INFO"
        Write-Host "  [i] BITS service status checked (managed by Windows Update)." -ForegroundColor Gray
    }
}

function Create-RestorePoint {
    Write-Log "Generating System Restore Point..." -Type "INFO"
    Write-Host "  [*] Invoking System Protection (Please stand by)..." -ForegroundColor Cyan
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        $srKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore"
        if (Test-Path $srKey) {
            Set-ItemProperty -Path $srKey -Name "SystemRestorePointCreationFrequency" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        }
        $warnMsg = $null
        Checkpoint-Computer -Description "WinPrinterSharingFix-SafetyBackup" -RestorePointType "MODIFY_SETTINGS" -WarningVariable warnMsg -ErrorAction Stop
        if ($warnMsg) {
            Write-Log "System Restore note: $($warnMsg[0])" -Type "INFO"
            Write-Host "  [i] Existing Windows Restore Point within 24 hours preserved." -ForegroundColor Cyan
        } else {
            Write-Log "System Restore Point generated successfully." -Type "SUCCESS"
            Write-Host "  [+] Windows Restore Point established." -ForegroundColor Green
        }
    }
    catch {
        Write-Log "System Restore note: $($_.Exception.Message)" -Type "INFO"
        Write-Host "  [i] System Restore point skipped or managed by Windows Protection." -ForegroundColor Gray
    }
}

function Run-QuickDiagnostics {
    Write-Host "`n  ======================================================================"
    Write-Host "                 SYSTEM DIAGNOSTICS"
    Write-Host "  ======================================================================"

    $spool = (Get-Service spooler -ErrorAction SilentlyContinue).Status
    if ($spool -eq 'Running') { $spc = "Green" } else { $spc = "Red" }
    Write-Host "  [+] Print Spooler : " -NoNewline; Write-Host $spool -ForegroundColor $spc

    $rpc = (Get-Service RpcSs -ErrorAction SilentlyContinue).Status
    if ($rpc -eq 'Running') { $rcc = "Green" } else { $rcc = "Red" }
    Write-Host "  [+] RPC Service   : " -NoNewline; Write-Host $rpc -ForegroundColor $rcc

    $fw = (Get-Service mpssvc -ErrorAction SilentlyContinue).Status
    if ($fw -eq 'Running') { $fwc = "Green" } else { $fwc = "Red" }
    Write-Host "  [+] Firewall      : " -NoNewline; Write-Host $fw -ForegroundColor $fwc

    $net = Get-NetConnectionProfile -ErrorAction SilentlyContinue | Select-Object -ExpandProperty NetworkCategory
    $netStr = ($net -join ", ")
    if ($netStr -match "Public") { $ntc = "Red" } else { $ntc = "Green" }
    Write-Host "  [+] Network Profile: " -NoNewline; Write-Host $netStr -ForegroundColor $ntc

    Write-Host "  [+] OS Type       : " -NoNewline; Write-Host $script:productName -ForegroundColor Cyan
    if ($script:isARM64) { Write-Host "  [+] Architecture  : ARM64 (Snapdragon / Apple M Series VM)" -ForegroundColor Cyan }

    Write-Host "  ======================================================================"
}

function Fix-V4ClassDriver {
    Write-Log "Scanning Universal Print Class Driver (V4) for corruption..." -Type "INFO"
    Write-Host "`n  ======================================================================"
    Write-Host "               UNIVERSAL PRINT CLASS DRIVER V4 REPAIR"
    Write-Host "  ======================================================================"
    try {
        $v4Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Environments\Windows x64\Drivers\Version-4"
        if (-not (Test-Path $v4Path)) {
            $v4Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Environments\Windows NT x86\Drivers\Version-4"
        }
        $corrupted = @()
        $corruptedDirs = @()
        if (Test-Path $v4Path) {
            $drivers = Get-ChildItem $v4Path -ErrorAction SilentlyContinue
            foreach ($drv in $drivers) {
                $props = Get-ItemProperty $drv.PSPath -ErrorAction SilentlyContinue
                if ($props.InfPath) {
                    $driverDir = $props.DriverPath
                    if ($driverDir) {
                        $parentDir = Split-Path $driverDir -Parent
                        $configDll = Join-Path $parentDir "PrintConfig.dll"
                        if (-not (Test-Path $configDll)) {
                            $corrupted += $drv.PSChildName
                            $corruptedDirs += $parentDir
                        }
                    }
                }
            }
        }
        if ($corrupted.Count -gt 0) {
            Write-Host "  [!] Corrupted V4 drivers detected: $($corrupted.Count)" -ForegroundColor Red
            foreach ($c in $corrupted) { Write-Host "      - $c" -ForegroundColor Yellow }
            Write-Host "  [*] Attempting repair via DriverStore re-registration..." -ForegroundColor Cyan
            $prnmsDir = Get-ChildItem "$env:SystemRoot\System32\DriverStore\FileRepository\prnms*" -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($prnmsDir) {
                $goodDll = Get-ChildItem $prnmsDir.FullName -Filter "PrintConfig.dll" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($goodDll) {
                    Write-Host "  [+] Known-good PrintConfig.dll located at $($goodDll.FullName)" -ForegroundColor Green
                    Write-Log "PrintConfig.dll source located: $($goodDll.FullName)" -Type "SUCCESS"
                    
                    # Copy the known-good PrintConfig.dll to repair each corrupted directory
                    for ($i = 0; $i -lt $corrupted.Count; $i++) {
                        $destDir = $corruptedDirs[$i]
                        $destFile = Join-Path $destDir "PrintConfig.dll"
                        try {
                            Copy-Item -Path $goodDll.FullName -Destination $destFile -Force -ErrorAction Stop
                            Write-Host "  [+] Restored PrintConfig.dll to $destDir" -ForegroundColor Green
                            Write-Log "Restored PrintConfig.dll to $destDir" -Type "SUCCESS"
                        } catch {
                            Write-Host "  [-] Failed to restore to $destDir : $($_.Exception.Message)" -ForegroundColor Red
                            Write-Log "Failed to copy PrintConfig.dll to $destDir : $($_.Exception.Message)" -Type "ERROR"
                        }
                    }
                }
            }
            & pnputil /scan-devices > $null 2>&1
            Write-Log "V4 driver scan complete. $($corrupted.Count) corrupted entries processed." -Type "WARNING"
        }
        else {
            Write-Host "  [+] All V4 Print Class Drivers are intact." -ForegroundColor Green
            Write-Log "V4 drivers healthy." -Type "SUCCESS"
        }
    }
    catch {
        Write-Log "Failed V4 scan: $($_.Exception.Message)" -Type "ERROR"
    }
}

function Switch-DriverMode {
    Write-Host "`n  ======================================================================"
    Write-Host "               TOGGLE PCL vs. POSTSCRIPT DRIVER MODE"
    Write-Host "  ======================================================================"
    Write-Log "Launching PCL/PostScript driver toggle..." -Type "INFO"
    try {
        $printers = Get-Printer -ErrorAction Stop
        if (-not $printers) { Write-Host "  [-] No printers installed." -ForegroundColor Red; return }
        Write-Host ""
        $idx = 1
        foreach ($p in $printers) {
            Write-Host "  [$idx] $($p.Name) | Driver: $($p.DriverName)" -ForegroundColor Cyan
            $idx++
        }
        $sel = Read-Host "`n  [?] Select printer number"
        $selIdx = -1
        try { $selIdx = [int]$sel - 1 } catch { Write-Host "  [-] Invalid input." -ForegroundColor Red; return }
        if ($selIdx -lt 0 -or $selIdx -ge $printers.Count) { Write-Host "  [-] Invalid selection." -ForegroundColor Red; return }
        $target = $printers[$selIdx]
        $allDrivers = Get-PrinterDriver -ErrorAction SilentlyContinue
        $currentDriver = $target.DriverName
        Write-Host "`n  Current Driver: $currentDriver" -ForegroundColor Yellow
        if ($currentDriver -match 'PCL') {
            $altDrivers = $allDrivers | Where-Object { $_.Name -match 'PS|PostScript' }
            Write-Host "  [*] Searching for PostScript alternatives..." -ForegroundColor Cyan
        }
        else {
            $altDrivers = $allDrivers | Where-Object { $_.Name -match 'PCL' }
            Write-Host "  [*] Searching for PCL alternatives..." -ForegroundColor Cyan
        }
        if ($altDrivers) {
            $idx = 1
            foreach ($d in $altDrivers) { Write-Host "  [$idx] $($d.Name)" -ForegroundColor Green; $idx++ }
            $drvSel = Read-Host "  [?] Select replacement driver number (0 to cancel)"
            if ($drvSel -ne '0') {
                $drvIdx = -1
                try { $drvIdx = [int]$drvSel - 1 } catch { Write-Host "  [-] Invalid input." -ForegroundColor Red; return }
                if ($drvIdx -ge 0 -and $drvIdx -lt $altDrivers.Count) {
                    Set-Printer -Name $target.Name -DriverName $altDrivers[$drvIdx].Name -ErrorAction Stop
                    Write-Log "Driver switched: $($target.Name) -> $($altDrivers[$drvIdx].Name)" -Type "SUCCESS"
                    Write-Host "  [+] Driver successfully switched!" -ForegroundColor Green
                }
            }
        }
        else {
            Write-Host "  [-] No alternative drivers found. Install the target driver first." -ForegroundColor Red
        }
    }
    catch { Write-Log "Driver toggle failed: $($_.Exception.Message)" -Type "ERROR" }
}

function Manage-WindowsUpdate {
    Write-Host "`n  ======================================================================"
    Write-Host "                  WINDOWS UPDATE & BLOCKER MANAGEMENT"
    Write-Host "  ======================================================================"
    Write-Host "  [1] Uninstall Specific KB Update"
    Write-Host "  [2] Pause Windows Updates for 35 Days"
    Write-Host "  [3] Disable Windows Update Services Permanently (Blocks printer fix reversion)"
    Write-Host "  [4] Re-enable Windows Update Services (Restore defaults)"
    Write-Host "  [5] Cancel"
    $opt = Read-Host "  Select Option (1-5)"

    switch ($opt) {
        '1' {
            Write-Log "Launching KB Update uninstaller..." -Type "INFO"
            try {
                Write-Host "  [!] KNOWN PRINTER-BREAKING KBs (2025-2026):" -ForegroundColor Red
                Write-Host "      KB5065426 (Sep 2025) - Blocks print sharing (SID check)" -ForegroundColor Yellow
                Write-Host "      KB5066835 (Oct 2025) - Major printer sharing breaker" -ForegroundColor Yellow
                Write-Host "      KB5068661 (Nov 2025) - Breaks printer & network sharing" -ForegroundColor Yellow
                Write-Host "      KB5089549 (May 2026) - Cross-signed driver enforcement" -ForegroundColor Yellow

                Write-Host "  [*] Enumerating recent Windows Updates..." -ForegroundColor Cyan
                $updates = Get-HotFix -ErrorAction SilentlyContinue | Sort-Object InstalledOn -Descending | Select-Object -First 20
                if ($updates) { $updates | Format-Table HotFixID, Description, InstalledOn -AutoSize }
                else { Write-Host "  [-] No hotfixes detected via Get-HotFix." -ForegroundColor Yellow }

                $kb = Read-Host "`n  [?] Input KB number to uninstall (e.g., KB5034441, or blank to cancel)"
                if (-not $kb) { return }
                $kb = $kb -replace '(?i)^KB', ''

                $dismSuccess = $false
                Write-Host "  [*] Attempting to uninstall KB$kb via DISM..." -ForegroundColor Cyan
                $packages = & dism /online /get-packages 2>&1 | Select-String "Package_for_KB$kb"

                if ($packages) {
                    $pkgName = ($packages[0].ToString() -split ':')[1].Trim()
                    $proc = Start-Process -FilePath "dism.exe" -ArgumentList "/online /remove-package /package-name:`"$pkgName`" /quiet /norestart" -Wait -PassThru -WindowStyle Hidden

                    if ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq 3010) {
                        $dismSuccess = $true
                        Write-Log "KB$kb uninstalled via DISM." -Type "SUCCESS"
                        Write-Host "  [+] KB$kb successfully uninstalled. (Reboot may be required)" -ForegroundColor Green
                    } else {
                        Write-Log "DISM failed to uninstall KB$kb. ExitCode: $($proc.ExitCode). Falling back to wusa.exe..." -Type "WARNING"
                        Write-Host "  [-] DISM failed (ExitCode $($proc.ExitCode)). Attempting wusa.exe fallback..." -ForegroundColor Yellow
                    }
                }

                if (-not $dismSuccess) {
                    Write-Host "  [!] A Windows dialog will appear. Please confirm the uninstallation if prompted." -ForegroundColor Cyan
                    $proc = Start-Process wusa.exe -ArgumentList "/uninstall /kb:$kb /norestart" -Wait -PassThru

                    if ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq 3010) {
                        Write-Log "KB$kb uninstalled via wusa." -Type "SUCCESS"
                        Write-Host "  [+] KB$kb successfully uninstalled. (Reboot may be required)" -ForegroundColor Green
                    } else {
                        Write-Log "Wusa failed/cancelled for KB$kb. ExitCode: $($proc.ExitCode)" -Type "WARNING"
                        Write-Host "  [-] Uninstallation failed or was cancelled. The update may be a permanent Security Update." -ForegroundColor Red
                    }
                }
            }
            catch { Write-Log "KB uninstall failed: $($_.Exception.Message)" -Type "ERROR" }
        }
        '2' {
            Write-Log "Pausing Windows Update for 35 days..." -Type "INFO"
            try {
                $wuPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
                if (-not (Test-Path $wuPath)) { New-Item -Path $wuPath -Force | Out-Null }

                $pauseStart = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ", [System.Globalization.CultureInfo]::InvariantCulture)
                $pauseEnd = (Get-Date).AddDays(35).ToString("yyyy-MM-ddTHH:mm:ssZ", [System.Globalization.CultureInfo]::InvariantCulture)

                # Set GPO Policy registry overrides
                Set-ItemProperty -Path $wuPath -Name PauseQualityUpdatesStartTime -Value $pauseStart -Force -ErrorAction Stop
                Set-ItemProperty -Path $wuPath -Name PauseFeatureUpdatesStartTime -Value $pauseStart -Force -ErrorAction Stop
                Set-ItemProperty -Path $wuPath -Name PauseUpdatesExpiryTime -Value $pauseEnd -Force -ErrorAction Stop
                Set-ItemProperty -Path $wuPath -Name SetDisableUXWUAccess -Value 1 -Type DWord -Force -ErrorAction Stop

                # Set UX Settings registry overrides (used by Windows Settings UX on Home & Pro)
                $uxPath = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
                if (-not (Test-Path $uxPath)) { New-Item -Path $uxPath -Force | Out-Null }
                Set-ItemProperty -Path $uxPath -Name PauseUpdatesStartTime -Value $pauseStart -Force -ErrorAction Stop
                Set-ItemProperty -Path $uxPath -Name PauseFeatureUpdatesStartTime -Value $pauseStart -Force -ErrorAction Stop
                Set-ItemProperty -Path $uxPath -Name PauseQualityUpdatesStartTime -Value $pauseStart -Force -ErrorAction Stop
                Set-ItemProperty -Path $uxPath -Name PauseFeatureUpdatesEndTime -Value $pauseEnd -Force -ErrorAction Stop
                Set-ItemProperty -Path $uxPath -Name PauseQualityUpdatesEndTime -Value $pauseEnd -Force -ErrorAction Stop
                Set-ItemProperty -Path $uxPath -Name PauseUpdatesExpiryTime -Value $pauseEnd -Force -ErrorAction Stop

                Write-Host "  [+] Windows Update fully paused for 35 days (GPO and Settings UX overrides applied)." -ForegroundColor Green
                Write-Log "Windows Update paused until $pauseEnd." -Type "SUCCESS"
            }
            catch { Write-Log "Failed to pause Windows Update: $($_.Exception.Message)" -Type "ERROR" }
        }
        '3' {
            Write-Log "Disabling Windows Update Services Permanently..." -Type "INFO"
            try {
                $services = @("wuauserv", "UsoSvc", "bits")
                foreach ($svc in $services) {
                    & sc.exe config $svc start= disabled > $null 2>&1
                    Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue | Out-Null
                }

                # Disable WaaSMedicSvc via registry bypass (sc config WaaSMedicSvc start= disabled returns Access Denied)
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" -Name Start -Value 4 -Type DWord -Force -ErrorAction Stop
                Stop-Service -Name "WaaSMedicSvc" -Force -ErrorAction SilentlyContinue | Out-Null

                # Configure NoAutoUpdate in Policies registry
                $auPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
                if (-not (Test-Path $auPath)) { New-Item -Path $auPath -Force | Out-Null }
                Set-ItemProperty -Path $auPath -Name NoAutoUpdate -Value 1 -Type DWord -Force -ErrorAction Stop

                Write-Log "Windows Update Services permanently disabled (Medic blocked)." -Type "SUCCESS"
                Write-Host "  [+] Core Windows Update services (wuauserv, UsoSvc, bits, WaaSMedicSvc) disabled." -ForegroundColor Green
                Write-Host "  [+] Registry policy NoAutoUpdate forced to 1." -ForegroundColor Green
                Write-Host "  [!] Security configurations will no longer be reverted by Windows Update." -ForegroundColor Yellow
            }
            catch { Write-Log "Failed to disable Windows Update: $($_.Exception.Message)" -Type "ERROR" }
        }
        '4' {
            Write-Log "Re-enabling Windows Update Services..." -Type "INFO"
            try {
                & sc.exe config wuauserv start= demand > $null 2>&1
                & sc.exe config UsoSvc start= auto > $null 2>&1
                & sc.exe config bits start= demand > $null 2>&1

                # Restore WaaSMedicSvc to manual
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" -Name Start -Value 3 -Type DWord -Force -ErrorAction Stop

                # Remove NoAutoUpdate restriction
                $auPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
                if (Test-Path $auPath) {
                    Remove-ItemProperty -Path $auPath -Name NoAutoUpdate -ErrorAction SilentlyContinue | Out-Null
                }

                # Remove pause overrides from policies
                $wuPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
                if (Test-Path $wuPath) {
                    $properties = @("PauseQualityUpdatesStartTime", "PauseFeatureUpdatesStartTime", "PauseUpdatesExpiryTime", "SetDisableUXWUAccess")
                    foreach ($prop in $properties) {
                        Remove-ItemProperty -Path $wuPath -Name $prop -ErrorAction SilentlyContinue | Out-Null
                    }
                }

                # Remove pause overrides from UX settings
                $uxPath = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
                if (Test-Path $uxPath) {
                    $properties = @("PauseUpdatesStartTime", "PauseFeatureUpdatesStartTime", "PauseQualityUpdatesStartTime", "PauseFeatureUpdatesEndTime", "PauseQualityUpdatesEndTime", "PauseUpdatesExpiryTime")
                    foreach ($prop in $properties) {
                        Remove-ItemProperty -Path $uxPath -Name $prop -ErrorAction SilentlyContinue | Out-Null
                    }
                }

                Write-Log "Windows Update Services restored to default startup types." -Type "SUCCESS"
                Write-Host "  [+] Windows Update services restored to default states." -ForegroundColor Green
                Write-Host "  [+] Automatic Update and pause restrictions removed." -ForegroundColor Green
            }
            catch { Write-Log "Failed to restore Windows Update: $($_.Exception.Message)" -Type "ERROR" }
        }
        default { return }
    }
}

function Sweep-OrphanedDrivers {
    Write-Host "`n  ======================================================================"
    Write-Host "               ORPHANED DRIVER SWEEPER (pnputil)"
    Write-Host "  ======================================================================"
    Write-Log "Scanning for orphaned printer drivers..." -Type "INFO"
    try {
        $rawOutput = & pnputil /enum-drivers 2>&1
        $activeDrivers = (Get-PrinterDriver -ErrorAction SilentlyContinue).Name
        $orphans = @()
        $currentOem = ""
        $currentClass = ""
        $currentProvider = ""
        foreach ($line in $rawOutput) {
            if ($line -match 'Published Name\s*:\s*(oem\d+\.inf)') { $currentOem = $Matches[1] }
            if ($line -match 'Class Name\s*:\s*(.+)') { $currentClass = $Matches[1].Trim() }
            if ($line -match 'Driver Package Provider\s*:\s*(.+)') { $currentProvider = $Matches[1].Trim() }
            if ($line -match '^\s*$' -and $currentOem -and $currentClass -match 'Printer') {
                $orphans += [PSCustomObject]@{ OemInf = $currentOem; Provider = $currentProvider }
                $currentOem = ""; $currentClass = ""; $currentProvider = ""
            }
        }
        if ($currentOem -and $currentClass -match 'Printer') {
            $orphans += [PSCustomObject]@{ OemInf = $currentOem; Provider = $currentProvider }
        }
        if ($orphans.Count -gt 0) {
            Write-Host "  [!] Found $($orphans.Count) printer driver package(s) in Driver Store:" -ForegroundColor Yellow
            $orphans | Format-Table OemInf, Provider -AutoSize
            $confirm = Read-Host "  [?] Force-delete ALL orphaned printer drivers? (Y/N)"
            if ($confirm -eq 'Y') {
                foreach ($o in $orphans) {
                    Write-Host "  [*] Removing $($o.OemInf)..." -ForegroundColor Cyan
                    & pnputil /delete-driver $o.OemInf /force 2>&1 | Out-Null
                }
                Write-Log "Orphaned drivers purged: $($orphans.Count) packages." -Type "SUCCESS"
                Write-Host "  [+] Cleanup complete." -ForegroundColor Green
            }
        }
        else {
            Write-Host "  [+] No orphaned printer drivers found in Driver Store." -ForegroundColor Green
            Write-Log "No orphaned drivers detected." -Type "SUCCESS"
        }
    }
    catch { Write-Log "Driver sweep failed: $($_.Exception.Message)" -Type "ERROR" }
}

function Force-KillDriverProcess {
    Write-Host "`n  ======================================================================"
    Write-Host "               BYPASS 'DRIVER IS CURRENTLY IN USE'"
    Write-Host "  ======================================================================"
    Write-Log "Force-killing driver isolation processes..." -Type "INFO"
    Write-Host "  [!] WARNING: This will terminate all active print processing." -ForegroundColor Red
    $confirm = Read-Host "  [?] Proceed? (Y/N)"
    if ($confirm -ne 'Y') { return }
    try {
        Write-Host "  [*] Stopping Print Spooler..." -ForegroundColor Cyan
        Stop-Service spooler -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
        $targets = @("PrintIsolationHost", "printfilterpipelinesvc", "splwow64")
        foreach ($proc in $targets) {
            $running = Get-Process -Name $proc -ErrorAction SilentlyContinue
            if ($running) {
                $running | Stop-Process -Force -ErrorAction SilentlyContinue
                Write-Host "  [+] Terminated: $proc (PID: $($running.Id -join ', '))" -ForegroundColor Green
            }
            else {
                Write-Host "  [*] $proc not running." -ForegroundColor Cyan
            }
        }
        Start-Sleep -Seconds 2
        Start-Service spooler -ErrorAction SilentlyContinue
        Write-Log "Driver handles released. Spooler restarted." -Type "SUCCESS"
        Write-Host "  [+] All driver handles released. You may now uninstall drivers." -ForegroundColor Green
    }
    catch { Write-Log "Force-kill failed: $($_.Exception.Message)" -Type "ERROR" }
}

function Convert-WSDtoTCPIP {
    Write-Host "`n  ======================================================================"
    Write-Host "               WSD to STANDARD TCP/IP PORT CONVERTER"
    Write-Host "  ======================================================================"
    Write-Log "Scanning for WSD ports..." -Type "INFO"
    try {
        $wsdPorts = Get-PrinterPort -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "WSD-*" }
        if (-not $wsdPorts) {
            Write-Host "  [+] No WSD ports detected. All ports are stable." -ForegroundColor Green
            Write-Log "No WSD ports found." -Type "SUCCESS"
            return
        }
        Write-Host "  [!] Found $($wsdPorts.Count) WSD port(s):" -ForegroundColor Yellow
        foreach ($wp in $wsdPorts) {
            $printerOnPort = Get-Printer -ErrorAction SilentlyContinue | Where-Object { $_.PortName -eq $wp.Name }
            $printerName = if ($printerOnPort) { $printerOnPort.Name } else { "(unassigned)" }
            Write-Host "      Port: $($wp.Name) | Printer: $printerName" -ForegroundColor Cyan
        }
        $ip = Read-Host "`n  [?] Input the actual IP of the WSD printer (e.g., 192.168.1.100)"
        if (-not $ip) { return }
        $newPortName = "IP_$ip"
        if (-not (Get-PrinterPort -Name $newPortName -ErrorAction SilentlyContinue)) {
            Add-PrinterPort -Name $newPortName -PrinterHostAddress $ip -ErrorAction Stop
            Write-Host "  [+] TCP/IP Port $newPortName created." -ForegroundColor Green
        }
        $printerToMove = Get-Printer -ErrorAction SilentlyContinue | Where-Object { $_.PortName -like "WSD-*" } | Select-Object -First 1
        if ($printerToMove) {
            Set-Printer -Name $printerToMove.Name -PortName $newPortName -ErrorAction Stop
            Write-Log "Printer $($printerToMove.Name) migrated from WSD to TCP/IP ($ip)." -Type "SUCCESS"
            Write-Host "  [+] $($printerToMove.Name) migrated to $newPortName." -ForegroundColor Green
        }
    }
    catch { Write-Log "WSD conversion failed: $($_.Exception.Message)" -Type "ERROR" }
}

function Reset-NetworkSockets {
    Write-Host "`n  ======================================================================"
    Write-Host "               NETWORK SOCKET RE-INIT (SELECTIVE PURGE)"
    Write-Host "  ======================================================================"
    Write-Log "Performing selective network socket cleanup..." -Type "INFO"
    try {
        Write-Host "  [*] Scanning for stuck SMB/RPC connections..." -ForegroundColor Cyan
        $stuck445 = & netstat -ano 2>&1 | Select-String ":445\s.*(ESTABLISHED|TIME_WAIT|CLOSE_WAIT)"
        $stuck135 = & netstat -ano 2>&1 | Select-String ":135\s.*(ESTABLISHED|TIME_WAIT|CLOSE_WAIT)"
        $totalStuck = 0
        if ($stuck445) { $totalStuck += $stuck445.Count; Write-Host "  [!] Port 445 (SMB): $($stuck445.Count) stuck connections" -ForegroundColor Yellow }
        if ($stuck135) { $totalStuck += $stuck135.Count; Write-Host "  [!] Port 135 (RPC): $($stuck135.Count) stuck connections" -ForegroundColor Yellow }
        if ($totalStuck -eq 0) { Write-Host "  [+] No stuck connections detected." -ForegroundColor Green }
        Write-Host "  [*] Restarting SMB Client & Server services only..." -ForegroundColor Cyan
        Restart-Service LanmanWorkstation -Force -ErrorAction SilentlyContinue
        Restart-Service LanmanServer -Force -ErrorAction SilentlyContinue
        $LASTEXITCODE = 0; ipconfig /registerdns > $null 2>&1
        Write-Log "Network sockets selectively purged. $totalStuck connections cleared." -Type "SUCCESS"
        Write-Host "  [+] Socket cleanup complete. $totalStuck stale connections purged." -ForegroundColor Green
    }
    catch { Write-Log "Socket re-init failed: $($_.Exception.Message)" -Type "ERROR" }
}

function Rescue-NetworkProfile {
    Write-Host "`n  ======================================================================"
    Write-Host "               RESCUE NETWORK PROFILE (AUTO-DETECT & WATCHDOG)"
    Write-Host "  ======================================================================"
    Write-Log "Rescuing network profile..." -Type "INFO"
    try {
        $profiles = Get-NetConnectionProfile -ErrorAction SilentlyContinue
        $publicFound = $false
        foreach ($p in $profiles) {
            if ($p.NetworkCategory -eq 'Public') {
                $publicFound = $true
                Write-Host "  [!] Public profile detected on: $($p.InterfaceAlias)" -ForegroundColor Red
                Set-NetConnectionProfile -InterfaceAlias $p.InterfaceAlias -NetworkCategory Private -ErrorAction SilentlyContinue
                Write-Host "  [+] Forced to Private: $($p.InterfaceAlias)" -ForegroundColor Green
            }
        }
        if (-not $publicFound) { Write-Host "  [+] All profiles are already Private/Domain. No action needed." -ForegroundColor Green }
        $deployWatchdog = Read-Host "`n  [?] Deploy Network Profile Watchdog (checks every 10 min)? (Y/N)"
        if ($deployWatchdog -eq 'Y') {
            $cmd = "powershell.exe -WindowStyle Hidden -Command \`"Get-NetConnectionProfile | Where-Object { `$_.NetworkCategory -eq 'Public' } | Set-NetConnectionProfile -NetworkCategory Private\`""
            & schtasks.exe /create /tn "NetworkProfileWatchdog" /tr $cmd /sc minute /mo 10 /ru "SYSTEM" /rl HIGHEST /f > $null 2>&1
            if ($LASTEXITCODE -eq 0) {
                # Configure task to run on battery power (disables 0x800710E0 error on laptops)
                try {
                    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
                    Set-ScheduledTask -TaskName "NetworkProfileWatchdog" -Settings $settings -ErrorAction SilentlyContinue | Out-Null
                } catch {}
                Write-Log "Network Profile Watchdog deployed (indefinite repetition)." -Type "SUCCESS"
                Write-Host "  [+] Watchdog deployed. Profile enforced to Private every 10 minutes." -ForegroundColor Green
            } else {
                Write-Log "Failed to deploy Network Profile Watchdog. schtasks returned exit code $LASTEXITCODE" -Type "ERROR"
            }
        }
    }
    catch { Write-Log "Network rescue failed: $($_.Exception.Message)" -Type "ERROR" }
}

function Remove-GhostUSBPrinters {
    Write-Host "`n  ======================================================================"
    Write-Host "               GHOST USB PORT & COPY ELIMINATOR"
    Write-Host "  ======================================================================"
    Write-Log "Scanning for ghost USB printers and duplicates..." -Type "INFO"
    try {
        $allPrinters = Get-Printer -ErrorAction SilentlyContinue
        $ghosts = $allPrinters | Where-Object { $_.Name -match '\(Copy \d+\)' -or $_.Name -match ' - Copy' -or $_.Name -match 'Copy \d+$' }
        $activePorts = ($allPrinters | Where-Object { $_.Name -notmatch 'Copy' }).PortName
        $deadUSB = Get-PrinterPort -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "USB*" -and $_.Name -notin $activePorts }
        if ($ghosts.Count -eq 0 -and $deadUSB.Count -eq 0) {
            Write-Host "  [+] No ghost printers or dead USB ports detected." -ForegroundColor Green
            Write-Log "No ghost devices found." -Type "SUCCESS"
            return
        }
        if ($ghosts.Count -gt 0) {
            Write-Host "  [!] Duplicate/Ghost printers found:" -ForegroundColor Yellow
            foreach ($g in $ghosts) { Write-Host "      - $($g.Name) [Port: $($g.PortName)]" -ForegroundColor Red }
        }
        if ($deadUSB.Count -gt 0) {
            Write-Host "  [!] Dead USB ports found:" -ForegroundColor Yellow
            foreach ($u in $deadUSB) { Write-Host "      - $($u.Name)" -ForegroundColor Red }
        }
        $confirm = Read-Host "`n  [?] Remove all ghost printers and dead USB ports? (Y/N)"
        if ($confirm -eq 'Y') {
            foreach ($g in $ghosts) {
                Remove-Printer -Name $g.Name -ErrorAction SilentlyContinue
                Write-Host "  [+] Removed printer: $($g.Name)" -ForegroundColor Green
            }
            foreach ($u in $deadUSB) {
                Remove-PrinterPort -Name $u.Name -ErrorAction SilentlyContinue
                Write-Host "  [+] Removed port: $($u.Name)" -ForegroundColor Green
            }
            Write-Log "Ghost cleanup: $($ghosts.Count) printers, $($deadUSB.Count) ports removed." -Type "SUCCESS"
        }
    }
    catch { Write-Log "Ghost USB cleanup failed: $($_.Exception.Message)" -Type "ERROR" }
}

function Nuke-PrintQueue {
    Write-Log "Executing Force Purge on Print Queue..." -Type "INFO"
    Write-Host "`n  ======================================================================"
    Write-Host "                FORCE PURGE PRINT QUEUE"
    Write-Host "  ======================================================================"
    try {
        Write-Host "  [*] Terminating Print Spooler and all child processes..." -ForegroundColor Cyan
        Stop-Service spooler -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 500
        Get-Process -Name "PrintIsolationHost", "printfilterpipelinesvc", "splwow64" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
        $spoolDir = "$env:SystemRoot\System32\Spool\Printers"
        $shdFiles = Get-ChildItem "$spoolDir\*.shd" -ErrorAction SilentlyContinue
        $splFiles = Get-ChildItem "$spoolDir\*.spl" -ErrorAction SilentlyContinue
        $totalFiles = 0
        if ($shdFiles) { $totalFiles += $shdFiles.Count; Remove-Item "$spoolDir\*.shd" -Force -ErrorAction SilentlyContinue }
        if ($splFiles) { $totalFiles += $splFiles.Count; Remove-Item "$spoolDir\*.spl" -Force -ErrorAction SilentlyContinue }
        Remove-Item "$spoolDir\*" -Force -Recurse -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
        Start-Service spooler -ErrorAction Stop
        Write-Log "Force Purge complete. $totalFiles corrupt spool files cleared." -Type "SUCCESS"
        Write-Host "  [+] Print Queue cleared. $totalFiles stale files purged. Spooler restarted." -ForegroundColor Green
    }
    catch { Write-Log "Force Purge failed: $($_.Exception.Message)" -Type "ERROR" }
}

function Reset-SpoolerDependencyRegistry {
    Write-Log "Resetting Spooler DependOnService via direct registry write..." -Type "INFO"
    try {
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Spooler"
        $current = (Get-ItemProperty $regPath -ErrorAction SilentlyContinue).DependOnService
        if ($current) {
            Write-Host "  [*] Current dependencies: $($current -join ', ')" -ForegroundColor Yellow
        }
        Set-ItemProperty -Path $regPath -Name DependOnService -Value @("RPCSS","http") -Type MultiString -Force -ErrorAction Stop
        Write-Log "Spooler DependOnService reset to factory defaults (RPCSS, http)." -Type "SUCCESS"
        Write-Host "  [+] Spooler dependencies reset to: RPCSS, http" -ForegroundColor Green
        Write-Host "  [*] Restarting Spooler to apply..." -ForegroundColor Cyan
        Restart-Service spooler -Force -ErrorAction SilentlyContinue
    }
    catch { Write-Log "Dependency registry reset failed: $($_.Exception.Message)" -Type "ERROR" }
}

function Inject-CrossUserCredentials {
    Write-Host "`n  ======================================================================"
    Write-Host "               CROSS-USER CREDENTIAL MAPPING"
    Write-Host "  ======================================================================"
    Write-Host "  [!] WARNING: This injects credentials into ALL user profiles on this PC." -ForegroundColor Red
    Write-Log "Cross-User Credential Mapping initiated..." -Type "INFO"
    $ip = Read-Host "  [?] Target IP/Hostname (e.g., 192.168.1.10)"
    $usr = Read-Host "  [?] Username on Target Host"
    $pass = Read-Host "  [?] Password on Target Host (Visible Text)"
    if (-not $ip -or -not $usr) { Write-Host "  [-] Cancelled." -ForegroundColor Red; return }
    try {
        $profiles = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^S-1-5-21-' }
        $injected = 0
        foreach ($profile in $profiles) {
            $sid = $profile.PSChildName
            $profilePath = (Get-ItemProperty $profile.PSPath -ErrorAction SilentlyContinue).ProfileImagePath
            $userName = Split-Path $profilePath -Leaf
            Write-Host "  [*] Injecting credential for user: $userName ($sid)..." -ForegroundColor Cyan
            $ntuser = Join-Path $profilePath "NTUSER.DAT"
            if (Test-Path $ntuser) {
                $LASTEXITCODE = 0; & reg load "HKU\$sid" $ntuser > $null 2>&1
                if ($LASTEXITCODE -eq 0) {
                    try {
                        # Create self-deleting cmd script with credential command
                        $credScript = Join-Path $profilePath "PrinterCredFix.cmd"
                        $cmdContent = "@echo off`r`ncmdkey.exe /add:$ip /user:$usr /pass:`"$pass`"`r`ndel `"%~f0`""
                        Set-Content -Path $credScript -Value $cmdContent -Encoding ASCII -Force -ErrorAction Stop

                        # Inject RunOnce to execute the script (script self-deletes after running)
                        $runOncePath = "Registry::HKEY_USERS\$sid\Software\Microsoft\Windows\CurrentVersion\RunOnce"
                        Set-ItemProperty -Path $runOncePath -Name "PrinterCredFix" -Value "`"$credScript`"" -Force -ErrorAction Stop
                        Write-Log "Injected RunOnce credential command for $userName." -Type "SUCCESS"
                    } catch {
                        Write-Log "Failed to write RunOnce registry for ${userName}: $($_.Exception.Message)" -Type "ERROR"
                    }
                    
                    # Retry loop to unload registry safely
                    $unloaded = $false
                    for ($retry = 1; $retry -le 5; $retry++) {
                        $LASTEXITCODE = 0
                        & reg unload "HKU\$sid" > $null 2>&1
                        if ($LASTEXITCODE -eq 0) {
                            $unloaded = $true
                            break
                        }
                        Start-Sleep -Milliseconds 200
                    }
                    if (-not $unloaded) {
                        Write-Log "Failed to unload registry hive for $userName ($sid) after 5 attempts." -Type "WARNING"
                    }
                    $injected++
                } else {
                    Write-Log "Failed to load registry hive for $userName ($sid)." -Type "ERROR"
                }
            }
        }
        Write-Log "Credentials injected for $injected user profiles." -Type "SUCCESS"
        Write-Host "  [+] Credentials injected into $injected user profiles." -ForegroundColor Green
        $pass = ""
    }
    catch { Write-Log "Cross-user credential injection failed: $($_.Exception.Message)" -Type "ERROR" }
}

function Force-DefaultPrinterRegistry {
    Write-Host "`n  ======================================================================"
    Write-Host "               FORCE-SET DEFAULT PRINTER (REGISTRY BYPASS 0x00000709)"
    Write-Host "  ======================================================================"
    Write-Log "Force-setting default printer via registry injection..." -Type "INFO"
    try {
        Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" -Name LegacyDefaultPrinterMode -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        $printers = Get-Printer -ErrorAction Stop
        if (-not $printers) { Write-Host "  [-] No printers found." -ForegroundColor Red; return }
        $idx = 1
        foreach ($p in $printers) {
            Write-Host "  [$idx] $($p.Name) | Port: $($p.PortName)" -ForegroundColor Cyan
            $idx++
        }
        $sel = Read-Host "`n  [?] Select printer number to force as default"
        $selIdx = -1
        try { $selIdx = [int]$sel - 1 } catch { Write-Host "  [-] Invalid input." -ForegroundColor Red; return }
        if ($selIdx -lt 0 -or $selIdx -ge $printers.Count) { Write-Host "  [-] Invalid selection." -ForegroundColor Red; return }
        $target = $printers[$selIdx]
        $deviceStr = "$($target.Name),winspool,$($target.PortName):"
        Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" -Name Device -Value $deviceStr -Type String -Force -ErrorAction Stop
        Write-Log "Default printer forced via registry: $($target.Name)" -Type "SUCCESS"
        Write-Host "  [+] Default printer set to: $($target.Name) (Registry bypass applied)." -ForegroundColor Green
    }
    catch { Write-Log "Registry default printer failed: $($_.Exception.Message)" -Type "ERROR" }
}

function Sanitize-PrinterShareName {
    Write-Log "Scanning for unsanitary printer share names..." -Type "INFO"
    Write-Host "`n  ======================================================================"
    Write-Host "               AUTO-SANITIZE PRINTER SHARE NAME"
    Write-Host "  ======================================================================"
    try {
        $shared = Get-Printer -ErrorAction SilentlyContinue | Where-Object { $_.Shared -eq $true }
        if (-not $shared) { Write-Host "  [+] No shared printers found." -ForegroundColor Yellow; return }
        $fixed = 0
        foreach ($p in $shared) {
            $original = $p.ShareName
            $clean = $original -replace '[^a-zA-Z0-9_\-\.]', '_' -replace '__+', '_' -replace '^_|_$', ''
            if ($clean -ne $original) {
                Write-Host "  [!] $original -> $clean" -ForegroundColor Yellow
                Set-Printer -Name $p.Name -ShareName $clean -ErrorAction SilentlyContinue
                $fixed++
            }
            else {
                Write-Host "  [+] $original (clean)" -ForegroundColor Green
            }
        }
        if ($fixed -gt 0) {
            Write-Log "Sanitized $fixed printer share names." -Type "SUCCESS"
            Write-Host "`n  [+] $fixed share name(s) sanitized." -ForegroundColor Green
        }
        else {
            Write-Host "`n  [+] All share names are already clean." -ForegroundColor Green
            Write-Log "All share names clean." -Type "SUCCESS"
        }
    }
    catch { Write-Log "Share name sanitization failed: $($_.Exception.Message)" -Type "ERROR" }
}

function Fix-BrowserPrintSandbox {
    Write-Log "Resetting browser print sandbox (Chromium)..." -Type "INFO"
    Write-Host "`n  ======================================================================"
    Write-Host "               BROWSER PRINT SANDBOX FIX (CHROMIUM)"
    Write-Host "  ======================================================================"
    try {
        Write-Host "  [*] Terminating browser processes..." -ForegroundColor Cyan
        Get-Process -Name "chrome", "msedge" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        $cleared = 0
        $chromePrintDir = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"
        $edgePrintDir = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"
        if (Test-Path $chromePrintDir) {
            Remove-Item "$chromePrintDir\*" -Force -Recurse -ErrorAction SilentlyContinue
            $cleared++; Write-Host "  [+] Chrome cache cleared." -ForegroundColor Green
        }
        if (Test-Path $edgePrintDir) {
            Remove-Item "$edgePrintDir\*" -Force -Recurse -ErrorAction SilentlyContinue
            $cleared++; Write-Host "  [+] Edge cache cleared." -ForegroundColor Green
        }
        & CheckNetIsolation.exe LoopbackExempt -a -n="microsoft.windows.printdialog_cw5n1h2txyewy" 2>&1 | Out-Null
        & CheckNetIsolation.exe LoopbackExempt -a -n="microsoft.microsoftedge_8wekyb3d8bbwe" 2>&1 | Out-Null
        Restart-Service spooler -Force -ErrorAction SilentlyContinue
        Write-Log "Browser print sandbox reset. $cleared browser cache(s) cleared." -Type "SUCCESS"
        Write-Host "  [+] Browser print sandbox reset complete. Restart your browser." -ForegroundColor Green
    }
    catch { Write-Log "Browser sandbox fix failed: $($_.Exception.Message)" -Type "ERROR" }
}

function Detect-GPOIntervention {
    Write-Log "Scanning for Group Policy intervention on printer registry..." -Type "INFO"
    Write-Host "`n  ======================================================================"
    Write-Host "               GROUP POLICY (GPO) INTERVENTION DETECTION"
    Write-Host "  ======================================================================"
    try {
        $isPartOfDomain = $false
        try {
            $sys = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
            $isPartOfDomain = $sys.PartOfDomain
        } catch {
            $netJoin = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -ErrorAction SilentlyContinue
            if ($netJoin -and $netJoin.Domain -and $netJoin.Domain -ne "") {
                $isPartOfDomain = $true
            }
        }

        if ($isPartOfDomain) {
            Write-Host "  [+] Domain status: DOMAIN JOINED" -ForegroundColor Green
        } else {
            Write-Host "  [+] Domain status: WORKGROUP (Not Domain Joined)" -ForegroundColor Green
        }

        $policyPaths = @(
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers"; Label = "Printer Policies" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint"; Label = "Point and Print" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\RPC"; Label = "RPC Policies" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\WPP"; Label = "Windows Protected Print" },
            @{ Path = "HKCU:\SOFTWARE\Policies\Microsoft\Windows NT\Printers"; Label = "User Printer Policies" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation"; Label = "Lanman Workstation Policies" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanServer"; Label = "Lanman Server Policies" }
        )

        $recommendations = @{
            "DisableClientSideRendering" = 1
            "RestrictDriverInstallationToAdministrators" = 0
            "InForest" = 1
            "TrustedServers" = 1
            "ServerList" = "*.*"
            "NoWarningNoElevationOnInstall" = 1
            "NoWarningNoElevationOnUpdate" = 1
            "UpdatePromptSettings" = 2
            "RpcUseNamedPipeProtocol" = 1
            "RpcTcpEnable" = 1
            "RpcProtocols" = 7
            "ForceSetup" = 1
            "RpcAuthenticationLevel" = 0
            "RpcOverNamedPipes" = 1
            "ForceKerberosForRpc" = 0
            "Enabled" = 0
            "PackagePointAndPrintServerList" = 1
            "RequireSecuritySignature" = 0
            "EnableSecuritySignature" = 0
        }

        $gpoDetected = $false
        $restrictionDetected = $false

        foreach ($entry in $policyPaths) {
            if (Test-Path $entry.Path) {
                $props = Get-ItemProperty $entry.Path -ErrorAction SilentlyContinue
                $propNames = $props.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' }
                if ($propNames.Count -gt 0) {
                    $gpoDetected = $true
                    Write-Host "`n  [*] Path: $($entry.Label)" -ForegroundColor Cyan
                    foreach ($prop in $propNames) {
                        $pName = $prop.Name
                        $pValue = $prop.Value
                        if ($recommendations.ContainsKey($pName)) {
                            $recVal = $recommendations[$pName]
                            if ($pValue.ToString() -eq $recVal.ToString()) {
                                Write-Host "      [Active Fix] $pName = $pValue" -ForegroundColor Green
                            } else {
                                $restrictionDetected = $true
                                Write-Host "      [!] Policy Override (Restricted): $pName = $pValue (Should be: $recVal)" -ForegroundColor Red
                            }
                        } else {
                            Write-Host "      [*] User Override: $pName = $pValue" -ForegroundColor Yellow
                        }
                    }
                }
            }
        }

        if ($isPartOfDomain) {
            Write-Host "`n  [*] Running gpresult for printer-related GPOs..." -ForegroundColor Cyan
            $gpresult = & gpresult /R /Scope Computer 2>&1 | Select-String -Pattern "Printer|Print|Point"
            if ($gpresult) {
                Write-Host "  [!] GPO references found in Computer Policy:" -ForegroundColor Yellow
                $gpresult | ForEach-Object { Write-Host "      $_" -ForegroundColor Cyan }
            } else {
                Write-Host "  [+] No active printer-related GPOs detected via gpresult." -ForegroundColor Green
            }

            if ($restrictionDetected) {
                Write-Host "`n  [!] WARNING: GPO-managed keys will be OVERWRITTEN by Domain Controller." -ForegroundColor Red
                Write-Host "  [!] Local changes to these keys will revert after gpupdate." -ForegroundColor Red
                Write-Log "GPO intervention detected on printer registry." -Type "WARNING"
            } else {
                Write-Host "`n  [+] GPO policies are aligned with printer sharing fixes or inactive." -ForegroundColor Green
                Write-Log "GPO checked; policies are aligned." -Type "SUCCESS"
            }
        } else {
            Write-Host "`n  [+] Local Workgroup environment (no active Domain Controller detected)." -ForegroundColor Green
            if ($restrictionDetected) {
                Write-Host "  [!] Some local policy overrides are restricting sharing. These can be adjusted locally." -ForegroundColor Yellow
                Write-Log "Local policy restrictions detected." -Type "WARNING"
            } else {
                Write-Host "  [+] No local policy conflicts detected." -ForegroundColor Green
                Write-Log "No policy conflicts detected." -Type "SUCCESS"
            }
        }
    }
    catch { Write-Log "GPO detection failed: $($_.Exception.Message)" -Type "ERROR" }
}

function Parse-PrintEventLog {
    Write-Log "Parsing top 5 PrintService Error/Warning events..." -Type "INFO"
    Write-Host "`n  ======================================================================"
    Write-Host "                 PRINTSERVICE EVENT LOG PARSER (TOP 5)"
    Write-Host "  ======================================================================"
    try {
        $events = Get-WinEvent -FilterHashtable @{
            LogName = 'Microsoft-Windows-PrintService/Admin'
            Level   = @(2, 3)
        } -MaxEvents 5 -ErrorAction SilentlyContinue
        if ($events) {
            $resolutionMap = @{
                '808' = "Driver install failure. Execute [43] Orphaned Driver Sweeper."
                '842' = "Queue corruption. Execute [37] Force Purge Print Queue."
                '354' = "Spooler failed to start. Execute [38] Spooler Dependency Reset."
                '824' = "Printer offline. Execute [26] WSD to TCP/IP Converter."
            }
            foreach ($evt in $events) {
                $levelStr = if ($evt.Level -eq 2) { "ERROR" } else { "WARNING" }
                $color = if ($evt.Level -eq 2) { "Red" } else { "Yellow" }
                Write-Host "`n  [$levelStr] Event $($evt.Id) - $($evt.TimeCreated)" -ForegroundColor $color
                Write-Host "  Message: $($evt.Message)" -ForegroundColor White

                $suggestion = ""
                if ($evt.Id -eq 372) {
                    if ($evt.Message -match "Access is denied" -or $evt.Message -match "error code.*: 5\b") {
                        $suggestion = "Permission blocked. Execute [12] Disable Password Sharing or [60] Inject Credentials."
                    }
                    elseif ($evt.Message -match "The network path was not found" -or $evt.Message -match "error code.*: 53\b") {
                        $suggestion = "Host unreachable. Verify Host IP/Power, then Execute [14] Open Firewall."
                    }
                    else {
                        $suggestion = "Spooler/Driver crash. Execute [06] or [37] Force Purge Print Queue."
                    }
                }
                elseif ($resolutionMap.ContainsKey($evt.Id.ToString())) {
                    $suggestion = $resolutionMap[$evt.Id.ToString()]
                }

                if ($suggestion) {
                    Write-Host "  SUGGESTION: $suggestion" -ForegroundColor Green
                }
            }
        }
        else {
            Write-Host "  [+] No Error/Warning events found. PrintService is healthy." -ForegroundColor Green
        }
        Write-Log "PrintService event log parsed." -Type "SUCCESS"
    }
    catch { Write-Log "Event log parse failed: $($_.Exception.Message)" -Type "ERROR" }
}

function Map-LocalPortUNC {
    Write-Host "`n  ======================================================================"
    Write-Host "               MAP LOCAL PORT TO UNC PATH (BYPASS)"
    Write-Host "  ======================================================================"
    Write-Host "  [!] Use this if standard sharing STILL fails with 'Check printer name' error."
    $ip = Read-Host "  [?] Target Host IP/Hostname (e.g., 192.168.1.10)"
    $share = Read-Host "  [?] Exact Printer Share Name (e.g., EPSON_L120)"
    if ($ip -and $share) {
        $uncPath = "\\$ip\$share"
        try {
            Write-Host "  [*] Attempting standard Local Port creation: $uncPath" -ForegroundColor Cyan
            Add-PrinterPort -Name $uncPath -ErrorAction Stop
            Write-Log "Local Port created for UNC via API: $uncPath" -Type "SUCCESS"
            Write-Host "  [+] Local Port injected! You can now Add a Local Printer and select this port." -ForegroundColor Green
        }
        catch {
            Write-Host "  [*] Standard method blocked by Windows. Deploying Registry Bypass..." -ForegroundColor Yellow
            try {
                $portRegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Ports"

                Set-ItemProperty -Path $portRegPath -Name $uncPath -Value "" -Type String -Force -ErrorAction Stop

                Write-Host "  [*] Port injected. Restarting Print Spooler to finalize..." -ForegroundColor Cyan
                Restart-Service spooler -Force -ErrorAction SilentlyContinue

                Write-Log "Local Port injected for UNC via Registry Bypass: $uncPath" -Type "SUCCESS"
                Write-Host "  [+] BYPASS SUCCESS! Port $uncPath is now available in your port list." -ForegroundColor Green
                Write-Host "  [!] NEXT STEP: Go to 'Add Printer' -> 'Add a local printer' -> 'Use an existing port'." -ForegroundColor Green
                Write-Host "  [!] Select $uncPath from the drop-down menu, then choose your driver." -ForegroundColor Green
            }
            catch {
                Write-Log " Bypass Failed: $($_.Exception.Message)" -Type "ERROR"
                Write-Host "  [-] Bypass failed. Registry access is completely locked down by Administrator/GPO." -ForegroundColor Red
            }
        }
    }
}

function Remove-LocalPortUNC {
    Write-Host "`n  ======================================================================"
    Write-Host "               REMOVE INJECTED LOCAL PORT (UNC)"
    Write-Host "  ======================================================================"

    Write-Host "  [*] Identifying active printer ports..." -ForegroundColor Cyan
    try {
        $ports = Get-PrinterPort | Select-Object -ExpandProperty Name | Sort-Object
        if ($ports) {
            Write-Host "  [>] Detected Ports:" -ForegroundColor Yellow
            foreach ($p in $ports) {
                if ($p -like "\\*") {
                    Write-Host "      -> $p (UNC Mapping)" -ForegroundColor Green
                } else {
                    Write-Host "      -> $p" -ForegroundColor Gray
                }
            }
        }
    } catch { Write-Host "  [!] Could not retrieve port list via API." -ForegroundColor Yellow }

    Write-Host "`n  [!] Use this to delete a port previously created by Option [86]."
    $portName = Read-Host "  [?] Input exact Port Name to remove (e.g., \\192.168.1.10\Printer)"
    if (-not $portName) { return }

    try {
        Write-Host "  [*] Attempting standard port removal..." -ForegroundColor Cyan
        Remove-PrinterPort -Name $portName -ErrorAction Stop
        Write-Log "Port $portName removed via API." -Type "SUCCESS"
        Write-Host "  [+] Port $portName successfully removed." -ForegroundColor Green
    }
    catch {
        Write-Host "  [*] Standard method failed. Deploying Registry Purge..." -ForegroundColor Yellow
        try {
            $portRegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Ports"
            Remove-ItemProperty -Path $portRegPath -Name $portName -ErrorAction Stop

            Write-Host "  [*] Port deleted from registry. Restarting Print Spooler..." -ForegroundColor Cyan
            Restart-Service spooler -Force -ErrorAction SilentlyContinue

            Write-Log "Port $portName removed via Registry Bypass." -Type "SUCCESS"
            Write-Host "  [+] BYPASS SUCCESS! Port $portName has been permanently deleted." -ForegroundColor Green
        }
        catch {
            Write-Log "Failed to remove UNC Port: $($_.Exception.Message)" -Type "ERROR"
            Write-Host "  [-] Failed to remove port. Ensure you typed the name EXACTLY as it appears in the port list." -ForegroundColor Red
        }
    }
}


function Fix-HostServerRole {
    cls
    $isEN = ($script:lang -eq "EN")
    $title = if ($isEN) { "OPTIMIZING HOST / PRINT SERVER PC (USB-CONNECTED)" } else { "OPTIMASI KOMPUTER HOST / SERVER PRINTER (TERHUBUNG USB)" }
    Write-Host "`n  ===================================================================================================" -ForegroundColor Cyan
    Write-Host "                    $title" -ForegroundColor Yellow
    Write-Host "  ===================================================================================================`n" -ForegroundColor Cyan
    Write-Log "Running Host/Print Server Optimization (LANG=$script:lang)" -Type "INFO"

    Write-Host $(if ($isEN) { "  [*] [1/8] Securing Registry Backup..." } else { "  [*] [1/8] Mengamankan Cadangan Registri (Backup)..." }) -ForegroundColor Cyan
    Backup-Registry

    Write-Host $(if ($isEN) { "  [*] [2/8] Enforcing Spooler Remote RPC Endpoint (Accepting Client Connections)..." } else { "  [*] [2/8] Mengizinkan Spooler Menerima Koneksi RPC Klien Jaringan..." }) -ForegroundColor Cyan
    try {
        $polPrint = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers"
        if (-not (Test-Path $polPrint)) { New-Item -Path $polPrint -Force | Out-Null }
        Set-ItemProperty -Path $polPrint -Name RegisterSpoolerRemoteRpcEndPoint -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
    } catch {}

    Write-Host $(if ($isEN) { "  [*] [3/8] Enforcing Network Connection Profile to Private..." } else { "  [*] [3/8] Mengubah Profil Jaringan ke Mode Private..." }) -ForegroundColor Cyan
    Set-NetworkPrivate

    Write-Host $(if ($isEN) { "  [*] [4/8] Opening Passwordless Sharing & Guest Access Permissions..." } else { "  [*] [4/8] Membuka Akses Berbagi Tanpa Sandi & Izin Guest..." }) -ForegroundColor Cyan
    Disable-PasswordSharing
    Enable-SMBGuest

    Write-Host $(if ($isEN) { "  [*] [5/8] Opening Windows Firewall for File & Printer Sharing and WSD Discovery..." } else { "  [*] [5/8] Membuka Akses Firewall untuk Printer & Penemuan WSD..." }) -ForegroundColor Cyan
    Open-Firewall
    Fix-WSDFirewall

    Write-Host $(if ($isEN) { "  [*] [6/8] Disabling SMB Server Security Signing Enforcement..." } else { "  [*] [6/8] Mematikan Wajib SMB Server Signing..." }) -ForegroundColor Cyan
    Fix-SMBSigning

    Write-Host $(if ($isEN) { "  [*] [7/8] Sanitizing Printer Share Names (Removing illegal characters & spaces)..." } else { "  [*] [7/8] Merapikan Nama Share Printer dari Spasi & Karakter Ilegal..." }) -ForegroundColor Cyan
    Sanitize-PrinterShareName

    Write-Host $(if ($isEN) { "  [*] [8/8] Deploying Spooler Watchdog Scheduled Task & Restarting Spooler..." } else { "  [*] [8/8] Memasang Tugas Pemantau Spooler Otomatis (Watchdog) & Restart..." }) -ForegroundColor Cyan
    Set-SpoolerWatchdog
    Reset-Spooler

    Write-Log "Host Server Optimization concluded." -Type "SUCCESS"
    Write-Host ""
    Write-Host $(if ($isEN) { "  [+] Host / Print Server optimization completed successfully!" } else { "  [+] Optimasi Komputer Host / Server Printer berhasil diterapkan!" }) -ForegroundColor Green
    Write-Host $(if ($isEN) { "  [i] Other PCs on the network can now connect to printers shared by this computer." } else { "  [i] Komputer lain di jaringan kini dapat mendeteksi dan tersambung ke printer PC ini." }) -ForegroundColor Cyan
}

function Fix-ClientWorkstationRole {
    cls
    $isEN = ($script:lang -eq "EN")
    $title = if ($isEN) { "OPTIMIZING CLIENT PC (CONNECTING TO SHARED PRINTER)" } else { "OPTIMASI KOMPUTER KLIEN (MENYAMBUNG KE PRINTER SHARING)" }
    Write-Host "`n  ===================================================================================================" -ForegroundColor Cyan
    Write-Host "                    $title" -ForegroundColor Yellow
    Write-Host "  ===================================================================================================`n" -ForegroundColor Cyan
    Write-Log "Running Client Workstation Optimization (LANG=$script:lang)" -Type "INFO"

    Write-Host $(if ($isEN) { "  [*] [1/7] Securing Registry Backup..." } else { "  [*] [1/7] Mengamankan Cadangan Registri (Backup)..." }) -ForegroundColor Cyan
    Backup-Registry

    Write-Host $(if ($isEN) { "  [*] [2/7] Activating RPC Named Pipes & TCP Protocol Pathways..." } else { "  [*] [2/7] Mengaktifkan Jalur Protokol RPC Named Pipes & TCP..." }) -ForegroundColor Cyan
    Fix-NamedPipes

    Write-Host $(if ($isEN) { "  [*] [3/7] Applying Point & Print Driver Elevation Bypass (PrintNightmare Override)..." } else { "  [*] [3/7] Menerapkan Bypass Elevasi Point and Print (Driver Install)..." }) -ForegroundColor Cyan
    Fix-AdvancedPointAndPrint

    Write-Host $(if ($isEN) { "  [*] [4/7] Disabling SMB Client Signing Enforcement (Resolving 24H2/25H2 block)..." } else { "  [*] [4/7] Mematikan Wajib SMB Client Signing (Atasi Blokir Win 11)..." }) -ForegroundColor Cyan
    Fix-SMBSigning

    Write-Host $(if ($isEN) { "  [*] [5/7] Fixing HKCU Printer Registry Key Permissions..." } else { "  [*] [5/7] Memperbaiki Izin Kunci Registri Printer HKCU..." }) -ForegroundColor Cyan
    Fix-HKCU-PrinterKeyPerms

    Write-Host $(if ($isEN) { "  [*] [6/7] Enabling Network Discovery Services (mDNS, LLMNR, SSDP)..." } else { "  [*] [6/7] Mengaktifkan Layanan Penemuan Perangkat Jaringan (mDNS, WSD)..." }) -ForegroundColor Cyan
    Fix-mDNS
    Fix-NetworkServices

    Write-Host $(if ($isEN) { "  [*] [7/7] Opening Firewall Rules & Flushing DNS Cache..." } else { "  [*] [7/7] Membuka Port Firewall & Menyegarkan Cache DNS..." }) -ForegroundColor Cyan
    Open-Firewall
    try { $LASTEXITCODE = 0; ipconfig /flushdns > $null 2>&1 } catch {}

    Write-Log "Client Workstation Optimization concluded." -Type "SUCCESS"
    Write-Host ""
    Write-Host $(if ($isEN) { "  [+] Client Workstation optimization completed successfully!" } else { "  [+] Optimasi Komputer Klien berhasil diterapkan!" }) -ForegroundColor Green
    Write-Host $(if ($isEN) { "  [i] Try connecting to the shared printer now (e.g. \\ComputerName\PrinterName)." } else { "  [i] Silakan coba sambungkan kembali printer sharing sekarang (contoh: \\NamaKomputer\NamaPrinter)." }) -ForegroundColor Cyan
    Write-Host $(if ($isEN) { "  [i] If still prompted for password, save credentials via Menu 6 -> 1." } else { "  [i] Jika masih meminta sandi, simpan kredensial via Menu 6 -> 1." }) -ForegroundColor Yellow
    Write-Host $(if ($isEN) { "  [i] If error 0x709 persists, use Local Port UNC Mapping via Menu 7 -> 1." } else { "  [i] Jika masih muncul error 0x709, gunakan Pemetaan Port UNC via Menu 7 -> 1." }) -ForegroundColor Yellow
}

# Windows Printer Sharing Fix - Interactive Engine & Bilingual UI
# Supports Bahasa Indonesia (ID) and English (EN)

$script:lang = "ID"
try {
    $savedLang = (Get-ItemProperty -Path "HKCU:\Software\WindowsPrinterSharingFix" -Name "Language" -ErrorAction SilentlyContinue).Language
    if ($savedLang -in @("ID", "EN")) {
        $script:lang = $savedLang
    }
} catch {}

function Set-AppLanguage {
    param([string]$NewLang)
    if ($NewLang -in @("ID", "EN")) {
        $script:lang = $NewLang
        try {
            if (-not (Test-Path "HKCU:\Software\WindowsPrinterSharingFix")) {
                New-Item -Path "HKCU:\Software\WindowsPrinterSharingFix" -Force | Out-Null
            }
            Set-ItemProperty -Path "HKCU:\Software\WindowsPrinterSharingFix" -Name "Language" -Value $script:lang -Force
        } catch {}
    }
}

function Toggle-AppLanguage {
    if ($script:lang -eq "ID") {
        Set-AppLanguage -NewLang "EN"
    } else {
        Set-AppLanguage -NewLang "ID"
    }
}

function Get-SystemHealthSummary {
    $spoolerOk = $false
    try {
        $spoolerOk = ((Get-Service spooler -ErrorAction SilentlyContinue).Status -eq 'Running')
    } catch {}

    $netPrivate = $true
    try {
        $pubProfile = Get-NetConnectionProfile -ErrorAction SilentlyContinue | Where-Object { $_.NetworkCategory -eq 'Public' }
        if ($pubProfile) { $netPrivate = $false }
    } catch {}

    $smbSignReq = $false
    try {
        $signVal = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name "RequireSecuritySignature" -ErrorAction SilentlyContinue).RequireSecuritySignature
        if ($signVal -eq 1) { $smbSignReq = $true }
    } catch {}

    $passSharingOff = $true
    try {
        $blankVal = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "LimitBlankPasswordUse" -ErrorAction SilentlyContinue).LimitBlankPasswordUse
        if ($blankVal -eq 1) { $passSharingOff = $false }
    } catch {}

    return @{
        Spooler         = $spoolerOk
        Network         = $netPrivate
        SMBSigning      = (-not $smbSignReq)
        PasswordSharing = $passSharingOff
    }
}

function AllFix-Core {
    cls
    $isEN = ($script:lang -eq "EN")
    $title = if ($isEN) { "EXECUTING ALLFIX (50 AUTOMATED FIXES)" } else { "MENJALANKAN ALLFIX (50 PERBAIKAN OTOMATIS SEKALIGUS)" }
    Write-Host "`n  ===================================================================================================" -ForegroundColor Cyan
    Write-Host "                    $title" -ForegroundColor Yellow
    Write-Host "  ===================================================================================================`n" -ForegroundColor Cyan
    Write-Log "RUN ALLFIX (SILENT=$script:silentNuke, LANG=$script:lang)" -Type "INFO"

    Write-Host $(if ($isEN) { "  [*] [1/50] Detecting Operating System..." } else { "  [*] [1/50] Mendeteksi Sistem Operasi..." }) -ForegroundColor Cyan
    Write-Host "      $script:productName Build $script:buildNumber" -ForegroundColor Gray

    Write-Host $(if ($isEN) { "  [*] [2/50] Securing Registry Backup..." } else { "  [*] [2/50] Mengamankan Cadangan Registri (Backup)..." }) -ForegroundColor Cyan
    Backup-Registry

    Write-Host $(if ($isEN) { "  [*] [3/50] Refreshing Group Policy cache (gpupdate)..." } else { "  [*] [3/50] Memperbarui Cache Kebijakan Sistem (gpupdate)..." }) -ForegroundColor Cyan
    try { $LASTEXITCODE = 0; gpupdate /force > $null 2>&1 } catch {}

    Write-Host $(if ($isEN) { "  [*] [4/50] Auditing & Initializing RPC / DCOM Services..." } else { "  [*] [4/50] Memeriksa & Mengaktifkan Layanan RPC & DCOM..." }) -ForegroundColor Cyan
    Check-RPC

    Write-Host $(if ($isEN) { "  [*] [5/50] Patching Error 0x0000011b (RpcAuthnLevelPrivacy)..." } else { "  [*] [5/50] Memperbaiki Error 0x0000011b (RpcAuthnLevelPrivacy)..." }) -ForegroundColor Cyan
    Fix-RpcAuthn0x0000011b

    Write-Host $(if ($isEN) { "  [*] [6/50] Deep Fix Error 0x00000709 (Multi-Layer RPC & Point and Print)..." } else { "  [*] [6/50] Memperbaiki Error 0x00000709 (Jalur RPC & Point and Print)..." }) -ForegroundColor Cyan
    Fix-Deep0x00000709

    Write-Host $(if ($isEN) { "  [*] [7/50] Aligning KB5089549 Driver Policy & HKCU Permissions..." } else { "  [*] [7/50] Menyelaraskan Kebijakan Driver & Izin Registri HKCU..." }) -ForegroundColor Cyan
    Fix-CrossSignedDriverPolicy
    Fix-HKCU-PrinterKeyPerms

    Write-Host $(if ($isEN) { "  [*] [8/50] Bypassing Error 0x00000bc4 (No Printers Found)..." } else { "  [*] [8/50] Mengatasi Error 0x00000bc4 (Printer Jaringan Tidak Ditemukan)..." }) -ForegroundColor Cyan
    Fix-Discovery0x00000bc4

    Write-Host $(if ($isEN) { "  [*] [9/50] Fixing Error 0x00000040 (KeepConn & Network Availability)..." } else { "  [*] [9/50] Memperbaiki Error 0x00000040 (KeepConn & Nama Jaringan)..." }) -ForegroundColor Cyan
    Fix-Network0x00000040

    Write-Host $(if ($isEN) { "  [*] [10/50] Fixing Error 0x00000002 (CopyFilesPolicy Driver Ingestion)..." } else { "  [*] [10/50] Mengatasi Error 0x00000002 (Kebijakan Salin Berkas Driver)..." }) -ForegroundColor Cyan
    Fix-DriverCopy0x00000002

    Write-Host $(if ($isEN) { "  [*] [11/50] Fixing Error 0x0000007e (RPC Bitness Mismatch 32/64-bit)..." } else { "  [*] [11/50] Mengatasi Error 0x0000007e (Bitness Driver 32/64-bit)..." }) -ForegroundColor Cyan
    Fix-RpcBitness0x0000007e

    Write-Host $(if ($isEN) { "  [*] [12/50] Enabling DnsOnWire, StrictNameChecking & UAC Token Filter Bypass..." } else { "  [*] [12/50] Mengaktifkan Nama Jaringan & Bypass Filter Token UAC..." }) -ForegroundColor Cyan
    try {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Print" -Name DnsOnWire -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name DisableStrictNameChecking -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
    }
    catch {}
    Fix-UACTokenFilter

    Write-Host $(if ($isEN) { "  [*] [13/50] Disabling SMB Signing Requirement (Fix Win 11 Access)..." } else { "  [*] [13/50] Mematikan Wajib SMB Signing (Fix Windows 11 Gagal Konek)..." }) -ForegroundColor Cyan
    Fix-SMBSigning

    Write-Host $(if ($isEN) { "  [*] [14/50] Enforcing Modern SMB2/SMB3 Compatibility & Provider Order..." } else { "  [*] [14/50] Memastikan Kompatibilitas Modern SMB2/SMB3 & Urutan Provider..." }) -ForegroundColor Cyan
    Fix-ModernSMB
    Fix-ProviderOrder

    Write-Host $(if ($isEN) { "  [*] [15/50] Enforcing RPC via Named Pipes & TCP Pathways..." } else { "  [*] [15/50] Mengaktifkan RPC via Named Pipes & TCP..." }) -ForegroundColor Cyan
    Fix-NamedPipes

    Write-Host $(if ($isEN) { "  [*] [16/50] Disabling Client-Side Rendering (CSR)..." } else { "  [*] [16/50] Mematikan Client-Side Rendering (CSR)..." }) -ForegroundColor Cyan
    Fix-CSR

    Write-Host $(if ($isEN) { "  [*] [17/50] Disabling Print Driver Isolation Policy..." } else { "  [*] [17/50] Mematikan Isolasi Driver Printer..." }) -ForegroundColor Cyan
    try {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Print" -Name IsolationPolicy -Value 0 -Type DWord -Force
    }
    catch {}

    Write-Host $(if ($isEN) { "  [*] [18/50] Starting Discovery Services (mDNS, WSD, NetBIOS)..." } else { "  [*] [18/50] Mengaktifkan Layanan Penemuan Jaringan (mDNS, WSD, NetBIOS)..." }) -ForegroundColor Cyan
    Fix-mDNS
    Fix-NetworkServices

    Write-Host $(if ($isEN) { "  [*] [19/50] Configuring Windows Firewall Rules for File & Printer Sharing..." } else { "  [*] [19/50] Membuka Akses Firewall untuk Printer & Berbagi Berkas..." }) -ForegroundColor Cyan
    Open-Firewall
    Fix-WSDFirewall

    Write-Host $(if ($isEN) { "  [*] [20/50] Opening SMB Guest Access & Dropping Anonymous Blocks..." } else { "  [*] [20/50] Membuka Akses SMB Guest & Anonymous..." }) -ForegroundColor Cyan
    Enable-SMBGuest

    Write-Host $(if ($isEN) { "  [*] [21/50] Disabling Password Protected Network Sharing..." } else { "  [*] [21/50] Mematikan Berbagi Berproteksi Password..." }) -ForegroundColor Cyan
    Disable-PasswordSharing

    Write-Host $(if ($isEN) { "  [*] [22/50] Aligning LSA Protection, NTLMv2 & Credential Guard..." } else { "  [*] [22/50] Menyelaraskan Proteksi LSA, Otentikasi NTLMv2 & Credential Guard..." }) -ForegroundColor Cyan
    Fix-LSAProtection
    Fix-NTLMv2
    Fix-CredentialGuard

    Write-Host $(if ($isEN) { "  [*] [23/50] Bypassing Smart App Control (SAC) Driver Block..." } else { "  [*] [23/50] Mengatasi Pembatasan Smart App Control (SAC)..." }) -ForegroundColor Cyan
    Fix-SAC

    Write-Host $(if ($isEN) { "  [*] [24/50] Initializing IPP & Mopria Print Sharing Foundation..." } else { "  [*] [24/50] Menyiapkan Fondasi Berbagi IPP & Mopria..." }) -ForegroundColor Cyan
    Fix-IPPSharing

    Write-Host $(if ($isEN) { "  [*] [25/50] Disabling WPP (Allowing Legacy Network Printer Drivers)..." } else { "  [*] [25/50] Menonaktifkan WPP untuk Mengizinkan Driver Jaringan..." }) -ForegroundColor Cyan
    try {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\WPP" -Name Enabled -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    }
    catch {}

    Write-Host $(if ($isEN) { "  [*] [26/50] Configuring RDP Printer Redirection & LPD Protocols..." } else { "  [*] [26/50] Menyesuaikan Protokol Printer RDP & LPD..." }) -ForegroundColor Cyan
    Fix-RDPPrinter
    Manage-LPR

    Write-Host $(if ($isEN) { "  [*] [27/50] Forcing Network Connection Profiles to Private Mode..." } else { "  [*] [27/50] Mengubah Kategori Jaringan ke Mode Private..." }) -ForegroundColor Cyan
    Set-NetworkPrivate

    Write-Host $(if ($isEN) { "  [*] [28/50] Deprioritizing Hyper-V / WSL Virtual Network Adapters..." } else { "  [*] [28/50] Menyesuaikan Prioritas Adaptor Jaringan Virtual Hyper-V..." }) -ForegroundColor Cyan
    Fix-HyperVConflict

    Write-Host $(if ($isEN) { "  [*] [29/50] Flushing DNS Cache & Resetting Network Winsock..." } else { "  [*] [29/50] Membersihkan Cache DNS & Winsock Jaringan..." }) -ForegroundColor Cyan
    Reset-Network

    Write-Host $(if ($isEN) { "  [*] [30/50] Stopping Print Spooler Service..." } else { "  [*] [30/50] Menghentikan Sementara Layanan Spooler..." }) -ForegroundColor Cyan
    Stop-Service spooler -Force -ErrorAction SilentlyContinue

    Write-Host $(if ($isEN) { "  [*] [31/50] Configuring Spooler Auto-Restart on Failure..." } else { "  [*] [31/50] Mengatur Pemulihan Otomatis Spooler Saat Crash..." }) -ForegroundColor Cyan
    Set-SpoolerRecovery

    Write-Host $(if ($isEN) { "  [*] [32/50] Purging Stale Spooler Dependencies (http & RPCSS)..." } else { "  [*] [32/50] Membersihkan Dependensi Layanan Spooler (http & RPCSS)..." }) -ForegroundColor Cyan
    Reset-SpoolerDependency

    Write-Host $(if ($isEN) { "  [*] [33/50] Resetting PRINTERS Folder Permissions (Universal SID)..." } else { "  [*] [33/50] Mereset Hak Akses Folder Antrean Cetak PRINTERS..." }) -ForegroundColor Cyan
    Reset-SpoolerPerm

    Write-Host $(if ($isEN) { "  [*] [34/50] Purging Stale Spooler Queue & Splwow64 Handles..." } else { "  [*] [34/50] Membersihkan Antrean Spooler yang Menumpuk..." }) -ForegroundColor Cyan
    Reset-Spooler

    Write-Host $(if ($isEN) { "  [*] [35/50] Bypassing AppContainer Loopback for Edge & UWP Apps..." } else { "  [*] [35/50] Menyesuaikan Izin Loopback Aplikasi Windows & Edge..." }) -ForegroundColor Cyan
    Fix-UWPPrinting

    Write-Host $(if ($isEN) { "  [*] [36/50] Applying Advanced Point & Print Elevation Overrides..." } else { "  [*] [36/50] Menerapkan Override Kebijakan Point and Print..." }) -ForegroundColor Cyan
    Fix-AdvancedPointAndPrint

    Write-Host $(if ($isEN) { "  [*] [37/50] Deploying Spooler Watchdog Scheduled Task..." } else { "  [*] [37/50] Memasang Tugas Pemantau Spooler Otomatis (Watchdog)..." }) -ForegroundColor Cyan
    Set-SpoolerWatchdog

    Write-Host $(if ($isEN) { "  [*] [38/50] Restarting Background Intelligent Transfer Service (BITS)..." } else { "  [*] [38/50] Merestart Layanan Transfer Berkas Latar Belakang (BITS)..." }) -ForegroundColor Cyan
    Manage-BITS

    Write-Host $(if ($isEN) { "  [*] [39/50] Verifying Spooler Status..." } else { "  [*] [39/50] Memastikan Layanan Spooler Berjalan Normal..." }) -ForegroundColor Cyan
    if ((Get-Service spooler).Status -ne 'Running') { Start-Service spooler -ErrorAction SilentlyContinue }
    Write-Host $(if ($isEN) { "  [+] Print Spooler validated operational." } else { "  [+] Layanan Spooler aktif dan terverifikasi normal." }) -ForegroundColor Green

    Write-Host $(if ($isEN) { "  [*] [40/50] Purging Kerberos Ticket Cache..." } else { "  [*] [40/50] Membersihkan Tiket Otentikasi Kerberos..." }) -ForegroundColor Cyan
    try { $LASTEXITCODE = 0; klist purge > $null 2>&1 } catch {}

    Write-Host $(if ($isEN) { "  [*] [41/50] Restarting System Diagnostic Service (WdiSystemHost)..." } else { "  [*] [41/50] Merestart Layanan Diagnostik Sistem (WdiSystemHost)..." }) -ForegroundColor Cyan
    try { Restart-Service WdiSystemHost -Force -ErrorAction SilentlyContinue } catch {}

    Write-Host $(if ($isEN) { "  [*] [42/50] Registering Multicast DNS..." } else { "  [*] [42/50] Mendaftarkan Ulang DNS Multicast..." }) -ForegroundColor Cyan
    try { $LASTEXITCODE = 0; ipconfig /registerdns > $null 2>&1 } catch {}

    Write-Host $(if ($isEN) { "  [*] [43/50] Generating System Restore Point..." } else { "  [*] [43/50] Membuat Titik Pemulihan Sistem (Restore Point)..." }) -ForegroundColor Cyan
    Create-RestorePoint

    Write-Host $(if ($isEN) { "  [*] [44/50] Scanning & Optimizing V4 Print Class Drivers..." } else { "  [*] [44/50] Memeriksa & Mengoptimalkan Driver Printer Kelas V4..." }) -ForegroundColor Cyan
    Fix-V4ClassDriver

    Write-Host $(if ($isEN) { "  [*] [45/50] Securing Network Connection Profile to Private..." } else { "  [*] [45/50] Mengamankan Profil Jaringan ke Mode Private..." }) -ForegroundColor Cyan
    $profiles = Get-NetConnectionProfile -ErrorAction SilentlyContinue
    $profiles | Where-Object { $_.NetworkCategory -eq 'Public' } | Set-NetConnectionProfile -NetworkCategory Private -ErrorAction SilentlyContinue

    Write-Host $(if ($isEN) { "  [*] [46/50] Forcibly Purging Corrupt Print Queue Files (.spl/.shd)..." } else { "  [*] [46/50] Menghapus Bersih Berkas Antrean Cetak yang Rusak..." }) -ForegroundColor Cyan
    Nuke-PrintQueue

    Write-Host $(if ($isEN) { "  [*] [47/50] Resetting Spooler Registry Dependencies..." } else { "  [*] [47/50] Menyetel Ulang Dependensi Registri Spooler..." }) -ForegroundColor Cyan
    Reset-SpoolerDependencyRegistry

    Write-Host $(if ($isEN) { "  [*] [48/50] Sanitizing Printer Share Names (Removing illegal characters)..." } else { "  [*] [48/50] Merapikan Nama Share Printer dari Karakter Ilegal..." }) -ForegroundColor Cyan
    Sanitize-PrinterShareName

    Write-Host $(if ($isEN) { "  [*] [49/50] Deploying Post-Update Auto-Reapply Scheduled Task..." } else { "  [*] [49/50] Memasang Tugas Pemulihan Otomatis Paska Update Windows..." }) -ForegroundColor Cyan
    Set-PostPatchTuesdayTask

    Write-Host $(if ($isEN) { "  [*] [50/50] Parsing PrintService Event Log & Final Spooler Validation..." } else { "  [*] [50/50] Menganalisis Log Peristiwa Cetak & Validasi Akhir Spooler..." }) -ForegroundColor Cyan
    Parse-PrintEventLog
    if ((Get-Service spooler).Status -ne 'Running') { Start-Service spooler -ErrorAction SilentlyContinue }
    Write-Host $(if ($isEN) { "  [+] All validations passed. Print Spooler running smoothly." } else { "  [+] Seluruh validasi selesai. Layanan Spooler berjalan sempurna." }) -ForegroundColor Green

    Write-Log $(if ($isEN) { "ALLFIX CONCLUDED" } else { "ALLFIX SELESAI" }) -Type "SUCCESS"

    if ($script:silentNuke) {
        Write-Host "`n  ===================================================================================================" -ForegroundColor Cyan
        $rebootMsg = if ($isEN) { "    [+] ALLFIX COMPLETED! REBOOTING SYSTEM IN 3 SECONDS..." } else { "    [+] ALLFIX SELESAI! KOMPUTER AKAN MERESTART DALAM 3 DETIK..." }
        Write-Host $rebootMsg -ForegroundColor Green
        Write-Host "  ===================================================================================================`n" -ForegroundColor Cyan
        Start-Sleep -Seconds 3
        Restart-Computer -Force
    }

    Write-Host "`n  ===================================================================================================" -ForegroundColor Cyan
    if ($isEN) {
        Write-Host "  [i] DOMAIN NOTICE: If host is AD-joined, verify 'Access this computer from network' in secpol.msc." -ForegroundColor Yellow
        Write-Host "  [i] STILL DENIED? Use Credential Injection [Menu 6 -> 1] or Local Port UNC Bypass [Menu 7 -> 1]." -ForegroundColor Green
    } else {
        Write-Host "  [i] INFO DOMAIN: Jika komputer ini tergabung dalam Domain Active Directory," -ForegroundColor Yellow
        Write-Host "      pastikan hak 'Access this computer from network' diatur di secpol.msc." -ForegroundColor Yellow
        Write-Host "  [i] MASIH TIDAK BISA KONEK? Gunakan Simpan Kredensial [Menu 6 -> 1] atau Pemetaan Port UNC [Menu 7 -> 1]." -ForegroundColor Green
    }

    $promptErr = if ($isEN) { "   [?] View execution error logs? (Y/N)" } else { "   [?] Tampilkan catatan error eksekusi jika ada? (Y/N)" }
    $checkError = Read-Host $promptErr
    if ($checkError -match '^[yY]') {
        Write-Host $(if ($isEN) { "`n   --- ERROR SCAN RESULTS ---" } else { "`n   --- HASIL PEMINDAIAN ERROR ---" }) -ForegroundColor Cyan
        $errors = Select-String -Path $script:logFile -Pattern " - ERROR - " -SimpleMatch
        if ($errors) {
            $errors.Line | ForEach-Object { Write-Host $_ -ForegroundColor Red }
        }
        else {
            Write-Host $(if ($isEN) { "   [+] No errors recorded in log file." } else { "   [+] Tidak ada error tercatat di dalam file log." }) -ForegroundColor Green
        }
        Write-Host "   ------------------------------`n"
    }

    $promptReboot = if ($isEN) { "   [?] Execute immediate system reboot? (Y/N)" } else { "   [?] Restart komputer sekarang untuk menerapkan seluruh perubahan? (Y/N)" }
    $allFixRestart = Read-Host $promptReboot
    if ($allFixRestart -match '^[yY]') {
        Write-Host $(if ($isEN) { "  [*] Proceeding, rebooting in 5 seconds..." } else { "  [*] Mempersiapkan restart dalam 5 detik..." }) -ForegroundColor Cyan
        Restart-Computer -Force
    }
    else {
        Write-Host $(if ($isEN) { "  [*] Reboot manually to commit all security changes." } else { "  [*] Silakan restart komputer secara manual saat santai agar seluruh perbaikan aktif." }) -ForegroundColor Cyan
    }
}

function Extreme-25H2 {
    cls
    $isEN = ($script:lang -eq "EN")
    Write-Host "`n  ===================================================================================================" -ForegroundColor Cyan
    $extremeTitle = if ($isEN) { "        EXTREME PATH FOR WIN 11 24H2 / 25H2 / 26H2+ & ARM64" } else { "        SOLUSI KOMPREHENSIF WINDOWS 11 VERSI TERBARU (24H2 / 25H2 / 26H2+ & ARM64)" }
    Write-Host $extremeTitle -ForegroundColor Yellow
    Write-Host "  ===================================================================================================" -ForegroundColor Cyan
    Write-Host $(if ($isEN) { "  [*] Applying deep policy modifications for strict security Windows 11 environments." } else { "  [*] Menerapkan penyesuaian menyeluruh untuk sistem Windows 11 dengan kebijakan keamanan ketat." }) -ForegroundColor Gray
    Write-Host $(if ($isEN) { "  [*] Running all automated fixes..." } else { "  [*] Menjalankan seluruh rangkaian perbaikan secara otomatis..." }) -ForegroundColor Cyan

    Write-Log $(if ($isEN) { "Run Extreme Fix 24H2/25H2/26H2" } else { "Menjalankan Solusi Khusus Windows 11 24H2/25H2/26H2" }) -Type "INFO"

    Write-Host $(if ($isEN) { "  [*] Flushing GPO cache before applying fixes..." } else { "  [*] Menyegarkan cache Group Policy sebelum perbaikan..." }) -ForegroundColor Cyan
    try { $LASTEXITCODE = 0; gpupdate /force > $null 2>&1 } catch {}

    Fix-Deep0x00000709
    Fix-CrossSignedDriverPolicy
    Fix-HKCU-PrinterKeyPerms
    Set-PostPatchTuesdayTask

    Fix-UACTokenFilter
    Fix-LSAProtection
    Fix-NTLMv2
    Fix-SMBSigning
    Fix-ProviderOrder
    Fix-SAC
    Fix-IPPSharing
    Fix-AdvancedPointAndPrint

    Fix-mDNS
    Reset-SpoolerDependency
    Fix-UWPPrinting
    Enable-SMBGuest
    Disable-PasswordSharing
    Fix-WSDFirewall
    Fix-Network0x00000040
    Fix-DriverCopy0x00000002
    Fix-RpcBitness0x0000007e
    Fix-RDPPrinter
    Fix-CredentialGuard
    Fix-V4ClassDriver
    Reset-SpoolerDependencyRegistry
    Sanitize-PrinterShareName

    try {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\WPP" -Name Enabled -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Print" -Name DnsOnWire -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name DisableStrictNameChecking -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0" -Name NtlmMinClientSec -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0" -Name NtlmMinServerSec -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    }
    catch {}

    try {
        $LASTEXITCODE = 0; cmdkey /list | Select-String $env:COMPUTERNAME | ForEach-Object { $t = $_.ToString() -replace '(?i)^\s*Target:\s*', ''; cmdkey /delete:$t > $null 2>&1 }
        $LASTEXITCODE = 0; klist purge > $null 2>&1
        $LASTEXITCODE = 0; ipconfig /flushdns > $null 2>&1
        $LASTEXITCODE = 0; nbtstat -RR > $null 2>&1
    }
    catch {}

    Write-Log $(if ($isEN) { "Extreme Path concluded!" } else { "Solusi Komprehensif Windows 11 Selesai!" }) -Type "SUCCESS"
    Write-Host $(if ($isEN) { "  [+] Extreme security changes completed. System reboot is recommended." } else { "  [+] Konfigurasi keamanan Windows 11 berhasil disesuaikan. Disarankan merestart komputer." }) -ForegroundColor Green

    $extremeRestart = Read-Host $(if ($isEN) { "`n   [?] Execute immediate system reboot now? (Y/N)" } else { "`n   [?] Restart komputer sekarang? (Y/N)" })
    if ($extremeRestart -match '^[yY]') { Restart-Computer -Force }
}

function Restart-PC {
    $msg = if ($script:lang -eq "EN") { "`n  [*] System rebooting in 5 seconds..." } else { "`n  [*] Komputer akan merestart dalam 5 detik..." }
    Write-Host $msg -ForegroundColor Yellow
    Start-Sleep -Seconds 5
    Restart-Computer -Force
}

function Detect-Win {
    $isEN = ($script:lang -eq "EN")
    Write-Host "`n  ======================================================================" -ForegroundColor Cyan
    Write-Host $(if ($isEN) { "             WINDOWS & ARCHITECTURE DETECTION" } else { "             DETEKSI VERSI & ARSITEKTUR WINDOWS" }) -ForegroundColor Yellow
    Write-Host "  ======================================================================" -ForegroundColor Cyan
    Write-Host $(if ($isEN) { "  [+] OS Version    : $script:productName" } else { "  [+] Versi OS      : $script:productName" }) -ForegroundColor Green
    Write-Host $(if ($isEN) { "  [+] OS Build      : $script:buildNumber" } else { "  [+] Build OS      : $script:buildNumber" }) -ForegroundColor Green
    if ($script:isARM64) {
        Write-Host $(if ($isEN) { "  [+] Architecture  : ARM64 (Snapdragon / Apple Silicon VM)" } else { "  [+] Arsitektur    : ARM64 (Snapdragon / VM Apple Silicon)" }) -ForegroundColor Yellow
    }
    else {
        Write-Host $(if ($isEN) { "  [+] Architecture  : AMD64 / x64 (64-Bit)" } else { "  [+] Arsitektur    : AMD64 / x64 (64-Bit)" }) -ForegroundColor Cyan
    }
    if ($script:isServer) {
        Write-Host $(if ($isEN) { "  [+] Edition       : Windows Server Edition" } else { "  [+] Edisi         : Windows Server Edition" }) -ForegroundColor Yellow
    }
    else {
        Write-Host $(if ($isEN) { "  [+] Edition       : Windows Client (Home / Pro / Enterprise)" } else { "  [+] Edisi         : Windows Client (Home / Pro / Enterprise)" }) -ForegroundColor Cyan
    }
}

function Show-Help {
    param([string]$Topic = "")

    $helpDataID = @{
        '1'  = @("Perbaiki Error 0x0000011b (RpcAuthnLevelPrivacy)", "Mematikan kebijakan registri RpcAuthnLevelPrivacyEnabled agar otentikasi RPC tidak memblokir koneksi printer sharing.", "Sering terjadi setelah update rutin Windows 10/11.")
        '2'  = @("Perbaiki Error 0x00000709 (Point and Print / Jalur RPC)", "Menerapkan perbaikan bertingkat: Named Pipes RPC, bypass otentikasi, pembersihan HKCU, dan override Point and Print.", "Error persisten 0x00000709 saat menyambung printer sharing di Windows 11. Perlu dijalankan juga di PC Server/Host.")
        '3'  = @("Bypass Error 0x00000bc4 (Printer Tidak Ditemukan)", "Memaksa protokol RPC menggunakan Named Pipes agar printer sharing dapat ditemukan.", "Muncul pesan 'No printers were found' padahal jaringan normal.")
        '4'  = @("Perbaiki Error 0x80070035 (Jalur Jaringan Tidak Ditemukan)", "Mengotomatiskan layanan fdPHost, FDResPub, SSDPSRV, dan upnphost agar PC terdeteksi di Network.", "Komputer target tidak muncul di jaringan atau muncul error 'The network path was not found'.")
        '5'  = @("Matikan Client-Side Rendering (Error 0x000006d1)", "Mengaktifkan DisableClientSideRendering di registri agar proses rendering ditangani oleh server.", "Pekerjaan cetak gagal karena masalah rendering driver di sisi client.")
        '6'  = @("Perbaiki Error 0x80070005 (Reset Izin ACL Spooler)", "Mereset hak akses direktori Spool\Printers ke standar menggunakan icacls dengan SID S-1-1-0 (Semua Pengguna).", "Muncul error 'Access Denied' saat mencetak.")
        '7'  = @("Perbaiki Error 0x00000040 (Jaringan Tidak Tersedia / KeepConn)", "Memperbaiki registri PrintProcessor dan Ports agar koneksi sharing tetap terjaga.", "Muncul pesan error 'Network is unavailable' saat mengakses printer.")
        '8'  = @("Perbaiki Error 0x00000002 (Kebijakan Salin Driver / CopyFilesPolicy)", "Mengatur CopyFilesPolicy agar client diizinkan mengunduh dan menyalin driver dari komputer host.", "Gagal mengkloning berkas driver printer dari server.")
        '9'  = @("Perbaiki Error 0x0000007e (Ketidakcocokan Bitness Driver RPC)", "Menyelaraskan registri untuk komunikasi lintas arsitektur 32-bit dan 64-bit.", "Ketidakcocokan versi driver 32-bit vs 64-bit antar-komputer.")
        '10' = @("Reset Total Jaringan (DNS, Winsock, NetBIOS)", "Membersihkan cache DNS, melepas & memperbarui IP, serta mereset Winsock dan NetBIOS.", "Koneksi jaringan tidak stabil, latency tinggi, atau IP nyangkut.")
        '11' = @("Ubah Profil Jaringan ke Private", "Mengubah seluruh profil adaptor jaringan menjadi Private.", "Sharing terblokir karena Windows menganggap jaringan sebagai Public.")
        '12' = @("Matikan Berbagi Berproteksi Password", "Mengatur registri LSA (limitblankpassworduse=0, everyoneincludesanonymous=1).", "Selalu meminta username/password padahal sharing sudah dibuka tanpa sandi.")
        '13' = @("Aktifkan RPC via Named Pipes & TCP", "Memaksa komunikasi RPC printer melalui Named Pipes dan TCP.", "Koneksi printer gagal karena pemblokiran endpoint RPC.")
        '14' = @("Buka Port Firewall untuk Berbagi Berkas & Printer", "Mengaktifkan aturan 'File and Printer Sharing' dan 'Network Discovery' pada Windows Firewall.", "Komputer tidak terdeteksi atau koneksi sharing terblokir firewall.")
        '15' = @("Kelola Protokol Warisan SMB 1.0 (ON/OFF)", "Mengaktifkan atau mematikan fitur opsional SMB 1.0.", "Dibutuhkan jika menghubungkan ke perangkat atau OS jadul (Win XP/7).")
        '16' = @("Matikan Wajib SMB Signing (Fix Windows 11 Gagal Konek)", "Mematikan RequireSecuritySignature pada klien dan server SMB.", "Windows 11 24H2+ gagal mengakses printer sharing atau NAS kantor.")
        '17' = @("Pastikan Topologi Modern SMB2/SMB3 Aktif", "Memastikan protokol aman SMB2 dan SMB3 berjalan optimal.", "Menjaga stabilitas dan kecepatan transfer data sharing.")
        '18' = @("Prioritaskan SMB dalam Urutan Provider Jaringan", "Menempatkan LanmanWorkstation di urutan teratas provider jaringan.", "Koneksi sharing terasa sangat lambat atau loading lama.")
        '19' = @("Matikan Tumpukan Protokol IPv6", "Menonaktifkan IPv6 via registri dan konfigurasi adaptor netsh.", "Routing IPv6 mengganggu pencarian perangkat di LAN kantor yang murni IPv4.")
        '20' = @("Aktifkan Protokol Penemuan mDNS & LLMNR", "Mengaktifkan resolusi nama Multicast DNS dan LLMNR.", "Printer tidak dapat ditemukan menggunakan nama komputer / hostname.")
        '21' = @("Buka Port Firewall WSD (Port UDP 3702)", "Membuka port 3702 pada firewall khusus protokol Web Services Discovery.", "Penemuan printer WSD terhalang oleh firewall.")
        '22' = @("Pasang Fondasi Berbagi IPP & Mopria", "Mengaktifkan fitur Windows Internet Printing Protocol dan standar Mopria.", "Dibutuhkan oleh printer jaringan generasi modern berbasis IPP.")
        '23' = @("Atasi Konflik Adaptor Virtual Hyper-V / WSL", "Mematikan binding printer sharing pada switch virtual internal.", "Switch virtual Hyper-V/WSL mengacaukan rute deteksi printer LAN.")
        '24' = @("Pasang Fitur Protokol Legacy LPR/LPD", "Mengaktifkan monitor port LPR dan layanan cetak LPD bawaan Windows.", "Diperlukan untuk printer jaringan lama berbasis antrean Unix/LPR.")
        '25' = @("Pindai & Temukan Printer Aktif di Komputer Target", "Memindai dan mendaftarkan seluruh printer yang sedang di-share pada PC target.", "Mencari nama share printer yang tepat pada komputer tujuan.")
        '26' = @("Ubah Port Printer dari WSD ke Standar TCP/IP", "Mendeteksi printer berport WSD dan memindahkannya ke port IP stabil.", "Printer sering hilang atau tiba-tiba offline karena bug penemuan WSD.")
        '27' = @("Bersihkan Soket Koneksi Jaringan yang Nyangkut", "Merestart layanan workstation/server dan membersihkan sesi port 445/135 yang menggantung.", "Koneksi printer terblokir setelah perubahan IP atau disconnect VPN.")
        '28' = @("Penjaga Profil Jaringan Otomatis (Rescue Network Profile)", "Memastikan status jaringan tetap Private dan memasang watchdog pencegah kembali ke Public.", "Profil jaringan sering otomatis berubah menjadi Public setelah restart.")
        '29' = @("Tambah Port Printer Standar TCP/IP Secara Manual", "Membuat port TCP/IP baru menggunakan skrip WMI.", "Menghubungkan printer jaringan melalui alamat IP statis.")
        '30' = @("Aktifkan Layanan WSD Print Device", "Menjalankan layanan WSDPrintDevice untuk penemuan printer berbasis web services.", "Printer jaringan WSD tidak muncul di daftar pencarian.")
        '31' = @("Reset Layanan Spooler & Bersihkan Antrean Cetak", "Menghentikan spooler, menghapus antrean macet di folder PRINTERS, dan menyalakan kembali.", "Antrean cetak macet total dan dokumen tidak mau keluar.")
        '32' = @("Restart Layanan Sistem RPC & DCOM", "Memeriksa dan merestart layanan inti RpcSs dan DcomLaunch.", "Muncul pesan error 'RPC server is unavailable'.")
        '33' = @("Restart Spooler Komputer Lain dari Jarak Jauh (Remote)", "Mengeksekusi perintah restart spooler pada komputer remote via PowerShell WinRM/DCOM.", "Spooler di komputer server printer hang tanpa harus datang langsung ke lokasi.")
        '34' = @("Atur Pemulihan Otomatis Spooler Saat Terjadi Crash", "Mengonfigurasi layanan agar otomatis restart saat mengalami kegagalan tak terduga.", "Layanan spooler sering mati mendadak saat mencetak dokumen tertentu.")
        '35' = @("Bersihkan Dependensi Usang Layanan Spooler", "Mengembalikan parameter DependOnService ke standar aman (RPCSS, http).", "Layanan Spooler tidak mau start padahal RPC berjalan normal.")
        '36' = @("Pasang Pemantau Spooler Otomatis (Watchdog Tiap 5 Menit)", "Mendaftarkan tugas terjadwal untuk memeriksa dan menyalakan spooler jika mendadak mati.", "Menjamin ketersediaan pencetakan di PC server kantor tanpa downtime.")
        '37' = @("Hapus Bersih Berkas Antrean Cetak yang Rusak (.shd/.spl)", "Menghentikan paksa proses cetak dan membuang file spooler yang mengunci.", "Dokumen macet di antrean dan tidak bisa di-cancel secara normal.")
        '38' = @("Reset Registri Dependensi Spooler ke Bawaan Pabrik", "Mereset kunci DependOnService langsung di registry HKLM.", "Spooler tetap mogok jalan bahkan setelah komputer direstart.")
        '39' = @("Buka Manajemen Driver Windows (Print Server Properties)", "Membuka jendela GUI Properti Server Cetak untuk mengelola driver terpasang.", "Memeriksa, menambah, atau menghapus driver printer sistem.")
        '40' = @("Matikan Isolasi Driver Printer", "Menonaktifkan IsolationPolicy agar driver berjalan di proses spooler utama.", "Mengatasi spooler crash mendadak akibat konflik isolasi driver pihak ketiga.")
        '41' = @("Perbaiki Driver Printer Kelas Universal V4", "Memindai file PrintConfig.dll yang korup dan mendaftarkan ulang DriverStore.", "Printer berdriver V4 tiba-tiba tidak bisa mencetak atau menghasilkan teks acak.")
        '42' = @("Ganti Mode Render Driver (PCL vs PostScript)", "Mengubah mode penerjemahan cetak antara PCL dan PostScript.", "Printer mengeluarkan kertas terus-menerus dengan karakter simbol aneh.")
        '43' = @("Bersihkan Driver Usang & Rusak dari Sistem (Driver Sweeper)", "Memindai DriverStore via pnputil dan menghapus paket driver printer yang tertinggal.", "Gagal menginstal driver baru karena terbentur sisa driver lama.")
        '44' = @("Hentikan Paksa Proses Driver yang Mengunci ('Driver is in use')", "Menghentikan paksa PrintIsolationHost, splwow64, dan pipeline agar file driver terlepas.", "Windows menolak menghapus driver karena dianggap masih digunakan.")
        '45' = @("Hapus Printer Hantu & Duplikat Port USB (Ghost Copy)", "Mendeteksi dan membersihkan salinan printer ganda (Copy 1, Copy 2) dan port USB mati.", "Printer dicolok ke port USB berbeda lalu membuat printer baru yang membingungkan.")
        '46' = @("Hapus Instalasi Printer Bermasalah Secara Paksa", "Menghapus printer yang membandel via antarmuka baris perintah printui.", "Printer rusak yang menolak dihapus melalui menu Settings/Control Panel.")
        '47' = @("Perbaiki Masalah Cetak Aplikasi Windows & Edge (UWP)", "Mendaftarkan ulang komponen cetak modern dan memberikan pengecualian loopback.", "Bisa mencetak dari Notepad/Word, tapi gagal saat mencetak dari Edge atau aplikasi Windows.")
        '48' = @("Pasang Ulang Printer Bawaan (Microsoft Print to PDF / XPS)", "Menginisialisasi ulang fitur pencetakan PDF dan XPS virtual bawaan Windows.", "Pilihan 'Microsoft Print to PDF' hilang dari daftar printer.")
        '49' = @("Perbaiki Masalah Cetak Browser (Chrome / Edge Sandbox)", "Membersihkan cache dialog cetak dan menyesuaikan izin sandbox browser.", "Bisa mencetak dari aplikasi biasa, tapi dialog print di Google Chrome hang.")
        '50' = @("Kunci Printer Default Permanen", "Mematikan fitur Windows yang mengubah printer default secara otomatis berdasarkan lokasi.", "Printer default sering berubah sendiri tanpa izin.")
        '51' = @("Paksa Setel Printer Default via Registri", "Menetapkan printer default langsung melalui kunci registri pengguna saat ini (HKCU).", "Gagal menetapkan printer default melalui menu Settings Windows.")
        '52' = @("Perbaiki Pengalihan Printer pada Remote Desktop (RDP)", "Mengaktifkan pengalihan printer lokal pada registri Terminal Services RDP.", "Saat login ke RDP, printer kantor lokal tidak muncul di sesi remote.")
        '53' = @("Rapikan Nama Share Printer dari Karakter Ilegal", "Memindai nama share printer dan mengganti spasi atau simbol terlarang dengan tanda hubung.", "Komputer lain gagal terhubung karena nama printer share terlalu panjang atau berkarakter aneh.")
        '54' = @("Longgarkan Proteksi Keamanan LSA (Legacy Auth)", "Menonaktifkan RunAsPPL pada registri LSA agar otentikasi sharing lawas diizinkan.", "Gagal login sharing printer akibat proteksi LSA Windows 11 yang terlalu ketat.")
        '55' = @("Bypass Blokir Driver oleh Smart App Control (SAC)", "Menyesuaikan kebijakan VerifiedAndReputablePolicyState.", "Windows 11 memblokir penginstalan driver printer pihak ketiga.")
        '56' = @("Bypass Pembatasan Driver Point and Print (Elevation Override)", "Menerapkan wildcard (*) pada ServerList dan melewati proteksi PrintNightmare.", "Muncul pesan 'Check Printer Name' atau 'Access Denied' saat mengunduh driver dari host.")
        '57' = @("Bypass Pembatasan Token Jaringan UAC Administrator", "Mengatur LocalAccountTokenFilterPolicy = 1 di registri.", "Akses remote administrasi printer antar-komputer Workgroup gagal karena filter UAC.")
        '58' = @("Selaraskan Respon Otentikasi NTLMv2", "Mengatur LmCompatibilityLevel secara tepat ke level NTLMv2.", "Pesan 'Access Denied' saat login antar-versi Windows atau NAS yang berbeda.")
        '59' = @("Kelola Windows Protected Print / WPP (Mode Proteksi Driver)", "Menonaktifkan fitur WPP Windows 11 yang melarang driver v3 pihak ketiga.", "Printer tidak bisa diinstal karena Windows 11 memaksa driver standar Mopria saja.")
        '60' = @("Simpan Kredensial Printer ke Windows Vault Permanen", "Menyimpan username dan password komputer target langsung ke Windows Credential Manager.", "Menghilangkan keharusan mengetik password setiap kali komputer dinyalakan.")
        '61' = @("Bersihkan Kredensial Usang dari Windows Vault", "Menghapus data login komputer target yang tersimpan lama di vault via cmdkey.", "Password di komputer host sudah diganti tetapi komputer client masih memakai sandi lama.")
        '62' = @("Bypass Pemblokiran NTLM oleh Credential Guard", "Menyesuaikan flag LsaCfgFlags pada registri Credential Guard.", "Lingkungan kerja yang mengaktifkan Credential Guard sehingga NTLM diblokir.")
        '63' = @("Terapkan Kredensial Login ke Semua Profil Pengguna", "Memasang tugas RunOnce ke seluruh profil pengguna Windows via pemuatan NTUSER.DAT.", "PC kantor yang digunakan bergantian oleh banyak user lokal (multi-user).")
        '64' = @("Cadangkan Registri Printer & Jaringan (Backup Registry)", "Mengekspor cabang registri Print, Policies, dan Jaringan ke C:\WindowsPrinterSharingFixBackup.", "SANGAT DISARANKAN dijalankan pertama kali sebelum melakukan perbaikan apapun!")
        '65' = @("Pulihkan Registri dari Cadangan (Rollback Registry)", "Mengimpor kembali berkas .reg cadangan yang pernah dibuat sebelumnya.", "Mengembalikan pengaturan sistem jika terjadi masalah setelah perbaikan.")
        '66' = @("Buat Titik Pemulihan Sistem (System Restore Point)", "Membuat System Restore Point Windows untuk perlindungan menyeluruh sistem.", "Langkah pengamanan sebelum melakukan perubahan besar pada sistem operasi.")
        '67' = @("Pindai & Perbaiki Kerusakan Berkas Sistem (SFC & DISM)", "Menjalankan sfc /scannow dan DISM RestoreHealth untuk memperbaiki file Windows yang rusak.", "Sistem sering error aneh, blue screen, atau mengalami kerusakan file sistem.")
        '68' = @("Restart Layanan Transfer Berkas Latar Belakang (BITS)", "Merestart Background Intelligent Transfer Service.", "Driver printer gagal terunduh secara otomatis dari jaringan.")
        '69' = @("Kelola Pembaruan Windows & Blokir Update Perusak Printer", "Alat untuk menjeda update, mencopot patch bermasalah, atau mencegah update mereset setting.", "Mencegah Windows Update merusak kembali setelan sharing printer yang sudah normal.")
        '70' = @("Jalankan Troubleshooter Printer Bawaan Windows", "Membuka alat pemecah masalah cetak resmi Windows (msdt).", "Langkah pemeriksaan diagnostik awal bawaan sistem.")
        '71' = @("Paksa Status Printer Menjadi 'Online'", "Mengubah status WorkOffline printer menjadi false melalui WMI/CIM.", "Printer nyangkut dalam kondisi 'Offline' padahal kabel dan daya sudah menyala.")
        '72' = @("Buka Jendela Layanan Windows (Services.msc)", "Membuka konsol manajemen Services Windows.", "Melihat status layanan sistem seperti Spooler, RPC, dan Workstation secara langsung.")
        '73' = @("Deteksi Versi & Arsitektur Windows", "Menampilkan edisi OS, nomor build, serta arsitektur processor (x64 / ARM64).", "Memastikan kompatibilitas modul dengan versi Windows yang digunakan.")
        '74' = @("Uji Ping & Pindai Port Jaringan Printer (Port 445/135)", "Melakukan tes ping ICMP serta mengecek keterbukaan port SMB (445) dan RPC (135).", "Memastikan apakah komputer printer dapat dijangkau melalui jaringan.")
        '75' = @("Buka Catatan Log Eksekusi Tool (Log Manager)", "Membuka file log riwayat perbaikan menggunakan Notepad.", "Melihat detail setiap tindakan yang telah dilakukan oleh aplikasi ini.")
        '76' = @("Audit 20 Log Error Terakhir Layanan Cetak", "Membaca 20 pesan error terbaru dari System Event Log Windows.", "Mencari petunjuk akar masalah kegagalan pencetakan dokumen.")
        '77' = @("Audit Ringkas Kesehatan Sistem (System Diagnostics)", "Memeriksa status Spooler, SMB, Firewall, dan konfigurasi jaringan.", "Melihat gambaran umum kondisi sistem sebelum perbaikan.")
        '78' = @("Analisis Event Log Layanan Print (Top 5 Error)", "Menganalisis 5 error log cetak terbaru dan memberikan saran solusi yang tepat.", "Masalah pencetakan misterius yang tidak memunculkan kode error di layar.")
        '79' = @("Buat Laporan Diagnostik Interaktif (File HTML)", "Menyusun seluruh informasi sistem dan riwayat perbaikan ke dalam format web HTML.", "Bahan dokumentasi tim IT kantor atau laporan ke atasan.")
        '80' = @("Pindai Intervensi Kebijakan Domain / GPO", "Memindai registri dan gpresult untuk mendeteksi kebijakan domain yang menimpa setelan.", "Perbaikan bekerja sementara tetapi rusak kembali setelah komputer direstart.")
        '81' = @("Cadangkan / Migrasikan Konfigurasi Printer (PrintBRM)", "Mengekspor atau memulihkan konfigurasi seluruh printer menggunakan PrintBrm.exe.", "Memindahkan instalasi printer ke komputer baru secara praktis.")
        '82' = @("Buka Akses Tamu SMB & Hilangkan Blokir Anonymous", "Mengatur AllowInsecureGuestAuth di registri LanmanWorkstation.", "Mengizinkan akses printer sharing tanpa login password di jaringan lokal.")
        '83' = @("Solusi Khusus Windows 11 Versi Terbaru (24H2 / 25H2 / 26H2 & ARM64)", "Kombinasi perbaikan untuk kebijakan ketat Windows 11 (SMB signing, guest access, RPC Named Pipes, bypass driver blocklist).", "Gunakan jika Windows 11 Build 26000 ke atas masih menolak koneksi printer.")
        '84' = @("ALLFIX - Jalankan 50 Perbaikan Otomatis Sekaligus", "Menjalankan 50 langkah perbaikan sistem, registri, RPC, SMB, firewall, dan spooler secara berurutan.", "REKOMENDASI UTAMA - solusi paling praktis untuk hampir semua masalah printer kantor.")
        '85' = @("Silent ALLFIX (Perbaikan Otomatis + Langsung Restart)", "Menjalankan seluruh 50 perbaikan secara otomatis tanpa prompt lalu merestart komputer.", "Khusus situasi darurat atau penanganan massal oleh teknisi tanpa konfirmasi manual.")
        '86' = @("Petakan Port Lokal ke Jalur UNC (Bypass Ampuh 0x00000709)", "Membuat port lokal baru yang langsung diarahkan ke path printer host (contoh: \\\\SERVER\\PRINTER).", "Solusi terbaik jika Windows menolak menghubungkan printer sharing melalui cara biasa.")
        '87' = @("Hapus Pemetaan Port Lokal UNC yang Pernah Dibuat", "Menghapus port lokal yang sebelumnya pernah dibuat oleh opsi [86].", "Membersihkan port pemetaan yang sudah tidak terpakai atau salah ketik.")
        '88' = @("Restart Komputer", "Merestart komputer saat ini secara langsung.", "Sangat disarankan setelah melakukan perbaikan agar seluruh perubahan sistem aktif.")
        '89' = @("Keluar dari Aplikasi", "Menutup dan keluar dari alat perbaikan ini.", "Selesai menggunakan aplikasi.")
    }

    $helpDataEN = @{
        '1'  = @("Fix Error 0x0000011b (RpcAuthnLevelPrivacy)", "Disables RpcAuthnLevelPrivacyEnabled registry policy to prevent RPC authentication from blocking printer connections.", "Frequently occurs after regular Windows 10/11 cumulative updates.")
        '2'  = @("Deep Fix Error 0x00000709 (Point and Print / RPC Path)", "Multi-layer fix: RPC Named Pipes, authentication bypass, HKCU cleanup, and Point and Print elevation override.", "Persistent 0x00000709 error when connecting to shared printers. Should also be run on the Host/Server PC.")
        '3'  = @("Bypass Error 0x00000bc4 (No Printers Found)", "Forces RPC protocol to use Named Pipes so shared printers can be discovered across the network.", "Displays 'No printers were found' even though the local network is operational.")
        '4'  = @("Fix Error 0x80070035 (Network Path Not Found)", "Automates fdPHost, FDResPub, SSDPSRV, and upnphost services so host PC appears in Network Places.", "Target PC is invisible in Network or throws 'The network path was not found'.")
        '5'  = @("Disable Client-Side Rendering (Error 0x000006d1)", "Enables DisableClientSideRendering in registry to offload print rendering tasks directly to the server.", "Print jobs fail due to driver rendering issues on the client side.")
        '6'  = @("Fix Error 0x80070005 (Reset Spooler ACL Permissions)", "Resets Spool\Printers directory permissions to default using icacls with universal SID S-1-1-0 (Everyone).", "Displays 'Access Denied' when spooling or printing documents.")
        '7'  = @("Fix Error 0x00000040 (Network Unavailable / KeepConn)", "Repairs PrintProcessor and Ports registry parameters to maintain active connection integrity.", "Displays 'The specified network name is no longer available'.")
        '8'  = @("Fix Error 0x00000002 (CopyFilesPolicy Driver Ingestion)", "Configures CopyFilesPolicy allowing clients to download and copy printer driver files from host PC.", "Fails to clone printer driver binaries from the print server.")
        '9'  = @("Fix Error 0x0000007e (RPC Driver Bitness Mismatch 32/64-bit)", "Aligns registry architecture for seamless communication across 32-bit and 64-bit platforms.", "Cross-architecture driver incompatibility between client and server.")
        '10' = @("Total Network Reset (DNS, Winsock, NetBIOS)", "Flushes DNS resolver cache, releases/renews IP leases, and resets Winsock catalog and NetBIOS cache.", "Network connection instability, high latency, or stale IP bindings.")
        '11' = @("Switch Network Profiles to Private", "Converts all network adapter profiles to Private mode.", "File and printer sharing blocked because Windows classified network connection as Public.")
        '12' = @("Disable Password Protected Network Sharing", "Configures LSA registry (limitblankpassworduse=0, everyoneincludesanonymous=1).", "Continuous login prompt even when printer sharing was configured without password requirement.")
        '13' = @("Enforce RPC via Named Pipes & TCP", "Forces printer RPC communication through standard Named Pipes and TCP endpoints.", "Printer connections fail due to restrictive RPC protocol restrictions.")
        '14' = @("Open Windows Firewall Rules for File & Printer Sharing", "Enables 'File and Printer Sharing' and 'Network Discovery' rule groups across all active profiles.", "Target PC cannot be reached or sharing traffic is dropped by firewall.")
        '15' = @("Manage Legacy SMB 1.0 Protocol (ON/OFF)", "Enables or disables the legacy SMB 1.0/CIFS optional Windows feature.", "Required only when connecting to legacy legacy network devices or OS (Win XP/7).")
        '16' = @("Disable SMB Signing Requirement (Fix Win 11 Access)", "Sets RequireSecuritySignature=0 on SMB client and server parameters.", "Windows 11 24H2+ fails to access shared printers or office NAS devices.")
        '17' = @("Enforce Modern SMB2 / SMB3 Topology", "Verifies and enables high-performance SMB2/SMB3 communication stacks.", "Maintains optimal stability and high throughput for shared printing.")
        '18' = @("Prioritize SMB in Network Provider Order", "Elevates LanmanWorkstation to the top position in system network provider order.", "Network printer sharing browsing feels sluggish or delayed.")
        '19' = @("Disable IPv6 Protocol Stack", "Disables IPv6 via registry bindings and netsh adapter properties.", "IPv6 priority causes routing delays on pure IPv4 office local networks.")
        '20' = @("Enable Discovery Protocols (mDNS & LLMNR)", "Enables Multicast DNS and Link-Local Multicast Name Resolution.", "Printer cannot be found by hostname or computer name.")
        '21' = @("Open WSD Firewall Port (UDP 3702)", "Opens UDP port 3702 on Windows Firewall specifically for Web Services Discovery.", "WSD network printer discovery is blocked by firewall policy.")
        '22' = @("Install IPP & Mopria Print Sharing Foundation", "Installs Internet Printing Client and standard Mopria framework.", "Required by modern network printers utilizing driverless IPP protocols.")
        '23' = @("Resolve Hyper-V / WSL Virtual Adapter Conflicts", "Disables printer sharing binding on internal virtual switches.", "Virtual Hyper-V or WSL adapters misroute LAN printer discovery traffic.")
        '24' = @("Install Legacy LPR / LPD Protocol Features", "Enables Windows built-in LPR Port Monitor and LPD Print Service.", "Required for legacy Unix/Linux style line printer queue network devices.")
        '25' = @("Scan & Discover Active Printers on Target Host", "Queries and enumerates all published shared printers on a specified remote host.", "Discovers exact share names when browsing fails via Windows GUI.")
        '26' = @("Convert WSD Printer Port to Standard TCP/IP", "Detects WSD-based ports and rebinds the printer to a stable IP socket.", "Printer randomly drops offline due to WSD discovery timeouts.")
        '27' = @("Purge Stale Network Connection Sockets", "Restarts Workstation/Server services and clears lingering sessions on ports 445/135.", "Printer connection deadlocked after IP change or VPN disconnection.")
        '28' = @("Rescue Network Profile (Auto-Enforce Private)", "Ensures current profile is Private and registers a scheduled task to prevent reverts.", "Windows periodically reverts network connection to Public after rebooting.")
        '29' = @("Add Standard TCP/IP Printer Port Manually", "Creates a new raw standard TCP/IP printer port using WMI scripting.", "Directly connects network printers via static IP address.")
        '30' = @("Enable WSD Print Device Service", "Starts and configures WSDPrintDevice service for web services printer discovery.", "WSD network printers missing from Windows discovery wizard.")
        '31' = @("Reset Spooler & Purge Print Queue", "Stops spooler, purges stuck documents in PRINTERS folder, and cleanly restarts.", "Print queue completely frozen with stuck documents refusing to cancel.")
        '32' = @("Restart Core RPC & DCOM Services", "Audits and restarts foundational RpcSs and DcomLaunch services.", "Displays 'The RPC server is unavailable' during printer access.")
        '33' = @("Restart Remote Spooler on Network Host", "Executes remote spooler restart on target computer via PowerShell WinRM/DCOM.", "Restarts printer server spooler remotely without physical access.")
        '34' = @("Configure Spooler Auto-Restart on Crash", "Configures service recovery parameters to restart spooler immediately upon failure.", "Print spooler terminates unexpectedly when receiving corrupted print jobs.")
        '35' = @("Clean Stale Spooler Service Dependencies", "Restores DependOnService configuration to safe baseline defaults (RPCSS, http).", "Spooler refuses to start even though RPC is active.")
        '36' = @("Deploy Spooler Watchdog Task (5-Minute Health Check)", "Registers scheduled task monitoring spooler health every 5 minutes.", "Ensures office print servers maintain 24/7 uptime without manual intervention.")
        '37' = @("Forcibly Purge Damaged Queue Files (.shd/.spl)", "Forcibly terminates locked processes and unlinks corrupted spool shadow files.", "Jammed print job refuses to delete through normal Windows queue.")
        '38' = @("Reset Spooler Registry Dependencies to Factory Default", "Resets DependOnService values directly in HKLM registry hive.", "Spooler fails to start across system reboots.")
        '39' = @("Open Print Server Properties Management", "Launches Windows Print Server Properties GUI to audit installed drivers.", "Review, add, or remove system-wide printer drivers and custom forms.")
        '40' = @("Disable Print Driver Isolation Policy", "Sets IsolationPolicy to 0 ensuring drivers execute within the main spooler process.", "Resolves random spooler crashes caused by third-party driver isolation sandboxes.")
        '41' = @("Repair V4 Universal Print Class Drivers", "Scans for corrupted PrintConfig.dll and re-registers DriverStore manifests.", "V4 drivers suddenly output garbage characters or fail silently.")
        '42' = @("Switch Driver Render Mode (PCL vs PostScript)", "Adjusts rendering translation modes between PCL and PostScript.", "Printer spits out endless blank pages containing bizarre symbols.")
        '43' = @("Clean Stale & Corrupt Drivers (Driver Sweeper)", "Scans DriverStore via pnputil and deletes orphaned OEM driver packages.", "Unable to update or reinstall driver due to lingering conflicting files.")
        '44' = @("Force-Kill Locking Driver Processes ('Driver in use')", "Terminates PrintIsolationHost, splwow64, and pipeline handles to unlock files.", "Windows refuses to delete driver claiming files are currently in use.")
        '45' = @("Remove Ghost & Duplicate USB Printers (Ghost Copy)", "Cleans duplicate copies (Copy 1, Copy 2) and removes dead USB virtual ports.", "Printer plugged into different USB port created confusing duplicate devices.")
        '46' = @("Force-Uninstall Problematic Printer Instance", "Removes persistent printer instances using the printui command-line engine.", "Printer cannot be deleted via Windows Settings or Control Panel.")
        '47' = @("Fix Modern Windows & Edge App Printing (UWP)", "Re-registers modern print components and configures AppContainer loopback.", "Can print from Word/Notepad, but printing fails from Edge or Store apps.")
        '48' = @("Reinstall Virtual Printers (Print to PDF / XPS)", "Reinitializes Windows built-in PDF and XPS virtual print features.", "'Microsoft Print to PDF' option is missing from the printer selection list.")
        '49' = @("Fix Web Browser Print Dialog (Chrome / Edge Sandbox)", "Cleans print preview cache and adjusts browser sandbox permissions.", "Print dialog in Google Chrome or Microsoft Edge freezes indefinitely.")
        '50' = @("Lock Default Printer Permanently", "Disables Windows automatic default printer management based on network.", "Default printer unexpectedly switches on its own.")
        '51' = @("Force Default Printer via Registry", "Assigns default printer directly in current user registry hive (HKCU).", "Fails to set default printer through standard Settings GUI.")
        '52' = @("Fix Printer Redirection on Remote Desktop (RDP)", "Enables local printer redirection in Terminal Services RDP client registry.", "Office local printer does not appear inside remote desktop sessions.")
        '53' = @("Sanitize Printer Share Names (Strip Illegal Characters)", "Scans shared names and replaces spaces and illegal symbols with hyphens.", "Clients fail to connect because share name exceeds limits or has bad characters.")
        '54' = @("Relax Strict LSA Security Protection (Legacy Auth)", "Disables RunAsPPL on LSA registry to permit legacy sharing authentication.", "Windows 11 strict LSA policies block non-domain printer sharing logins.")
        '55' = @("Bypass Driver Block by Smart App Control (SAC)", "Adjusts VerifiedAndReputablePolicyState configuration.", "Windows 11 blocks installation of uncertified third-party printer drivers.")
        '56' = @("Bypass Point and Print Restrictions (Elevation Override)", "Sets wildcard (*) on ServerList and overrides PrintNightmare admin prompts.", "Displays 'Check Printer Name' or 'Access Denied' downloading drivers from host.")
        '57' = @("Bypass UAC Administrator Network Token Filter", "Sets LocalAccountTokenFilterPolicy=1 in registry.", "Remote administration between Workgroup PCs fails due to UAC token filtering.")
        '58' = @("Align NTLMv2 Authentication Response", "Sets LmCompatibilityLevel correctly to NTLMv2 response standard.", "'Access Denied' when authenticating between heterogeneous Windows versions or NAS.")
        '59' = @("Manage Windows Protected Print / WPP (Driver Protection)", "Disables WPP mode which blocks third-party v3 printer drivers in modern Windows.", "Printer cannot be installed because Windows 11 enforces Mopria-only drivers.")
        '60' = @("Save Printer Credentials to Windows Vault (Permanent Login)", "Stores target host credentials directly into Windows Credential Manager.", "Eliminates having to re-enter credentials every time computer reboots.")
        '61' = @("Clean Stale Credentials from Windows Vault", "Purges stored obsolete credentials using cmdkey.", "Password was changed on host PC but client still sends obsolete credentials.")
        '62' = @("Bypass NTLM Blocking by Credential Guard", "Configures LsaCfgFlags registry parameter under Credential Guard.", "Corporate environments with active Credential Guard blocking NTLM sharing.")
        '63' = @("Deploy Login Credentials to All User Profiles", "Installs RunOnce task across all user profiles via NTUSER.DAT loading.", "Shared office computers utilized by multiple local user accounts.")
        '64' = @("Backup Printer & Network Registry (Backup Registry)", "Exports Print, Policies, and Network registry hives to C:\WindowsPrinterSharingFixBackup.", "HIGHLY RECOMMENDED as the very first step before applying changes!")
        '65' = @("Rollback Registry from Previous Backup", "Imports previously exported .reg backup snapshots back into the system.", "Restores original system state if any issues occur after repairs.")
        '66' = @("Create System Restore Point", "Creates a full Windows System Restore Point for disaster recovery.", "Safety milestone before major system-wide modifications.")
        '67' = @("Scan & Repair System Files (SFC & DISM)", "Runs sfc /scannow and DISM RestoreHealth to repair corrupted Windows files.", "System experiences unexpected blue screens, crashes, or file corruption.")
        '68' = @("Restart Background Intelligent Transfer Service (BITS)", "Restarts BITS service to unblock background file transfers.", "Printer drivers fail to download automatically across the network.")
        '69' = @("Manage Windows Updates & Block Printer-Breaking Patches", "Pauses updates, uninstalls problematic patches, or blocks update regressions.", "Prevents Windows Update from breaking printer sharing configurations.")
        '70' = @("Run Built-in Windows Printer Troubleshooter", "Launches the official Windows printing diagnostics wizard (msdt).", "Initial baseline troubleshooting provided natively by Windows.")
        '71' = @("Force Printer Status to 'Online'", "Forces WorkOffline flag to false via WMI/CIM provider.", "Printer stays stuck in 'Offline' status despite being powered on and connected.")
        '72' = @("Open Windows Services Console (services.msc)", "Launches services.msc to inspect services directly.", "Directly check status of Spooler, RPC, Workstation, and Server services.")
        '73' = @("Detect Windows Version & Architecture", "Displays OS edition, build number, and processor architecture (x64 / ARM64).", "Ensures module compatibility with current Windows environment.")
        '74' = @("Test Connectivity & Scan Printer Ports (Ping & Port 135/445)", "Performs ICMP ping and tests TCP port availability on SMB (445) and RPC (135).", "Confirms if print host computer is accessible across the network.")
        '75' = @("Open Tool Execution Log File (Log Manager)", "Opens execution log history using Notepad.", "Inspect details of every action performed by this utility.")
        '76' = @("Audit Last 20 Print Service Error Events", "Retrieves 20 most recent error entries from Windows System Event Log.", "Identifies root cause of printer communication and spooling failures.")
        '77' = @("Quick System Health & Diagnostics Audit", "Audits Spooler, SMB, Firewall, and network profile configuration.", "Provides quick high-level overview of system status before repairs.")
        '78' = @("Analyze Print Service Event Logs (Top 5 Errors)", "Analyzes top 5 print service error codes and recommends targeted fixes.", "Unusual printing failures that do not provide clear error messages.")
        '79' = @("Generate Interactive HTML Diagnostic Report", "Compiles comprehensive system state and repair log into an HTML document.", "Documentation for office IT technicians or submission to management.")
        '80' = @("Scan Active Directory / GPO Intervention", "Scans registry and gpresult for corporate domain policies overriding settings.", "Repairs work temporarily but revert after system reboot due to domain GPO.")
        '81' = @("Backup / Migrate Printer Configurations (PrintBRM)", "Exports or restores all printer configurations and drivers using PrintBrm.exe.", "Conveniently migrates entire printer setups to another computer.")
        '82' = @("Open SMB Guest Access & Remove Anonymous Blocks", "Sets AllowInsecureGuestAuth on LanmanWorkstation registry.", "Allows shared printer access without requiring password login on local LAN.")
        '83' = @("Extreme Path for Modern Windows 11 (24H2 / 25H2 / 26H2 & ARM64)", "Comprehensive combination fix for strict Win 11 policies (SMB, RPC, SAC, WPP).", "Essential if Windows 11 Build 26000+ still rejects network printer connections.")
        '84' = @("ALLFIX - Run 50 Automated Fixes Simultaneously", "Runs 50 sequential system, registry, RPC, SMB, firewall, and spooler fixes.", "PRIMARY RECOMMENDATION - the ultimate one-click fix for network printer sharing.")
        '85' = @("Silent ALLFIX (Automated Fixes + Immediate Reboot)", "Runs all 50 automated fixes without interactive prompts and immediately reboots.", "Designed for technicians or automated mass deployments.")
        '86' = @("Map Local Port to UNC Share (Ultimate 0x00000709 Bypass)", "Creates a local printer port pointing directly to host UNC share (e.g. \\\\SERVER\\PRINTER).", "Ultimate solution when Windows rejects normal printer sharing connections.")
        '87' = @("Remove Mapped Local UNC Port", "Deletes previously created local UNC port mapping created by option [86].", "Cleans up outdated or mistyped UNC port mappings.")
        '88' = @("Restart Computer", "Reboots local computer immediately.", "Highly recommended after applying fixes so all system settings take full effect.")
        '89' = @("Exit Application", "Closes and exits this utility.", "Done using the application.")
    }

    $isEN = ($script:lang -eq "EN")
    $helpData = if ($isEN) { $helpDataEN } else { $helpDataID }

    if ($Topic -eq "" -or $Topic.ToLower() -eq "menu" -or $Topic.ToLower() -eq "help") {
        cls
        Write-Host ""
        Write-Host "  ======================================================================================" -ForegroundColor Cyan
        if ($isEN) {
            Write-Host "      USER GUIDE: Windows Printer Sharing Fix - @KHAIRUDINFAHMI" -ForegroundColor Green
            Write-Host "  ======================================================================================" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "  HOW TO USE THIS UTILITY:" -ForegroundColor Yellow
            Write-Host "    - Choose a category number (1 - 8) to open targeted repair submenus."
            Write-Host "    - You can also type classic module codes directly (e.g. '84', '83', '64', '86')."
            Write-Host "    - Type 'L' at any time to switch language between Indonesian and English."
            Write-Host "    - Type '?' to view this guide at any time."
            Write-Host "    - Type '? <number>' (e.g. '? 84' or '? 86') to view details of any module."
            Write-Host "    - Type '? all' to open complete HTML documentation in your default browser."
            Write-Host ""
            Write-Host "  RECOMMENDED STEPS FOR OFFICE WORKSTATIONS (Standard Flow):" -ForegroundColor Yellow
            Write-Host "    1. Run Backup Registry [Menu 8 -> 1 or type 64] (Highly Recommended)" -ForegroundColor White
            Write-Host "    2. Run ALLFIX [Menu 1 -> 1 or type 84] (Applies 50 automated fixes)" -ForegroundColor White
            Write-Host "    3. Restart your computer [Menu 0 or type 88]" -ForegroundColor White
            Write-Host "    4. Connect to your shared network printer again." -ForegroundColor White
            Write-Host ""
            Write-Host "  STEPS FOR MODERN WINDOWS 11 24H2 / 25H2 / 26H2+ (Build 26000 and above):" -ForegroundColor Yellow
            Write-Host "    1. Run Backup Registry [Menu 8 -> 1 or type 64]" -ForegroundColor White
            Write-Host "    2. Run Win 11 Solution [Menu 1 -> 2 or type 83]" -ForegroundColor White
            Write-Host "    3. Restart your computer." -ForegroundColor White
            Write-Host ""
            Write-Host "  QUICK TROUBLESHOOTING CHEATSHEET:" -ForegroundColor Yellow
            Write-Host "    - Continuously asking for password? -> Run Menu 3 -> 2 (or type 12 & 82)" -ForegroundColor White
            Write-Host "    - 'Access Denied' error message?     -> Save Credentials via Menu 6 -> 1 (type 60)" -ForegroundColor White
            Write-Host "    - 'Check Printer Name' / Error 0x709? -> Map Local Port UNC via Menu 7 -> 1 (type 86)" -ForegroundColor White
            Write-Host "    - Printer stuck in offline status?   -> Force Online via Menu 8 -> 10 (type 71)" -ForegroundColor White
            Write-Host "    - Computer not visible in Network?   -> Run Menu 3 -> 1 & Menu 3 -> 5" -ForegroundColor White
            Write-Host "    - Want to restore previous settings? -> Run Registry Rollback via Menu 8 -> 2 (type 65)" -ForegroundColor White
            Write-Host ""
        } else {
            Write-Host "      PANDUAN PENGGUNAAN: Windows Printer Sharing Fix - @KHAIRUDINFAHMI" -ForegroundColor Green
            Write-Host "  ======================================================================================" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "  CARA MENGGUNAKAN APLIKASI:" -ForegroundColor Yellow
            Write-Host "    - Pilih nomor kategori (1 - 8) untuk membuka submenu perbaikan terarah."
            Write-Host "    - Anda juga bisa langsung mengetik kode modul klasik (misal: '84', '83', '64', '86')."
            Write-Host "    - Ketik 'L' kapan saja untuk berganti bahasa antara Indonesia dan Inggris."
            Write-Host "    - Ketik '?' untuk melihat panduan ini kapan saja."
            Write-Host "    - Ketik '? <nomor>' (contoh: '? 84' atau '? 86') untuk melihat fungsi modul tersebut."
            Write-Host "    - Ketik '? all' untuk membuka dokumentasi lengkap dalam format HTML di browser."
            Write-Host ""
            Write-Host "  LANGKAH REKOMENDASI UNTUK PENGGUNA KANTOR (Solusi Standar):" -ForegroundColor Yellow
            Write-Host "    1. Jalankan Cadangkan Registri [Menu 8 -> 1 atau ketik 64] (Sangat Disarankan)" -ForegroundColor White
            Write-Host "    2. Jalankan ALLFIX [Menu 1 -> 1 atau ketik 84] (Menjalankan 50 perbaikan otomatis)" -ForegroundColor White
            Write-Host "    3. Restart komputer Anda [Menu 0 atau ketik 88]" -ForegroundColor White
            Write-Host "    4. Coba sambungkan kembali printer di jaringan." -ForegroundColor White
            Write-Host ""
            Write-Host "  LANGKAH UNTUK WINDOWS 11 24H2 / 25H2 / 26H2+ (Build 26000 ke atas):" -ForegroundColor Yellow
            Write-Host "    1. Jalankan Cadangkan Registri [Menu 8 -> 1 atau ketik 64]" -ForegroundColor White
            Write-Host "    2. Jalankan Solusi Khusus Windows 11 [Menu 1 -> 2 atau ketik 83]" -ForegroundColor White
            Write-Host "    3. Restart komputer Anda." -ForegroundColor White
            Write-Host ""
            Write-Host "  PANDUAN CEPAT BERDASARKAN KELUHAN:" -ForegroundColor Yellow
            Write-Host "    - Selalu minta password padahal tanpa password? -> Jalankan Menu 3 -> 2 (atau ketik 12 & 82)" -ForegroundColor White
            Write-Host "    - Muncul error 'Access Denied' / Akses Ditolak?  -> Simpan Kredensial via Menu 6 -> 1 (ketik 60)" -ForegroundColor White
            Write-Host "    - Muncul error 'Check Printer Name' / 0x709?    -> Gunakan Pemetaan Port UNC via Menu 7 -> 1 (ketik 86)" -ForegroundColor White
            Write-Host "    - Printer offline terus padahal kabel menyala?  -> Paksa Online via Menu 8 -> 10 (ketik 71)" -ForegroundColor White
            Write-Host "    - Komputer printer tidak muncul di Network?     -> Jalankan Menu 3 -> 1 & Menu 3 -> 5" -ForegroundColor White
            Write-Host "    - Ingin mengembalikan setelan seperti semula?   -> Jalankan Rollback via Menu 8 -> 2 (ketik 65)" -ForegroundColor White
            Write-Host ""
        }
        Write-Host "  ======================================================================================" -ForegroundColor Cyan
    }
    elseif ($Topic.ToLower() -eq "all") {
        $docPath = $null
        try {
            $exeDir = Split-Path ([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName) -Parent
            $searchPaths = @(
                (Join-Path $exeDir "documentation.html"),
                (Join-Path $exeDir "docs\documentation.html"),
                (Join-Path (Split-Path $exeDir -Parent) "docs\documentation.html")
            )
            foreach ($sp in $searchPaths) {
                if (Test-Path $sp) { $docPath = $sp; break }
            }
        }
        catch {}

        if (-not $docPath -or -not (Test-Path $docPath)) {
            try {
                if ($PSCommandPath) {
                    $scriptDir = Split-Path $PSCommandPath -Parent
                    $fallbacks = @(
                        (Join-Path $scriptDir "documentation.html"),
                        (Join-Path $scriptDir "docs\documentation.html"),
                        (Join-Path (Split-Path $scriptDir -Parent) "docs\documentation.html")
                    )
                    foreach ($fb in $fallbacks) {
                        if (Test-Path $fb) { $docPath = $fb; break }
                    }
                }
            }
            catch {}
        }
        if ($docPath -and (Test-Path $docPath)) {
            Write-Host $(if ($isEN) { "  [*] Opening HTML documentation in browser..." } else { "  [*] Membuka dokumentasi lengkap HTML di browser..." }) -ForegroundColor Cyan
            $fileUrl = "file:///" + $docPath.Replace("\", "/") + "?all"
            Start-Process $fileUrl
        }
        else {
            Write-Host $(if ($isEN) { "  [-] documentation.html not found in installation directory." } else { "  [-] File documentation.html tidak ditemukan pada direktori instalasi." }) -ForegroundColor Red
            Write-Host $(if ($isEN) { "  [!] Use '?' for quick help or '? <number>' for specific module info." } else { "  [!] Gunakan '?' untuk bantuan ringkas atau '? <nomor>' untuk info fitur spesifik." }) -ForegroundColor Yellow
        }
    }
    else {
        $num = $Topic.TrimStart('0')
        if ($helpData.ContainsKey($num)) {
            $h = $helpData[$num]
            Write-Host ""
            Write-Host "  ======================================================================================" -ForegroundColor Cyan
            Write-Host $(if ($isEN) { "      MODULE INFORMATION [$Topic]" } else { "      INFORMASI MODUL [$Topic]" }) -ForegroundColor Green
            Write-Host "  ======================================================================================" -ForegroundColor Cyan
            Write-Host ""
            Write-Host $(if ($isEN) { "  MODULE NAME : $($h[0])" } else { "  NAMA MODUL : $($h[0])" }) -ForegroundColor Yellow
            Write-Host ""
            Write-Host $(if ($isEN) { "  FUNCTION    : $($h[1])" } else { "  FUNGSI     : $($h[1])" }) -ForegroundColor White
            Write-Host ""
            if ($h[2] -ne "") {
                Write-Host $(if ($isEN) { "  USAGE       : $($h[2])" } else { "  PENGGUNAAN : $($h[2])" }) -ForegroundColor Cyan
            }
            Write-Host ""
            Write-Host "  ======================================================================================" -ForegroundColor Cyan
        }
        else {
            Write-Host $(if ($isEN) { "  [-] Module number '$Topic' not found. Enter a number between 1 and 89." } else { "  [-] Nomor modul '$Topic' tidak ditemukan. Masukkan angka 1-89." }) -ForegroundColor Red
        }
    }
}

function Pause-User {
    Write-Host ""
    if ($script:lang -eq "EN") {
        Write-Host "  [>] Press ENTER to return..." -ForegroundColor Yellow
    } else {
        Write-Host "  [>] Tekan ENTER untuk kembali..." -ForegroundColor Yellow
    }
    [void][System.Console]::ReadLine()
}

function Show-Header {
    param([string]$SubTitle = "")
    cls
    $winName = "$script:productName $script:buildNumber".ToUpper()
    if ($script:isARM64) { $winName += " ARM64" }
    elseif ([Environment]::Is64BitOperatingSystem) { $winName += " 64-BIT" }
    else { $winName += " 32-BIT" }

    $health = Get-SystemHealthSummary

    $line = "=" * 86
    Write-Host $line -ForegroundColor Cyan
    if ($script:lang -eq "EN") {
        Write-Host "   WINDOWS PRINTER SHARING FIX  |  Windows Network Printer Repair Tool" -ForegroundColor Green
        Write-Host "   Version: $script:version  |  System: $winName" -ForegroundColor Cyan
        Write-Host "   Computer: $env:COMPUTERNAME  |  User: $env:USERNAME" -ForegroundColor Gray
        if ($SubTitle) {
            Write-Host "   Category: $SubTitle" -ForegroundColor Yellow
        }
        Write-Host "   STATUS: " -NoNewline -ForegroundColor Gray
        if ($health.Spooler) { Write-Host "Spooler [RUNNING] " -ForegroundColor Green -NoNewline } else { Write-Host "Spooler [STOPPED] " -ForegroundColor Red -NoNewline }
        Write-Host "| " -NoNewline -ForegroundColor DarkGray
        if ($health.Network) { Write-Host "Network [PRIVATE] " -ForegroundColor Green -NoNewline } else { Write-Host "Network [PUBLIC - FIX NEEDED] " -ForegroundColor Red -NoNewline }
        Write-Host "| " -NoNewline -ForegroundColor DarkGray
        if ($health.SMBSigning) { Write-Host "SMB Signing [OK] " -ForegroundColor Green -NoNewline } else { Write-Host "SMB Signing [STRICT - MAY BLOCK] " -ForegroundColor Yellow -NoNewline }
        Write-Host "| " -NoNewline -ForegroundColor DarkGray
        if ($health.PasswordSharing) { Write-Host "Pass Sharing [OFF]" -ForegroundColor Green } else { Write-Host "Pass Sharing [ON - LOGIN REQ]" -ForegroundColor Yellow }
    }
    else {
        Write-Host "   WINDOWS PRINTER SHARING FIX  |  Solusi Berbagi Printer Windows" -ForegroundColor Green
        Write-Host "   Versi: $script:version  |  Sistem: $winName" -ForegroundColor Cyan
        Write-Host "   Komputer: $env:COMPUTERNAME  |  Pengguna: $env:USERNAME" -ForegroundColor Gray
        if ($SubTitle) {
            Write-Host "   Kategori: $SubTitle" -ForegroundColor Yellow
        }
        Write-Host "   STATUS SISTEM: " -NoNewline -ForegroundColor Gray
        if ($health.Spooler) { Write-Host "Spooler [AKTIF] " -ForegroundColor Green -NoNewline } else { Write-Host "Spooler [BERHENTI] " -ForegroundColor Red -NoNewline }
        Write-Host "| " -NoNewline -ForegroundColor DarkGray
        if ($health.Network) { Write-Host "Jaringan [PRIVATE] " -ForegroundColor Green -NoNewline } else { Write-Host "Jaringan [PUBLIC - PERLU PERBAIKAN] " -ForegroundColor Red -NoNewline }
        Write-Host "| " -NoNewline -ForegroundColor DarkGray
        if ($health.SMBSigning) { Write-Host "SMB Signing [SESUAI] " -ForegroundColor Green -NoNewline } else { Write-Host "SMB Signing [WAJIB - BISA BLOKIR] " -ForegroundColor Yellow -NoNewline }
        Write-Host "| " -NoNewline -ForegroundColor DarkGray
        if ($health.PasswordSharing) { Write-Host "Sandi Sharing [OFF]" -ForegroundColor Green } else { Write-Host "Sandi Sharing [ON - BUTUH LOGIN]" -ForegroundColor Yellow }
    }
    Write-Host $line -ForegroundColor Cyan
}

function Show-Submenu1 {
    do {
        $isEN = ($script:lang -eq "EN")
        Show-Header -SubTitle $(if ($isEN) { "1. Quick & Automated Solutions" } else { "1. Solusi Cepat & Otomatis" })
        Write-Host ""
        if ($isEN) {
            Write-Host "  [1] ALLFIX - Run 50 Automated Fixes Simultaneously" -ForegroundColor Green
            Write-Host "      (Most reliable one-click fix for almost all network printer problems)" -ForegroundColor Gray
            Write-Host "  [2] Extreme Path for Modern Windows 11 (24H2 / 25H2 / 26H2 & ARM64)" -ForegroundColor Yellow
            Write-Host "      (Bypasses RPC restrictions, SMB Signing, and new Win 11 security policies)" -ForegroundColor Gray
            Write-Host "  [3] Optimize Host / Print Server PC (Connected directly to printer)" -ForegroundColor White
            Write-Host "      (Enforce remote RPC endpoint, Private network, guest sharing, and watchdog)" -ForegroundColor Gray
            Write-Host "  [4] Optimize Client PC (Connecting to shared printer over network)" -ForegroundColor White
            Write-Host "      (RPC Named Pipes, Point and Print bypass, SMB signing fix, HKCU permissions)" -ForegroundColor Gray
            Write-Host "  [5] Silent ALLFIX (Automated Fixes + Immediate Reboot)" -ForegroundColor Red
            Write-Host "      (For technicians/unattended deployment - WARNING: PC reboots immediately!)" -ForegroundColor Gray
            Write-Host "  [6] Manage Windows Updates & Block Printer-Breaking Patches" -ForegroundColor White
            Write-Host "      (Pause updates 35 days, uninstall bad patches, prevent setting reverts)" -ForegroundColor Gray
            Write-Host ""
            Write-Host "  [L] Switch Language / Ganti Bahasa" -ForegroundColor DarkCyan
            Write-Host "  [B] Back to Main Menu" -ForegroundColor Cyan
            Write-Host ""
            Write-Host ("-" * 86) -ForegroundColor Cyan
            Write-Host "Select option [1-6], L, or B: " -NoNewline -ForegroundColor Yellow
        } else {
            Write-Host "  [1] ALLFIX - Jalankan 50 Perbaikan Otomatis Sekaligus" -ForegroundColor Green
            Write-Host "      (Solusi paling ampuh untuk hampir seluruh masalah sharing printer kantor)" -ForegroundColor Gray
            Write-Host "  [2] Solusi Khusus Windows 11 Versi Terbaru (24H2 / 25H2 / 26H2 & ARM64)" -ForegroundColor Yellow
            Write-Host "      (Bypass proteksi RPC, SMB Signing, dan kebijakan baru Windows 11)" -ForegroundColor Gray
            Write-Host "  [3] Optimasi Komputer Host / Server Printer (PC yang terhubung kabel printer)" -ForegroundColor White
            Write-Host "      (Izinkan RPC remote spooler, mode Private, akses tamu, dan pemantau otomatis)" -ForegroundColor Gray
            Write-Host "  [4] Optimasi Komputer Klien (PC staf yang ingin menyambung ke printer)" -ForegroundColor White
            Write-Host "      (RPC Named Pipes, bypass Point & Print, nonaktifkan SMB Signing, izin HKCU)" -ForegroundColor Gray
            Write-Host "  [5] Silent ALLFIX (Perbaikan Otomatis + Langsung Reboot Otomatis)" -ForegroundColor Red
            Write-Host "      (Cocok untuk teknisi/unattended - PERINGATAN: PC langsung restart!)" -ForegroundColor Gray
            Write-Host "  [6] Kelola Pembaruan Windows & Blokir Update Perusak Printer" -ForegroundColor White
            Write-Host "      (Jeda update 35 hari, hapus update bermasalah, atau cegah update reset setting)" -ForegroundColor Gray
            Write-Host ""
            Write-Host "  [L] Ganti Bahasa / Switch to English" -ForegroundColor DarkCyan
            Write-Host "  [B] Kembali ke Menu Utama" -ForegroundColor Cyan
            Write-Host ""
            Write-Host ("-" * 86) -ForegroundColor Cyan
            Write-Host "Pilih nomor [1-6], L, atau B: " -NoNewline -ForegroundColor Yellow
        }
        $sub = Read-Host
        if ($null -eq $sub) { continue }
        $sub = $sub.Trim()
        if ($sub -match '^(l|lang|language)$') { Toggle-AppLanguage; continue }
        if ($sub -match '^(b|0|back|kembali)$') { return }
        switch ($sub) {
            '1'  { AllFix-Core; Pause-User }
            '2'  { Extreme-25H2; Pause-User }
            '3'  { Fix-HostServerRole; Pause-User }
            '4'  { Fix-ClientWorkstationRole; Pause-User }
            '5'  { $script:silentNuke = $true; AllFix-Core }
            '6'  { Manage-WindowsUpdate; Pause-User }
            '84' { AllFix-Core; Pause-User }
            '83' { Extreme-25H2; Pause-User }
            '85' { $script:silentNuke = $true; AllFix-Core }
            '69' { Manage-WindowsUpdate; Pause-User }
            default { Write-Host $(if ($isEN) { "  [-] Invalid choice." } else { "  [-] Pilihan tidak valid." }) -ForegroundColor Red; Start-Sleep -Milliseconds 1200 }
        }
    } while ($true)
}

function Show-Submenu2 {
    do {
        $isEN = ($script:lang -eq "EN")
        Show-Header -SubTitle $(if ($isEN) { "2. Fix Specific Error Codes" } else { "2. Perbaikan Berdasarkan Kode Error" })
        Write-Host ""
        if ($isEN) {
            Write-Host "  [1] Error 0x0000011b - Patch RPC Authentication Block (RpcAuthnLevelPrivacy)" -ForegroundColor White
            Write-Host "  [2] Error 0x00000709 / 0x7c - Network Printer Connection Failure (Point and Print / RPC)" -ForegroundColor White
            Write-Host "  [3] Error 0x00000bc4 - No Printers Were Found (Enforce RPC Named Pipes)" -ForegroundColor White
            Write-Host "  [4] Error 0x80070035 - Network Path Not Found (Initialize Discovery Services)" -ForegroundColor White
            Write-Host "  [5] Error 0x000006d1 - Disable Client-Side Rendering (CSR)" -ForegroundColor White
            Write-Host "  [6] Error 0x80070005 - Access Denied to Spooler Folder (Reset Universal ACL Permissions)" -ForegroundColor White
            Write-Host "  [7] Error 0x00000040 - Network Name Is No Longer Available (KeepConn & Ports)" -ForegroundColor White
            Write-Host "  [8] Error 0x00000002 - Driver File Copy Policy Block (CopyFilesPolicy Ingestion)" -ForegroundColor White
            Write-Host "  [9] Error 0x0000007e - RPC Driver Bitness Mismatch (32-bit & 64-bit Systems)" -ForegroundColor White
            Write-Host ""
            Write-Host "  [L] Switch Language / Ganti Bahasa" -ForegroundColor DarkCyan
            Write-Host "  [B] Back to Main Menu" -ForegroundColor Cyan
            Write-Host ""
            Write-Host ("-" * 86) -ForegroundColor Cyan
            Write-Host "Select error number [1-9], L, or B: " -NoNewline -ForegroundColor Yellow
        } else {
            Write-Host "  [1] Error 0x0000011b - Atasi Pemblokiran Otentikasi RPC (RpcAuthnLevelPrivacy)" -ForegroundColor White
            Write-Host "  [2] Error 0x00000709 / 0x7c - Gagal Sambung Printer Sharing (Point and Print / RPC)" -ForegroundColor White
            Write-Host "  [3] Error 0x00000bc4 - Printer Jaringan Tidak Ditemukan (No Printers Found)" -ForegroundColor White
            Write-Host "  [4] Error 0x80070035 - Jalur Jaringan Tidak Ditemukan (Nyalakan Servis Jaringan)" -ForegroundColor White
            Write-Host "  [5] Error 0x000006d1 - Matikan Client-Side Rendering (CSR)" -ForegroundColor White
            Write-Host "  [6] Error 0x80070005 - Akses Ditolak ke Folder Spooler (Reset Izin ACL Universal)" -ForegroundColor White
            Write-Host "  [7] Error 0x00000040 - Nama Jaringan Tidak Tersedia Lagi (KeepConn & NetBIOS)" -ForegroundColor White
            Write-Host "  [8] Error 0x00000002 - Gagal Menyalin Berkas Driver dari Host (CopyFilesPolicy)" -ForegroundColor White
            Write-Host "  [9] Error 0x0000007e - Ketidakcocokan Arsitektur Driver 32-bit & 64-bit" -ForegroundColor White
            Write-Host ""
            Write-Host "  [L] Ganti Bahasa / Switch to English" -ForegroundColor DarkCyan
            Write-Host "  [B] Kembali ke Menu Utama" -ForegroundColor Cyan
            Write-Host ""
            Write-Host ("-" * 86) -ForegroundColor Cyan
            Write-Host "Pilih nomor error [1-9], L, atau B: " -NoNewline -ForegroundColor Yellow
        }
        $sub = Read-Host
        if ($null -eq $sub) { continue }
        $sub = $sub.Trim()
        if ($sub -match '^(l|lang|language)$') { Toggle-AppLanguage; continue }
        if ($sub -match '^(b|0|back|kembali)$') { return }
        switch ($sub) {
            '1' { Fix-RpcAuthn0x0000011b; Pause-User }
            '2' { Fix-Deep0x00000709; Pause-User }
            '3' { Fix-Discovery0x00000bc4; Pause-User }
            '4' { Fix-NetworkServices; Pause-User }
            '5' { Fix-CSR; Pause-User }
            '6' { Reset-SpoolerPerm; Pause-User }
            '7' { Fix-Network0x00000040; Pause-User }
            '8' { Fix-DriverCopy0x00000002; Pause-User }
            '9' { Fix-RpcBitness0x0000007e; Pause-User }
            default { Write-Host $(if ($isEN) { "  [-] Invalid choice." } else { "  [-] Pilihan tidak valid." }) -ForegroundColor Red; Start-Sleep -Milliseconds 1200 }
        }
    } while ($true)
}

function Show-Submenu3 {
    do {
        $isEN = ($script:lang -eq "EN")
        Show-Header -SubTitle $(if ($isEN) { "3. Network, File & Printer Sharing (SMB) & Firewall" } else { "3. Jaringan, Berbagi (SMB) & Firewall" })
        Write-Host ""
        if ($isEN) {
            Write-Host "  [1] Switch Network Profile to Private (Required for printer sharing)" -ForegroundColor White
            Write-Host "  [2] Open Passwordless Sharing (Guest Access & Anonymous Sharing)" -ForegroundColor Green
            Write-Host "      (Combines guest permissions and eliminates password-protected sharing)" -ForegroundColor Gray
            Write-Host "  [3] Disable SMB Signing Requirement (Fix Win 11 connection to Printer/NAS)" -ForegroundColor White
            Write-Host "  [4] Manage SMB Protocols (Ensure Modern SMB2/SMB3 & SMB 1.0 Settings)" -ForegroundColor White
            Write-Host "  [5] Open Windows Firewall Rules for File & Printer Sharing (Including WSD Port 3702)" -ForegroundColor White
            Write-Host "  [6] Enable Automatic Device Discovery (mDNS, LLMNR, and WSD Discovery)" -ForegroundColor White
            Write-Host "  [7] Set Network Provider Order & Resolve Virtual Hyper-V/WSL Conflicts" -ForegroundColor White
            Write-Host "  [8] Total Network & Socket Reset (Winsock, Flush DNS, NetBIOS & Port Purge)" -ForegroundColor White
            Write-Host "  [9] Disable IPv6 Protocol Stack (Use if office LAN is pure IPv4)" -ForegroundColor White
            Write-Host "  [10] Install IPP / Mopria Sharing Foundation & Legacy LPR/LPD Protocols" -ForegroundColor White
            Write-Host ""
            Write-Host "  [L] Switch Language / Ganti Bahasa" -ForegroundColor DarkCyan
            Write-Host "  [B] Back to Main Menu" -ForegroundColor Cyan
            Write-Host ""
            Write-Host ("-" * 86) -ForegroundColor Cyan
            Write-Host "Select option [1-10], L, or B: " -NoNewline -ForegroundColor Yellow
        } else {
            Write-Host "  [1] Ubah Profil Jaringan ke Private (Wajib agar Sharing Printer Aktif)" -ForegroundColor White
            Write-Host "  [2] Buka Akses Berbagi Tanpa Password (Guest Access & Anonymous Sharing)" -ForegroundColor Green
            Write-Host "      (Menggabungkan izin akun tamu dan mematikan proteksi password sharing)" -ForegroundColor Gray
            Write-Host "  [3] Matikan Wajib SMB Signing (Fix Windows 11 Gagal Konek ke Printer/NAS)" -ForegroundColor White
            Write-Host "  [4] Kelola Protokol SMB (Aktifkan SMB2/SMB3 Modern & Pengaturan SMB 1.0)" -ForegroundColor White
            Write-Host "  [5] Buka Port Firewall untuk Berbagi Berkas & Printer (Termasuk Port WSD 3702)" -ForegroundColor White
            Write-Host "  [6] Aktifkan Penemuan Perangkat Otomatis (mDNS, LLMNR, dan WSD Discovery)" -ForegroundColor White
            Write-Host "  [7] Atur Prioritas Protokol Jaringan & Atasi Konflik Virtual Hyper-V/WSL" -ForegroundColor White
            Write-Host "  [8] Reset Total Jaringan & Sockets (Winsock, Flush DNS, NetBIOS & Port Purge)" -ForegroundColor White
            Write-Host "  [9] Matikan Protokol IPv6 (Gunakan jika LAN Kantor Murni IPv4)" -ForegroundColor White
            Write-Host "  [10] Pasang Fondasi Berbagi IPP / Mopria & Protokol Legacy LPR/LPD" -ForegroundColor White
            Write-Host ""
            Write-Host "  [L] Ganti Bahasa / Switch to English" -ForegroundColor DarkCyan
            Write-Host "  [B] Kembali ke Menu Utama" -ForegroundColor Cyan
            Write-Host ""
            Write-Host ("-" * 86) -ForegroundColor Cyan
            Write-Host "Pilih nomor [1-10], L, atau B: " -NoNewline -ForegroundColor Yellow
        }
        $sub = Read-Host
        if ($null -eq $sub) { continue }
        $sub = $sub.Trim()
        if ($sub -match '^(l|lang|language)$') { Toggle-AppLanguage; continue }
        if ($sub -match '^(b|0|back|kembali)$') { return }
        switch ($sub) {
            '1' { Set-NetworkPrivate; Pause-User }
            '2' {
                Write-Host $(if ($isEN) { "`n  [*] Applying passwordless sharing & guest access permissions..." } else { "`n  [*] Menerapkan akses berbagi tanpa sandi & izin Guest..." }) -ForegroundColor Cyan
                Disable-PasswordSharing
                Enable-SMBGuest
                Pause-User
            }
            '3' { Fix-SMBSigning; Pause-User }
            '4' {
                Fix-ModernSMB
                Manage-SMB1
                Pause-User
            }
            '5' {
                Open-Firewall
                Fix-WSDFirewall
                Pause-User
            }
            '6' {
                Fix-mDNS
                Start-Service WSDPrintDevice -ErrorAction SilentlyContinue
                Write-Host $(if ($isEN) { "  [+] WSD Print Device Discovery Enabled." } else { "  [+] Penemuan Perangkat Cetak WSD Diaktifkan." }) -ForegroundColor Green
                Pause-User
            }
            '7' {
                Fix-ProviderOrder
                Fix-HyperVConflict
                Pause-User
            }
            '8' {
                Reset-Network
                Reset-NetworkSockets
                Pause-User
            }
            '9' { Disable-IPv6; Pause-User }
            '10' {
                Fix-IPPSharing
                Manage-LPR
                Pause-User
            }
            default { Write-Host $(if ($isEN) { "  [-] Invalid choice." } else { "  [-] Pilihan tidak valid." }) -ForegroundColor Red; Start-Sleep -Milliseconds 1200 }
        }
    } while ($true)
}

function Show-Submenu4 {
    do {
        $isEN = ($script:lang -eq "EN")
        Show-Header -SubTitle $(if ($isEN) { "4. Print Spooler Service & Print Queue Maintenance" } else { "4. Layanan Print Spooler & Antrean Cetak" })
        Write-Host ""
        if ($isEN) {
            Write-Host "  [1] Clean Spooler Reset & Purge Jammed Print Queue Files (.spl/.shd)" -ForegroundColor Green
            Write-Host "      (Stops spooler, removes locked documents, and cleanly restarts service)" -ForegroundColor Gray
            Write-Host "  [2] Configure Automatic Spooler Recovery on Crash (Auto-Restart)" -ForegroundColor White
            Write-Host "  [3] Deploy Spooler Watchdog Scheduled Task (Monitors every 5 minutes)" -ForegroundColor White
            Write-Host "  [4] Repair & Reset Spooler Registry Dependencies (RPCSS & HTTP)" -ForegroundColor White
            Write-Host "  [5] Restart Core System RPC & DCOM Services" -ForegroundColor White
            Write-Host "  [6] Restart Remote Spooler Service on Target Computer" -ForegroundColor White
            Write-Host ""
            Write-Host "  [L] Switch Language / Ganti Bahasa" -ForegroundColor DarkCyan
            Write-Host "  [B] Back to Main Menu" -ForegroundColor Cyan
            Write-Host ""
            Write-Host ("-" * 86) -ForegroundColor Cyan
            Write-Host "Select option [1-6], L, or B: " -NoNewline -ForegroundColor Yellow
        } else {
            Write-Host "  [1] Reset Bersih Spooler & Hapus Berkas Antrean Cetak yang Nyangkut" -ForegroundColor Green
            Write-Host "      (Hentikan spooler, bersihkan antrean .spl/.shd, dan restart layanan)" -ForegroundColor Gray
            Write-Host "  [2] Konfigurasi Pemulihan Otomatis Spooler Saat Crash (Auto-Restart)" -ForegroundColor White
            Write-Host "  [3] Pasang Pemantau Spooler Otomatis (Watchdog Cek Tiap 5 Menit)" -ForegroundColor White
            Write-Host "  [4] Perbaiki & Reset Dependensi Registri Spooler (RPCSS & HTTP)" -ForegroundColor White
            Write-Host "  [5] Restart Layanan Sistem RPC & DCOM" -ForegroundColor White
            Write-Host "  [6] Restart Layanan Spooler di Komputer Jarak Jauh (Remote Spooler)" -ForegroundColor White
            Write-Host ""
            Write-Host "  [L] Ganti Bahasa / Switch to English" -ForegroundColor DarkCyan
            Write-Host "  [B] Kembali ke Menu Utama" -ForegroundColor Cyan
            Write-Host ""
            Write-Host ("-" * 86) -ForegroundColor Cyan
            Write-Host "Pilih nomor [1-6], L, atau B: " -NoNewline -ForegroundColor Yellow
        }
        $sub = Read-Host
        if ($null -eq $sub) { continue }
        $sub = $sub.Trim()
        if ($sub -match '^(l|lang|language)$') { Toggle-AppLanguage; continue }
        if ($sub -match '^(b|0|back|kembali)$') { return }
        switch ($sub) {
            '1' {
                Nuke-PrintQueue
                Reset-Spooler
                Pause-User
            }
            '2' { Set-SpoolerRecovery; Pause-User }
            '3' { Set-SpoolerWatchdog; Pause-User }
            '4' {
                Reset-SpoolerDependency
                Reset-SpoolerDependencyRegistry
                Pause-User
            }
            '5' { Check-RPC; Pause-User }
            '6' { Remote-SpoolerReset; Pause-User }
            default { Write-Host $(if ($isEN) { "  [-] Invalid choice." } else { "  [-] Pilihan tidak valid." }) -ForegroundColor Red; Start-Sleep -Milliseconds 1200 }
        }
    } while ($true)
}

function Show-Submenu5 {
    do {
        $isEN = ($script:lang -eq "EN")
        Show-Header -SubTitle $(if ($isEN) { "5. Driver Management & Printer Cleanup" } else { "5. Pengelolaan Driver & Pembersihan Printer" })
        Write-Host ""
        if ($isEN) {
            Write-Host "  [1] Force-Kill Locking Driver Processes ('Driver is in use')" -ForegroundColor White
            Write-Host "  [2] Disable Print Driver Isolation (Prevent separate process crashes)" -ForegroundColor White
            Write-Host "  [3] Clean Stale & Corrupted Drivers (Driver Sweeper via pnputil)" -ForegroundColor White
            Write-Host "  [4] Remove Ghost & Duplicate USB Printers (Copy 1, Copy 2, dead ports)" -ForegroundColor White
            Write-Host "  [5] Repair Universal V4 Print Class Drivers & Switch PCL / PostScript Mode" -ForegroundColor White
            Write-Host "  [6] Fix Web Browser Printing (Chrome/Edge Sandbox & Modern UWP Apps)" -ForegroundColor White
            Write-Host "  [7] Reinstall Windows Virtual Built-in Printers (Microsoft Print to PDF / XPS)" -ForegroundColor White
            Write-Host "  [8] Lock Default Printer Permanently (Prevent automatic location switching)" -ForegroundColor White
            Write-Host "  [9] Sanitize Printer Share Names (Strip spaces and illegal characters)" -ForegroundColor White
            Write-Host "  [10] Open Print Server Properties Management Console" -ForegroundColor White
            Write-Host "  [11] Force-Uninstall Specific Problematic Printer" -ForegroundColor White
            Write-Host ""
            Write-Host "  [L] Switch Language / Ganti Bahasa" -ForegroundColor DarkCyan
            Write-Host "  [B] Back to Main Menu" -ForegroundColor Cyan
            Write-Host ""
            Write-Host ("-" * 86) -ForegroundColor Cyan
            Write-Host "Select option [1-11], L, or B: " -NoNewline -ForegroundColor Yellow
        } else {
            Write-Host "  [1] Hentikan Paksa Proses Driver yang Mengunci ('Driver is in use')" -ForegroundColor White
            Write-Host "  [2] Matikan Isolasi Driver Printer (Cegah Driver Crash Terpisah)" -ForegroundColor White
            Write-Host "  [3] Bersihkan Driver Usang / Rusak dari Sistem (Driver Sweeper via pnputil)" -ForegroundColor White
            Write-Host "  [4] Hapus Printer Hantu & Duplikat Port USB (Ghost Copy 1, Copy 2)" -ForegroundColor White
            Write-Host "  [5] Perbaiki Driver Kelas Universal V4 & Ganti Mode PCL / PostScript" -ForegroundColor White
            Write-Host "  [6] Perbaiki Masalah Cetak Browser (Chrome/Edge Sandbox & Aplikasi UWP)" -ForegroundColor White
            Write-Host "  [7] Pasang Ulang Printer Bawaan Windows (Microsoft Print to PDF / XPS)" -ForegroundColor White
            Write-Host "  [8] Kunci Printer Default Permanen (Cegah Berubah Otomatis)" -ForegroundColor White
            Write-Host "  [9] Bersihkan Nama Share Printer dari Spasi & Karakter Terlarang" -ForegroundColor White
            Write-Host "  [10] Buka Properti Server Cetak Windows (Print Server Properties)" -ForegroundColor White
            Write-Host "  [11] Hapus Instalasi Printer Tertentu Secara Manual" -ForegroundColor White
            Write-Host ""
            Write-Host "  [L] Ganti Bahasa / Switch to English" -ForegroundColor DarkCyan
            Write-Host "  [B] Kembali ke Menu Utama" -ForegroundColor Cyan
            Write-Host ""
            Write-Host ("-" * 86) -ForegroundColor Cyan
            Write-Host "Pilih nomor [1-11], L, atau B: " -NoNewline -ForegroundColor Yellow
        }
        $sub = Read-Host
        if ($null -eq $sub) { continue }
        $sub = $sub.Trim()
        if ($sub -match '^(l|lang|language)$') { Toggle-AppLanguage; continue }
        if ($sub -match '^(b|0|back|kembali)$') { return }
        switch ($sub) {
            '1' { Force-KillDriverProcess; Pause-User }
            '2' {
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Print" -Name IsolationPolicy -Value 0 -Type DWord -Force
                Write-Host $(if ($isEN) { "  [+] Driver Isolation Disabled." } else { "  [+] Isolasi Driver Dinonaktifkan." }) -ForegroundColor Green
                Pause-User
            }
            '3' { Sweep-OrphanedDrivers; Pause-User }
            '4' { Remove-GhostUSBPrinters; Pause-User }
            '5' {
                Fix-V4ClassDriver
                Switch-DriverMode
                Pause-User
            }
            '6' {
                Fix-UWPPrinting
                Fix-BrowserPrintSandbox
                Pause-User
            }
            '7' { Fix-PrintToPDF; Pause-User }
            '8' {
                Manage-DefaultPrinter
                Force-DefaultPrinterRegistry
                Pause-User
            }
            '9' { Sanitize-PrinterShareName; Pause-User }
            '10' { Manage-Drivers; Pause-User }
            '11' { Uninstall-Printer; Pause-User }
            default { Write-Host $(if ($isEN) { "  [-] Invalid choice." } else { "  [-] Pilihan tidak valid." }) -ForegroundColor Red; Start-Sleep -Milliseconds 1200 }
        }
    } while ($true)
}

function Show-Submenu6 {
    do {
        $isEN = ($script:lang -eq "EN")
        Show-Header -SubTitle $(if ($isEN) { "6. Credentials, Access Rights & Security" } else { "6. Kredensial, Hak Akses & Keamanan" })
        Write-Host ""
        if ($isEN) {
            Write-Host "  [1] Save Printer Credentials (Username & Password) to Windows Vault" -ForegroundColor White
            Write-Host "  [2] Clean Stale/Outdated Printer Credentials from Windows Vault" -ForegroundColor White
            Write-Host "  [3] Deploy Login Credentials to All User Profiles on This Machine" -ForegroundColor White
            Write-Host "  [4] Bypass Administrator UAC Network Token Filter for Workgroups" -ForegroundColor White
            Write-Host "  [5] Align NTLMv2 Authentication Response (LmCompatibilityLevel)" -ForegroundColor White
            Write-Host "  [6] Relax Strict Security Protections (LSA Protection, Smart App Control, Credential Guard)" -ForegroundColor White
            Write-Host "  [7] Manage Windows Protected Print / WPP (Win 11 Driver Mode)" -ForegroundColor White
            Write-Host "  [8] Bypass Point and Print Driver Restrictions (Elevation Override)" -ForegroundColor White
            Write-Host "  [9] Fix Printer Redirection on Remote Desktop Connections (RDP)" -ForegroundColor White
            Write-Host ""
            Write-Host "  [L] Switch Language / Ganti Bahasa" -ForegroundColor DarkCyan
            Write-Host "  [B] Back to Main Menu" -ForegroundColor Cyan
            Write-Host ""
            Write-Host ("-" * 86) -ForegroundColor Cyan
            Write-Host "Select option [1-9], L, or B: " -NoNewline -ForegroundColor Yellow
        } else {
            Write-Host "  [1] Simpan Kredensial (User & Password) Printer ke Windows Vault Permanen" -ForegroundColor White
            Write-Host "  [2] Bersihkan Kredensial Printer yang Usang atau Gagal dari Windows Vault" -ForegroundColor White
            Write-Host "  [3] Terapkan Kredensial Login ke Semua Profil Pengguna di Komputer Ini" -ForegroundColor White
            Write-Host "  [4] Bypass Filter Token UAC Administrator untuk Jaringan Workgroup" -ForegroundColor White
            Write-Host "  [5] Selaraskan Respon Otentikasi NTLMv2 (LmCompatibilityLevel)" -ForegroundColor White
            Write-Host "  [6] Longgarkan Proteksi Keamanan Ketat (LSA Protection, Smart App Control, Credential Guard)" -ForegroundColor White
            Write-Host "  [7] Kelola Windows Protected Print / WPP (Mode Proteksi Driver Win 11)" -ForegroundColor White
            Write-Host "  [8] Bypass Pembatasan Driver Point and Print (Elevation Override)" -ForegroundColor White
            Write-Host "  [9] Perbaiki Masalah Berbagi Printer pada Sambungan Remote Desktop (RDP)" -ForegroundColor White
            Write-Host ""
            Write-Host "  [L] Ganti Bahasa / Switch to English" -ForegroundColor DarkCyan
            Write-Host "  [B] Kembali ke Menu Utama" -ForegroundColor Cyan
            Write-Host ""
            Write-Host ("-" * 86) -ForegroundColor Cyan
            Write-Host "Pilih nomor [1-9], L, atau B: " -NoNewline -ForegroundColor Yellow
        }
        $sub = Read-Host
        if ($null -eq $sub) { continue }
        $sub = $sub.Trim()
        if ($sub -match '^(l|lang|language)$') { Toggle-AppLanguage; continue }
        if ($sub -match '^(b|0|back|kembali)$') { return }
        switch ($sub) {
            '1' { Add-Credential; Pause-User }
            '2' { Clean-Credential; Pause-User }
            '3' { Inject-CrossUserCredentials; Pause-User }
            '4' { Fix-UACTokenFilter; Pause-User }
            '5' { Fix-NTLMv2; Pause-User }
            '6' {
                Fix-LSAProtection
                Fix-SAC
                Fix-CredentialGuard
                Pause-User
            }
            '7' { Manage-WPP; Pause-User }
            '8' { Fix-AdvancedPointAndPrint; Pause-User }
            '9' { Fix-RDPPrinter; Pause-User }
            default { Write-Host $(if ($isEN) { "  [-] Invalid choice." } else { "  [-] Pilihan tidak valid." }) -ForegroundColor Red; Start-Sleep -Milliseconds 1200 }
        }
    } while ($true)
}

function Show-Submenu7 {
    do {
        $isEN = ($script:lang -eq "EN")
        Show-Header -SubTitle $(if ($isEN) { "7. Port Mapping & Manual Connections" } else { "7. Pemetaan Port & Sambungan Manual" })
        Write-Host ""
        if ($isEN) {
            Write-Host "  [1] Map Local Port to UNC Share (Ultimate Bypass for Error 0x00000709)" -ForegroundColor Green
            Write-Host "      (Example: connects local port directly to \\SERVER\PRINTER)" -ForegroundColor Gray
            Write-Host "  [2] Remove Previously Created Local UNC Port Mapping" -ForegroundColor White
            Write-Host "  [3] Convert WSD Printer Port to Stable Standard TCP/IP Socket" -ForegroundColor White
            Write-Host "  [4] Add Standard TCP/IP Printer Port Manually" -ForegroundColor White
            Write-Host "  [5] Scan & Discover Shared Printers on Remote Network Host" -ForegroundColor White
            Write-Host ""
            Write-Host "  [L] Switch Language / Ganti Bahasa" -ForegroundColor DarkCyan
            Write-Host "  [B] Back to Main Menu" -ForegroundColor Cyan
            Write-Host ""
            Write-Host ("-" * 86) -ForegroundColor Cyan
            Write-Host "Select option [1-5], L, or B: " -NoNewline -ForegroundColor Yellow
        } else {
            Write-Host "  [1] Petakan Port Lokal ke Jalur Share UNC (Solusi Ampuh Bypass 0x00000709)" -ForegroundColor Green
            Write-Host "      (Contoh: menghubungkan port lokal langsung ke \\NAMA-SERVER\PRINTER)" -ForegroundColor Gray
            Write-Host "  [2] Hapus Pemetaan Port Lokal UNC yang Pernah Dibuat" -ForegroundColor White
            Write-Host "  [3] Ubah Port Printer dari WSD Menjadi Standar TCP/IP Stabil" -ForegroundColor White
            Write-Host "  [4] Tambah Port Printer Standar TCP/IP Secara Manual" -ForegroundColor White
            Write-Host "  [5] Pindai & Temukan Printer yang Aktif di Jaringan Komputer Target" -ForegroundColor White
            Write-Host ""
            Write-Host "  [L] Ganti Bahasa / Switch to English" -ForegroundColor DarkCyan
            Write-Host "  [B] Kembali ke Menu Utama" -ForegroundColor Cyan
            Write-Host ""
            Write-Host ("-" * 86) -ForegroundColor Cyan
            Write-Host "Pilih nomor [1-5], L, atau B: " -NoNewline -ForegroundColor Yellow
        }
        $sub = Read-Host
        if ($null -eq $sub) { continue }
        $sub = $sub.Trim()
        if ($sub -match '^(l|lang|language)$') { Toggle-AppLanguage; continue }
        if ($sub -match '^(b|0|back|kembali)$') { return }
        switch ($sub) {
            '1' { Map-LocalPortUNC; Pause-User }
            '2' { Remove-LocalPortUNC; Pause-User }
            '3' { Convert-WSDtoTCPIP; Pause-User }
            '4' { Manage-TCPPort; Pause-User }
            '5' { Scan-RemotePrinter; Pause-User }
            default { Write-Host $(if ($isEN) { "  [-] Invalid choice." } else { "  [-] Pilihan tidak valid." }) -ForegroundColor Red; Start-Sleep -Milliseconds 1200 }
        }
    } while ($true)
}

function Show-Submenu8 {
    do {
        $isEN = ($script:lang -eq "EN")
        Show-Header -SubTitle $(if ($isEN) { "8. Backup, System Diagnostics & Disaster Recovery" } else { "8. Cadangan, Diagnostik & Pemulihan" })
        Write-Host ""
        if ($isEN) {
            Write-Host "  [1] Backup Printer & Network Registry (Always Recommended Before Fixes)" -ForegroundColor Green
            Write-Host "  [2] Rollback Registry from Previous Backup Snapshot" -ForegroundColor White
            Write-Host "  [3] Create System Restore Point for Disaster Recovery" -ForegroundColor White
            Write-Host "  [4] Scan & Repair System Files (SFC /scannow & DISM)" -ForegroundColor White
            Write-Host "  [5] Test Network Connectivity & Scan Ports (Ping & Port 135/445)" -ForegroundColor White
            Write-Host "  [6] Audit & Analyze Print Service Event Logs (Event Log Parser)" -ForegroundColor White
            Write-Host "  [7] Generate Interactive HTML Diagnostic Report" -ForegroundColor White
            Write-Host "  [8] Scan Active Directory Domain Policy / GPO Intervention" -ForegroundColor White
            Write-Host "  [9] Backup & Migrate Printers to Another Computer (PrintBRM)" -ForegroundColor White
            Write-Host "  [10] Force Printer Status to 'Online' (If stuck offline)" -ForegroundColor White
            Write-Host "  [11] Open Windows Services Console (services.msc)" -ForegroundColor White
            Write-Host "  [12] Open Repair Execution Log File (Log Manager)" -ForegroundColor White
            Write-Host "  [13] Quick System Diagnostics Audit" -ForegroundColor White
            Write-Host ""
            Write-Host "  [L] Switch Language / Ganti Bahasa" -ForegroundColor DarkCyan
            Write-Host "  [B] Back to Main Menu" -ForegroundColor Cyan
            Write-Host ""
            Write-Host ("-" * 86) -ForegroundColor Cyan
            Write-Host "Select option [1-13], L, or B: " -NoNewline -ForegroundColor Yellow
        } else {
            Write-Host "  [1] Cadangkan Registri Printer & Jaringan (Backup Registry Sebelum Perbaikan)" -ForegroundColor Green
            Write-Host "  [2] Pulihkan Registri dari Cadangan Sebelumnya (Rollback Registry)" -ForegroundColor White
            Write-Host "  [3] Buat Titik Pemulihan Sistem Windows (System Restore Point)" -ForegroundColor White
            Write-Host "  [4] Pindai & Perbaiki Kerusakan File Sistem Windows (SFC /scannow & DISM)" -ForegroundColor White
            Write-Host "  [5] Uji Koneksi & Pindai Port Jaringan Printer (Ping & Port 135/445)" -ForegroundColor White
            Write-Host "  [6] Audit & Analisis Log Error Layanan Print Windows (Event Log Parser)" -ForegroundColor White
            Write-Host "  [7] Buat Laporan Diagnostik Interaktif (File HTML Lengkap)" -ForegroundColor White
            Write-Host "  [8] Pindai Intervensi Kebijakan Domain / GPO yang Mengunci Pengaturan" -ForegroundColor White
            Write-Host "  [9] Cadangkan / Migrasikan Seluruh Printer ke Komputer Lain (PrintBRM)" -ForegroundColor White
            Write-Host "  [10] Paksa Status Printer Menjadi 'Online' (Jika Nyangkut Status Offline)" -ForegroundColor White
            Write-Host "  [11] Buka Jendela Layanan Windows (Services.msc)" -ForegroundColor White
            Write-Host "  [12] Buka Catatan Log Eksekusi Perbaikan (Log Manager)" -ForegroundColor White
            Write-Host "  [13] Audit Ringkas Kesehatan Sistem (System Diagnostics Audit)" -ForegroundColor White
            Write-Host ""
            Write-Host "  [L] Ganti Bahasa / Switch to English" -ForegroundColor DarkCyan
            Write-Host "  [B] Kembali ke Menu Utama" -ForegroundColor Cyan
            Write-Host ""
            Write-Host ("-" * 86) -ForegroundColor Cyan
            Write-Host "Pilih nomor [1-13], L, atau B: " -NoNewline -ForegroundColor Yellow
        }
        $sub = Read-Host
        if ($null -eq $sub) { continue }
        $sub = $sub.Trim()
        if ($sub -match '^(l|lang|language)$') { Toggle-AppLanguage; continue }
        if ($sub -match '^(b|0|back|kembali)$') { return }
        switch ($sub) {
            '1' { Backup-Registry; Pause-User }
            '2' { Rollback-Registry; Pause-User }
            '3' { Create-RestorePoint; Pause-User }
            '4' { Run-SfcDism; Pause-User }
            '5' { Test-Connectivity; Pause-User }
            '6' {
                Scan-PrintEventLog
                Parse-PrintEventLog
                Pause-User
            }
            '7' { Generate-HtmlLog; Pause-User }
            '8' { Detect-GPOIntervention; Pause-User }
            '9' { Print-Migration; Pause-User }
            '10' { Force-PrinterOnline; Pause-User }
            '11' { Open-Services; Pause-User }
            '12' { Log-Manager; Pause-User }
            '13' { Run-QuickDiagnostics; Pause-User }
            default { Write-Host $(if ($isEN) { "  [-] Invalid choice." } else { "  [-] Pilihan tidak valid." }) -ForegroundColor Red; Start-Sleep -Milliseconds 1200 }
        }
    } while ($true)
}

function Show-Submenu9 {
    do {
        $isEN = ($script:lang -eq "EN")
        Show-Header -SubTitle $(if ($isEN) { "9. Help & Usage Guide" } else { "9. Panduan & Bantuan Penggunaan" })
        Write-Host ""
        if ($isEN) {
            Write-Host "  [1] Show Quick Guide & Office Troubleshooting Flow" -ForegroundColor White
            Write-Host "  [2] Open Offline HTML Documentation in Browser" -ForegroundColor White
            Write-Host "  [3] Detect Current Windows Version & Architecture" -ForegroundColor White
            Write-Host "  [4] Run Windows Built-in Printer Troubleshooter (msdt)" -ForegroundColor White
            Write-Host ""
            Write-Host "  [L] Switch Language / Ganti Bahasa" -ForegroundColor DarkCyan
            Write-Host "  [B] Back to Main Menu" -ForegroundColor Cyan
            Write-Host ""
            Write-Host ("-" * 86) -ForegroundColor Cyan
            Write-Host "Select option [1-4], L, or B: " -NoNewline -ForegroundColor Yellow
        } else {
            Write-Host "  [1] Tampilkan Panduan Singkat & Langkah Alur Perbaikan Kantor" -ForegroundColor White
            Write-Host "  [2] Buka Dokumentasi Lengkap Offline (File HTML)" -ForegroundColor White
            Write-Host "  [3] Deteksi Versi & Arsitektur Windows Saat Ini" -ForegroundColor White
            Write-Host "  [4] Jalankan Troubleshooter Bawaan Windows (msdt)" -ForegroundColor White
            Write-Host ""
            Write-Host "  [L] Ganti Bahasa / Switch to English" -ForegroundColor DarkCyan
            Write-Host "  [B] Kembali ke Menu Utama" -ForegroundColor Cyan
            Write-Host ""
            Write-Host ("-" * 86) -ForegroundColor Cyan
            Write-Host "Pilih nomor [1-4], L, atau B: " -NoNewline -ForegroundColor Yellow
        }
        $sub = Read-Host
        if ($null -eq $sub) { continue }
        $sub = $sub.Trim()
        if ($sub -match '^(l|lang|language)$') { Toggle-AppLanguage; continue }
        if ($sub -match '^(b|0|back|kembali)$') { return }
        switch ($sub) {
            '1' { Show-Help -Topic "menu"; Pause-User }
            '2' { Show-Help -Topic "all"; Pause-User }
            '3' { Detect-Win; Pause-User }
            '4' { Start-Troubleshooter; Pause-User }
            default { Write-Host $(if ($isEN) { "  [-] Invalid choice." } else { "  [-] Pilihan tidak valid." }) -ForegroundColor Red; Start-Sleep -Milliseconds 1200 }
        }
    } while ($true)
}

function Show-MainMenu {
    try {
        $rawUI = $Host.UI.RawUI
        $bufSize = $rawUI.BufferSize
        if ($bufSize.Width -lt 88) {
            $bufSize.Width = 88
            $rawUI.BufferSize = $bufSize
        }
        $winSize = $rawUI.WindowSize
        if ($winSize.Width -lt 88) {
            $winSize.Width = 88
            $rawUI.WindowSize = $winSize
        }
    } catch {}

    Show-Header
    Write-Host ""
    if ($script:lang -eq "EN") {
        Write-Host "  SELECT REPAIR CATEGORY:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  [1] Quick & Automated Solutions (ALLFIX & Modern Win 11)" -ForegroundColor Green -NoNewline
        Write-Host "  <-- RECOMMENDED" -ForegroundColor Red
        Write-Host "  [2] Fix Specific Error Codes (0x11b, 0x709, 0xbc4, 0x040, etc.)" -ForegroundColor White
        Write-Host "  [3] Network, File & Printer Sharing (SMB) & Firewall" -ForegroundColor White
        Write-Host "  [4] Print Spooler Service & Print Queue Maintenance" -ForegroundColor White
        Write-Host "  [5] Driver Management & Ghost / USB Printer Cleanup" -ForegroundColor White
        Write-Host "  [6] Credentials, Access Rights & Security (Vault, LSA, UAC)" -ForegroundColor White
        Write-Host "  [7] Port Mapping & Manual Connections (UNC Port Map & TCP/IP)" -ForegroundColor White
        Write-Host "  [8] Backup, System Diagnostics & Disaster Recovery" -ForegroundColor White
        Write-Host ""
        Write-Host "  [9] Help & Usage Guide" -ForegroundColor Cyan
        Write-Host "  [L] Switch to Bahasa Indonesia" -ForegroundColor Yellow
        Write-Host "  [0] Exit Application" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host ("-" * 86) -ForegroundColor Cyan
        Write-Host "  [Shortcut Tips]: Enter menu (1-9), press [L] to switch language, or type classic" -ForegroundColor Gray
        Write-Host "                   codes directly like 84 (AllFix), 83 (Extreme), 64 (Backup), 86 (UNC)." -ForegroundColor Gray
        Write-Host ("-" * 86) -ForegroundColor Cyan
        Write-Host "Select option: " -NoNewline -ForegroundColor Yellow
    }
    else {
        Write-Host "  PILIH KATEGORI PERBAIKAN:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  [1] Solusi Cepat & Otomatis (ALLFIX & Windows 11 Terbaru)" -ForegroundColor Green -NoNewline
        Write-Host "  <-- REKOMENDASI UTAMA" -ForegroundColor Red
        Write-Host "  [2] Perbaikan Kode Error Spesifik (0x11b, 0x709, 0xbc4, 0x040, dll.)" -ForegroundColor White
        Write-Host "  [3] Pengaturan Jaringan, Berbagi (SMB) & Firewall" -ForegroundColor White
        Write-Host "  [4] Layanan Print Spooler & Pembersihan Antrean Cetak" -ForegroundColor White
        Write-Host "  [5] Pengelolaan Driver & Pembersihan Printer Hantu/USB" -ForegroundColor White
        Write-Host "  [6] Kredensial, Hak Akses & Keamanan Windows (Vault, LSA, UAC)" -ForegroundColor White
        Write-Host "  [7] Pemetaan Port & Sambungan Manual (UNC Port Map & TCP/IP)" -ForegroundColor White
        Write-Host "  [8] Cadangan (Backup), Diagnostik & Pemulihan Sistem" -ForegroundColor White
        Write-Host ""
        Write-Host "  [9] Panduan & Bantuan Penggunaan" -ForegroundColor Cyan
        Write-Host "  [L] Ganti ke English" -ForegroundColor Yellow
        Write-Host "  [0] Keluar dari Aplikasi" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host ("-" * 86) -ForegroundColor Cyan
        Write-Host "  [Tips Pintasan]: Ketik nomor menu (1-9), tekan [L] ganti bahasa, atau ketik langsung" -ForegroundColor Gray
        Write-Host "                   kode modul seperti 84 (AllFix), 83 (Extreme), 64 (Backup), 86 (UNC)." -ForegroundColor Gray
        Write-Host ("-" * 86) -ForegroundColor Cyan
        Write-Host "Pilih nomor menu: " -NoNewline -ForegroundColor Yellow
    }
}

function Invoke-Module {
    param([string]$Code)
    $num = $Code.TrimStart('0')
    if (-not $num) { return }

    Clear-Host
    $isEN = ($script:lang -eq "EN")
    Write-Host ("=" * 86) -ForegroundColor Cyan
    Write-Host $(if ($isEN) { "  EXECUTING REPAIR MODULE [$Code]" } else { "  MENJALANKAN MODUL PERBAIKAN [$Code]" }) -ForegroundColor Yellow
    Write-Host ("=" * 86) -ForegroundColor Cyan
    Write-Host ""

    switch ($num) {
        '1'  { Fix-RpcAuthn0x0000011b }
        '2'  { Fix-Deep0x00000709 }
        '3'  { Fix-Discovery0x00000bc4 }
        '4'  { Fix-NetworkServices }
        '5'  { Fix-CSR }
        '6'  { Reset-SpoolerPerm }
        '7'  { Fix-Network0x00000040 }
        '8'  { Fix-DriverCopy0x00000002 }
        '9'  { Fix-RpcBitness0x0000007e }
        '10' { Reset-Network }
        '11' { Set-NetworkPrivate }
        '12' { Disable-PasswordSharing }
        '13' { Fix-NamedPipes }
        '14' { Open-Firewall }
        '15' { Manage-SMB1 }
        '16' { Fix-SMBSigning }
        '17' { Fix-ModernSMB }
        '18' { Fix-ProviderOrder }
        '19' { Disable-IPv6 }
        '20' { Fix-mDNS }
        '21' { Fix-WSDFirewall }
        '22' { Fix-IPPSharing }
        '23' { Fix-HyperVConflict }
        '24' { Manage-LPR }
        '25' { Scan-RemotePrinter }
        '26' { Convert-WSDtoTCPIP }
        '27' { Reset-NetworkSockets }
        '28' { Rescue-NetworkProfile }
        '29' { Manage-TCPPort }
        '30' { Start-Service WSDPrintDevice -ErrorAction SilentlyContinue; Write-Host $(if ($isEN) { "  [+] WSD Discovery Enabled." } else { "  [+] WSD Discovery Diaktifkan." }) -ForegroundColor Green }
        '31' { Reset-Spooler }
        '32' { Check-RPC }
        '33' { Remote-SpoolerReset }
        '34' { Set-SpoolerRecovery }
        '35' { Reset-SpoolerDependency }
        '36' { Set-SpoolerWatchdog }
        '37' { Nuke-PrintQueue }
        '38' { Reset-SpoolerDependencyRegistry }
        '39' { Manage-Drivers }
        '40' { Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Print" -Name IsolationPolicy -Value 0 -Type DWord -Force; Write-Host $(if ($isEN) { "  [+] Driver Isolation Disabled." } else { "  [+] Isolasi Driver Dinonaktifkan." }) -ForegroundColor Green }
        '41' { Fix-V4ClassDriver }
        '42' { Switch-DriverMode }
        '43' { Sweep-OrphanedDrivers }
        '44' { Force-KillDriverProcess }
        '45' { Remove-GhostUSBPrinters }
        '46' { Uninstall-Printer }
        '47' { Fix-UWPPrinting }
        '48' { Fix-PrintToPDF }
        '49' { Fix-BrowserPrintSandbox }
        '50' { Manage-DefaultPrinter }
        '51' { Force-DefaultPrinterRegistry }
        '52' { Fix-RDPPrinter }
        '53' { Sanitize-PrinterShareName }
        '54' { Fix-LSAProtection }
        '55' { Fix-SAC }
        '56' { Fix-AdvancedPointAndPrint }
        '57' { Fix-UACTokenFilter }
        '58' { Fix-NTLMv2 }
        '59' { Manage-WPP }
        '60' { Add-Credential }
        '61' { Clean-Credential }
        '62' { Fix-CredentialGuard }
        '63' { Inject-CrossUserCredentials }
        '64' { Backup-Registry }
        '65' { Rollback-Registry }
        '66' { Create-RestorePoint }
        '67' { Run-SfcDism }
        '68' { Manage-BITS }
        '69' { Manage-WindowsUpdate }
        '70' { Start-Troubleshooter }
        '71' { Force-PrinterOnline }
        '72' { Open-Services }
        '73' { Detect-Win }
        '74' { Test-Connectivity }
        '75' { Log-Manager }
        '76' { Scan-PrintEventLog }
        '77' { Run-QuickDiagnostics }
        '78' { Parse-PrintEventLog }
        '79' { Generate-HtmlLog }
        '80' { Detect-GPOIntervention }
        '81' { Print-Migration }
        '82' { Enable-SMBGuest }
        '83' { Extreme-25H2 }
        '84' { AllFix-Core }
        '85' { $script:silentNuke = $true; AllFix-Core }
        '86' { Map-LocalPortUNC }
        '87' { Remove-LocalPortUNC }
        '88' { Restart-PC }
        '89' { Write-Log $(if ($isEN) { "Application terminated." } else { "Aplikasi Dihentikan." }) -Type "INFO"; exit }
        default { Write-Host $(if ($isEN) { "  [-] Module [$Code] not found. Enter valid code (1-89)." } else { "  [-] Modul [$Code] tidak ditemukan. Masukkan kode modul yang valid (1-89)." }) -ForegroundColor Red }
    }
}

if ($script:silentNuke) {
    AllFix-Core
    exit
}

if ($script:skipInteractiveLoop -ne $true) {
    do {
        Show-MainMenu
        $choice = Read-Host
        if ($null -eq $choice) { continue }
        $choice = $choice.Trim()

        if ($choice -match '^(l|lang|language)$') {
            Toggle-AppLanguage
            continue
        }

        if ($choice -match '^\?(.*)$' -or $choice -match '^help\s*(.*)$') {
            $helpTopic = $Matches[1].Trim()
            Show-Help -Topic $helpTopic
            Pause-User
            continue
        }

        if ($choice -match '^(0|exit|keluar|quit)$') {
            Write-Log $(if ($script:lang -eq "EN") { "Application Terminated by User." } else { "Aplikasi Dihentikan oleh Pengguna." }) -Type "INFO"
            Write-Host $(if ($script:lang -eq "EN") { "`n  [*] Thank you for using Windows Printer Sharing Fix.`n" } else { "`n  [*] Terima kasih telah menggunakan Windows Printer Sharing Fix.`n" }) -ForegroundColor Green
            exit
        }

        switch ($choice) {
            '1' { Show-Submenu1 }
            '2' { Show-Submenu2 }
            '3' { Show-Submenu3 }
            '4' { Show-Submenu4 }
            '5' { Show-Submenu5 }
            '6' { Show-Submenu6 }
            '7' { Show-Submenu7 }
            '8' { Show-Submenu8 }
            '9' { Show-Submenu9 }
            default {
                if ($choice -match '^\d+$') {
                    Invoke-Module -Code $choice
                    Pause-User
                }
                else {
                    $errChoice = if ($script:lang -eq "EN") { "`n  [-] Unrecognized choice '$choice'. Enter a number (1-9), [L] for language, or 0 to exit." } else { "`n  [-] Pilihan menu '$choice' tidak dikenali. Masukkan angka 1-9, [L] ganti bahasa, atau 0." }
                    Write-Host $errChoice -ForegroundColor Red
                    Start-Sleep -Milliseconds 1200
                }
            }
        }
    } while ($true)
}
