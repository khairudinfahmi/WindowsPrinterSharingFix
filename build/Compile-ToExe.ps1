$ProjectRoot = Split-Path $PSScriptRoot -Parent

$SourceFile = Join-Path $ProjectRoot "src\WindowsPrinterSharingFix.ps1"
$OutputDir  = Join-Path $ProjectRoot "release"
$OutputFile = Join-Path $OutputDir "WindowsPrinterSharingFix.exe"
$IconFile   = Join-Path $ProjectRoot "assets\icon.ico"

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

if (-not (Test-Path $SourceFile)) {
    Write-Host "[ERROR] Source file not found: $SourceFile" -ForegroundColor Red
    Write-Host "Ensure the script is executed from within the WindowsPrinterSharingFix project directory." -ForegroundColor Yellow
    exit 1
}

Write-Host "Verifying PS2EXE module..." -ForegroundColor Cyan
if (-not (Get-Module -ListAvailable -Name ps2exe)) {
    Write-Host "PS2EXE module not installed. Installing..." -ForegroundColor Yellow
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Install-Module -Name ps2exe -Force -Scope CurrentUser -AllowClobber
}

Write-Host "PS2EXE module found." -ForegroundColor Green
Write-Host "Compiling $SourceFile to $OutputFile..." -ForegroundColor Cyan

$ps2exeParams = @{
    inputFile   = $SourceFile
    outputFile  = $OutputFile
    requireAdmin = $true
    title       = "Windows Printer Sharing Fix"
    description = "Windows Printer Sharing Fix Tool"
    version     = "2.4.0.0"
    company     = "khairudinfahmi"
    copyright   = "2026 khairudinfahmi"
}

if (Test-Path $IconFile) {
    $ps2exeParams.iconFile = $IconFile
}

try {
    Invoke-ps2exe @ps2exeParams
    
    Write-Host "`nCompilation Successful!" -ForegroundColor Green
    Write-Host "EXE file generated at: $OutputFile" -ForegroundColor Cyan
    
    $docSource = Join-Path $ProjectRoot "docs\documentation.html"
    $docDest = Join-Path $OutputDir "documentation.html"
    if (Test-Path $docSource) {
        Copy-Item $docSource $docDest -Force
        Write-Host "Documentation bundled: $docDest" -ForegroundColor Green
    }
    
    Write-Host "Starting Code Signing..." -ForegroundColor Magenta
    $certName = "khairudinfahmi"
    $cert = Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert | Where-Object Subject -match $certName | Select-Object -First 1
    
    if (-not $cert) {
        Write-Host "Code Signing certificate '$certName' not found. Generating new certificate..." -ForegroundColor Yellow
        $cert = New-SelfSignedCertificate -Subject "CN=$certName" -Type CodeSigningCert -CertStoreLocation "Cert:\CurrentUser\My"
        Write-Host "New certificate generated." -ForegroundColor Green
    }
    
    $cerExportPath = Join-Path $ProjectRoot "assets\khairudinfahmi_cert.cer"
    Export-Certificate -Cert $cert -FilePath $cerExportPath -Force | Out-Null
    Write-Host "Certificate file exported to: $cerExportPath" -ForegroundColor Cyan
    
    Write-Host "Injecting digital signature into $OutputFile..." -ForegroundColor Cyan
    $sig = Set-AuthenticodeSignature -FilePath $OutputFile -Certificate $cert -TimestampServer "http://timestamp.sectigo.com"
    
    if ($sig.Status -eq "Valid" -or $sig.Status -eq "UnknownError") {
        Write-Host "Signature injected! (Status: $($sig.Status))" -ForegroundColor Green
    } else {
        Write-Host "Signing failed: $($sig.StatusMessage)" -ForegroundColor Red
    }

    # Inno Setup Installer Compilation
    Write-Host "`nChecking for Inno Setup compiler (ISCC.exe)..." -ForegroundColor Magenta
    $isccPath = $null
    $candidatePaths = @(
        "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe",
        "C:\Users\Dina\AppData\Local\Programs\Inno Setup 6\ISCC.exe",
        "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
        "$env:ProgramFiles\Inno Setup 6\ISCC.exe"
    )
    foreach ($cand in $candidatePaths) {
        if ($cand -and (Test-Path $cand)) {
            $isccPath = $cand
            break
        }
    }
    if (-not $isccPath) {
        $cmd = Get-Command iscc.exe -ErrorAction SilentlyContinue
        if ($cmd) { $isccPath = $cmd.Source }
    }

    $issScript = Join-Path $ProjectRoot "build\installer.iss"
    $installerExe = Join-Path $OutputDir "WindowsPrinterSharingFix_Installer.exe"

    if ($isccPath -and (Test-Path $issScript)) {
        Write-Host "Inno Setup compiler found: $isccPath" -ForegroundColor Green
        Write-Host "Compiling setup installer: $issScript..." -ForegroundColor Cyan
        & $isccPath $issScript
        
        if (Test-Path $installerExe) {
            Write-Host "Installer compiled successfully at: $installerExe" -ForegroundColor Green
            Write-Host "Injecting digital signature into $installerExe..." -ForegroundColor Cyan
            $sigInstaller = Set-AuthenticodeSignature -FilePath $installerExe -Certificate $cert -TimestampServer "http://timestamp.sectigo.com"
            if ($sigInstaller.Status -eq "Valid" -or $sigInstaller.Status -eq "UnknownError") {
                Write-Host "Installer signature injected! (Status: $($sigInstaller.Status))" -ForegroundColor Green
            } else {
                Write-Host "Installer signing failed: $($sigInstaller.StatusMessage)" -ForegroundColor Red
            }
        } else {
            Write-Host "Installer build failed: output file not found." -ForegroundColor Red
        }
    } else {
        Write-Host "ISCC.exe not found or installer.iss missing. Skipping installer compilation." -ForegroundColor Yellow
    }

} catch {
    Write-Host "Process Failed: $_" -ForegroundColor Red
}

Start-Sleep -Seconds 2


