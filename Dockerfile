FROM alpine:3.20

USER root

ARG ARCH="unspecified"

RUN apk update && \
    apk add --no-cache \
        lighttpd \
        php83 \
        php83-fpm \
        php83-common \
        php83-json \
        php83-curl \
        php83-openssl \
        php83-mbstring \
        lsof \
        bash \
        ca-certificates

COPY --chown=lighttpd:lighttpd byedpi /var/www/html/byedpi
RUN rm -f /var/www/html/byedpi/ciadpi
COPY --chown=lighttpd:lighttpd css /var/www/html/css
COPY --chown=lighttpd:lighttpd js /var/www/html/js
COPY --chown=lighttpd:lighttpd php /var/www/html/php
COPY --chown=lighttpd:lighttpd config.json /var/www/html
COPY --chown=lighttpd:lighttpd favicon.ico /var/www/html
COPY --chown=lighttpd:lighttpd index.html /var/www/html
COPY --chown=lighttpd:lighttpd local.pac /var/www/html
COPY --chown=lighttpd:lighttpd readme.txt /var/www/html

RUN mkdir -p /var/www/html/byedpi && \
    cd /var/www/html/byedpi && \
    apk add --no-cache --virtual .deps curl tar && \
    case "$ARCH" in \
        aarch64) \
            curl -L -o byedpi.tar.gz "https://github.com/hufrea/byedpi/releases/download/v0.17/byedpi-17-aarch64.tar.gz" ;; \
        armv6) \
            curl -L -o byedpi.tar.gz "https://github.com/hufrea/byedpi/releases/download/v0.17/byedpi-17-armv6.tar.gz" ;; \
        armv7l) \
            curl -L -o byedpi.tar.gz "https://github.com/hufrea/byedpi/releases/download/v0.17/byedpi-17-armv7l.tar.gz" ;; \
        x86_64) \
            curl -L -o byedpi.tar.gz "https://github.com/hufrea/byedpi/releases/download/v0.17/byedpi-17-x86_64.tar.gz" ;; \
        *) \
            echo "ОШИБКА: Не указана или неподдерживаемая архитектура (ARCH=$ARCH). Поддерживаемые: aarch64, armv6, armv7l, x86_64" >&2 ; \
            exit 1 ;; \
    esac && \
    tar -xzf byedpi.tar.gz && \
    mv ciadpi* ciadpi && \
    chmod +x ciadpi && \	
    rm byedpi.tar.gz && \
    apk del .deps

RUN sed -i \
    -e 's/user = nobody/user = lighttpd/' \
    -e 's/group = nobody/group = lighttpd/' \
    -e 's/listen = 127.0.0.1:9000/listen = \/var\/run\/php-fpm83.sock/' \
    -e 's/;listen.owner = nobody/listen.owner = lighttpd/' \
    -e 's/;listen.group = nobody/listen.group = lighttpd/' \
    /etc/php83/php-fpm.d/www.conf

RUN cat <<EOF > /etc/lighttpd/lighttpd.conf
server.modules = (
    "mod_access",
    "mod_fastcgi"
)
server.document-root = "/var/www/html"
# Порт http веб сервера
server.port = 20000
index-file.names = ( "index.html" )
server.username = "lighttpd"
server.groupname = "lighttpd"
server.errorlog = "/dev/null"
fastcgi.server = (
    ".php" => ((
        "socket" => "/var/run/php-fpm83.sock",
        "broken-scriptfilename" => "enable"
    ))
)
EOF

RUN mkdir -p /var/run/php /var/run/lighttpd && \
    chown -R lighttpd:lighttpd /var/www/html /var/run/lighttpd /var/run/php

# Порт http веб сервера
EXPOSE 20000

# Порты ciadpi для использования
EXPOSE 20001-20008

RUN echo -e '#!/bin/sh\n\
php-fpm83 &\n\
lighttpd -D -f /etc/lighttpd/lighttpd.conf' > /entrypoint.sh && \
chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]