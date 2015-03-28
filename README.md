# PHP7 Apache Ubuntu Setup
My workflow to get PHP7 running with apache on ubuntu via php-fpm.

From an empty folder via an empty Ubuntu Vagrantbox to an Apache server thats running PHP7.

Warning: You'll need Vagrant and quite some bandwidth for this :)
# Automatic setup
Just clone this repository and run vagrant up in it (Go grab a coffe or something, this will take a while...):
```bash
$ git clone https://github.com/cookiecavekeeper/php7_apache_ubuntu_setup.git
$ cd php7_apache_ubuntu_setup
$ vagrant up
```
And after a few minutes you are done!

# Manual Setup
Here we will do everything the scripts above do, but manually (with a bit of explanation).
## VM setup
Initializing the box (from a base ubuntu/trusty64)
```bash
$ mkdir php7
$ cd php7
$ vagrant init ubuntu/trusty64
```
Now you should edit the Vagrantfile to add an IP address and some more RAM.
Just comment out the following lines and edit them to something like this:
```
config.vm.network "private_network", ip: "192.168.7.8"
config.vm.provider "virtualbox" do |vb|
  vb.customize ["modifyvm", :id, "--memory", "2048"]
end
```
Now run: (this takes a while)
```bash
$ vagrant up
```
And once that's done:
```bash
$ vagrant ssh
```

## Inside our VM
### Installing dependencies
First we need git:
```bash
$ sudo apt-get install git
```
Now we can get the php-src repo: (this takes a while as well)
```bash
$ git clone https://github.com/php/php-src.git --depth=1
```
Once inside, we'll install all the dependecies we need to actually compile any php source code:
```bash
$ cd php-src
$ sudo apt-get install build-essential autoconf automake libtool bison re2c
```
What we just installed:
build-essentials: compilers, make etc....
autoconf: used to generate the configure script
automake: generates Makefile.in files
libtool: helps manage shared libraries
bison: is used to generate the PHP parser
re2c: is used to generate the PHP lexer
([Stolen from the PHP internals Book](http://www.phpinternalsbook.com/build_system/building_php.html))

### Installing extension dependencies
Everybody needs a different set of extensions in their build, but I put together a list that I think is pretty solid.
We first need the following development packages:
```bash
$ sudo apt-get install libxml2-dev libssl-dev libcurl4-openssl-dev libjpeg-dev libpng12-dev libc-client-dev libmcrypt-dev libxslt1-dev
$ sudo ln -s /usr/lib/libc-client.a /usr/lib/x86_64-linux-gnu/libc-client.a
```
### Actually building PHP
Now that we have all the dependencies, we can actually start building PHP itself. 
Inside the php-src directory we run:
```bash
$ ./buildconf
```
This will generate the necessary configuration files / headers etc (--force flag will clear configuration caches).

Now we are going to run ./configure. Here comes the Part where everyone will pass a set of different flags (for a list of all of the run: ./configure --help).

I used [this site](http://zgadzaj.com/how-to-install-php-53-and-52-together-on-ubuntu-1204) a lot to find out what I had to install for certain flags / error messages.

Here is my / our version (that needs the packages listed above in Installing extension dependencies):
```bash
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
--with-png-dir=/usr \
```
Once we have run this and got no errors we get to the exciting part:
```bash
$ make
$ sudo make install
```
Now we have php installed (into /usr/local) and can run php -v to verify that =D
### Setting up PHP-FPM
To use PHP-FPM we just have to copy a few configuration files around:
```bash
$ sudo cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
$ sudo chmod 755 /etc/init.d/php-fpm
$ sudo cp /usr/local/etc/php-fpm.conf.default /usr/local/etc/php-fpm.conf
$ sudo cp /usr/local/etc/php-fpm.d/www.conf.default /usr/local/etc/php-fpm.d/www.conf
```
Not sure why but we have to change the last line of: /usr/local/etc/php-fpm.conf to:
```
include=etc/php-fpm.d/*.conf
```
To see if it works we can run:
```bash
$ sudo service php-fpm start
```
### Setting up Apache with PHP-FPM
Now since I'm used to working with apache I'm using it as an example here, but you can use any php5 guide for setting up nginx with php-fpm as well.

To install everything, we first need to uncomment a few package sources from: /etc/apt/sources.list
You should comment out the following lines:
```
deb http://archive.ubuntu.com/ubuntu trusty multiverse
deb-src http://archive.ubuntu.com/ubuntu trusty multiverse
deb http://archive.ubuntu.com/ubuntu trusty-updates multiverse
deb-src http://archive.ubuntu.com/ubuntu trusty-updates multiverse
```

Alright, now we can run the following to install apache and all we need to run it with php fpm:
```bash
$ sudo apt-get update
$ sudo apt-get install apache2-mpm-worker libapache2-mod-fastcgi
$ sudo a2enmod actions fastcgi alias
```
(That last command enables the fastcgi and alias modules in apache).

Now we add the following somewhere into the /etc/apache2/apache2.conf file:
```
<IfModule mod_fastcgi.c>
        AddHandler php5-fcgi .php
        Action php5-fcgi /php5-fcgi
        Alias /php5-fcgi /usr/lib/cgi-bin/php5-fcgi
        FastCgiExternalServer /usr/lib/cgi-bin/php5-fcgi -host 127.0.0.1:9000 -pass-header Authorization
</IfModule>
```
But Apache thinks that /php5-fcgi is a directory it blocks it by default. So we have to delete the following block from the file:
```
<Directory />
        .........
</Directory>
```

Well now we just restart apache and are good to go:
```bash
$ sudo service apache2 restart
```

If you now put a test.php file into /var/www/html with the following content:
```php
<?php

phpinfo();
```
You should now see the phpinfo page when you visit 192.168.7.8/test.php on your host pc.

If did something wrong or generally made and mistakes, please tell me, I'm still just learning all this stuff =D
