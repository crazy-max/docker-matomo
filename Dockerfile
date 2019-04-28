FROM nginx:stable-alpine

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

LABEL maintainer="CrazyMax" \
  org.label-schema.build-date=$BUILD_DATE \
  org.label-schema.name="matomo" \
  org.label-schema.description="Matomo (formerly Piwik)" \
  org.label-schema.version=$VERSION \
  org.label-schema.url="https://github.com/crazy-max/docker-matomo" \
  org.label-schema.vcs-ref=$VCS_REF \
  org.label-schema.vcs-url="https://github.com/crazy-max/docker-matomo" \
  org.label-schema.vendor="CrazyMax" \
  org.label-schema.schema-version="1.0"

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
  && mkdir -p /usr/src \
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

RUN cd /tmp \
  && mkdir -p /etc/nginx/geoip \
  && wget -q http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.tar.gz \
  && wget -q http://geolite.maxmind.com/download/geoip/database/GeoLite2-Country.tar.gz \
  && wget -q http://geolite.maxmind.com/download/geoip/database/GeoLite2-ASN.tar.gz \
  && tar -xvzf GeoLite2-City.tar.gz --strip-components=1 \
  && tar -xvzf GeoLite2-Country.tar.gz --strip-components=1 \
  && tar -xvzf GeoLite2-ASN.tar.gz --strip-components=1 \
  && mv *.mmdb /etc/nginx/geoip \
  && rm -rf /tmp/*

ENV MATOMO_VERSION="3.9.1" \
  CRONTAB_PATH="/var/spool/cron/crontabs"

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
  && chown -R nginx. /etc/nginx /usr/lib/nginx /var/cache/nginx /var/log/nginx /var/log/php7 /var/www \
  && apk del build-dependencies \
  && rm -rf /root/.gnupg /tmp/* /var/cache/apk/*

COPY entrypoint.sh /entrypoint.sh
COPY assets /

RUN chmod a+x /entrypoint.sh /usr/local/bin/* \
  && chown nginx. /var/www/bootstrap.php

EXPOSE 8000
WORKDIR /var/www
VOLUME [ "/data" ]

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "/usr/bin/supervisord", "-c", "/etc/supervisord.conf" ]
