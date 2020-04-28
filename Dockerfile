# syntax=docker/dockerfile:experimental
FROM --platform=${TARGETPLATFORM:-linux/amd64} nginx:mainline-alpine

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

LABEL maintainer="CrazyMax" \
  org.opencontainers.image.created=$BUILD_DATE \
  org.opencontainers.image.url="https://github.com/crazy-max/docker-matomo" \
  org.opencontainers.image.source="https://github.com/crazy-max/docker-matomo" \
  org.opencontainers.image.version=$VERSION \
  org.opencontainers.image.revision=$VCS_REF \
  org.opencontainers.image.vendor="CrazyMax" \
  org.opencontainers.image.title="Matomo" \
  org.opencontainers.image.description="Matomo (formerly Piwik)" \
  org.opencontainers.image.licenses="MIT"

RUN apk --update --no-cache add -t build-dependencies \
    gcc \
    gd-dev \
    geoip-dev \
    git \
    gnupg \
    libc-dev \
    libmaxminddb-dev \
    libxslt-dev \
    linux-headers \
    make \
    openssl-dev \
    pcre-dev \
    perl-dev \
    zlib-dev \
  && mkdir -p /usr/src /var/lib/nginx/body /var/lib/nginx/fastcgi \
  && cd /usr/src \
  && wget http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz \
  && tar zxvf nginx-$NGINX_VERSION.tar.gz \
  && git clone -b master --single-branch https://github.com/leev/ngx_http_geoip2_module.git \
  && cd nginx-$NGINX_VERSION \
  && ./configure --with-compat --add-dynamic-module=../ngx_http_geoip2_module \
  && make modules \
  && cp objs/ngx_http_geoip2_module.so /etc/nginx/modules \
  && apk del build-dependencies \
  && rm -rf /usr/src/nginx-* /usr/src/ngx_http_geoip2_module /var/cache/apk/* /var/www/* /tmp/*

RUN apk --update --no-cache add \
    curl \
    geoip \
    inotify-tools \
    libmaxminddb \
    php7 \
    php7-cli \
    php7-ctype \
    php7-curl \
    php7-dom \
    php7-iconv \
    php7-fpm \
    php7-gd \
    php7-json \
    php7-ldap \
    php7-mbstring \
    php7-opcache \
    php7-openssl \
    php7-pdo \
    php7-pdo_mysql \
    php7-redis \
    php7-session \
    php7-simplexml \
    php7-xml \
    php7-zlib \
    ssmtp \
    supervisor \
    tzdata \
    wget \
  && rm -rf /var/cache/apk/* /var/www/* /tmp/*

RUN mkdir -p /var/mmdb \
  && wget -q https://github.com/crazy-max/docker-matomo/raw/mmdb/GeoLite2-ASN.mmdb -qO /var/mmdb/GeoLite2-ASN.mmdb \
  && wget -q https://github.com/crazy-max/docker-matomo/raw/mmdb/GeoLite2-City.mmdb -qO /var/mmdb/GeoLite2-City.mmdb \
  && wget -q https://github.com/crazy-max/docker-matomo/raw/mmdb/GeoLite2-Country.mmdb -qO /var/mmdb/GeoLite2-Country.mmdb

ENV MATOMO_VERSION="3.13.5" \
  CRONTAB_PATH="/var/spool/cron/crontabs" \
  TZ="UTC"

RUN apk --update --no-cache add -t build-dependencies \
    ca-certificates gnupg libressl tar \
  && mkdir -p /var/www \
  && cd /tmp \
  && wget -q https://builds.matomo.org/piwik-${MATOMO_VERSION}.tar.gz \
  && wget -q https://builds.matomo.org/piwik-${MATOMO_VERSION}.tar.gz.asc \
  && wget -q https://builds.matomo.org/signature.asc \
  && gpg --import signature.asc \
  && gpg --verify --batch --no-tty piwik-${MATOMO_VERSION}.tar.gz.asc piwik-${MATOMO_VERSION}.tar.gz \
  && tar -xzf piwik-${MATOMO_VERSION}.tar.gz --strip 1 -C /var/www \
  && wget -q https://matomo.org/wp-content/uploads/unifont.ttf.zip \
  && unzip unifont.ttf.zip -d /var/www/plugins/ImageGraph/fonts/ \
  && rm unifont.ttf.zip \
  && chown -R nginx. /etc/nginx /usr/lib/nginx /var/cache/nginx /var/lib/nginx /var/log/nginx /var/log/php7 /var/www \
  && apk del build-dependencies \
  && rm -rf /root/.gnupg /tmp/* /var/cache/apk/*

COPY entrypoint.sh /entrypoint.sh
COPY rootfs /

RUN chmod a+x /entrypoint.sh /usr/local/bin/* \
  && chown nginx. /var/www/bootstrap.php

EXPOSE 8000
WORKDIR /var/www
VOLUME [ "/data" ]

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "/usr/bin/supervisord", "-c", "/etc/supervisord.conf" ]

HEALTHCHECK --interval=10s --timeout=5s \
  CMD /usr/local/bin/healthcheck
