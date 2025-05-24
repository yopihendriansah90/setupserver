#!/bin/bash

echo "=== ⚙️ Setting IP Statis dengan Netplan ==="

# Interface default
iface="enp0s3"

# Input IP Address
read -p "Masukkan IP statis (default: 192.168.18.200/24): " ipaddr
ipaddr=${ipaddr:-192.168.18.200/24}

# Input Gateway
read -p "Masukkan Gateway (default: 192.168.18.1): " gateway
gateway=${gateway:-192.168.18.1}

# Input DNS
read -p "Masukkan DNS (default: 8.8.8.8,8.8.4.8): " dns
dns=${dns:-8.8.8.8,8.8.4.8}

# Ambil file YAML netplan
yaml_file=$(find /etc/netplan -name "*.yaml" | head -n 1)

if [ -z "$yaml_file" ]; then
    echo "❌ Tidak menemukan file konfigurasi Netplan!"
    exit 1
fi

echo "📁 Menggunakan file konfigurasi: $yaml_file"

# Backup dulu
sudo cp "$yaml_file" "$yaml_file.bak"

# Tulis konfigurasi baru
sudo tee "$yaml_file" > /dev/null <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    $iface:
      dhcp4: no
      addresses:
        - $ipaddr
      routes:
        - to: default
          via: $gateway
      nameservers:
        addresses: [${dns//,/\, }]
EOF

echo "✅ Konfigurasi berhasil ditulis."

# Terapkan konfigurasi
echo "📡 Menerapkan konfigurasi baru..."
sudo netplan apply

# Tampilkan hasil
echo "🔍 IP saat ini:"
ip a show $iface
