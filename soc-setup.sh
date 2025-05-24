#!/bin/bash
set -e
trap ctrl_c INT

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

ctrl_c() {
    echo -e "\n${RED}Instalasi dibatalkan oleh pengguna.${NC}"
    exit 1
}

read_password() {
    local prompt=$1
    local pass1 pass2
    while true; do
        read -s -p "$prompt: " pass1
        echo
        read -s -p "Konfirmasi $prompt: " pass2
        echo
        [ "$pass1" = "$pass2" ] && { echo "$pass1"; break; } || echo "Password tidak cocok, coba lagi."
    done
}

check_status() {
    local service=$1
    echo -e "${GREEN}Status service $service:${NC}"
    systemctl is-active --quiet $service && echo -e "${GREEN}Aktif${NC}" || echo -e "${RED}Tidak aktif${NC}"
    echo "------------------------------"
}

show_menu() {
    echo -e "${GREEN}=========== MENU INSTALASI TOOLS ===========${NC}"
    echo "1. Install Semua (SIEM + HIDS + NIDS) dengan setup password"
    echo "2. Install Elasticsearch + setup user/password"
    echo "3. Install Kibana + setup user/password"
    echo "4. Install Filebeat + konfigurasi ke Elasticsearch"
    echo "5. Install Wazuh Manager + setup admin password"
    echo "6. Install Suricata"
    echo "0. Batal dan Keluar"
    echo "==========================================="
}

install_elasticsearch() {
    echo -e "${GREEN}[+] Menginstal Elasticsearch...${NC}"
    curl -s https://artifacts.elastic.co/GPG-KEY-elasticsearch | gpg --dearmor | tee /etc/apt/trusted.gpg.d/elastic.gpg > /dev/null
    echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-7.x.list
    apt update && apt install -y elasticsearch

    echo -e "${GREEN}Setting security elasticsearch...${NC}"
    sed -i 's/#xpack.security.enabled: true/xpack.security.enabled: true/' /etc/elasticsearch/elasticsearch.yml || echo "xpack.security.enabled: true" >> /etc/elasticsearch/elasticsearch.yml
    sed -i 's/#xpack.security.authc.api_key.enabled: true/xpack.security.authc.api_key.enabled: true/' /etc/elasticsearch/elasticsearch.yml || echo "xpack.security.authc.api_key.enabled: true" >> /etc/elasticsearch/elasticsearch.yml
    systemctl daemon-reexec
    systemctl enable --now elasticsearch

    echo -e "${GREEN}Tunggu 30 detik sampai Elasticsearch siap...${NC}"
    sleep 30

    echo -e "${GREEN}Set password untuk user 'elastic'${NC}"
    ELASTIC_PASS=$(read_password "Masukkan password untuk user 'elastic'")
    curl -XPUT -u elastic:changeme "http://localhost:9200/_security/user/elastic/_password" -H "Content-Type: application/json" -d "{\"password\":\"$ELASTIC_PASS\"}" || echo "Gagal set password elastic, silakan set manual nanti"

    echo "$ELASTIC_PASS" > /root/.elastic_pass
    echo -e "${GREEN}Password user elastic sudah disimpan di /root/.elastic_pass${NC}"

    check_status elasticsearch
    echo -e "${GREEN}Akses Elasticsearch di: http://localhost:9200${NC}"
}

install_kibana() {
    echo -e "${GREEN}[+] Menginstal Kibana...${NC}"
    apt install -y kibana

    ELASTIC_PASS=$(cat /root/.elastic_pass)
    sed -i "s|#elasticsearch.username: \"kibana_system\"|elasticsearch.username: \"elastic\"|" /etc/kibana/kibana.yml
    sed -i "s|#elasticsearch.password: \"\"|elasticsearch.password: \"$ELASTIC_PASS\"|" /etc/kibana/kibana.yml

    systemctl enable --now kibana

    check_status kibana
    echo -e "${GREEN}Akses Kibana di: http://localhost:5601${NC}"
}

install_filebeat() {
    echo -e "${GREEN}[+] Menginstal Filebeat...${NC}"
    apt install -y filebeat

    ELASTIC_PASS=$(cat /root/.elastic_pass)

    cat > /etc/filebeat/filebeat.yml << EOF
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/*.log

output.elasticsearch:
  hosts: ["localhost:9200"]
  username: "elastic"
  password: "$ELASTIC_PASS"

setup.kibana:
  host: "localhost:5601"
EOF

    systemctl enable --now filebeat

    check_status filebeat
    echo -e "${GREEN}Filebeat berjalan untuk kirim log ke Elasticsearch.${NC}"
}

install_wazuh_manager() {
    echo -e "${GREEN}[+] Menginstal Wazuh Manager...${NC}"
    curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --dearmor -o /usr/share/keyrings/wazuh.gpg
    echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" > /etc/apt/sources.list.d/wazuh.list
    apt update && apt install -y wazuh-manager

    echo -e "${GREEN}Setup password user admin Wazuh API${NC}"
    ADMIN_PASS=$(read_password "Masukkan password baru untuk user admin Wazuh API")
    /var/ossec/wazuh-passwords-tool.sh --update admin <<< "$ADMIN_PASS"$'\n'"$ADMIN_PASS"

    systemctl enable --now wazuh-manager

    check_status wazuh-manager
    echo -e "${GREEN}Wazuh Manager berjalan.${NC}"
}

install_suricata() {
    echo -e "${GREEN}[+] Menginstal Suricata...${NC}"
    add-apt-repository ppa:oisf/suricata-stable -y
    apt update && apt install -y suricata

    systemctl enable --now suricata

    check_status suricata
    echo -e "${GREEN}Suricata berjalan untuk NIDS.${NC}"
}

install_all() {
    install_elasticsearch
    install_kibana
    install_filebeat
    install_wazuh_manager
    install_suricata
    echo -e "${GREEN}[✓] Semua tools berhasil diinstal dan dikonfigurasi.${NC}"
}

clear
show_menu
read -p "Pilih opsi instalasi [0-6]: " choice

case $choice in
    1) install_all ;;
    2) install_elasticsearch ;;
    3) install_kibana ;;
    4) install_filebeat ;;
    5) install_wazuh_manager ;;
    6) install_suricata ;;
    0) echo -e "${RED}Instalasi dibatalkan.${NC}" ; exit 0 ;;
    *) echo -e "${RED}Pilihan tidak valid.${NC}" ; exit 1 ;;
esac
