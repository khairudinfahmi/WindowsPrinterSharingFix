# Windows Printer Sharing Fix

![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011%20%7C%20Server-0078D6?logo=windows&logoColor=white)
[![Version](https://img.shields.io/badge/version-2.4.0-blue.svg)](https://github.com/khairudinfahmi/WindowsPrinterSharingFix/releases)

A simple but powerful tool to fix common Windows printer sharing problems. Works on Windows 10, 11 (including 24H2+), ARM64, and Windows Server 2025.

---

## What it fixes

Windows updates often break network printing with cryptic errors. This tool fixes them:
- `0x0000011b`, `0x00000709`, `0x00000bc4`, `0x80070035`, `0x00000040`, `0x0000007e`, etc.

---

## Fitur Baru: Pilihan Bahasa (Bilingual ID / EN) & Live Health Banner

- **Ganti Bahasa Instan (Tekan `[L]`):** Pengguna dapat memilih dan berganti bahasa antara **Bahasa Indonesia** dan **English** kapan saja dengan menekan huruf `[L]` pada Menu Utama maupun Submenu. Preferensi bahasa tersimpan permanen di registry pengguna.
- **Indikator Kesehatan Sistem Waktu-Nyata (*Live Health Banner*):** Header di setiap menu langsung menampilkan status 4 pilar penting sistem:
  ```text
  STATUS: Spooler [AKTIF] | Jaringan [PRIVATE] | SMB Signing [SESUAI] | Sandi Sharing [OFF]
  ```
  Teknisi dapat langsung mengidentifikasi sumber masalah hanya dalam 1 detik.

---

## Struktur Menu & Kategori Perbaikan (8 Kategori Aksi + 1 Panduan Bantuan)

Aplikasi kini dirancang ramah pengguna dengan struktur menu dan submenu yang bersih, komunikatif, dan mudah dipahami oleh staf kantor maupun teknisi IT. Tidak ada lagi tampilan berjejal 180 kolom.

> [!TIP]
> **Dukungan Pintasan Langsung (*Direct Shortcuts*):**
> Anda tetap bisa mengetik langsung kode modul klasik (seperti `84` untuk ALLFIX, `83` untuk Extreme Path, `64` untuk Backup Registri, `86` untuk Pemetaan Port UNC, `31` untuk Spooler Reset, dll.) langsung dari Menu Utama tanpa harus membuka submenu terlebih dahulu!

### 1. Solusi Cepat & Otomatis (ALLFIX & Windows 11 Terbaru)
* **[1] ALLFIX - 50 Perbaikan Otomatis Sekaligus** (Modul 84) — *Rekomendasi Utama: perbaikan menyeluruh yang menyelesaikan hampir seluruh masalah printer sharing kantor.*
* **[2] Solusi Khusus Windows 11 Versi Terbaru (24H2/25H2/26H2 & ARM64)** (Modul 83) — *Mengatasi proteksi ketat RPC over Named Pipes, SMB Signing, dan kebijakan driver baru Windows 11.*
* **[3] Optimasi Komputer Host / Server Printer** — *Khusus PC yang tercolok kabel USB printer: izinkan remote RPC endpoint spooler, set Private network, guest sharing, buka port firewall & WSD, dan pasang Spooler Watchdog.*
* **[4] Optimasi Komputer Klien** — *Khusus PC staf yang menyambung ke printer: aktifkan RPC Named Pipes, bypass Point & Print elevation, nonaktifkan SMB Signing, perbaiki izin HKCU, dan flush DNS.*
* **[5] Silent ALLFIX (Otomatis + Langsung Reboot)** (Modul 85) — *Mode cepat untuk teknisi tanpa konfirmasi interaktif.*
* **[6] Kelola Pembaruan Windows & Blokir Update Perusak Printer** (Modul 69) — *Jeda update 35 hari atau cegah update Windows mereset setelan sharing.*

### 2. Perbaikan Berdasarkan Kode Error Spesifik
* **[1] Error 0x0000011b** — Atasi pemblokiran otentikasi RPC (RpcAuthnLevelPrivacy) (Modul 01)
* **[2] Error 0x00000709 / 0x7c** — Atasi pembatasan Point and Print & sambungan RPC (Modul 02)
* **[3] Error 0x00000bc4** — Printer jaringan tidak ditemukan padahal LAN normal (Modul 03)
* **[4] Error 0x80070035** — Jalur jaringan tidak ditemukan / nyalakan servis penemuan (Modul 04)
* **[5] Error 0x000006d1** — Matikan Client-Side Rendering (CSR) (Modul 05)
* **[6] Error 0x80070005** — Akses ditolak ke folder antrean cetak / reset izin Spooler (Modul 06)
* **[7] Error 0x00000040** — Nama jaringan tidak tersedia lagi / KeepConn & NetBIOS (Modul 07)
* **[8] Error 0x00000002** — Gagal menyalin berkas driver dari komputer host (Modul 08)
* **[9] Error 0x0000007e** — Ketidakcocokan arsitektur driver 32-bit & 64-bit (Modul 09)

### 3. Pengaturan Jaringan, Berbagi (SMB) & Firewall
* **[1] Ubah Profil Jaringan ke Private** — Wajib agar printer sharing dapat dideteksi (Modul 11)
* **[2] Buka Akses Berbagi Tanpa Password** — Menggabungkan akun tamu (Guest) & matikan sandi sharing (Modul 12 & 82)
* **[3] Matikan Wajib SMB Signing** — Atasi Windows 11 gagal konek ke printer atau NAS kantor (Modul 16)
* **[4] Kelola Protokol SMB** — Aktifkan SMB2/SMB3 modern & pengaturan opsional SMB 1.0 (Modul 15 & 17)
* **[5] Buka Port Firewall** — Mengaktifkan aturan berbagi berkas, printer, dan port WSD (Modul 14 & 21)
* **[6] Penemuan Perangkat Otomatis** — Mengaktifkan resolusi mDNS, LLMNR, dan WSD Discovery (Modul 20 & 30)
* **[7] Prioritas Jaringan & Konflik Virtual** — Mengatur urutan provider dan atasi switch Hyper-V/WSL (Modul 18 & 23)
* **[8] Reset Total Jaringan & Sockets** — Flush DNS, Winsock, NetBIOS, dan pembersihan sesi port menggantung (Modul 10 & 27)
* **[9] Matikan Protokol IPv6** — Digunakan jika jaringan kantor murni IPv4 (Modul 19)
* **[10] Fondasi Berbagi IPP / Mopria & Legacy LPR** — Standar cetak internet dan antrean Unix (Modul 22 & 24)

### 4. Layanan Print Spooler & Antrean Cetak
* **[1] Reset Bersih Spooler & Hapus Antrean Macet** — Menghentikan spooler, membuang file .spl/.shd, dan restart layanan (Modul 31 & 37)
* **[2] Konfigurasi Pemulihan Otomatis Saat Crash** — Otomatis restart spooler jika mendadak mati (Modul 34)
* **[3] Pasang Watchdog Spooler Otomatis** — Tugas terjadwal yang memeriksa spooler tiap 5 menit (Modul 36)
* **[4] Perbaiki Dependensi Registri Spooler** — Menyetel ulang RPCSS & HTTP ke bawaan pabrik (Modul 35 & 38)
* **[5] Restart Layanan Sistem RPC & DCOM** — Mengatasi pesan 'RPC server unavailable' (Modul 32)
* **[6] Restart Spooler Komputer Lain (Remote)** — Restart spooler server via PowerShell jarak jauh (Modul 33)

### 5. Pengelolaan Driver & Pembersihan Printer
* **[1] Hentikan Paksa Driver Mengunci** — Hentikan splwow64 & isolasi agar driver bisa dihapus (Modul 44)
* **[2] Matikan Isolasi Driver Printer** — Mencegah driver pihak ketiga crash terpisah (Modul 40)
* **[3] Bersihkan Driver Usang (Driver Sweeper)** — Hapus paket driver lama via pnputil (Modul 43)
* **[4] Hapus Printer Hantu & Duplikat USB** — Bersihkan copy 1, copy 2, dan port USB mati (Modul 45 & 46)
* **[5] Driver Universal V4 & Mode Render** — Perbaiki Driver V4 dan ganti mode PCL / PostScript (Modul 41 & 42)
* **[6] Perbaiki Cetak Browser & Aplikasi UWP** — Atasi dialog cetak Chrome/Edge dan aplikasi Windows hang (Modul 47 & 49)
* **[7] Pasang Ulang Printer Bawaan Windows** — Mengembalikan Microsoft Print to PDF & XPS (Modul 48)
* **[8] Kunci Printer Default Permanen** — Mencegah printer default berganti sendiri (Modul 50 & 51)
* **[9] Rapikan Nama Share Printer** — Hapus spasi dan simbol terlarang dari nama share (Modul 53)
* **[10] Buka Print Server Properties** — Kelola driver terpasang melalui antarmuka resmi Windows (Modul 39)

### 6. Kredensial, Hak Akses & Keamanan Windows
* **[1] Simpan Kredensial Printer ke Vault** — Simpan username & password printer permanen di Windows (Modul 60)
* **[2] Bersihkan Kredensial Usang dari Vault** — Hapus sandi usang yang tersimpan di Credential Manager (Modul 61)
* **[3] Terapkan Kredensial ke Semua Pengguna** — Pasang login printer ke seluruh akun di PC ini (Modul 63)
* **[4] Bypass Filter Token UAC Administrator** — Atasi penolakan remote administrasi Workgroup (Modul 57)
* **[5] Selaraskan Otentikasi NTLMv2** — Standarisasi level respon NTLMv2 (Modul 58)
* **[6] Longgarkan Proteksi Keamanan Ketat** — Bypass pembatasan LSA Protection, SAC, dan Credential Guard (Modul 54, 55, 62)
* **[7] Kelola Windows Protected Print (WPP)** — Matikan pemaksaan driver Mopria di Windows 11 (Modul 59)
* **[8] Bypass Point and Print (Elevation Override)** — Hilangkan error 'Do you trust this printer?' (Modul 56)
* **[9] Perbaiki Printer Remote Desktop (RDP)** — Mengaktifkan pengalihan printer lokal pada sesi RDP (Modul 52)

### 7. Pemetaan Port & Sambungan Manual (UNC / TCP-IP)
* **[1] Petakan Port Lokal ke Jalur UNC** — Solusi paling ampuh bypass 0x00000709 langsung ke `\\SERVER\PRINTER` (Modul 86)
* **[2] Hapus Pemetaan Port Lokal UNC** — Menghapus port UNC yang sudah tidak digunakan (Modul 87)
* **[3] Ubah Port WSD ke Standar TCP/IP** — Mengubah port printer WSD yang sering offline ke IP stabil (Modul 26)
* **[4] Tambah Port Standar TCP/IP Manual** — Menambahkan port printer IP baru via WMI (Modul 29)
* **[5] Pindai Printer di Komputer Target** — Menemukan printer aktif yang di-share di komputer tujuan (Modul 25)

### 8. Cadangan (Backup), Diagnostik & Pemulihan Sistem
* **[1] Cadangkan Registri Printer & Jaringan** — Ekspor registri penting sebelum perbaikan (Modul 64)
* **[2] Pulihkan Registri dari Cadangan** — Kembalikan setelan registri jika terjadi kendala (Modul 65)
* **[3] Buat System Restore Point** — Titik pemulihan sistem Windows menyeluruh (Modul 66)
* **[4] Periksa File Sistem (SFC & DISM)** — Memperbaiki kerusakan file sistem operasi Windows (Modul 67)
* **[5] Tes Koneksi Ping & Port (445/135)** — Uji jangkauan jaringan dan firewall komputer printer (Modul 74)
* **[6] Analisis Log Error Layanan Cetak** — Baca dan telaah 20 error log cetak terbaru (Modul 76 & 78)
* **[7] Buat Laporan Diagnostik Interaktif (HTML)** — Ekspor seluruh hasil diagnosa ke file web HTML (Modul 79)
* **[8] Pindai Kebijakan Domain / GPO** — Deteksi apakah pengaturan printer ditimpa oleh Group Policy (Modul 80)
* **[9] Migrasi Printer Lengkap (PrintBRM)** — Backup dan restore konfigurasi printer antar-PC (Modul 81)
* **[10] Paksa Status Printer Menjadi Online** — Memulihkan printer yang macet di status offline (Modul 71)
* **[11] Buka Services.msc & Catatan Log** — Buka manajer layanan Windows atau file log eksekusi (Modul 72 & 75)

---

## ⚠️ Good to Know: Under the Hood

To keep things completely transparent, if you run the automated playbooks (`[83]`, `[84]`, or `[85]`), the script does a few extra things in the background that don't pop up on the screen. This is done to make sure the fixes actually stick:

- **GPO Override (`gpupdate /force`):** It forces a local Group Policy update right before modifying the registry so your domain controller doesn't immediately overwrite the fixes.
- **Scheduled Tasks Injection:** The script deploys background tasks under Windows Task Scheduler for persistent repairs and diagnostics:
  - `PrinterFixPostUpdate` (runs on startup) & `PrinterFixDaily` (runs daily at 10:00 AM): Automatically re-apply critical registry fixes in case Windows Updates reset them.
  - `SpoolerWatchdog` (runs every 5 minutes): Checks and automatically restarts the Print Spooler service if a driver crash stops it.
  > [!NOTE]
  > All registered tasks are configured to bypass laptop AC constraints (they will execute successfully even when unplugged). However, because `SpoolerWatchdog` runs periodically every 5 minutes, it can cause minor battery drain on laptops over time. If you want to maximize battery life, you can easily disable or delete it through the Task Scheduler GUI or by running: `Disable-ScheduledTask -TaskName "SpoolerWatchdog"` in PowerShell (as Administrator).
- **Network & Credential Wipes:** It runs commands like `klist purge`, `ipconfig /flushdns`, and `nbtstat -RR`. If you use Extreme Path `[83]`, it also forcefully wipes stale network credentials from your Windows Vault using `cmdkey`. 
- **Registry Overrides [86/87]:** If you use the UNC Bypass feature and Windows blocks the standard API, the script will forcefully inject or delete the port directly inside `HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Ports`. 
- **Force Kills [37] & [44]:** When you purge the queue or try to bypass a locked driver, the script sends a direct termination signal (`Stop-Process -Force`) to `splwow64`, `PrintIsolationHost`, and `printfilterpipelinesvc`. This drops all active print jobs immediately.
- **Driver Signature & Policy Bypass (KB5089549):** Temporarily sets `VulnerableDriverBlocklistEnable = 0` and `VerifiedAndReputablePolicyState = 0` to bypass driver block restrictions introduced in the post-KB5089549 cumulative update.
- **Strict Name & DNS Aliasing:** Configures `DisableStrictNameChecking = 1` and `DnsOnWire = 1` to ensure you can map/connect to printer shares using DNS CNAMEs or hostname aliases instead of only IPs.
- **NTLM Minimum Security Relaxation:** In Extreme Path `[83]`, sets client/server NTLM requirements to allow legacy authentication handshakes and prevent credential validation errors on Workgroups.

---

## Repository Structure

```text
WindowsPrinterSharingFix/
├── src/
│   └── WindowsPrinterSharingFix.ps1           # Core PowerShell source code (89 features)
├── assets/
│   ├── icon.ico                                # Application icon
│   └── khairudinfahmi_cert.cer                 # Code signing certificate
├── docs/
│   └── documentation.html                      # Offline HTML Documentation
├── build/
│   ├── Compile-ToExe.ps1                       # Build automation script
│   └── installer.iss                           # Inno Setup installer script
├── release/
│   ├── WindowsPrinterSharingFix.exe            # Compiled portable executable
│   └── WindowsPrinterSharingFix_Installer.exe  # Full setup installer
├── .gitignore
├── CHANGELOG.md                                # Version history
├── CONTRIBUTING.md                             # Contribution guidelines
├── LICENSE                                     # GPL-3.0 License
└── README.md                                   # Primary documentation
```

---

## Download & Installation

Pre-compiled binaries are available in the **[Releases](../../releases)** tab:

| File | Description |
|---|---|
| `WindowsPrinterSharingFix.exe` | Portable Executable — Run directly as Administrator |
| `WindowsPrinterSharingFix_Installer.exe` | Full Installer (includes start menu shortcuts & code signing) |

---

## Usage Instructions

### Quick Start (Recommended for Beginners)
1. Download the installer from the **[Releases](../../releases)** tab.
2. Run the application as an **Administrator**.
3. Type `64` → Enter (Execute registry backup).
4. Type `84` → Enter (Execute ALLFIX - 50 automated fixes).
5. Reboot your system.

### Specific Workflow for Windows 11 24H2/25H2/26H2+
1. Type `64` → Enter (Execute registry backup).
2. Type `83` → Enter (Execute Extreme Path fixes).
3. Reboot your system.

### Emergency Mode (Unattended)
- Type `85` → Enter (Silent AllFix: Executes all fixes and forcibly reboots the system without user prompts).

### Help & Documentation
- Type `?` → Display the help guide.
- Type `? 7` → Display detailed documentation for feature 7.
- Type `? all` → Open the complete offline HTML.

---

## Tampilan Antarmuka Console Baru (UI Friendly & Rapi)

```text
======================================================================================
   WINDOWS PRINTER SHARING FIX  |  Solusi Berbagi Printer Windows
   Versi: 2.4.0  |  Sistem: WINDOWS 11 PRO 26100 64-BIT
   Komputer: PC-KANTOR-01  |  Pengguna: Administrator
   STATUS SISTEM: Spooler [AKTIF] | Jaringan [PRIVATE] | SMB Signing [SESUAI] | Sandi Sharing [OFF]
======================================================================================

  PILIH KATEGORI PERBAIKAN:

  [1] Solusi Cepat & Otomatis (ALLFIX & Windows 11 Terbaru)  <-- REKOMENDASI UTAMA
  [2] Perbaikan Kode Error Spesifik (0x11b, 0x709, 0xbc4, 0x040, dll.)
  [3] Pengaturan Jaringan, Berbagi (SMB) & Firewall
  [4] Layanan Print Spooler & Pembersihan Antrean Cetak
  [5] Pengelolaan Driver & Pembersihan Printer Hantu/USB
  [6] Kredensial, Hak Akses & Keamanan Windows (Vault, LSA, UAC)
  [7] Pemetaan Port & Sambungan Manual (UNC Port Map & TCP/IP)
  [8] Cadangan (Backup), Diagnostik & Pemulihan Sistem

  [9] Panduan & Bantuan Penggunaan
  [L] Ganti ke English
  [0] Keluar dari Aplikasi

--------------------------------------------------------------------------------------
  [Tips Pintasan]: Ketik nomor menu (1-9), tekan [L] ganti bahasa, atau ketik langsung
                   kode modul seperti 84 (AllFix), 83 (Extreme), 64 (Backup), 86 (UNC).
--------------------------------------------------------------------------------------
Pilih nomor menu: _
```

---

## System Compatibility

| OS | Support Status |
|---|---|
| Windows 10 (All Builds) | Fully Supported |
| Windows 11 21H2 - 23H2 | Fully Supported |
| Windows 11 24H2 / 25H2 / 26H2+ | Supported (Requires Extreme Path `[83]`) |
| Windows 11 ARM64 (Snapdragon) | Supported |
| Windows Server 2012 / 2016 / 2019 / 2022 / 2025 | Fully Supported |
| Windows 7, 8, 8.1 | Partial / Registry Support Only |

---

## Building from Source

### Prerequisites
- PowerShell 5.1+
- [ps2exe](https://www.powershellgallery.com/packages/ps2exe) module (installed automatically by the build script)
- [Inno Setup 6](https://jrsoftware.org/isdl.php) (for compiling the installer)

### Compile Portable EXE

```powershell
# From the project root, execute:
.\build\Compile-ToExe.ps1
```

Or compile manually:
```powershell
# Install the ps2exe module (if not present)
Install-Module -Name ps2exe -Force -Scope CurrentUser

# Compile
Invoke-ps2exe -inputFile src\WindowsPrinterSharingFix.ps1 -outputFile release\WindowsPrinterSharingFix.exe `
    -iconFile assets\icon.ico -requireAdmin `
    -title "Windows Printer Sharing Fix" -company "khairudinfahmi"
```

### Compile Installer

```powershell
# Ensure WindowsPrinterSharingFix.exe exists in the release/ directory
& "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" build\installer.iss
```

---

## Testing & Verification

Testing is split into static code analysis, isolated execution tests, and scheduled tasks verification.

---

### Static Analysis & Shift-Left Validation

These steps ensure the codebase is clean, follows styling standards, and is free of syntax errors before git commit. Run these commands from the project root folder:

#### Test 1: PSScriptAnalyzer Pre-Commit Verification
To run standard security and styling rule scans on the script:
```powershell
# Install the analyzer module if missing
Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser

# Run analysis against the script
Invoke-ScriptAnalyzer -Path src/WindowsPrinterSharingFix.ps1
```

#### Test 2: PowerShell AST Syntax Validation
Verify that the script compiles successfully without unclosed brackets or parse errors:
```powershell
$errors = $null
[System.Management.Automation.Language.Parser]::ParseFile(
    (Resolve-Path "src/WindowsPrinterSharingFix.ps1"),
    [ref]$null,
    [ref]$errors
)
if ($errors) {
    Write-Host "[-] Syntax errors detected:" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host "Line $($_.Extent.StartLineNumber): $($_.Message)" -ForegroundColor Red }
} else {
    Write-Host "[SUCCESS] PowerShell script AST validation passed." -ForegroundColor Green
}
```

---

### Isolated Execution Testing

To safely run the script in a clean, sandboxed workspace without affecting your host system:

#### Test 3: Dev Containers & WSL Isolation
For lightweight container testing, configure a development container using WSL or Docker:
1. Make sure Docker Desktop and the VS Code Dev Containers extension are installed.
2. Create a `.devcontainer` configuration referencing a PowerShell image.
3. Reopen the project folder inside the container to run isolated manual tests.

#### Test 4: Session-Level Constrained Language Mode (CLM)
To verify that the script behaves correctly under constrained system environments, run a test session under CLM:
```powershell
# Start a new PowerShell session in Constrained Language Mode
Powershell.exe -ValidationLvl Path -LanguageMode ConstrainedLanguage
```

---

### Scheduled Background Tasks Verification

Run these commands in an elevated PowerShell console (run as Administrator) to verify that the registered tasks are working:

#### Task 1: SpoolerWatchdog Verification
This task detects if the Print Spooler service stops and restarts it automatically:
```powershell
# 1. Stop the spooler service manually
Stop-Service spooler -Force

# 2. Trigger the watchdog task immediately
Start-ScheduledTask -TaskName "SpoolerWatchdog"

# 3. Check the service status (should be "Running")
Get-Service spooler
```

#### Task 2: PrinterFixPostUpdate Verification
This task automatically re-applies critical registry configurations immediately on system startup:
```powershell
# 1. Temporarily write a test value (0) to a sharing registry key
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Print" -Name "RpcOverNamedPipes" -Value 0

# 2. Trigger the startup reapply task immediately
Start-ScheduledTask -TaskName "PrinterFixPostUpdate"

# 3. Check the registry value again (should be restored to "1")
Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Print" -Name "RpcOverNamedPipes"
```

#### Task 3: PrinterFixDaily Verification
This task daily re-applies critical registry configurations to prevent Windows Update from reverting changes:
```powershell
# 1. Temporarily write a test value (0) to a sharing registry key
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Print" -Name "RpcOverNamedPipes" -Value 0

# 2. Trigger the daily reapply task immediately
Start-ScheduledTask -TaskName "PrinterFixDaily"

# 3. Check the registry value again (should be restored to "1")
Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Print" -Name "RpcOverNamedPipes"
```

---

## Important Notes
- **Elevation Required**: This utility **must be executed as an Administrator** to modify registry keys and manage Windows subsystem services.
- **Backup Mandatory**: Always execute a **Registry Backup (Option `[64]`)** before running any automated fixes.
- **Reboot Required**: A system reboot is strictly necessary to commit registry changes and restart network stacks.
- **Air-Gapped Support**: This tool operates **100% offline**, requiring zero internet connectivity.

---

## Contributing

Contributions, issues, and feature requests are welcome! Please review [CONTRIBUTING.md](CONTRIBUTING.md) for detailed contribution guidelines.

---

## License

This project is open-source and free to use under the [GPL-3.0 License](LICENSE).
Feel free to modify and distribute, but please ensure credit is attributed to the original author.

---

## Author

**@khairudinfahmi** — 2026
