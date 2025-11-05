#!/bin/bash
set -e

# Check if secrets exist
if [ ! -f /run/secrets/mysql_user ]; then
    echo "❌ ERROR: Secret file 'mysql_user' not found!"
    exit 1
fi

if [ ! -f /run/secrets/mysql_password ]; then
    echo "❌ ERROR: Secret file 'mysql_password' not found!"
    exit 1
fi

# Load secrets into environment variables
export MYSQL_USER=$(cat /run/secrets/mysql_user)
export MYSQL_PASSWORD=$(cat /run/secrets/mysql_password)

CONFIG_FILE=/var/www/html/wp-config.php
KEYS=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)

cat > "$CONFIG_FILE" << EOF
<?php
/* Database configuration */
define( 'DB_NAME', 'wordpress' );
define( 'DB_USER', '${MYSQL_USER}' );
define( 'DB_PASSWORD', '${MYSQL_PASSWORD}' );
define( 'DB_HOST', 'mariadb' );
define( 'DB_CHARSET', 'utf8' );
define( 'DB_COLLATE', '' );

/* Authentication unique keys and salts */
${KEYS}

/* WordPress database table prefix */
\$table_prefix = 'wp_';

/* Debug settings */
define( 'WP_DEBUG', true );
define( 'WP_DEBUG_LOG', true );
define( 'WP_DEBUG_DISPLAY', false );

define( 'WP_MEMORY_LIMIT', '512M' );

/* Absolute path to the WordPress directory */
if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', dirname( __FILE__ ) . '/' );
}

/* Sets up WordPress vars and included files */
require_once ABSPATH . 'wp-settings.php';
EOF
chown www-data:www-data "$CONFIG_FILE"
chmod 644 "$CONFIG_FILE"

exec ./setup-wp.sh