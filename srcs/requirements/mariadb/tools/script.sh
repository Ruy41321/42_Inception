#!/bin/bash

# Check if secrets exist
if [ ! -f /run/secrets/mysql_root_password ]; then
    echo "❌ ERROR: Secret file 'mysql_root_password' not found!"
    exit 1
fi

if [ ! -f /run/secrets/mysql_user ]; then
    echo "❌ ERROR: Secret file 'mysql_user' not found!"
    exit 1
fi

if [ ! -f /run/secrets/mysql_password ]; then
    echo "❌ ERROR: Secret file 'mysql_password' not found!"
    exit 1
fi

# Load secrets into environment variables
export MYSQL_ROOT_PASSWORD=$(cat /run/secrets/mysql_root_password)
export MYSQL_USER=$(cat /run/secrets/mysql_user)
export MYSQL_PASSWORD=$(cat /run/secrets/mysql_password)

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