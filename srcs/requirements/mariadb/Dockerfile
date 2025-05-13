FROM alpine:3.20.0

RUN apk update && apk add --no-cache bash \
    mariadb mariadb-client && \
    mkdir -p /var/lib/mysql && \
    chown -R mysql:mysql /var/lib/mysql && \
    mysql_install_db --user=mysql --datadir=/var/lib/mysql

RUN mkdir -p /run/mysqld && chown -R mysql:mysql /run/mysqld

COPY ./conf/my.cnf /etc/my.cnf
COPY ./tools/script.sh ./script.sh

RUN chmod +x script.sh

EXPOSE 3306

ENTRYPOINT [ "./script.sh" ]