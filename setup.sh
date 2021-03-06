# get vars
echo "\033[0;32m"
echo "First things first, you need your magento access keys. Go to https://marketplace.magento.com/customer/accessKeys/ and get them."
echo "\033[0m"

read -p "Enter public key: " pubkey
read -p "Enter private key: " privkey

# get ip
ip="http://"$(curl -s https://ipinfo.io/ip)"/"

# update
apt-get update

# install tools we need
echo "\033[0;32m"
echo "> Installing needed linux tools"
echo "\033[0m"

apt-get -y install zip unzip apt-transport-https

# elasticsearch preinstallation
echo "\033[0;32m"
echo "> Installing elasticsearch sourcelists"
echo "\033[0m"

wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-7.x.list
apt-get update

# install apache, php74, mysql and elasticsearch
echo "\033[0;32m"
echo "> Installing apache, php74, mysql and elasticsearch"
echo "\033[0m"

apt-get -y install apache2 php7.4 php7.4-mysql php7.4-bcmath php7.4-soap php7.4-zip php7.4-mbstring php7.4-intl php7.4-gd php7.4-xml php7.4-curl mysql-server openjdk-8-jdk elasticsearch

# reload elasticsearch
echo "\033[0;32m"
echo "> Reloading elasticsearch"
echo "\033[0m"

sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable elasticsearch.service
sudo /bin/systemctl start elasticsearch.service

# add PHP config changes, per https://devdocs.magento.com/guides/v2.4/install-gde/prereq/php-settings.html
echo "\033[0;32m"
echo "> Making Magento PHP config amends (per https://devdocs.magento.com/guides/v2.4/install-gde/prereq/php-settings.html)"
echo "\033[0m"

touch /etc/php/7.4/apache2/conf.d/50-magento.ini

echo "realpath_cache_size=10M" >> /etc/php/7.4/apache2/conf.d/50-magento.ini
echo "realpath_cache_ttl=7200" >> /etc/php/7.4/apache2/conf.d/50-magento.ini
echo "date.timezone=Europe/London" >> /etc/php/7.4/apache2/conf.d/50-magento.ini
echo "memory_limit=2G" >> /etc/php/7.4/apache2/conf.d/50-magento.ini
echo "opcache.save_comments=1" >> /etc/php/7.4/apache2/conf.d/50-magento.ini

# install composer
echo "\033[0;32m"
echo "> Installing composer"
echo "\033[0m"

php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
sudo php composer-setup.php --install-dir=/usr/bin --filename=composer
php -r "unlink('composer-setup.php');"

export COMPOSER_ALLOW_SUPERUSER=1
composer config --global http-basic.repo.magento.com $pubkey $privkey

# Apache changes
echo "\033[0;32m"
echo "> Making Magento apache amends (per https://devdocs.magento.com/guides/v2.4/install-gde/prereq/apache.html)"
echo "\033[0m"

a2enmod rewrite proxy_http

rm /var/www/html/index.html

mv /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.backup

touch /etc/apache2/sites-available/000-default.conf

echo "Listen 8080" >> /etc/apache2/sites-available/000-default.conf
echo "<VirtualHost *:80>" >> /etc/apache2/sites-available/000-default.conf
echo "    ServerAdmin webmaster@localhost" >> /etc/apache2/sites-available/000-default.conf
echo "    DocumentRoot /var/www/html" >> /etc/apache2/sites-available/000-default.conf
echo '    ErrorLog ${APACHE_LOG_DIR}/error.log' >> /etc/apache2/sites-available/000-default.conf
echo '    CustomLog /${APACHE_LOG_DIR}/access.log combined' >> /etc/apache2/sites-available/000-default.conf
echo '    AllowEncodedSlashes NoDecode' >> /etc/apache2/sites-available/000-default.conf
echo '    <Directory "/var/www/html">' >> /etc/apache2/sites-available/000-default.conf
echo "        AllowOverride All" >> /etc/apache2/sites-available/000-default.conf
echo "    </Directory>" >> /etc/apache2/sites-available/000-default.conf
echo "</VirtualHost>" >> /etc/apache2/sites-available/000-default.conf
echo "<VirtualHost *:8080>" >> /etc/apache2/sites-available/000-default.conf
echo '    ProxyPass "/" "http://localhost:9200/"' >> /etc/apache2/sites-available/000-default.conf
echo '    ProxyPassReverse "/" "http://localhost:9200/"' >> /etc/apache2/sites-available/000-default.conf
echo "</VirtualHost>" >> /etc/apache2/sites-available/000-default.conf

service apache2 restart

# create database
echo "\033[0;32m"
echo "> Creating database"
echo "\033[0m"

mysql -u root -e "CREATE DATABASE magento; CREATE USER 'magento'@'localhost' IDENTIFIED BY 'magento'; GRANT ALL ON magento.* TO 'magento'@'localhost'; FLUSH PRIVILEGES;"

# ufw
echo "\033[0;32m"
echo "> Configuring firewall"
echo "\033[0m"

ufw allow "Apache Full"

# install magento
composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition /var/www/html

# fix permissions
cd /var/www/html/
find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} +
find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} +
chown -R www-data:www-data .
chmod u+x bin/magento

# install magento
bin/magento setup:install --base-url=$ip --db-host=localhost --db-name=magento --db-user=magento --db-password=magento --admin-firstname=admin --admin-lastname=admin --admin-email=admin@admin.com --admin-user=admin --admin-password=admin123 --language=en_GB --currency=GBP --timezone=Europe/London --use-rewrites=1

sudo -u www-data php /var/www/html/bin/magento cron:install

cp ~/.config/composer/auth.json /var/www/html/var/composer_home/auth.json
cp ~/.config/composer/auth.json /var/www/html/var/auth.json

echo "\033[0;32m"
echo "> Hello! All donem however take a look at the optional Stuff"
echo ""

echo "> 1. Disable admin 2FA"
echo "> run"
echo 'bin/magento module:disable Magento_TwoFactorAuth'
echo 'bin/magento setup:di:compile'
echo ""

echo "> 2. Install ntp"
echo "> run"
echo 'apt-get -y install ntp'
echo '> Hit Y during installation'
echo ""

echo "> 3. Sample data"
echo "> run"
echo "bin/magento sampledata:deploy"
echo "bin/magento setup:upgrade"

echo "\033[0m"
