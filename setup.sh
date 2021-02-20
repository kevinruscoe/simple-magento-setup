# update
apt-get update

# install tools we (may) need
echo "\033[0;32m"
echo "> Installing tools"
echo "\033[0m"

apt-get -y install zip unzip apt-transport-https

# elasticsearch preinstallation
echo "\033[0;32m"
echo "> Installing elasticsearch sourcelists"
echo "\033[0m"
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-7.x.list
apt-get update

# install software
echo "\033[0;32m"
echo "> Installing apache, php74, mysql and elasticsearch"
echo "\033[0m"
apt-get -y install apache2 php7.4 php7.4-mbstring php7.4-intl php7.4-gd php7.4-dom php7.4-curl mysql-server openjdk-8-jdk elasticsearch

# reloadi elasticsearch
echo "\033[0;32m"
echo "> Reloaing elasticsearch"
echo "\033[0m"
sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable elasticsearch.service

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

# reload apache
echo "\033[0;32m"
echo "> Enabling apache mods"
echo "\033[0m"
a2enmod rewrite proxy_http

# install composer
echo "\033[0;32m"
echo "> Installing composer"
echo "\033[0m"
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
sudo php composer-setup.php --install-dir=/usr/bin --filename=composer
php -r "unlink('composer-setup.php');"

# apache changes
echo "\033[0;32m"
echo "> Making Magento apache amends (per https://devdocs.magento.com/guides/v2.4/install-gde/prereq/apache.html)"
echo "\033[0m"
rm /var/www/html/index.html

mv /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.backup

touch /etc/apache2/sites-available/000-default.conf

echo "Listen 8080" >> /etc/apache2/sites-available/000-default.conf
echo "<VirtualHost *:80>" >> /etc/apache2/sites-available/000-default.conf
echo "\tServerAdmin webmaster@localhost" >> /etc/apache2/sites-available/000-default.conf
echo "\tDocumentRoot /var/www/html" >> /etc/apache2/sites-available/000-default.conf
echo '\tErrorLog ${APACHE_LOG_DIR}/error.log' >> /etc/apache2/sites-available/000-default.conf
echo '\tCustomLog /${APACHE_LOG_DIR}/access.log combined' >> /etc/apache2/sites-available/000-default.conf
echo '\tAllowEncodedSlashes NoDecode' >> /etc/apache2/sites-available/000-default.conf
echo '\t<Directory "/var/www/html">' >> /etc/apache2/sites-available/000-default.conf
echo "\t\tAllowOverride All" >> /etc/apache2/sites-available/000-default.conf
echo "\t</Directory>" >> /etc/apache2/sites-available/000-default.conf
echo "</VirtualHost>" >> /etc/apache2/sites-available/000-default.conf
echo "<VirtualHost *:8080>" >> /etc/apache2/sites-available/000-default.conf
echo '\tProxyPass "/" "http://localhost:9200/"' >> /etc/apache2/sites-available/000-default.conf
echo '\tProxyPassReverse "/" "http://localhost:9200/"' >> /etc/apache2/sites-available/000-default.conf
echo "</VirtualHost>" >> /etc/apache2/sites-available/000-default.conf

# ufw
echo "\033[0;32m"
echo "> Configuring firewall"
echo "\033[0m"
ufw allow "Apache Full"

echo "\033[0;32m"
echo "> Hello!"
echo "> You now have to make a database, please go to https://devdocs.magento.com/guides/v2.4/install-gde/prereq/mysql.html#instgde-prereq-mysql-config"
echo "> After that, go grab your magento keys from https://marketplace.magento.com/customer/accessKeys/"
echo "> Then, install magento following:"
echo "1. https://devdocs.magento.com/guides/v2.4/install-gde/composer.html#get-the-metapackage"
echo "2. https://devdocs.magento.com/guides/v2.4/install-gde/composer.html#set-file-permissions"
echo "3. https://devdocs.magento.com/guides/v2.4/install-gde/composer.html#install-magento"
echo "\033[0m"
