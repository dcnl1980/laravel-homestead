#!/usr/bin/env bash

# Laravel homestead original provisioning script
# https://github.com/laravel/settler

# Update Package List
apt-get update
apt-get upgrade -y

# Force Locale
echo "LC_ALL=en_US.UTF-8" >> /etc/default/locale
locale-gen en_US.UTF-8
export LANG=en_US.UTF-8

# Install ssh server
apt-get -y install openssh-server pwgen
mkdir -p /var/run/sshd
sed -i "s/UsePrivilegeSeparation.*/UsePrivilegeSeparation no/g" /etc/ssh/sshd_config
sed -i "s/UsePAM.*/UsePAM no/g" /etc/ssh/sshd_config
sed -i "s/PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config

# Basic packages
apt-get install -y sudo software-properties-common nano curl \
build-essential dos2unix gcc git git-flow libmcrypt4 libpcre3-dev apt-utils \
make python2.7-dev python-pip re2c supervisor unattended-upgrades whois vim zip unzip

# PPA
apt-add-repository ppa:nginx/development -y
apt-add-repository ppa:chris-lea/redis-server -y
apt-add-repository ppa:ondrej/php -y

# PHP Blackfire
curl -s https://packagecloud.io/gpg.key | apt-key add -
echo "deb http://packages.blackfire.io/debian any main" | tee /etc/apt/sources.list.d/blackfire.list

# Update Package Lists
apt-get update

# Create homestead user
adduser homestead
usermod -p $(echo secret | openssl passwd -1 -stdin) homestead
# Add homestead to the sudo group and www-data
usermod -aG sudo homestead
usermod -aG www-data homestead

# Timezone
ln -sf /usr/share/zoneinfo/UTC /etc/localtime

# PHP
apt-get install -y --force-yes php7.1-cli php7.1-dev \
php7.1-pgsql php7.1-sqlite3 php7.1-gd \
php7.1-curl php7.1-memcached \
php7.1-imap php7.1-mysql php7.1-mbstring \
php7.1-xml php7.1-zip php7.1-bcmath php7.1-soap \
php7.1-intl php7.1-readline php-xdebug

# Nginx & PHP-FPM
apt-get install -y nginx php7.1-fpm

# Apache2 on Port 81
apt-get install -y apache2
sed -i 's/Listen\ 80/Listen\ 81/g' /etc/apache2/ports.conf
apt-get -y install php7.1 libapache2-mod-php7.1
## TODO: toevoegen een php.ini voor development waar display_errors op aan staat
sed -i 's/short_open_tag =\ Off/short_open_tag =\ On/g' /etc/php/7.1/apache2/php.ini
sudo a2enmod rewrite
## TODO: default laravel website toevoegen aan 000-default
## Scripts aanmaken om een laravel website te starten of wordpress of etc....
sudo a2enmod proxy_fcgi setenvif
sudo a2enconf php7.1-fpm
	
# Enable mcrypt
phpenmod mcrypt

# Add the HHVM Key & Repository
wget -O - http://dl.hhvm.com/conf/hhvm.gpg.key | apt-key add -
echo deb http://dl.hhvm.com/ubuntu xenial main | tee /etc/apt/sources.list.d/hhvm.list
apt-get update
apt-get install -y hhvm

# Configure HHVM To Run As Homestead

service hhvm stop
sed -i 's/#RUN_AS_USER="www-data"/RUN_AS_USER="homestead"/' /etc/default/hhvm
service hhvm start

# Start HHVM On System Start

update-rc.d hhvm defaults

# Enable postfix
apt-get install -y postfix mailutils
sudo sed -i 's/relayhost =/relayhost = 127.0.0.1:1025/' /etc/postfix/main.cf
service postfix start

# Install Composer
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# Add Composer Global Bin To Path
printf "\nPATH=\"/home/homestead/.composer/vendor/bin:\$PATH\"\n" | tee -a /home/homestead/.profile

# Laravel Envoy & Installer
su homestead <<'EOF'
/usr/local/bin/composer global require "laravel/envoy=~1.0"
/usr/local/bin/composer global require "laravel/installer=~1.1"
EOF

# Set Some PHP CLI Settings
sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.1/cli/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.1/cli/php.ini
sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/7.1/cli/php.ini
sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.1/cli/php.ini

sed -i "s/.*daemonize.*/daemonize = no/" /etc/php/7.1/fpm/php-fpm.conf
sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.1/fpm/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.1/fpm/php.ini
sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.1/fpm/php.ini
sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/7.1/fpm/php.ini
sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.1/fpm/php.ini

# Xdebug installation
# check if already installed with php -m | grep -i xdebug
# wget -c "http://xdebug.org/files/xdebug-2.4.0.tgz"
# tar -xf xdebug-2.4.0.tgz
# cd xdebug-2.4.0/
# sudo phpize
# sudo ./configure
# sudo make && sudo make install 

# Enable Remote xdebug
echo "zend_extension=xdebug.so" >> /etc/php/7.1/mods-available/xdebug.ini
echo "xdebug.idekey = PHPSTORM" >> /etc/php/7.1/mods-available/xdebug.ini
echo "xdebug.default_enable = 0" >> /etc/php/7.1/mods-available/xdebug.ini
echo "xdebug.remote_enable = 1" >> /etc/php/7.1/mods-available/xdebug.ini
echo "xdebug.remote_autostart = 0" >> /etc/php/7.1/mods-available/xdebug.ini
echo "xdebug.remote_connect_back = 1" >> /etc/php/7.1/mods-available/xdebug.ini
echo "xdebug.remote_host = 172.17.0.1" >> /etc/php/7.1/mods-available/xdebug.ini
echo "xdebug.remote_port = 9000" >> /etc/php/7.1/mods-available/xdebug.ini
echo "xdebug.var_display_max_depth = -1" >> /etc/php/7.1/mods-available/xdebug.ini
echo "xdebug.var_display_max_children = -1" >> /etc/php/7.1/mods-available/xdebug.ini
echo "xdebug.var_display_max_data = -1" >> /etc/php/7.1/mods-available/xdebug.ini
echo "xdebug.max_nesting_level = 500" >> /etc/php/7.1/mods-available/xdebug.ini

sudo ln -sf /etc/php/7.1/mods-available/xdebug.ini /etc/php/7.1/fpm/conf.d/20-xdebug.ini
sudo ln -sf /etc/php/7.1/mods-available/xdebug.ini /etc/php/7.1/cli/conf.d/20-xdebug.ini
sudo ln -sf /etc/php/7.1/mods-available/xdebug.ini /etc/php/7.1/apache2/conf.d/20-xdebug.ini

# Not xdebug when on cli
phpdismod -s cli xdebug

# Set The Nginx & PHP-FPM User
sed -i "1 idaemon off;" /etc/nginx/nginx.conf
sed -i "s/user www-data;/user homestead;/" /etc/nginx/nginx.conf
sed -i "s/# server_names_hash_bucket_size.*/server_names_hash_bucket_size 64;/" /etc/nginx/nginx.conf

mkdir -p /run/php
touch /run/php/php7.1-fpm.sock

sed -i "s/user = www-data/user = homestead/" /etc/php/7.1/fpm/pool.d/www.conf
sed -i "s/group = www-data/group = homestead/" /etc/php/7.1/fpm/pool.d/www.conf
sed -i "s/;listen\.owner.*/listen.owner = homestead/" /etc/php/7.1/fpm/pool.d/www.conf
sed -i "s/;listen\.group.*/listen.group = homestead/" /etc/php/7.1/fpm/pool.d/www.conf
sed -i "s/;listen\.mode.*/listen.mode = 0666/" /etc/php/7.1/fpm/pool.d/www.conf

# Install Node
curl --silent --location https://deb.nodesource.com/setup_6.x | bash -
apt-get install -y nodejs
npm install -g grunt-cli
npm install -g gulp
npm install -g bower
npm install -g yarn

# Install SQLite
apt-get install -y sqlite3 libsqlite3-dev

# Memcached
apt-get install -y memcached

# Beanstalkd
apt-get install -y beanstalkd
sed -i "s/#START=yes/START=yes/" /etc/default/beanstalkd

# Redis
apt-get install -y redis-server
sed -i 's/daemonize yes/daemonize no/' /etc/redis/redis.conf

# PHP Blackfire
apt-get install -y blackfire-agent blackfire-php

# Install & Configure MailHog
# Download binary from github
sudo wget --quiet -O /usr/local/bin/mailhog https://github.com/mailhog/MailHog/releases/download/v0.2.1/MailHog_linux_amd64

# Make it executable
sudo chmod +x /usr/local/bin/mailhog

# Make it start on reboot
sudo tee /etc/systemd/system/mailhog.service <<EOL
[Unit]
Description=Mailhog
After=network.target
[Service]
User=homestead
ExecStart=/usr/bin/env /usr/local/bin/mailhog > /dev/null 2>&1 &
[Install]
WantedBy=multi-user.target
EOL

# Start it now in the background
sudo /usr/bin/env /usr/local/bin/mailhog > /dev/null 2>&1 &

# Configure default nginx site
block="server {
    listen 80 default_server;
    listen [::]:80 default_server ipv6only=on;

    root /var/www/html;
    server_name localhost;

    index index.html index.htm index.php;

    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    access_log off;
    error_log  /var/log/nginx/app-error.log error;

    error_page 404 /index.php;

    sendfile off;

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php7.1-fpm.sock;
        fastcgi_index index.php;
        include fastcgi.conf;
    }

    location ~ /\.ht {
        deny all;
    }
}
"

rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default

cat > /etc/nginx/sites-enabled/default
echo "$block" > "/etc/nginx/sites-enabled/default"

