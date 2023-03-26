# syntax=docker/dockerfile:1

ARG MATOMO_VERSION=4.14.0
ARG ALPINE_VERSION=3.17

FROM crazymax/yasu:latest AS yasu
FROM --platform=${BUILDPLATFORM:-linux/amd64} crazymax/alpine-s6:${ALPINE_VERSION}-2.2.0.3 AS download
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

FROM crazymax/alpine-s6:${ALPINE_VERSION}-2.2.0.3

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
    php81 \
    php81-bcmath \
    php81-cli \
    php81-ctype \
    php81-curl \
    php81-dom \
    php81-iconv \
    php81-fpm \
    php81-gd \
    php81-gmp \
    php81-json \
    php81-ldap \
    php81-mbstring \
    php81-opcache \
    php81-openssl \
    php81-pdo \
    php81-pdo_mysql \
    php81-pecl-maxminddb \
    php81-redis \
    php81-session \
    php81-simplexml \
    php81-xml \
    php81-zlib \
    rsync \
    shadow \
    tzdata \
  && addgroup -g ${PGID} matomo \
  && adduser -D -H -u ${PUID} -G matomo -h /var/www/matomo  -s /bin/sh matomo \
  && rm -rf /tmp/*

COPY rootfs /

EXPOSE 8000
VOLUME [ "/data" ]

ENTRYPOINT [ "/init" ]

HEALTHCHECK --interval=30s --timeout=20s --start-period=10s \
  CMD /usr/local/bin/healthcheck
