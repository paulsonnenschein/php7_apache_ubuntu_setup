#!/usr/bin/env bash

# Coning php-src and getting dependencies
sudo apt-get update
sudo apt-get -y install git 
git clone https://github.com/php/php-src.git --depth=1
cd php-src
sudo apt-get -y install build-essential autoconf automake libtool bison re2c
sudo apt-get -y install libxml2-dev libssl-dev libcurl4-openssl-dev libjpeg-dev libpng12-dev libc-client-dev libmcrypt-dev libxslt1-dev
sudo ln -s /usr/lib/libc-client.a /usr/lib/x86_64-linux-gnu/libc-client.a

# Build PHP
./buildconf
./configure --enable-fpm \
--with-libdir=/lib/x86_64-linux-gnu \
--with-kerberos \
--with-fpm-user=vagrant \
--with-fpm-group=vagrant \
--without-pear \
--with-openssl \
--with-pdo-sqlite \
--with-pdo-mysql=mysqlnd \
--enable-sockets \
--with-gettext \
--with-curl \
--enable-exif \
--enable-ftp \
--with-gd \
--enable-mbstring \
--with-mcrypt \
--enable-zip \
--with-zlib \
--with-imap \
--with-imap-ssl \
--enable-xmlreader \
--enable-phar \
--with-xsl \
--enable-cgi \
--with-jpeg-dir=/usr \
--with-png-dir=/usr
make
sudo make install

# Setting up PHP-FPM
sudo cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
sudo chmod 755 /etc/init.d/php-fpm
sudo cp /usr/local/etc/php-fpm.conf.default /usr/local/etc/php-fpm.conf
sudo cp /usr/local/etc/php-fpm.d/www.conf.default /usr/local/etc/php-fpm.d/www.conf

sudo sed -i '$ d' /usr/local/etc/php-fpm.conf
echo 'include=etc/php-fpm.d/*.conf' | sudo tee -a /usr/local/etc/php-fpm.conf

sudo service php-fpm start

# Start php-fpm on startup
sudo update-rc.d php-fpm defaults

# Setting up Apache
# Not quite commenting out but it works:
echo -e 'deb http://archive.ubuntu.com/ubuntu trusty multiverse \n' | sudo tee -a /etc/apt/sources.list
echo -e 'deb-src http://archive.ubuntu.com/ubuntu trusty multiverse \n' | sudo tee -a /etc/apt/sources.list
echo -e 'deb http://archive.ubuntu.com/ubuntu trusty-updates multiverse \n' | sudo tee -a /etc/apt/sources.list
echo -e 'deb-src http://archive.ubuntu.com/ubuntu trusty-updates multiverse \n' | sudo tee -a /etc/apt/sources.list 

sudo apt-get update
sudo apt-get -y install apache2-mpm-worker libapache2-mod-fastcgi
sudo a2enmod actions fastcgi alias

echo -e '<IfModule mod_fastcgi.c>\n' | sudo tee -a /etc/apache2/apache2.conf
echo -e '        AddHandler php5-fcgi .php\n' | sudo tee -a /etc/apache2/apache2.conf
echo -e '        Action php5-fcgi /php5-fcgi\n' | sudo tee -a /etc/apache2/apache2.conf
echo -e '        Alias /php5-fcgi /usr/lib/cgi-bin/php5-fcgi\n' | sudo tee -a /etc/apache2/apache2.conf
echo -e '        FastCgiExternalServer /usr/lib/cgi-bin/php5-fcgi -host 127.0.0.1:9000 -pass-header Authorization\n' | sudo tee -a /etc/apache2/apache2.conf
echo -e '</IfModule>\n' | sudo tee -a /etc/apache2/apache2.conf

sudo sed -ie '/<Directory \/>/{N; N; N; N; d;}' /etc/apache2/apache2.conf

sudo service apache2 restart

rm /var/www/html/index.html
echo '<?php phpinfo();' > /var/www/html/index.php

echo 'Go open up 192.168.7.8 on your host machine!'
