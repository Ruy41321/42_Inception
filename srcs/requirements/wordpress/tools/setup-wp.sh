#!/bin/bash

# Check if secrets exist
for secret in mysql_user mysql_password wp_admin_usr wp_admin_pwd wp_admin_email wp_usr wp_email wp_pwd; do
    if [ ! -f "/run/secrets/$secret" ]; then
        echo "❌ ERROR: Secret file '$secret' not found!"
        exit 1
    fi
done

# Load secrets into environment variables
export MYSQL_USER=$(cat /run/secrets/mysql_user)
export MYSQL_PASSWORD=$(cat /run/secrets/mysql_password)
export WP_ADMIN_USR=$(cat /run/secrets/wp_admin_usr)
export WP_ADMIN_PWD=$(cat /run/secrets/wp_admin_pwd)
export WP_ADMIN_EMAIL=$(cat /run/secrets/wp_admin_email)
export WP_USR=$(cat /run/secrets/wp_usr)
export WP_EMAIL=$(cat /run/secrets/wp_email)
export WP_PWD=$(cat /run/secrets/wp_pwd)

#modyfing www.conf to set up php-fpm

sed -i -r 's|^user = .*$|user = www-data|' /etc/php82/php-fpm.d/www.conf
sed -i -r 's|^group = .*$|group = www-data|' /etc/php82/php-fpm.d/www.conf
sed -i -r 's|listen = 127.0.0.1:9000|listen = 0.0.0.0:9000|' /etc/php82/php-fpm.d/www.conf


#setting up wordpress

mkdir -p /var/www/html
cd /var/www/html
# chown -R www-data:www-data /var/www/html
# echo "- Setting directory permissions..."
# find /var/www/html -type d -exec chmod 755 {} \;
# echo "- Setting file permissions..."
# find /var/www/html -type f -exec chmod 644 {} \;
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
sed -i -r 's/memory_limit =.+/memory_limit = 512M/' /etc/php82/php.ini
if [ ! -f "wp-load.php" ]; then
	./wp-cli.phar core download --allow-root
	./wp-cli.phar core install --path=/var/www/html --url=$DOMAIN_NAME --title=Inception --admin_user=$WP_ADMIN_USR --admin_password=$WP_ADMIN_PWD --admin_email=$WP_ADMIN_EMAIL --allow-root
	./wp-cli.phar user create $WP_USR $WP_EMAIL --role=author --user_pass=$WP_PWD --allow-root --path=/var/www/html;

	mkdir -p /run/php
	chown -R www-data:www-data /run/php

fi
#setting up db

attempt=1
max_attempts=30
until mysqladmin ping -h "mariadb" -P "3306" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" --silent; do
    if [ $attempt -eq $max_attempts ]; then
        echo "❌ ERROR: Could not connect to MariaDB after $max_attempts attempts!"
        exit 1
    fi
    echo "- Attempt $attempt/$max_attempts: MariaDB is not ready yet. Retrying in 2 seconds..."
    attempt=$((attempt + 1))
    sleep 2
done
mysql -h "mariadb" -P "3306" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -D "wordpress" <<EOSQL
CREATE TABLE IF NOT EXISTS wp_users (
  ID bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  user_login varchar(60) NOT NULL DEFAULT '',
  user_pass varchar(255) NOT NULL DEFAULT '',
  user_nicename varchar(50) NOT NULL DEFAULT '',
  user_email varchar(100) NOT NULL DEFAULT '',
  user_url varchar(100) NOT NULL DEFAULT '',
  user_registered datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  user_activation_key varchar(255) NOT NULL DEFAULT '',
  user_status int(11) NOT NULL DEFAULT '0',
  display_name varchar(250) NOT NULL DEFAULT '',
  PRIMARY KEY (ID),
  KEY user_login_key (user_login),
  KEY user_nicename (user_nicename),
  KEY user_email (user_email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
EOSQL

# mysql -h "mariadb" -P "3306" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -D "wordpress" <<EOSQL
# INSERT INTO wp_users (user_login, user_pass, user_email, user_registered, display_name)
# SELECT 'editor_user', MD5('securepassword'), 'editor@example.com', NOW(), 'Editor'
# WHERE NOT EXISTS (SELECT 1 FROM wp_users WHERE user_login = 'editor_user');

# INSERT INTO wp_users (user_login, user_pass, user_email, user_registered, display_name)
# SELECT 'non_admin', MD5('securepassword'), 'nonadmin@example.com', NOW(), 'Non Admin'
# WHERE NOT EXISTS (SELECT 1 FROM wp_users WHERE user_login = 'non_admin');
# EOSQL

# chmod -R 775 /var/www/html/wp-content
# chown -R www-data:www-data /var/www/html/wp-content

# mkdir -p /run/php
# chown -R www-data:www-data /run/php

exec php-fpm82 -F