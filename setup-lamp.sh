#!/bin/bash

# Script Otomatis Install LAMP Server
# Tested on Ubuntu 20.04 / 22.04

echo "⏳ Memulai proses update dan upgrade..."
sudo apt update && sudo apt upgrade -y

echo "🚀 Menginstall Apache2..."
sudo apt install apache2 -y

echo "✅ Apache2 terinstall!"

echo "🔥 Mengaktifkan Apache Rewrite Module..."
sudo a2enmod rewrite
sudo systemctl restart apache2

echo "🔧 Menginstall MySQL Server..."
sudo apt install mysql-server -y

echo "🔐 Menjalankan konfigurasi keamanan MySQL..."
sudo mysql_secure_installation <<EOF

n
y
y
y
y
EOF

echo "✅ MySQL siap digunakan!"

echo "🧠 Menginstall PHP dan ekstensi penting..."
sudo apt install php libapache2-mod-php php-mysql php-cli php-curl php-zip php-mbstring php-xml php-bcmath unzip -y

echo "📄 Membuat file info.php untuk tes PHP..."
echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/info.php

echo "🔗 Membuat file test koneksi ke MySQL..."
cat <<EOF | sudo tee /var/www/html/koneksi.php
<?php
\$koneksi = new mysqli("localhost", "root", "", "mysql");
if (\$koneksi->connect_error) {
    die("Koneksi GAGAL: " . \$koneksi->connect_error);
}
echo "Koneksi Berhasil ke MySQL!";
?>
EOF

echo "📦 Install phpMyAdmin..."
sudo apt install phpmyadmin -y

echo "🔧 Menyambungkan phpMyAdmin ke Apache..."
sudo ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin

echo "🛡️ Mengatur hak akses folder /var/www/html..."
sudo chown -R $USER:www-data /var/www/html
sudo chmod -R 755 /var/www/html

echo ""
echo "🎉 Instalasi LAMP Selesai!"
echo "Cek di browser:"
echo "  🌐 http://<IP_SERVER>/info.php"
echo "  🌐 http://<IP_SERVER>/koneksi.php"
echo "  🌐 http://<IP_SERVER>/phpmyadmin"
echo ""
