FROM alpine:3.20.0

RUN apk update && apk add --no-cache \
    php82 \
    php82-fpm \
    php82-mysqli \
    php82-phar \
    php82-mbstring \
	mariadb-client \
	curl \
    bash \
    && ln -s /usr/bin/php82 /usr/bin/php

RUN adduser -S -G www-data www-data

COPY ./tools/wp-config.sh .
COPY ./tools/setup-wp.sh .

RUN chmod +x setup-wp.sh
RUN chmod +x wp-config.sh
# RUN mkdir -p /var/www/html && \
# 	chown -R www-data:www-data /var/www/html && \
#     chmod -R 755 /var/www/html

EXPOSE 9000

ENTRYPOINT ["./wp-config.sh"]