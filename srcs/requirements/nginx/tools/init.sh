#!/bin/sh
set -e

#risolvere il mancato caricamento del css e poi vederti i database per capire

cat << EOF > /etc/nginx/nginx.conf
# /etc/nginx/nginx.conf

user nginx;

# Set number of worker processes automatically based on number of CPU cores.
worker_processes auto;

# Enables the use of JIT for regular expressions to speed-up their processing.
pcre_jit on;

# Configures default error logger.
error_log /var/log/nginx/error.log warn;

# Includes files with directives to load dynamic modules.
include /etc/nginx/modules/*.conf;

# Include files with config snippets into the root context.
include /etc/nginx/conf.d/*.conf;

events {
	# The maximum number of simultaneous connections that can be opened by
	# a worker process.
	worker_connections 1024;
}

http {
	# Includes mapping of file name extensions to MIME types of responses
	# and defines the default type.
	include /etc/nginx/mime.types;
	default_type application/octet-stream;

	# Name servers used to resolve names of upstream servers into addresses.
	# It's also needed when using tcpsocket and udpsocket in Lua modules.
	#resolver 1.1.1.1 1.0.0.1 [2606:4700:4700::1111] [2606:4700:4700::1001];

	# Don't tell nginx version to the clients. Default is 'on'.
	server_tokens off;

	# Specifies the maximum accepted body size of a client request, as
	# indicated by the request header Content-Length. If the stated content
	# length is greater than this size, then the client receives the HTTP
	# error code 413. Set to 0 to disable. Default is '1m'.
	client_max_body_size 1m;

	# Sendfile copies data between one FD and other from within the kernel,
	# which is more efficient than read() + write(). Default is off.
	sendfile on;

	# Causes nginx to attempt to send its HTTP response head in one packet,
	# instead of using partial frames. Default is 'off'.
	tcp_nopush on;



	# Enable gzipping of responses.
	#gzip on;

	# Set the Vary HTTP header as defined in the RFC 2616. Default is 'off'.
	gzip_vary on;


	# Helper variable for proxying websockets.
	map \$http_upgrade \$connection_upgrade {
		default upgrade;
		'' close;
	}


	# Specifies the main log format.
	log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
			'\$status \$body_bytes_sent "\$http_referer" '
			'"\$http_user_agent" "\$http_x_forwarded_for"';

	# Sets the path, format, and configuration for a buffered log write.
	access_log /var/log/nginx/access.log main;

	server {
        listen 443 ssl;
        listen [::]:443 ssl;
        server_name ${DOMAIN_NAME};

        # SSL Configuration
        ssl_certificate ${SSL_CERTIFICATE};
        ssl_certificate_key ${SSL_KEY};
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_prefer_server_ciphers off;
        ssl_ciphers 'TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_128_GCM_SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384';

        # Root and index
        root /var/www/html;
        index index.php index.html index.htm;

      	# === PHP Processing ===
		location ~ \.php$ {
			# Parses PHP URLs for proper routing
			fastcgi_split_path_info ^(.+\.php)(/.+)$;

			# Routes PHP requests to WordPress container
			fastcgi_pass wordpress:9000;
			fastcgi_index index.php;

			# Constructs absolute path to PHP script
			include fastcgi_params;
			fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
			fastcgi_param PATH_INFO \$fastcgi_path_info;

			# Extended timeout for long-running scripts
			fastcgi_read_timeout 300;
		}
	}
}
EOF

exec nginx -g "daemon off;"