# Windows Printer Sharing Fix

[![Windows Compatibility](https://img.shields.io/badge/Windows-10%20%7C%2011%20(24H2%2F25H2%2F26H2)%20%7C%20Server%202025-0078D6?logo=windows&logoColor=white)](https://github.com/khairudinfahmi/WindowsPrinterSharingFix/releases)
[![Version](https://img.shields.io/badge/version-2.4.0-emerald.svg?style=flat)](https://github.com/khairudinfahmi/WindowsPrinterSharingFix/releases/tag/v2.4.0)
[![License](https://img.shields.io/badge/license-GPL--3.0-blue.svg)](LICENSE)
[![Architecture](https://img.shields.io/badge/architecture-x64%20%7C%20ARM64-orange.svg)](https://github.com/khairudinfahmi/WindowsPrinterSharingFix)
[![Language](https://img.shields.io/badge/language-Indonesian%20%7C%20English-purple.svg)](https://github.com/khairudinfahmi/WindowsPrinterSharingFix)

Solusi lengkap, otomatis, dan teruji untuk mengatasi seluruh permasalahan berbagi (*sharing*) printer pada jaringan Windows lokal (Workgroup maupun Active Directory). Dirancang khusus agar ramah bagi pengguna kantor biasa sekaligus sangat tangguh bagi teknisi IT dan administrator sistem jaringan.

Bekerja secara sempurna pada **Windows 10**, **Windows 11 (termasuk update terbaru 24H2, 25H2, 26H2+)**, arsitektur **ARM64**, dan **Windows Server 2016 / 2019 / 2022 / 2025**.

---

## 🌟 Apa yang Baru di Versi 2.4.0?

1. **Dukungan Dwibahasa Penuh (Bilingual Engine ID / EN)**:
   - Pengguna dapat beralih bahasa antarmuka secara instan antara **Bahasa Indonesia** dan **English** cukup dengan menekan tombol **`[L]`** pada Menu Utama maupun Submenu.
   - Pilihan bahasa disimpan secara permanen di registri pengguna (`HKCU:\Software\WindowsPrinterSharingFix\Language`).
2. **Indikator Kesehatan Sistem Waktu-Nyata (*Live Health Banner*)**:
   - Header konsol kini secara otomatis memindai dan menampilkan status 4 pilar penting printer sharing setiap kali menu dimuat:
     ```text
     STATUS SISTEM: Spooler [AKTIF] | Jaringan [PRIVATE] | SMB Signing [SESUAI] | Sandi Sharing [OFF]
     ```
   - Memudahkan teknisi mengidentifikasi akar permasalahan jaringan hanya dalam 1 detik.
3. **Antarmuka Konsol Ramah Pengguna (*Human-Friendly UI*)**:
   - Menata ulang menu dari format lama yang padat (180 kolom) menjadi **8 Kategori Solusi Logis + 1 Panduan Bantuan** yang rapi dan nyaman dibaca di layar terminal standar (86 kolom).
4. **Optimasi Cepat Berbasis Peran Komputer**:
   - **Komputer Host / Server Printer (Opsi [3] di Submenu 1)**: Untuk PC yang langsung terhubung ke printer fisik via kabel USB atau jaringan lokal.
   - **Komputer Klien / Staf (Opsi [4] di Submenu 1)**: Untuk PC kerja karyawan yang ingin menyambung dan mencetak ke printer yang di-share.
5. **Mitigasi Kebijakan Keamanan Windows 11 Terbaru**:
   - Memperbaiki pemblokiran *RPC over Named Pipes* (`RpcOverNamedPipes`, `RegisterSpoolerRemoteRpcEndPoint`).
   - Menyelaraskan kebijakan wajib *SMB Signing* pada Windows 11 24H2 agar komputer klien tetap dapat terhubung tanpa error permission.
   - Mengatasi proteksi Kerberos ketat pada jaringan Workgroup lokal melalui pengaturan fallback NTLMv2 yang aman.
6. **Dukungan Pintasan Langsung (*Direct Shortcuts*)**:
   - Anda tetap dapat mengetikkan kode modul klasik (misal: `84` untuk ALLFIX, `83` untuk Jalur Ekstrem Windows 11, `64` untuk Cadangan Registri, `86` untuk Pemetaan Port UNC, `31` untuk Reset Spooler, dll.) langsung dari Menu Utama tanpa perlu masuk ke submenu.

---

## 🚀 Panduan Memulai Cepat (Quick Start)

### Pilihan 1: Jalankan Installer Setup (Disarankan)
1. Unduh berkas installer terbaru: `WindowsPrinterSharingFix_Installer.exe` dari menu [Releases](https://github.com/khairudinfahmi/WindowsPrinterSharingFix/releases).
2. Jalankan berkas installer dan ikuti petunjuk di layar (akan membuat shortcut di Desktop dan Start Menu).
3. Buka **Windows Printer Sharing Fix** dari Desktop (otomatis meminta akses Administrator).

### Pilihan 2: Gunakan Versi Portabel (.EXE)
1. Unduh berkas `WindowsPrinterSharingFix.exe` dari menu [Releases](https://github.com/khairudinfahmi/WindowsPrinterSharingFix/releases).
2. Klik kanan pada berkas, pilih **Run as Administrator** (*Jalankan sebagai Administrator*).

### Pilihan 3: Jalankan Langsung Melalui PowerShell
Buka PowerShell sebagai Administrator dan jalankan skrip sumber:
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
& ".\src\WindowsPrinterSharingFix.ps1"
```

---

## 📋 Struktur Menu & Submenu Lengkap (Versi 2.4.0)

Aplikasi memiliki susunan menu yang terstruktur dan mudah dipahami:

```text
======================================================================================
   WINDOWS PRINTER SHARING FIX  |  Solusi Berbagi Printer Windows
   Versi: 2.4.0  |  Sistem: WINDOWS 11 HOME SINGLE LANGUAGE 26200 64-BIT
   Komputer: PC-KANTOR-01  |  Pengguna: Administrator
   STATUS SISTEM: Spooler [AKTIF] | Jaringan [PRIVATE] | SMB Signing [SESUAI] | Sandi Sharing [OFF]
======================================================================================

  [1] Solusi Cepat & Otomatis (ALLFIX & Windows 11 Terbaru)
  [2] Perbaikan Berdasarkan Kode Error Spesifik (Error 0x...)
  [3] Pengaturan Jaringan, Berbagi (SMB) & Firewall
  [4] Manajemen Layanan Spooler & Antrean Cetak
  [5] Penanganan Driver Printer & Kompatibilitas
  [6] Kredensial, Hak Akses & Keamanan Windows
  [7] Pemetaan Port & Sambungan Manual (UNC / TCP-IP)
  [8] Cadangan (Backup), Diagnostik & Pemulihan Sistem
  [9] Panduan Bantuan Modul Lengkap (Help System)

  [L] Ganti Bahasa (English / Indonesia)
  [?] Tampilkan Bantuan Per Modul (contoh: ? 84 atau help 86)
  [0] Keluar dari Aplikasi
```

---

### 1. Solusi Cepat & Otomatis (ALLFIX & Windows 11 Terbaru)
Kategori utama yang paling sering digunakan untuk menyelesaikan masalah printer sharing dalam 1 kali klik.

| No | Nama Solusi / Modul | Kode Modul | Fungsi & Penjelasan |
| :---: | :--- | :---: | :--- |
| **1** | **ALLFIX - 50 Perbaikan Otomatis Sekaligus** | `[84]` | **Rekomendasi Utama**: Menjalankan 50 langkah perbaikan sistem, registri, firewall, protokol RPC, dan spooler secara berurutan. Menyelesaikan 98% kasus printer kantor. |
| **2** | **Solusi Khusus Windows 11 Terbaru (24H2/25H2/26H2 & ARM64)** | `[83]` | Menerapkan perbaikan mendalam untuk Windows 11 versi rilis terbaru: mengizinkan *RPC over Named Pipes*, relaksasi *SMB Signing*, dan membuka proteksi keamanan modern. |
| **3** | **Optimasi Komputer Host / Server Printer** | `[87]` | Khusus dijalankan di **PC yang dicolok printer**: Mengaktifkan remote spooler RPC endpoint, set jaringan Private, buka guest sharing, buka port firewall & WSD, rapikan nama share, dan pasang Spooler Watchdog. |
| **4** | **Optimasi Komputer Klien / Staf** | `[88]` | Khusus dijalankan di **PC staf/klien yang ingin mencetak**: Mengaktifkan RPC Named Pipes, bypass elevasi Point and Print, matikan client SMB signing, perbaiki izin HKCU, aktifkan penemuan perangkat, dan flush cache DNS. |
| **5** | **Silent ALLFIX (Otomatis + Langsung Restart)** | `[85]` | Mengeksekusi seluruh 50 perbaikan secara senyap tanpa konfirmasi lalu langsung merestart sistem operasi (sangat praktis untuk teknisi lapangan). |
| **6** | **Kelola Pembaruan Windows & Blokir Update Perusak** | `[69]` | Memberikan opsi jeda Windows Update selama 35 hari, menghapus paket KB tertentu yang bermasalah, atau memblokir sementara layanan pembaruan otomatis agar setelan printer tidak rusak. |

---

### 2. Perbaikan Berdasarkan Kode Error Spesifik
Solusi presisi untuk mengatasi kode error angka heksadesimal yang sering dimunculkan Windows saat mencoba menyambung ke printer sharing.

| No | Kode Error | Modul | Penyebab Masalah & Solusi Teknis |
| :---: | :--- | :---: | :--- |
| **1** | **0x0000011b** | `[01]` | Disebabkan oleh mitigasi keamanan CVE-2021-1678. Skrip menyetel `RpcAuthnLevelPrivacyEnabled = 0` sehingga sambungan RPC antar-komputer printer kembali diizinkan. |
| **2** | **0x00000709 / 0x7c** | `[02]` | Terjadi saat Windows menolak menyambung karena nama printer atau driver dibatasi. Menyetel `CopyFilesPolicy = 1` dan `ForceLegacyPrintDriver = 1` untuk mengizinkan instalasi driver legacy. |
| **3** | **0x00000bc4** | `[03]` | Windows melaporkan "No printers were found" padahal printer aktif di LAN. Mengonfigurasi `RpcUseNamedPipeProtocol = 1` dan `RpcProtocols = 7` agar pencarian RPC berhasil. |
| **4** | **0x80070035** | `[04]` | "The network path was not found". Memastikan layanan penemuan jaringan Windows (`fdPHost`, `FDResPub`, `SSDPSRV`, `upnphost`) berjalan dan terkonfigurasi otomatis. |
| **5** | **0x000006d1** | `[05]` | Terjadi saat proses Client-Side Rendering (CSR) gagal mengolah format cetak. Skrip mematikan CSR (`DisableClientSideRendering = 1`) sehingga proses rendering dipindahkan ke komputer host. |
| **6** | **0x80070005** | `[06]` | "Access Denied" pada folder antrean cetak. Mengatur ulang hak akses folder `C:\Windows\System32\Spool\Printers` dan memberikan hak penuh (*Full Control*) kepada universal SID Everyone (`S-1-1-0`). |
| **7** | **0x00000040** | `[07]` | "The specified network name is no longer available". Mengonfigurasi parameter SMB `KeepConn = 1`, `EnableMultichannel = 0`, serta membersihkan sesi NetBIOS yang menggantung. |
| **8** | **0x00000002** | `[08]` | Gagal menyalin berkas driver dari PC server ke klien. Mengaktifkan `UseSharedSpooler = 1` untuk bypass pembatasan instalasi driver klien. |
| **9** | **0x0000007e** | `[09]` | Ketidakcocokan arsitektur driver 32-bit dan 64-bit pada lingkungan cetak campuran. Mendaftarkan kunci kompatibilitas bitness RPC. |

---

### 3. Pengaturan Jaringan, Berbagi (SMB) & Firewall
Fondasi penting agar komputer dapat saling melihat, mengirim data, dan berkomunikasi melalui port jaringan tanpa hambatan.

| No | Opsi Submenu | Modul | Rincian & Manfaat |
| :---: | :--- | :---: | :--- |
| **1** | **Ubah Profil Jaringan ke Private** | `[11]` | Mengubah status koneksi dari Public ke Private. Wajib dilakukan karena Windows memblokir seluruh fitur printer sharing jika jaringan bertipe Public. |
| **2** | **Buka Akses Berbagi Tanpa Sandi & Guest Auth** | `[12]` | Mengaktifkan `AllowInsecureGuestAuth = 1`, `everyoneincludesanonymous = 1`, dan `LimitBlankPasswordUse = 0` agar PC lain bisa langsung mencetak tanpa diminta password login Windows. |
| **3** | **Matikan Wajib SMB Signing** | `[16]` | Menyetel `RequireSecuritySignature = 0` pada LanmanWorkstation & LanmanServer. Mengatasi Windows 11 gagal mengakses printer atau shared folder di komputer lain. |
| **4** | **Kelola Protokol SMB (SMB2/SMB3 & SMB 1.0)** | `[15] & [17]` | Mengonfigurasi protokol SMB modern serta menyediakan opsi darurat untuk mengaktifkan atau menonaktifkan protokol lawas SMB 1.0. |
| **5** | **Buka Port Firewall untuk Berbagi Berkas & Printer** | `[14] & [21]` | Membuka port TCP 445, 139, 135 dan UDP 137, 138, 3702 (WSD), 5353 (mDNS) pada Windows Defender Firewall. |
| **6** | **Aktifkan Penemuan Perangkat Jaringan & WSD** | `[20] & [30]` | Menjalankan tumpukan layanan penemuan perangkat (`fdPHost`, `FDResPub`, `SSDPSRV`) agar printer modern otomatis muncul di daftar pencarian Windows. |
| **7** | **Prioritas Jaringan & Atasi Konflik Virtual Switch** | `[18] & [23]` | Mengurutkan provider jaringan fisik di atas kartu virtual (Hyper-V / WSL / VMware / VPN) agar lalulintas printer tidak tersasar. |
| **8** | **Reset Total Konfigurasi Jaringan & Sockets** | `[10] & [27]` | Melakukan flush DNS, reset Winsock, reset TCP/IP stack (`netsh int ip reset`), dan membersihkan sesi port yang menggantung. |
| **9** | **Matikan Protokol IPv6** | `[19]` | Menonaktifkan binding IPv6 pada kartu jaringan jika kantor menggunakan jaringan murni IPv4 (mencegah keterlambatan pencarian nama host via link-local IPv6). |
| **10** | **Konfigurasi Berbagi IPP / Mopria & LPR Port** | `[22] & [24]` | Mengaktifkan dukungan Internet Printing Protocol (IPP) dan port legacy LPR untuk printer jaringan modern maupun mesin cetak industri. |

---

### 4. Manajemen Layanan Spooler & Antrean Cetak
Mengatasi masalah umum layanan Print Spooler yang sering tiba-tiba mati (*crash*), macet (*freeze*), atau menolak menerima dokumen baru.

| No | Opsi Submenu | Modul | Rincian & Manfaat |
| :---: | :--- | :---: | :--- |
| **1** | **Reset Layanan Spooler & Bersihkan Antrean Macet** | `[31] & [37]` | Menghentikan paksa spooler dan proses terkait, menghapus berkas dokumen macet (`.spl` dan `.shd`) di folder `PRINTERS`, lalu menyalakan spooler kembali secara bersih. |
| **2** | **Konfigurasi Pemulihan Otomatis Saat Spooler Crash** | `[34]` | Mengatur konfigurasi service recovery Windows agar otomatis me-restart layanan Spooler segera setelah mengalami crash (tindakan pemulihan ke-1, 2, dan berikutnya). |
| **3** | **Pasang Spooler Watchdog Otomatis Tiap 5 Menit** | `[36]` | Membuat tugas terjadwal (*Scheduled Task*) di Windows yang secara aktif memantau status Spooler setiap 5 menit dan menyalakannya kembali jika mati. |
| **4** | **Setel Ulang Dependensi Registri Spooler** | `[35] & [38]` | Mengembalikan dependensi layanan Spooler ke standar pabrik (`RPCSS` dan `http`), membersihkan dependensi rusak dari pihak ketiga yang membuat spooler gagal start. |
| **5** | **Restart Layanan Sistem RPC & DCOM** | `[32]` | Memeriksa dan merestart layanan fondasi sistem `RpcSs` dan `DcomLaunch` untuk mengatasi pesan error *"The RPC server is unavailable"*. |
| **6** | **Restart Spooler Komputer Lain dari Jarak Jauh (Remote)** | `[33]` | Mengeksekusi perintah restart spooler pada komputer server printer melalui jaringan via PowerShell WinRM/DCOM tanpa harus datang fisik ke komputer tersebut. |

---

### 5. Penanganan Driver Printer & Kompatibilitas
Mengelola driver printer pihak ketiga, menghapus driver usang yang mengunci sistem, dan mengatasi konflik driver modern Windows 11.

| No | Opsi Submenu | Modul | Rincian & Manfaat |
| :---: | :--- | :---: | :--- |
| **1** | **Hentikan Paksa Driver Mengunci (Force Kill)** | `[44]` | Mematikan paksa proses `splwow64.exe`, `printfilterpipelinesvc.exe`, dan isolasi driver yang menahan berkas driver agar dapat dihapus atau diperbarui. |
| **2** | **Matikan Isolasi Driver Printer** | `[40]` | Mengubah `IsolationPolicy = 0`. Driver berjalan langsung di dalam proses spooler, mencegah printer tipe lama crash karena isolasi proses. |
| **3** | **Bersihkan Driver Usang & Rusak (Driver Sweeper)** | `[43]` | Memindai paket driver printer pihak ketiga yang sudah tidak terikat ke perangkat fisik menggunakan `pnputil` dan menghapusnya secara aman. |
| **4** | **Hapus Printer Hantu & Duplikat Port USB** | `[45] & [46]` | Menghapus antrean printer duplikat ("Copy 1", "Copy 2") dan membersihkan port USB mati yang tertinggal saat printer berpindah colokan. |
| **5** | **Konfigurasi Driver Universal V4 & Mode Render Driver** | `[41] & [42]` | Mengizinkan sharing untuk driver Windows 11 V4 Class Driver dan menyediakan opsi penggantian mode render antara RAW, PCL, dan PostScript. |
| **6** | **Perbaiki Cetak Browser & Aplikasi UWP Windows** | `[47] & [49]` | Mengatasi jendela dialog cetak pada Google Chrome, Microsoft Edge, dan aplikasi modern Windows yang sering macet (*blank* atau *freeze*). |
| **7** | **Pasang Ulang Printer Bawaan Windows** | `[48]` | Menginstal ulang printer virtual bawaan Windows yang hilang, seperti *Microsoft Print to PDF* dan *Microsoft XPS Document Writer*. |
| **8** | **Kunci Printer Default Permanen via Registri** | `[50] & [51]` | Mengunci printer default pilihan pengguna di registri Windows dan menonaktifkan fitur otomatis Windows yang suka mengganti printer default sendiri. |
| **9** | **Rapikan Nama Share Printer dari Karakter Ilegal** | `[53]` | Memindai seluruh nama share printer dan mengganti spasi atau simbol terlarang (`!@#$%^&*`) menjadi garis bawah (`_`) agar tidak ditolak protokol jaringan. |
| **10** | **Buka Antarmuka Print Management & Driver Properties** | `[39]` | Membuka jendela resmi Windows Server Print Management (`printmanagement.msc` atau `printui`) untuk memeriksa seluruh rincian driver terinstal. |

---

### 6. Kredensial, Hak Akses & Keamanan Windows
Mengelola otentikasi login antar-komputer, kredensial tersimpan di Windows Vault, serta mitigasi kebijakan keamanan Windows tingkat tinggi.

| No | Opsi Submenu | Modul | Rincian & Manfaat |
| :---: | :--- | :---: | :--- |
| **1** | **Simpan Kredensial Komputer Printer ke Vault** | `[60]` | Menyimpan username dan password komputer target secara permanen ke *Windows Credential Manager* (`cmdkey`) agar akses ke shared printer selalu diizinkan. |
| **2** | **Bersihkan Kredensial Usang dari Windows Vault** | `[61]` | Memeriksa dan menghapus kredensial login usang yang tersimpan di Vault yang sering membuat koneksi printer ditolak karena password lama. |
| **3** | **Terapkan Kredensial ke Semua Pengguna di Komputer Ini** | `[63]` | Menyuntikkan kredensial printer ke seluruh profil pengguna yang ada di komputer (*RunOnce multi-user injection*) dengan pembersihan otomatis. |
| **4** | **Bypass Filter Token UAC Administrator** | `[57]` | Mengaktifkan `LocalAccountTokenFilterPolicy = 1` agar akun administrator lokal di jaringan Workgroup tidak dibatasi saat mengakses printer via remote. |
| **5** | **Standarisasi Otentikasi NTLMv2** | `[58]` | Menyelaraskan respon otentikasi NTLMv2 (`LmCompatibilityLevel = 2` atau `3`) agar komputer dengan edisi Windows berbeda dapat saling mengenali. |
| **6** | **Bypass Proteksi Keamanan Ketat (LSA, SAC, Credential Guard)** | `[54], [55], [62]` | Menyesuaikan proteksi ketat Windows 11 yang sering memblokir komunikasi otentikasi RPC/SMB legacy antar-komputer kantor. |
| **7** | **Kelola Windows Protected Print (WPP)** | `[59]` | Mengatur fitur baru Windows 11 *Windows Protected Print* agar sistem tidak mematikan driver v3 pihak ketiga secara sepihak. |
| **8** | **Bypass Kebijakan Point and Print Elevation** | `[56]` | Menghilangkan pesan konfirmasi dan permintaan izin Administrator saat pengguna klien menginstal driver printer dari komputer server. |
| **9** | **Perbaiki Pengalihan Printer Remote Desktop (RDP)** | `[52]` | Mengaktifkan pengalihan (*redirection*) printer lokal ke dalam sesi Remote Desktop (RDP) melalui modifikasi registri Terminal Services. |

---

### 7. Pemetaan Port & Sambungan Manual (UNC / TCP-IP)
Solusi pamungkas ketika Windows bersikeras menolak menghubungkan printer melalui penelusuran jaringan biasa (*Network Discovery*).

| No | Opsi Submenu | Modul | Rincian & Manfaat |
| :---: | :--- | :---: | :--- |
| **1** | **Petakan Port Lokal ke Jalur UNC (Bypass Ampuh 0x00000709)** | `[86]` | **Solusi Paling Ampuh**: Membuat port lokal baru yang langsung diarahkan ke path jaringan host (contoh: `\\192.168.1.10\PRINTER`). Melewati seluruh pembatasan dialog printer sharing Windows! |
| **2** | **Hapus Pemetaan Port Lokal UNC** | `[87]` | Menghapus port lokal UNC yang pernah dibuat sebelumnya dari daftar port spooler atau registri Ports. |
| **3** | **Ubah Port Printer WSD ke Standar TCP/IP** | `[26]` | Mengonversi printer modern berbasis WSD (yang sering tiba-tiba berstatus *Offline*) menjadi port standar IP statis yang jauh lebih stabil dan tahan gangguan. |
| **4** | **Tambah Port Standar TCP/IP Secara Manual** | `[29]` | Membuat port printer raw TCP/IP baru (port 9100) menggunakan skrip WMI langsung berdasarkan alamat IP printer. |
| **5** | **Pindai Printer Aktif di Komputer Target** | `[25]` | Melakukan pemindaian terhadap komputer tujuan di jaringan dan menampilkan daftar nama share printer yang sedang dibuka. |

---

### 8. Cadangan (Backup), Diagnostik & Pemulihan Sistem
Fitur keselamatan kerja untuk mencadangkan kondisi sistem sebelum perubahan dilakukan serta instrumen lengkap untuk analisis mendalam.

| No | Opsi Submenu | Modul | Rincian & Manfaat |
| :---: | :--- | :---: | :--- |
| **1** | **Cadangkan 5 Hive Registri Printer & Jaringan** | `[64]` | Mengekspor 5 cabang registri vital (Print, PrintersPolicy, LanmanWorkstation, LanmanServer, Lsa) ke folder cadangan `C:\WindowsPrinterSharingFixBackup`. |
| **2** | **Pulihkan Registri dari Cadangan (Rollback)** | `[65]` | Mengimpor kembali berkas cadangan registri jika Anda ingin mengembalikan kondisi sistem ke keadaan semula sebelum perbaikan. |
| **3** | **Buat System Restore Point Windows** | `[66]` | Membuat titik pemulihan sistem Windows (*System Restore Point*) secara instan dengan proteksi pembatasan frekuensi otomatis. |
| **4** | **Periksa & Perbaiki Integritas File Sistem (SFC & DISM)** | `[67]` | Menjalankan utilitas resmi Windows `sfc /scannow` dan `dism /online /cleanup-image /restorehealth` untuk memperbaiki file sistem operasi yang korup. |
| **5** | **Tes Jangkauan Jaringan & Ping Port 445/135** | `[74]` | Menguji konektivitas soket TCP pada port 445 (SMB) dan port 135 (RPC) ke komputer target untuk memastikan tidak ada firewall pihak ketiga yang memblokir. |
| **6** | **Analisis Log Error Layanan Cetak (PrintService/Admin)** | `[76] & [78]` | Membaca log kejadian Windows (*Event Viewer*) untuk layanan cetak dan memberikan saran tindakan teknis berdasarkan ID kesalahan yang ditemukan. |
| **7** | **Buat Laporan Diagnostik Interaktif (HTML)** | `[79]` | Mengumpulkan seluruh data status sistem, layanan, port, dan registri ke dalam satu berkas laporan web interaktif (*HTML Diagnostic Report*). |
| **8** | **Pindai Intervensi Kebijakan Domain / GPO** | `[80]` | Memeriksa apakah komputer terhubung ke Domain Controller dan mendeteksi apakah kebijakan Group Policy menimpa setelan printer sharing lokal. |
| **9** | **Alat Migrasi Konfigurasi Printer (PrintBRM)** | `[81]` | Mengekspor atau mengimpor seluruh antrean, port, dan driver printer antar-komputer menggunakan utilitas bawaan Windows PrintBRM. |
| **10** | **Paksa Status Printer Menjadi Online** | `[71]` | Mengirim instruksi WMI ke antrean cetak untuk memaksa printer yang tersangkut pada status *Offline* kembali menjadi *Online*. |
| **11** | **Buka Konsol Services.msc & Catatan Log Skrip** | `[72] & [75]` | Membuka manajer layanan Windows (`services.msc`) atau langsung membuka berkas catatan log eksekusi (`C:\WindowsPrinterSharingFixLog.txt`). |

---

### 9. Panduan Bantuan Modul Lengkap (Help System)
Menampilkan penjelasan mendalam, fungsi teknis, dan saran penggunaan untuk seluruh 89 modul yang ada di dalam aplikasi.
- Ketik **`? <kode>`** atau **`help <kode>`** di Menu Utama (contoh: `? 84` atau `help 86`) untuk melihat panduan instan modul tersebut.
- Membuka dokumentasi web offline interaktif melalui peramban web default Anda.

---

## ⚙️ Mekanisme Otomatis di Balik Layar (Under the Hood)

Saat Anda menjalankan salah satu modul perbaikan otomatis (seperti **ALLFIX [84]** atau **Jalur Ekstrem [83]**), aplikasi mengeksekusi serangkaian mekanisme pelindung di latar belakang untuk menjamin solusi bersifat permanen:

1. **Sinkronisasi Kebijakan (`gpupdate /force`)**: Memperbarui kebijakan Group Policy lokal sebelum registri ditulis, mencegah setelan langsung ditimpa ulang oleh sistem.
2. **Pencadangan Otomatis Registri**: Secara proaktif mencadangkan 5 node registri utama ke `C:\WindowsPrinterSharingFixBackup` sebelum melakukan modifikasi apa pun.
3. **Penyuntikan Tugas Terjadwal (*Scheduled Tasks*)**:
   - `PrinterFixPostUpdate` (saat komputer boot) & `PrinterFixDaily` (setiap hari jam 10:00): Menerapkan ulang kunci registri penting jika sewaktu-waktu pembaruan bulanan Windows Update (*Patch Tuesday*) mereset pengaturan sharing Anda.
   - `SpoolerWatchdog` (setiap 5 menit): Memastikan layanan Print Spooler selalu menyala dan pulih secara otomatis jika terjadi crash akibat driver pihak ketiga.
   *(Semua tugas terjadwal ini telah dikonfigurasi kebal batas baterai laptop sehingga tetap aktif saat tidak tersambung ke charger).*
4. **Pembersihan Bersih Sesi & Soket**: Menjalankan `klist purge`, `ipconfig /flushdns`, dan `nbtstat -RR` untuk memastikan komputer tidak terkunci pada tiket otentikasi atau sesi SMB lama yang kedaluwarsa.

---

## 🌐 English Quick Reference

Windows Printer Sharing Fix is a robust, bilingual, and automated utility designed to eliminate all printer sharing and network printing errors on Windows environments.

### Key Highlights:
- **Instant Bilingual Switching**: Press **`[L]`** at any prompt to switch between English and Indonesian instantly.
- **Real-Time System Health Banner**: Displays live status for Print Spooler, Network Profile, SMB Signing, and Password Protection directly in the menu header.
- **Role-Based Optimization**: Dedicated playbooks for Printer Host PCs (USB-connected) and Client Workstations.
- **Windows 11 24H2/25H2 Ready**: Resolves RPC over Named Pipes restrictions, enforces local NTLMv2 auth fallback, and neutralizes strict SMB signing blocks.
- **Direct Shortcuts**: Enter any classic module code (e.g., `84` for ALLFIX, `83` for Extreme Path, `86` for UNC Port Bypass) directly from the Main Menu.

---

## 📄 Lisensi & Kontribusi

Proyek ini dirilis di bawah lisensi resmi **GPL-3.0 License**. Silakan gunakan, pelajari, dan distribusikan secara bebas untuk kebutuhan personal maupun perkantoran.

Jika Anda menemukan kendala atau ingin menyumbangkan perbaikan, silakan buat laporan pada menu [GitHub Issues](https://github.com/khairudinfahmi/WindowsPrinterSharingFix/issues) atau ajukan Pull Request sesuai panduan di [CONTRIBUTING.md](CONTRIBUTING.md).
