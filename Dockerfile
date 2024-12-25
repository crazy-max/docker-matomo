# syntax=docker/dockerfile:1

ARG MATOMO_VERSION=5.2.1
ARG ALPINE_VERSION=3.21

FROM --platform=${BUILDPLATFORM} crazymax/alpine-s6:${ALPINE_VERSION}-2.2.0.3 AS download
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

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS="2" \
  TZ="UTC" \
  PUID="1000" \
  PGID="1000" \
  MATOMO_PLUGIN_DIRS="/var/www/matomo/data-plugins/;data-plugins" \
  MATOMO_PLUGIN_COPY_DIR="/var/www/matomo/data-plugins/"

COPY --from=crazymax/yasu:latest / /
COPY --from=download --chown=nobody:nogroup /dist/matomo /var/www/matomo
COPY --from=download --chown=nobody:nogroup /dist/mmdb /var/mmdb

RUN apk --update --no-cache add \
    bash \
    ca-certificates \
    curl \
    libmaxminddb \
    nginx \
    openssl \
    php83 \
    php83-bcmath \
    php83-cli \
    php83-ctype \
    php83-curl \
    php83-dom \
    php83-iconv \
    php83-fpm \
    php83-gd \
    php83-gmp \
    php83-json \
    php83-ldap \
    php83-mbstring \
    php83-opcache \
    php83-openssl \
    php83-pdo \
    php83-pdo_mysql \
    php83-pecl-maxminddb \
    php83-redis \
    php83-session \
    php83-simplexml \
    php83-xml \
    php83-zlib \
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
