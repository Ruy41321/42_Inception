#!/bin/bash

mkdir -p initdb.d

cat << EOF > /initdb.d/init.sql
-- Create the specified database
CREATE DATABASE IF NOT EXISTS wordpress;

-- Create a non-root user and grant privileges
CREATE USER IF NOT EXISTS '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';
CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON wordpress.* TO '$MYSQL_USER'@'localhost';
GRANT ALL PRIVILEGES ON wordpress.* TO '$MYSQL_USER'@'%';

-- Set root password and allow root access from any host
ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;

-- Flush privileges to apply changes
FLUSH PRIVILEGES;
EOF

exec mysqld --datadir=/var/lib/mysql --user=mysql --init-file=/initdb.d/init.sql