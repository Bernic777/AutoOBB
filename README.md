# **🚀 AutoOBB Legendary Installer v0.1**

**AutoOBB** adalah installer otomatis yang profesional, berperforma tinggi, dan memiliki tampilan visual yang memukau untuk interactsh-server (oleh ProjectDiscovery). Dirancang khusus untuk peneliti keamanan dan pemburu bug bounty, alat ini mengubah VPS kosong menjadi server interaksi Out-of-Band (OOB) yang berfungsi penuh dalam hitungan menit.

**Dibuat oleh Bernic777** — "Simplifying OOB Infrastructure Deployment."

## **✨ Fitur Utama**

* **🎨 Legendary Terminal UI**: Dilengkapi dengan antarmuka terminal modern berbasis warna ANSI, ASCII art profesional, dan indikator status langkah-demi-langkah.  
* **🛠️ Zero-Config Conflict Resolution**: Secara otomatis mendeteksi dan menonaktifkan layanan yang memperebutkan port seperti Apache, Nginx, dan systemd-resolved (Solusi Port 53 untuk Debian 12).  
* **🔒 Automated SSL**: Integrasi Certbot manual DNS-01 challenge untuk mendapatkan sertifikat Wildcard (\*.domainanda.com).  
* **📦 Template Engine**: Secara otomatis menyuntikkan Domain, Token, dan IP VPS Anda ke dalam config.yaml, index.html, dan layanan Systemd.  
* **⚡ Source Build**: Selalu mendapatkan versi terbaru dengan mengompilasi interactsh-server langsung dari repositori resmi Go.  
* **📡 Smart IP Detection**: Deteksi otomatis IP publik VPS untuk kemudahan konfigurasi dan panduan DNS.

## **📋 Konfigurasi DNS Wajib**

Sebelum menjalankan installer, pastikan DNS record Anda sudah diarahkan ke IP VPS. Ini sangat krusial agar server dapat menangkap interaksi.

| Host Name | Record Type | Address/Value | Priority |
| :---- | :---- | :---- | :---- |
| @ | A | IP\_VPS\_ANDA | N/A |
| \* | A | IP\_VPS\_ANDA | N/A |

* **@ (A Record)**: Mengarahkan domain utama ke VPS.  
* **\* (A Record)**: Mengarahkan semua subdomain (wildcard) ke VPS.  
* **TXT Record**: Anda akan diminta membuat record ini nanti saat proses verifikasi SSL Certbot.

## **🚀 Persiapan Cepat**

Pastikan Anda menjalankan ini sebagai **root** pada server **Debian 12+** atau **Ubuntu**.

### **1\. Unduh Installer**

wget \[https://raw.githubusercontent.com/username-anda/AutoOBB/main/interactsh-install-v3.sh\](https://raw.githubusercontent.com/username-anda/AutoOBB/main/interactsh-install-v3.sh)  
chmod \+x interactsh-install-v3.sh

### **2\. Jalankan Instalasi**

sudo ./interactsh-install-v3.sh \-d domainanda.com \-t token\_rahasia\_anda

### **3\. Flag Penggunaan**

| Flag | Deskripsi | Wajib |
| :---- | :---- | :---- |
| \-d | Domain target Anda (contoh: oob.example.com) | **Ya** |
| \-t | Token autentikasi untuk akses client | **Ya** |
| \-i | Jalur (path) ke template index.html kustom | Opsional |

## **🛠️ Alur Kerja Internal (Workflow)**

Installer ini mengikuti proses ketat dalam 6 tahap:

1. **Tahap 1: Dependensi**: Instalasi curl, git, certbot, jq, dan build essentials.  
2. **Tahap 2: Pembersihan Konflik**: Mematikan proses pada port 53, 80, 443, 25, dan 389\. Menonaktifkan DNS Stub Listener.  
3. **Tahap 3: Provisi SSL**: Menjalankan Certbot manual DNS-01 untuk SSL Wildcard.  
4. **Tahap 4: Templating**: Memproses file config.yaml dan layanan systemd menggunakan placeholder engine.  
5. **Tahap 5: Build Go Engine**: Instalasi Go runtime terbaru dan kompilasi binary server.  
6. **Tahap 6: Aktivasi**: Reload systemd dan mengaktifkan layanan interactsh agar otomatis menyala saat reboot.

## **🖥️ Koneksi Client**

Setelah server berjalan, Anda dapat terhubung menggunakan interactsh-client:

interactsh-client \-server domainanda.com \-token token\_rahasia\_anda

## **📁 Struktur File**

* **Database**: /var/lib/interactsh  
* **Web Index**: /var/www/oob/index.html  
* **Konfigurasi**: /root/.config/interactsh-server/config.yaml  
* **System Service**: /etc/systemd/system/interactsh.service

## **🤝 Kredit**

* [ProjectDiscovery](https://www.google.com/search?q=https://github.com/projectdiscovery) untuk engine interactsh yang luar biasa.  
* Komunitas Bug Bounty atas dukungan berkelanjutan dalam metodologi pengujian OOB.

## **⚖️ Lisensi**

Didistribusikan di bawah Lisensi MIT. Lihat file LICENSE untuk informasi lebih lanjut.

\<p align="center"\>

\<b\>Dibuat dengan ❤️ untuk Komunitas Bug Bounty\</b\>

\</p\>
