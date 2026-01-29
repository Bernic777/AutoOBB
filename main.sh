#!/bin/bash
set -e

#############################################
# AUTOOBB LEGENDARY INSTALLER v0.1 (PROD)
# Visual Edition - Modern Terminal UI
# Created by Bernic777
#############################################

# Warna untuk estetika terminal
R='\033[0;31m'
G='\033[0;32m'
Y='\033[1;33m'
B='\033[0;34m'
M='\033[0;35m'
C='\033[0;36m'
W='\033[1;37m'
NC='\033[0m' # No Color

# Ikon status
CHECK="[${G}✔${NC}]"
INFO="[${B}i${NC}]"
WARN="[${Y}!${NC}]"
ERROR="[${R}✘${NC}]"
ACTION="[${M}➜${NC}]"

# Ambil direktori tempat skrip ini berada
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
# Deteksi IP Publik VPS
VPS_IP=$(curl -s https://ifconfig.me || echo "YOUR_VPS_IP")

# Fungsi Banner (Logo AutoOBB)
show_banner() {
    clear
    echo -e "${C}"
    echo "     _         _           ___  ____  ____  "
    echo "    / \  _   _| |_ ___    / _ \| __ )| __ ) "
    echo "   / _ \| | | | __/ _ \  | | | |  _ \|  _ \ "
    echo "  / ___ \ |_| | || (_) | | |_| | |_) | |_) |"
    echo " /_/   \_\__,_|\__\___/   \___/|____/|____/ "
    echo -e "              ${W}Auto OBB INSTALLER v0.1${NC}"
    echo -e "           ${B}-----------------------------------------${NC}"
    echo ""
}

# Fungsi Panduan DNS (Wajib Dilakukan)
show_dns_guide() {
    echo -e "${Y}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${Y}║         MANDATORY DNS CONFIGURATION (MUST DO)            ║${NC}"
    echo -e "${Y}╚══════════════════════════════════════════════════════════╝${NC}"
    echo -e "${W}Buka DNS Management Panel Anda dan tambahkan record berikut:${NC}"
    echo ""
    echo -e "${C}Host Name      Type       Address/Value            Priority${NC}"
    echo -e "${G}@              A          $VPS_IP           N/A${NC}"
    echo -e "${G}* A          $VPS_IP           N/A${NC}"
    echo ""
    echo -e "${INFO} ${W}Penjelasan:${NC}"
    echo -e " • ${C}@ (A Record)${NC}  : Mengarahkan domain utama ke IP VPS ini."
    echo -e " • ${C}* (A Record)${NC}  : Mengarahkan semua subdomain (wildcard) ke IP VPS."
    echo -e " • ${C}TXT Record${NC}   : Akan diminta nanti saat proses SSL (Certbot)."
    echo ""
    echo -e "${B}------------------------------------------------------------${NC}"
    echo -e "${Y}Point your domain to this IP ($VPS_IP) before proceeding.${NC}"
    echo -e "${B}------------------------------------------------------------${NC}"
    read -p "Sudah dikonfigurasi? Tekan [ENTER] untuk memulai instalasi..."
}

usage() {
    show_banner
    echo -e "${Y}PENGGUNAAN:${NC}"
    echo -e "  bash $0 -d domain.com -t token_rahasia [-i /path/ke/index.html]"
    echo ""
    echo -e "${Y}OPSI:${NC}"
    echo -e "  -d    Domain utama (Contoh: oob.domain.id)"
    echo -e "  -t    Auth Token untuk akses client"
    echo -e "  -i    (Opsional) Custom index.html template"
    echo ""
    exit 1
}

# Parsing argumen
while getopts "d:t:i:" opt; do
  case "$opt" in
    d) DOMAIN="$OPTARG" ;;
    t) TOKEN="$OPTARG" ;;
    i) CUSTOM_INDEX="$OPTARG" ;;
    *) usage ;;
  esac
done

if [ -z "$DOMAIN" ] || [ -z "$TOKEN" ]; then usage; fi
if [ "$EUID" -ne 0 ]; then echo -e "${ERROR} ${R}FATAL: Jalankan skrip ini sebagai ROOT!${NC}"; exit 1; fi

show_banner
echo -e "${INFO} ${W}Konfigurasi Target:${NC}"
echo -e "      ${C}• Domain : ${G}$DOMAIN${NC}"
echo -e "      ${C}• Token  : ${G}$TOKEN${NC}"
echo -e "      ${C}• IP VPS : ${G}$VPS_IP${NC}"
echo -e "${B}------------------------------------------------------------${NC}"
sleep 1

# Tampilkan panduan DNS sebelum lanjut
show_dns_guide

#############################################
# 1. DEPENDENCIES
#############################################
echo -e "\n${ACTION} ${W}Tahap 1: Menginstal Dependensi Sistem...${NC}"
apt update -qq && apt install -y curl wget git build-essential certbot jq psmisc lsof -qq
echo -e "${CHECK} Dependensi berhasil diinstal."

# Setup Folder Produksi
mkdir -p /var/lib/interactsh /var/www/oob /root/.config/interactsh-server/storage
chmod 700 /var/lib/interactsh

#############################################
# 2. RESOLVE PORT CONFLICTS (DEBIAN 12 FIX)
#############################################
echo -e "\n${ACTION} ${W}Tahap 2: Membersihkan Konflik Port (Apache/Nginx/Resolved)...${NC}"

# Stop dan Disable layanan pengganggu
services=("apache2" "nginx" "systemd-resolved")
for svc in "${services[@]}"; do
    if systemctl is-active --quiet "$svc"; then
        echo -e "      ${Y}»${NC} Menghentikan $svc..."
        systemctl stop "$svc" || true
        systemctl disable "$svc" || true
    fi
done

# Khusus Debian 12: Lepaskan port 53 dari systemd-resolved
if [ -f /etc/systemd/resolved.conf ]; then
    echo -e "      ${Y}»${NC} Konfigurasi ulang DNS Stub listener..."
    sed -i 's/#DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf || true
    systemctl restart systemd-resolved || true
fi

# Paksa kill proses yang masih menduduki port krusial
echo -e "      ${Y}»${NC} Membersihkan sisa proses di port 53, 80, 443, 25, 389..."
fuser -k 53/tcp 53/udp 80/tcp 443/tcp 25/tcp 389/tcp > /dev/null 2>&1 || true

echo -e "${CHECK} Konflik port berhasil dibersihkan."

#############################################
# 3. SSL CERTIFICATES
#############################################
echo -e "\n${ACTION} ${W}Tahap 3: Konfigurasi SSL (Wildcard Certificate)...${NC}"
echo -e "${WARN} ${Y}ACTION REQUIRED: Tambahkan TXT record di panel DNS Anda saat diminta!${NC}"
echo -e "${B}------------------------------------------------------------${NC}"
certbot certonly --manual --preferred-challenges dns --agree-tos --register-unsafely-without-email -d "$DOMAIN" -d "*.$DOMAIN"
echo -e "${B}------------------------------------------------------------${NC}"

CERT_PATH="/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
KEY_PATH="/etc/letsencrypt/live/$DOMAIN/privkey.pem"

if [ ! -f "$CERT_PATH" ]; then
    echo -e "${ERROR} ${R}Sertifikat SSL tidak ditemukan. Pastikan TXT record sudah benar.${NC}"
    exit 1
fi
echo -e "${CHECK} SSL Berhasil diverifikasi: ${G}$DOMAIN${NC}"

#############################################
# 4. TEMPLATE PROCESSING
#############################################
echo -e "\n${ACTION} ${W}Tahap 4: Memproses Konfigurasi & Template...${NC}"

process_template() {
    local SRC_FILE=$1
    local DEST_FILE=$2
    if [ -f "$SRC_FILE" ]; then
        echo -e "      ${B}»${NC} Mengolah template: ${C}$(basename "$SRC_FILE")${NC}"
        cp "$SRC_FILE" "$DEST_FILE"
        sed -i "s/{{DOMAIN}}/$DOMAIN/g" "$DEST_FILE"
        sed -i "s/{{TOKEN}}/$TOKEN/g" "$DEST_FILE"
        sed -i "s/{{IP}}/$VPS_IP/g" "$DEST_FILE"
        sed -i "s|{{CERT_PATH}}|$CERT_PATH|g" "$DEST_FILE"
        sed -i "s|{{KEY_PATH}}|$KEY_PATH|g" "$DEST_FILE"
    else
        return 1
    fi
}

# Index Deployment
if [ -n "$CUSTOM_INDEX" ] && [ -f "$CUSTOM_INDEX" ]; then
    process_template "$CUSTOM_INDEX" "/var/www/oob/index.html"
elif ! process_template "$SCRIPT_DIR/index.html" "/var/www/oob/index.html"; then
    cat > /var/www/oob/index.html <<EOF
<!DOCTYPE html><html><head><title>AutoOBB - $DOMAIN</title><style>body{background:#0a0a0a;color:#00ff41;font-family:monospace;text-align:center;padding-top:15%;} .box{border:1px solid #00ff41;display:inline-block;padding:20px;}</style></head>
<body><div class="box"><h1>AUTOOBB SERVER ACTIVE</h1><p>Target: $DOMAIN</p><p>IP VPS: $VPS_IP</p><p>Status: Monitoring...</p></div></body></html>
EOF
fi

# Config & Service (Auto-generation fallback)
if ! process_template "$SCRIPT_DIR/config.yaml" "/root/.config/interactsh-server/config.yaml"; then
    cat > /root/.config/interactsh-server/config.yaml <<EOF
domain: ["$DOMAIN"]
listen-ip: $VPS_IP
dns-port: 53
http-port: 80
https-port: 443
smtp-port: 25
ldap-port: 389
disk: true
disk-path: /var/lib/interactsh
auth: true
token: "$TOKEN"
cert: $CERT_PATH
privkey: $KEY_PATH
wildcard: true
EOF
fi

if ! process_template "$SCRIPT_DIR/interactsh.service" "/etc/systemd/system/interactsh.service"; then
    cat > /etc/systemd/system/interactsh.service <<EOF
[Unit]
Description=Interactsh Server (AutoOBB)
After=network-online.target
[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/interactsh-server -domain $DOMAIN -listen-ip $VPS_IP -token $TOKEN -cert $CERT_PATH -privkey $KEY_PATH -disk -disk-path /var/lib/interactsh -auth=true -http-index /var/www/oob/index.html
Restart=always
AmbientCapabilities=CAP_NET_BIND_SERVICE
LimitNOFILE=1048576
[Install]
WantedBy=multi-user.target
EOF
fi

#############################################
# 5. GO & BINARY INSTALL
#############################################
echo -e "\n${ACTION} ${W}Tahap 5: Instalasi Engine (Source Build)...${NC}"
rm -rf /usr/local/go
GO_VERSION=$(curl -s https://go.dev/VERSION?m=text | head -n 1)
wget -q https://go.dev/dl/${GO_VERSION}.linux-amd64.tar.gz -O /tmp/go.tar.gz
tar -C /usr/local -xzf /tmp/go.tar.gz
export PATH=/usr/local/go/bin:$PATH

echo -e "      ${B}»${NC} Mengompilasi Interactsh Server terbaru..."
go install -v github.com/projectdiscovery/interactsh/cmd/interactsh-server@latest > /dev/null 2>&1

GOPATH_BIN=$(go env GOPATH)/bin
if [ -f "$GOPATH_BIN/interactsh-server" ]; then
    mv "$GOPATH_BIN/interactsh-server" /usr/local/bin/interactsh-server
    chmod +x /usr/local/bin/interactsh-server
    echo -e "${CHECK} Interactsh Server berhasil diinstal."
else
    echo -e "${ERROR} ${R}Gagal kompilasi binary.${NC}"
    exit 1
fi

#############################################
# 6. ACTIVATION
#############################################
echo -e "\n${ACTION} ${W}Tahap 6: Finalisasi & Aktivasi Layanan...${NC}"
systemctl daemon-reload
systemctl enable interactsh -q
systemctl restart interactsh
echo -e "${CHECK} Systemd Service Activated."

#############################################
# FINAL REPORT
#############################################
echo -e "\n${G}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${G}║             AUTOOBB SETUP SUCCESSFUL!                    ║${NC}"
echo -e "${G}╚══════════════════════════════════════════════════════════╝${NC}"
echo -e "  ${W}DOMAIN  :${NC} ${C}$DOMAIN${NC}"
echo -e "  ${W}IP VPS  :${NC} ${C}$VPS_IP${NC}"
echo -e "  ${W}TOKEN   :${NC} ${C}$TOKEN${NC}"
echo -e "  ${W}STATUS  :${NC} ${G}RUNNING${NC}"
echo -e "${B}------------------------------------------------------------${NC}"
echo -e "${Y}Client Command:${NC}"
echo -e "  ${W}interactsh-client -server $DOMAIN -token $TOKEN${NC}"
echo -e "${B}------------------------------------------------------------${NC}\n"

systemctl status interactsh --no-pager | grep -E "Active:|Main PID:"
