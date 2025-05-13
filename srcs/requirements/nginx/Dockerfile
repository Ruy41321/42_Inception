FROM alpine:3.20.0

RUN apk update && apk add --no-cache \
		nginx \
		openssl \
		shadow

RUN mkdir -p /var/www/html
RUN chown -R nginx:www-data /var/www/html
RUN	usermod -aG www-data nginx

RUN mkdir /etc/nginx/ssl_cert && openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
		-keyout /etc/nginx/ssl_cert/server.key \
		-out /etc/nginx/ssl_cert/server.crt \
		-subj "/C=IT/ST=Rome/L=Rome/O=42/OU=42/CN=lpennisi.42.fr"

# Copy the initialization script
COPY --chown=nginx:nginx ./tools/init.sh /init.sh
RUN chmod +x /init.sh

ENTRYPOINT ["/init.sh"]