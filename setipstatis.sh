#!/bin/bash

echo "=== 🛠️  Setup IP Statis untuk Ubuntu Server ==="

read -p "🧾 Masukkan nama interface jaringan (contoh: enp0s3, eth0, ens33): " iface
read -p "🌐 Masukkan IP statis yang ingin digunakan (contoh: 192.168.1.100): " ipaddr
read -p "🧱 Masukkan subnet prefix (contoh: 24 untuk 255.255.255.0): " prefix
read -p "🚪 Masukkan default gateway (contoh: 192.168.1.1): " gateway
read -p "🧭 Masukkan DNS server (contoh: 8.8.8.8,8.8.4.4): " dns

# Mencari file konfigurasi netplan
yaml_file=$(find /etc/netplan -name "*.yaml" | head -n 1)

if [ -z "$yaml_file" ]; then
    echo "❌ Tidak menemukan file konfigurasi Netplan!"
    exit 1
fi

# Backup dulu sebelum ngedit
sudo cp "$yaml_file" "$yaml_file.bak"

# Menulis ulang konfigurasi netplan
sudo tee "$yaml_file" > /dev/null <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    $iface:
      dhcp4: no
      addresses:
        - $ipaddr/$prefix
      gateway4: $gateway
      nameservers:
        addresses: [${dns//,/\, }]
EOF

echo "✅ Konfigurasi berhasil disimpan ke $yaml_file"
echo "📡 Menerapkan konfigurasi jaringan..."

# Terapkan perubahan
sudo netplan apply

echo "✅ IP statis sudah diterapkan ke interface $iface"
ip a show $iface
