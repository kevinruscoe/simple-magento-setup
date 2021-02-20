# update
apt-get update

# install tools we (may) need
echo "\033[0;32m> Installing tools\033[0m"
apt-get -y install zip unzip apt-transport-https

# elasticsearch preinstallation
echo "\033[0;32m> Installing elasticsearch sourcelists\033[0m"
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-7.x.list
apt-get update

# install software
echo "\033[0;32m> Installing apache, php74, mysql and elasticsearch\033[0m"
apt-get -y install apache2 php7.4 php7.4-common php7.4-dom php7.4-curl mysql-server openjdk-8-jdk elasticsearch

# reloadi elasticsearch
echo "\033[0;32m> Reloaing elasticsearch\033[0m"
sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable elasticsearch.service

# add PHP config changes, per https://devdocs.magento.com/guides/v2.4/install-gde/prereq/php-settings.html
echo "\033[0;32m> Making Magento PHP config amends\033[0m"

touch /etc/php/7.4/apache2/conf.d/50-magento.ini

echo "realpath_cache_size=10M" >> /etc/php/7.4/apache2/conf.d/50-magento.ini
echo "realpath_cache_ttl=7200" >> /etc/php/7.4/apache2/conf.d/50-magento.ini
echo "date.timezone=Europe/London" >> /etc/php/7.4/apache2/conf.d/50-magento.ini
echo "memory_limit=2G" >> /etc/php/7.4/apache2/conf.d/50-magento.ini
echo "opcache.save_comments=1" >> /etc/php/7.4/apache2/conf.d/50-magento.ini

# reload apache
echo "\033[0;32m> Enabling apache mods\033[0m"
a2enmod rewrite proxy_http

# install composer
echo "\033[0;32m> Installing composer\033[0m"
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
sudo php composer-setup.php --install-dir=/usr/bin --filename=composer
php -r "unlink('composer-setup.php');"

# apache changes
echo "\033[0;32m> Making Magento apache amends\033[0m"
rm /var/www/html/index.html

mv /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.backup

touch /etc/apache2/sites-available/000-default.conf

echo "Listen 8080" >> /etc/apache2/sites-available/000-default.conf
echo "<VirtualHost *:80>" >> /etc/apache2/sites-available/000-default.conf
echo -e "\tServerAdmin webmaster@localhost" >> /etc/apache2/sites-available/000-default.conf
echo -e "\tDocumentRoot /var/www/html" >> /etc/apache2/sites-available/000-default.conf
echo -e '\tErrorLog ${APACHE_LOG_DIR}/error.log' >> /etc/apache2/sites-available/000-default.conf
echo -e '\tCustomLog /${APACHE_LOG_DIR}/access.log combined' >> /etc/apache2/sites-available/000-default.conf
echo -e '\t<Directory "/var/www/html">' >> /etc/apache2/sites-available/000-default.conf
echo -e "\t\tAllowOverride All" >> /etc/apache2/sites-available/000-default.conf
echo -e "\t</Directory>" >> /etc/apache2/sites-available/000-default.conf
echo "</VirtualHost>" >> /etc/apache2/sites-available/000-default.conf
echo "<VirtualHost *:8080>" >> /etc/apache2/sites-available/000-default.conf
echo -e '\tProxyPass "/" "http://localhost:9200/"' >> /etc/apache2/sites-available/000-default.conf
echo -e '\tProxyPassReverse "/" "http://localhost:9200/"' >> /etc/apache2/sites-available/000-default.conf
echo "</VirtualHost>" >> /etc/apache2/sites-available/000-default.conf

# ufw
echo "\033[0;32m> Configuring firewall\033[0m"
ufw allow "Apache Full"

echo "\033[0;32m> Hello!\033[0m"
echo "\033[0;32m> You now have to make a database, please go to https://devdocs.magento.com/guides/v2.4/install-gde/prereq/mysql.html#instgde-prereq-mysql-config"
echo "\033[0;32m> After that, go grab your magento keys from https://marketplace.magento.com/customer/accessKeys/\033[0m"
echo "\033[0;32m> Then, install magento following:\033[0m"
echo "\033[0;32m1. https://devdocs.magento.com/guides/v2.4/install-gde/composer.html#get-the-metapackage\033[0m"
echo "\033[0;32m2. https://devdocs.magento.com/guides/v2.4/install-gde/composer.html#set-file-permissions\033[0m"
echo "\033[0;32m3. https://devdocs.magento.com/guides/v2.4/install-gde/composer.html#install-magento\033[0m"
