<#
.SYNOPSIS
    Generates 100% dynamic, pure vector SVG terminal cards directly from src/WindowsPrinterSharingFix.ps1.
.DESCRIPTION
    Dynamically dot-sources WindowsPrinterSharingFix.ps1, intercepts Write-Host, captures
    the authentic colored console output, and emits pixel-perfect SVG files with zero hardcoded text.
.OUTPUTS
    assets/console-preview.svg          (Main Menu - English)
    assets/console-preview-id.svg       (Main Menu - Indonesian)
    assets/console-preview-submenu7.svg (Submenu 7 - Scanner)
    assets/social-banner.svg            (1200x630 Social card with real terminal lines)
    assets/console-lines.json           (Captured lines for PNG sync)
#>

[CmdletBinding()]
param()

$ProjectRoot = Split-Path $PSScriptRoot -Parent
$SourceFile  = Join-Path $ProjectRoot "src\WindowsPrinterSharingFix.ps1"
$AssetsDir   = Join-Path $ProjectRoot "assets"

if (-not (Test-Path $AssetsDir)) {
    New-Item -ItemType Directory -Path $AssetsDir -Force | Out-Null
}

if (-not (Test-Path $SourceFile)) {
    Write-Error "Source file not found: $SourceFile"
    exit 1
}

function Convert-ColorToHex {
    param([string]$ColorName)
    switch ($ColorName) {
        'Green'       { '#4ade80' } # Vivid Terminal Green
        'Cyan'        { '#38bdf8' } # Terminal Cyan
        'Yellow'      { '#facc15' } # Terminal Yellow
        'Red'         { '#f87171' } # Terminal Red
        'White'       { '#f8fafc' } # Terminal White
        'Gray'        { '#94a3b8' } # Slate Gray
        'DarkGray'    { '#64748b' } # Slate Dark Gray
        'DarkCyan'    { '#0284c7' } # Deep Cyan
        'DarkGreen'   { '#16a34a' }
        'DarkYellow'  { '#ca8a04' }
        'Magenta'     { '#e879f9' }
        'DarkMagenta' { '#c026d3' }
        'Blue'        { '#60a5fa' }
        'DarkBlue'    { '#2563eb' }
        default       { '#cbd5e1' }
    }
}

function Escape-Xml {
    param([string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return "" }
    return $Text.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;').Replace("'", '&apos;')
}

function Capture-ConsoleOutput {
    param(
        [scriptblock]$Action
    )

    $capturedLines = [System.Collections.Generic.List[PSCustomObject]]::new()
    $currentLine   = [System.Collections.Generic.List[PSCustomObject]]::new()

    function global:Clear-Host { }
    function global:Read-Host { param($Prompt) return 'B' }

    function global:Write-Host {
        [CmdletBinding()]
        param(
            [Parameter(Position=0, ValueFromPipeline=$true)]
            $Object,
            [ConsoleColor]$ForegroundColor = [ConsoleColor]::Gray,
            [ConsoleColor]$BackgroundColor = [ConsoleColor]::Black,
            [switch]$NoNewline
        )
        $text = if ($null -eq $Object) { "" } else { [string]$Object }
        $currentLine.Add([PSCustomObject]@{
            Text  = $text
            Color = $ForegroundColor.ToString()
        })
        if (-not $NoNewline) {
            $capturedLines.Add([PSCustomObject]@{
                Segments = $currentLine.ToArray()
            })
            $currentLine.Clear()
        }
    }

    try {
        & $Action
        if ($currentLine.Count -gt 0) {
            $capturedLines.Add([PSCustomObject]@{
                Segments = $currentLine.ToArray()
            })
            $currentLine.Clear()
        }
    }
    finally {
        Remove-Item Function:\Write-Host -ErrorAction SilentlyContinue
        Remove-Item Function:\Clear-Host -ErrorAction SilentlyContinue
        Remove-Item Function:\Read-Host -ErrorAction SilentlyContinue
    }

    return $capturedLines
}

function Export-LinesToSvg {
    param(
        [System.Collections.Generic.List[PSCustomObject]]$Lines,
        [string]$OutputFile,
        [string]$WindowTitle = "PowerShell (Admin) - Windows Printer Sharing Fix"
    )

    $charWidth     = 8.2
    $lineHeight    = 20
    $paddingX      = 24
    $paddingTop    = 54
    $paddingBottom = 26

    $maxLineChars = 0
    foreach ($line in $Lines) {
        $len = 0
        foreach ($seg in $line.Segments) {
            $len += $seg.Text.Length
        }
        if ($len -gt $maxLineChars) { $maxLineChars = $len }
    }
    if ($maxLineChars -lt 88) { $maxLineChars = 88 }

    $svgWidth  = [int]($maxLineChars * $charWidth + ($paddingX * 2) + 20)
    $svgHeight = [int]($Lines.Count * $lineHeight + $paddingTop + $paddingBottom)

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine(@"
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $svgWidth $svgHeight" width="$svgWidth" height="$svgHeight" xml:space="preserve">
  <defs>
    <style>
      .term-font {
        font-family: 'Cascadia Mono', 'Consolas', 'Courier New', monospace;
        font-size: 13.5px;
        letter-spacing: 0px;
      }
      .window-title {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
        font-size: 13px;
        font-weight: 500;
        fill: #94a3b8;
      }
      @keyframes blink {
        0%, 100% { opacity: 1; }
        50% { opacity: 0; }
      }
      .cursor {
        animation: blink 1s infinite;
      }
    </style>
    <filter id="shadow" x="-5%" y="-5%" width="110%" height="110%">
      <feDropShadow dx="0" dy="8" stdDeviation="12" flood-color="#000000" flood-opacity="0.5"/>
    </filter>
  </defs>

  <!-- Terminal Window Background with drop shadow -->
  <rect x="4" y="4" width="$($svgWidth - 8)" height="$($svgHeight - 8)" rx="10" ry="10" fill="#0c1017" stroke="#30363d" stroke-width="1.5" filter="url(#shadow)" />

  <!-- Terminal Header Bar -->
  <path d="M 4,14 A 10,10 0 0,1 14,4 L $($svgWidth - 14),4 A 10,10 0 0,1 $($svgWidth - 4),14 L $($svgWidth - 4),38 L 4,38 Z" fill="#161b22" />
  <line x1="4" y1="38" x2="$($svgWidth - 4)" y2="38" stroke="#30363d" stroke-width="1" />

  <!-- Window Control Buttons (Red, Yellow, Green) -->
  <circle cx="22" cy="21" r="5.5" fill="#ff5f56" stroke="#e0443e" stroke-width="0.5"/>
  <circle cx="38" cy="21" r="5.5" fill="#ffbd2e" stroke="#dea123" stroke-width="0.5"/>
  <circle cx="54" cy="21" r="5.5" fill="#27c93f" stroke="#1aab29" stroke-width="0.5"/>

  <!-- Window Title -->
  <text x="76" y="25" class="window-title">$(Escape-Xml $WindowTitle)</text>
"@)

    $y = $paddingTop
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        $line = $Lines[$i]
        $x = $paddingX
        [void]$sb.Append("  <text x=`"$x`" y=`"$y`" class=`"term-font`">")

        $lineFullText = ""
        foreach ($seg in $line.Segments) {
            $hex = Convert-ColorToHex $seg.Color
            $escaped = Escape-Xml $seg.Text
            $lineFullText += $seg.Text
            [void]$sb.Append("<tspan fill=`"$hex`">$escaped</tspan>")
        }

        if ($lineFullText -match 'Select option.*:\s*$' -or $lineFullText -match 'Pilih nomor.*:\s*$') {
            [void]$sb.Append("<tspan fill=`"#facc15`" class=`"cursor`">&#x2588;</tspan>")
        }

        [void]$sb.AppendLine("</text>")
        $y += $lineHeight
    }

    [void]$sb.AppendLine("</svg>")

    [System.IO.File]::WriteAllText($OutputFile, $sb.ToString(), [System.Text.UTF8Encoding]::new($false))
    Write-Host "[+] Exported dynamic SVG: $OutputFile" -ForegroundColor Green
}

function Export-SocialBannerSvg {
    param(
        [System.Collections.Generic.List[PSCustomObject]]$Lines,
        [string]$Version,
        [string]$OutputFile
    )

    $w = 1200
    $h = 630

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine(@"
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $w $h" width="$w" height="$h" xml:space="preserve">
  <defs>
    <style>
      .banner-title { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; font-size: 32px; font-weight: 800; fill: #f8fafc; }
      .banner-accent { fill: #38bdf8; }
      .banner-sub { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; font-size: 15px; fill: #94a3b8; }
      .banner-tag { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; font-size: 12px; font-weight: 700; fill: #93c5fd; }
      .pill-badge { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; font-size: 11px; font-weight: 700; }
      .pill-text { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; font-size: 13.5px; fill: #f1f5f9; }
      .term-text { font-family: 'Cascadia Mono', 'Consolas', monospace; font-size: 10.8px; letter-spacing: 0px; }
      .term-header-title { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; font-size: 12px; fill: #94a3b8; }
      @keyframes blink { 0%, 100% { opacity: 1; } 50% { opacity: 0; } }
      .cursor { animation: blink 1s infinite; fill: #facc15; }
    </style>
    <linearGradient id="cyanGlow" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#0ea5e9" stop-opacity="0.35"/>
      <stop offset="100%" stop-color="#0ea5e9" stop-opacity="0"/>
    </linearGradient>
    <linearGradient id="greenGlow" x1="0%" y1="100%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#10b981" stop-opacity="0.3"/>
      <stop offset="100%" stop-color="#10b981" stop-opacity="0"/>
    </linearGradient>
    <filter id="cardShadow" x="-5%" y="-5%" width="110%" height="110%">
      <feDropShadow dx="0" dy="10" stdDeviation="14" flood-color="#000000" flood-opacity="0.6"/>
    </filter>
  </defs>

  <!-- Background -->
  <rect x="0" y="0" width="$w" height="$h" fill="#0a0f1d"/>
  <circle cx="1000" cy="150" r="320" fill="url(#cyanGlow)"/>
  <circle cx="100" cy="500" r="260" fill="url(#greenGlow)"/>
  <rect x="8" y="8" width="$($w - 16)" height="$($h - 16)" rx="16" ry="16" fill="none" stroke="#1e293b" stroke-width="2"/>

  <!-- Left Column -->
  <!-- Top Tag -->
  <rect x="54" y="46" width="240" height="30" rx="15" ry="15" fill="#1e3a8a" stroke="#3b82f6" stroke-width="1"/>
  <text x="70" y="66" class="banner-tag">OPEN SOURCE UTILITY  &#x2022;  v$(Escape-Xml $Version)</text>

  <!-- Main Title -->
  <text x="54" y="118" class="banner-title">Windows Printer</text>
  <text x="54" y="156" class="banner-title banner-accent">Sharing Fix</text>

  <!-- Subtitle -->
  <text x="54" y="196" class="banner-sub">Diagnose &amp; resolve network printer sharing errors:</text>
  <text x="54" y="218" class="banner-sub">0x0000011b, 0x00000709, 0x00000bc4, 0x00000040.</text>

  <!-- Feature Pills -->
  <!-- Pill 1 -->
  <rect x="54" y="246" width="460" height="34" rx="8" ry="8" fill="#0f172a" stroke="#334155" stroke-width="1"/>
  <rect x="58" y="250" width="84" height="26" rx="5" ry="5" fill="#166534" stroke="#22c55e" stroke-width="1"/>
  <text x="78" y="267" class="pill-badge" fill="#86efac">ALLFIX</text>
  <text x="152" y="268" class="pill-text">50-Step Automated Repair Routine</text>

  <!-- Pill 2 -->
  <rect x="54" y="290" width="460" height="34" rx="8" ry="8" fill="#0f172a" stroke="#334155" stroke-width="1"/>
  <rect x="58" y="294" width="84" height="26" rx="5" ry="5" fill="#1e3a8a" stroke="#3b82f6" stroke-width="1"/>
  <text x="79" y="311" class="pill-badge" fill="#93c5fd">WIN 11</text>
  <text x="152" y="312" class="pill-text">24H2 &amp; 26H2 SMB Signing Mitigations</text>

  <!-- Pill 3 -->
  <rect x="54" y="334" width="460" height="34" rx="8" ry="8" fill="#0f172a" stroke="#334155" stroke-width="1"/>
  <rect x="58" y="338" width="84" height="26" rx="5" ry="5" fill="#701a75" stroke="#c026d3" stroke-width="1"/>
  <text x="72" y="355" class="pill-badge" fill="#f0abfc">SCANNER</text>
  <text x="152" y="356" class="pill-text">Remote Printer Discovery &amp; 1-Click Port Map</text>

  <!-- Pill 4 -->
  <rect x="54" y="378" width="460" height="34" rx="8" ry="8" fill="#0f172a" stroke="#334155" stroke-width="1"/>
  <rect x="58" y="382" width="84" height="26" rx="5" ry="5" fill="#854d0e" stroke="#ca8a04" stroke-width="1"/>
  <text x="69" y="399" class="pill-badge" fill="#fde047">BILINGUAL</text>
  <text x="152" y="400" class="pill-text">English &amp; Bahasa Indonesia Toggle (Key [L])</text>

  <!-- Pill 5 -->
  <rect x="54" y="422" width="460" height="34" rx="8" ry="8" fill="#0f172a" stroke="#334155" stroke-width="1"/>
  <rect x="58" y="426" width="84" height="26" rx="5" ry="5" fill="#334155" stroke="#64748b" stroke-width="1"/>
  <text x="70" y="443" class="pill-badge" fill="#e2e8f0">PLATFORM</text>
  <text x="152" y="444" class="pill-text">x64, ARM64 &amp; Windows Server 2012-2025</text>

  <!-- GitHub Link with Vector Star -->
  <polygon points="60,578 62,583 67,583 63,586 65,591 60,588 55,591 57,586 53,583 58,583" fill="#facc15"/>
  <text x="74" y="588" class="banner-sub">github.com/khairudinfahmi/WindowsPrinterSharingFix</text>

  <!-- Right Column: Real Console Window Rendered Directly from .ps1 -->
  <g transform="translate(545, 45)" filter="url(#cardShadow)">
    <rect x="0" y="0" width="605" height="540" rx="12" ry="12" fill="#0c1017" stroke="#30363d" stroke-width="1.5"/>
    <path d="M 0,12 A 12,12 0 0,1 12,0 L 593,0 A 12,12 0 0,1 605,12 L 605,34 L 0,34 Z" fill="#161b22"/>
    <line x1="0" y1="34" x2="605" y2="34" stroke="#30363d" stroke-width="1"/>

    <!-- Window Dots -->
    <circle cx="18" cy="17" r="5" fill="#ff5f56"/>
    <circle cx="33" cy="17" r="5" fill="#ffbd2e"/>
    <circle cx="48" cy="17" r="5" fill="#27c93f"/>
    <text x="66" y="21" class="term-header-title">PowerShell (Admin) - Windows Printer Sharing Fix v$(Escape-Xml $Version)</text>

    <!-- Dynamic Terminal Lines Captured from Show-MainMenu -->
"@)

    $termX = 14
    $termY = 52
    $termLineHeight = 17.5

    for ($i = 0; $i -lt $Lines.Count; $i++) {
        $line = $Lines[$i]
        [void]$sb.Append("    <text x=`"$termX`" y=`"$termY`" class=`"term-text`">")

        $lineFullText = ""
        foreach ($seg in $line.Segments) {
            $hex = Convert-ColorToHex $seg.Color
            $escaped = Escape-Xml $seg.Text
            $lineFullText += $seg.Text
            [void]$sb.Append("<tspan fill=`"$hex`">$escaped</tspan>")
        }

        if ($lineFullText -match 'Select option.*:\s*$' -or $lineFullText -match 'Pilih nomor.*:\s*$') {
            [void]$sb.Append("<tspan class=`"cursor`">&#x2588;</tspan>")
        }

        [void]$sb.AppendLine("</text>")
        $termY += $termLineHeight
    }

    [void]$sb.AppendLine(@"
  </g>
</svg>
"@)

    [System.IO.File]::WriteAllText($OutputFile, $sb.ToString(), [System.Text.UTF8Encoding]::new($false))
    Write-Host "[+] Exported 100% dynamic Social Banner SVG: $OutputFile" -ForegroundColor Green
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Generating Dynamic SVG Console Visuals from .ps1 Source" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Load the real script in non-interactive mode
$script:skipElevationCheck = $true
$script:skipInteractiveLoop = $true
Write-Host "[*] Dot-sourcing $SourceFile..." -ForegroundColor Yellow
. $SourceFile

# Canonical showcase environment for clean, reproducible assets across all machines and CI runners
$env:COMPUTERNAME   = "DESKTOP-OFFICE01"
$env:USERNAME       = "Administrator"
$script:productName = "Windows 11 Pro 24H2"
$script:buildNumber = "26200"

function Get-SystemHealthSummary {
    return @{
        Spooler         = $true
        Network         = $true
        SMBSigning      = $true
        PasswordSharing = $true
    }
}

# 2. Capture and Export English Main Menu
Write-Host "[*] Capturing Show-MainMenu (English)..." -ForegroundColor Yellow
$script:lang = "EN"
$enLines = Capture-ConsoleOutput -Action { Show-MainMenu }
$enSvgFile = Join-Path $AssetsDir "console-preview.svg"
Export-LinesToSvg -Lines $enLines -OutputFile $enSvgFile -WindowTitle "PowerShell (Admin) - Windows Printer Sharing Fix v$script:version"

# Also save as preview-main-menu.svg for alternative link
$altEnSvg = Join-Path $AssetsDir "preview-main-menu.svg"
Copy-Item $enSvgFile $altEnSvg -Force

# 3. Capture and Export Indonesian Main Menu
Write-Host "[*] Capturing Show-MainMenu (Bahasa Indonesia)..." -ForegroundColor Yellow
$script:lang = "ID"
$idLines = Capture-ConsoleOutput -Action { Show-MainMenu }
$idSvgFile = Join-Path $AssetsDir "console-preview-id.svg"
Export-LinesToSvg -Lines $idLines -OutputFile $idSvgFile -WindowTitle "PowerShell (Admin) - Windows Printer Sharing Fix v$script:version [ID]"

# 4. Capture and Export Submenu 7 (Port Mapping & Scanner)
Write-Host "[*] Capturing Show-Submenu7 (Port Mapping & Scanner)..." -ForegroundColor Yellow
$script:lang = "EN"
$sub7Lines = Capture-ConsoleOutput -Action { Show-Submenu7 }
$sub7SvgFile = Join-Path $AssetsDir "console-preview-submenu7.svg"
Export-LinesToSvg -Lines $sub7Lines -OutputFile $sub7SvgFile -WindowTitle "PowerShell (Admin) - Submenu 7: Port Mapping & Scanner"

# 5. Export 100% Dynamic Social Banner SVG
Write-Host "[*] Exporting 100% Dynamic Social Banner SVG (Live from .ps1)..." -ForegroundColor Yellow
$bannerSvgFile = Join-Path $AssetsDir "social-banner.svg"
Export-SocialBannerSvg -Lines $enLines -Version $script:version -OutputFile $bannerSvgFile

# 6. Export captured lines as JSON for Python to sync social-banner.png identically
$jsonLinesFile = Join-Path $AssetsDir "console-lines.json"
$exportData = @{
    version = $script:version
    lines = $enLines
}
$jsonStr = $exportData | ConvertTo-Json -Depth 5
[System.IO.File]::WriteAllText($jsonLinesFile, $jsonStr, [System.Text.UTF8Encoding]::new($false))
Write-Host "[+] Exported console line data for PNG sync: $jsonLinesFile" -ForegroundColor Green

Write-Host "`n[+] All dynamic SVG console assets successfully generated from .ps1 source code!" -ForegroundColor Green
