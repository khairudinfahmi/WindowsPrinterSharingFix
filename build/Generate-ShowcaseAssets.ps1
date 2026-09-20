<#
.SYNOPSIS
    Generates high-resolution terminal console and social preview assets for Windows Printer Sharing Fix.
.DESCRIPTION
    Executes the Python Pillow asset generator to produce:
      - assets/preview-main-menu.png
      - assets/preview-scanner.png
      - assets/social-banner.png
.EXAMPLE
    .\build\Generate-ShowcaseAssets.ps1
#>

[CmdletBinding()]
param()

$ProjectRoot = Split-Path $PSScriptRoot -Parent
$PythonScript = Join-Path $PSScriptRoot "generate_showcase_assets.py"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Generating Visual Showcase Assets for Social Media & Docs" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan

if (-not (Test-Path $PythonScript)) {
    Write-Host "[-] Asset generator script not found: $PythonScript" -ForegroundColor Red
    exit 1
}

# Check if Python is installed
$pythonCmd = Get-Command python -ErrorAction SilentlyContinue
if (-not $pythonCmd) {
    Write-Host "[-] Python is not detected in PATH. Please install Python to render image assets." -ForegroundColor Red
    exit 1
}

$SvgScript = Join-Path $PSScriptRoot "Export-ConsoleSvg.ps1"
if (Test-Path $SvgScript) {
    Write-Host "[*] Exporting dynamic vector SVGs directly from .ps1 source..." -ForegroundColor Yellow
    & powershell -ExecutionPolicy Bypass -File $SvgScript
}

Write-Host "[*] Executing Python asset generator (with dynamic console lines)..." -ForegroundColor Yellow
& python $PythonScript

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n[+] All showcase assets and dynamic SVGs generated successfully!" -ForegroundColor Green
    Write-Host "[+] Visual assets in: \assets" -ForegroundColor Cyan
} else {
    Write-Host "`n[-] Asset generation exited with error code $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}
