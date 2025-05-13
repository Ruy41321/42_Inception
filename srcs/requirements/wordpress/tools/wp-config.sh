#!/bin/bash
set -e

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