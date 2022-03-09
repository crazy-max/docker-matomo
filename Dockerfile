ARG MATOMO_VERSION=4.8.0

FROM crazymax/yasu:latest AS yasu
FROM --platform=${BUILDPLATFORM:-linux/amd64} crazymax/alpine-s6:3.15-2.2.0.3 AS download
RUN apk --update --no-cache add curl tar unzip xz

ARG MATOMO_VERSION
WORKDIR /dist/matomo
RUN curl -sSL "https://builds.matomo.org/matomo-${MATOMO_VERSION}.tar.gz" | tar xz matomo --strip 1
RUN curl -sSL "https://matomo.org/wp-content/uploads/unifont.ttf.zip" -o "unifont.ttf.zip"
RUN unzip "unifont.ttf.zip" -d "./plugins/ImageGraph/fonts/"
RUN rm -f "unifont.ttf.zip"

WORKDIR /dist/mmdb
RUN curl -SsOL "https://github.com/crazy-max/geoip-updater/raw/mmdb/GeoLite2-ASN.mmdb" \
  && curl -SsOL "https://github.com/crazy-max/geoip-updater/raw/mmdb/GeoLite2-City.mmdb" \
  && curl -SsOL "https://github.com/crazy-max/geoip-updater/raw/mmdb/GeoLite2-Country.mmdb"

FROM crazymax/alpine-s6:3.15-2.2.0.3

COPY --from=yasu / /
COPY --from=download --chown=nobody:nogroup /dist/matomo /var/www/matomo
COPY --from=download --chown=nobody:nogroup /dist/mmdb /var/mmdb

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS="2" \
  TZ="UTC" \
  PUID="1000" \
  PGID="1000" \
  MATOMO_PLUGIN_DIRS="/var/www/matomo/data-plugins/;data-plugins" \
  MATOMO_PLUGIN_COPY_DIR="/var/www/matomo/data-plugins/"

RUN apk --update --no-cache add \
    bash \
    ca-certificates \
    curl \
    libmaxminddb \
    nginx \
    openssl \
    php8 \
    php8-bcmath \
    php8-cli \
    php8-ctype \
    php8-curl \
    php8-dom \
    php8-iconv \
    php8-fpm \
    php8-gd \
    php8-gmp \
    php8-json \
    php8-ldap \
    php8-mbstring \
    php8-opcache \
    php8-openssl \
    php8-pdo \
    php8-pdo_mysql \
    php8-pecl-maxminddb \
    php8-redis \
    php8-session \
    php8-simplexml \
    php8-xml \
    php8-zlib \
    rsync \
    shadow \
    tzdata \
  && ln -s /usr/bin/php8 /usr/bin/php \
  && addgroup -g ${PGID} matomo \
  && adduser -D -H -u ${PUID} -G matomo -h /var/www/matomo  -s /bin/sh matomo \
  && rm -rf /tmp/*

COPY rootfs /

EXPOSE 8000
VOLUME [ "/data" ]

ENTRYPOINT [ "/init" ]

HEALTHCHECK --interval=30s --timeout=20s --start-period=10s \
  CMD /usr/local/bin/healthcheck
