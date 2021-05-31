ARG MATOMO_VERSION=4.3.1

FROM crazymax/yasu:latest AS yasu
FROM --platform=${BUILDPLATFORM:-linux/amd64} crazymax/alpine-s6:3.13-2.2.0.3 AS download
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

FROM crazymax/alpine-s6:3.13-2.2.0.3
LABEL maintainer="CrazyMax"

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
    libressl \
    nginx \
    php7 \
    php7-bcmath \
    php7-cli \
    php7-ctype \
    php7-curl \
    php7-dom \
    php7-iconv \
    php7-fpm \
    php7-gd \
    php7-gmp \
    php7-json \
    php7-ldap \
    php7-maxminddb \
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
    rsync \
    shadow \
    tzdata \
  && addgroup -g ${PGID} matomo \
  && adduser -D -H -u ${PUID} -G matomo -h /var/www/matomo  -s /bin/sh matomo \
  && rm -rf /tmp/* /var/cache/apk/*

COPY rootfs /

EXPOSE 8000
VOLUME [ "/data" ]

ENTRYPOINT [ "/init" ]

HEALTHCHECK --interval=30s --timeout=20s --start-period=10s \
  CMD /usr/local/bin/healthcheck
