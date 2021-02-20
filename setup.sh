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

# ufw
echo "\033[0;32m"
echo "> Configuring firewall"
echo "\033[0m"

ufw allow "Apache Full"

# install magento
echo "\033[0;32m"
echo "> Hello! You might want to copy the following to a text doc because composer's output is massive. However, there are a few things YOU need to do"
echo "> 1. Create a database"
echo "> READ: https://devdocs.magento.com/guides/v2.4/install-gde/prereq/mysql.html#instgde-prereq-mysql-config"
echo "> run"
echo "mysql -u root -p"
echo "create database magento;"
echo "create user 'magento'@'localhost' IDENTIFIED BY 'magento';"
echo "GRANT ALL ON magento.* TO 'magento'@'localhost';"
echo "flush privileges;"
echo ""

echo "> 2. Install Mangeto via composer"
echo "> READ: https://devdocs.magento.com/guides/v2.4/install-gde/composer.html#get-the-metapackage"
echo "> You'll need to go to https://marketplace.magento.com/customer/accessKeys/ to get your access keys"
echo "> run"
echo "composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition /var/www/html"
echo ""

echo "> 3. Clean up permissions"
echo "> READ: https://devdocs.magento.com/guides/v2.4/install-gde/composer.html#set-file-permissions"
echo "> run"
echo "cd /var/www/html/"
echo "find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} +"
echo "find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} +"
echo "chown -R www-data:www-data . # Ubuntu"
echo "chmod u+x bin/magento"
echo ""

echo "> 4. Setup Magento"
echo "> READ: https://devdocs.magento.com/guides/v2.4/install-gde/composer.html#install-magento"
echo "> run"
echo 'bin/magento setup:install \'
echo '--base-url=http://YOUR_IP_ADDRESS/ \'
echo '--db-host=localhost \'
echo '--db-name=magento \'
echo '--db-user=magento \'
echo '--db-password=magento \'
echo '--admin-firstname=admin \'
echo '--admin-lastname=admin \'
echo '--admin-email=admin@admin.com \'
echo '--admin-user=admin \'
echo '--admin-password=admin123 \'
echo '--language=en_GB \'
echo '--currency=GBP \'
echo '--timezone=Europe/London \'
echo '--use-rewrites=1'
echo ""

echo "> 5. Enable Cron"
echo "> You need to add the www-data cron"
echo "> run"
echo 'sudo -u www-data php bin/magento cron:install'
echo ""

echo "> 6. Other Stuff"
echo "> 6.1 Disable 2FA"
echo "> Mangeto now comes with 2FA out of the box. If you need to disable it."
echo "> run"
echo 'bin/magento module:disable Magento_TwoFactorAuth'
echo 'bin/magento setup:di:compile'
echo ""

echo "> 6.2. The Magento docs recommends install ntp"
echo "> run"
echo 'apt-get -y install ntp'
echo '> Hit Y during installation'
echo ""

echo "\033[0m"
