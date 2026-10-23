# syntax=docker/dockerfile:1

ARG MATOMO_VERSION=5.14.1
ARG ALPINE_VERSION=3.24

FROM tianon/gosu:latest AS gosu

FROM --platform=${BUILDPLATFORM} crazymax/alpine-s6:${ALPINE_VERSION}-2.2.0.3 AS download
RUN apk --update --no-cache add curl tar unzip xz
ARG MATOMO_VERSION
WORKDIR /dist/matomo
RUN curl -sSL "https://builds.matomo.org/matomo-${MATOMO_VERSION}.tar.gz" | tar xz matomo --strip 1
RUN curl -sSL "https://matomo.org/wp-content/uploads/unifont.ttf.zip" -o "unifont.ttf.zip"
RUN unzip "unifont.ttf.zip" -d "./plugins/ImageGraph/fonts/"
RUN rm -f "unifont.ttf.zip"
# Download free marketplace plugins
RUN curl -sSL "https://plugins.matomo.org/api/2.0/plugins/QueuedTracking/download/5.2.0" \
  -o /tmp/QueuedTracking.zip \
  && unzip /tmp/QueuedTracking.zip -d plugins/ \
  && rm /tmp/QueuedTracking.zip

RUN curl -sSL "https://plugins.matomo.org/api/2.0/plugins/CustomAlerts/download/5.2.3" \
  -o /tmp/CustomAlerts.zip \
  && unzip /tmp/CustomAlerts.zip -d plugins/ \
  && rm /tmp/CustomAlerts.zip

RUN curl -sSL "https://plugins.matomo.org/api/2.0/plugins/TrackingSpamPrevention/download/5.0.8" \
  -o /tmp/TrackingSpamPrevention.zip \
  && unzip /tmp/TrackingSpamPrevention.zip -d plugins/ \
  && rm /tmp/TrackingSpamPrevention.zip

RUN curl -sSL "https://plugins.matomo.org/api/2.0/plugins/InvalidateReports/download/5.0.2" \
  -o /tmp/InvalidateReports.zip \
  && unzip /tmp/InvalidateReports.zip -d plugins/ \
  && rm /tmp/InvalidateReports.zip

RUN curl -sSL "https://plugins.matomo.org/api/2.0/plugins/Migration/download/5.0.6" \
  -o /tmp/Migration.zip \
  && unzip /tmp/Migration.zip -d plugins/ \
  && rm /tmp/Migration.zip

RUN curl -sSL "https://plugins.matomo.org/api/2.0/plugins/SecurityInfo/download/5.0.4" \
  -o /tmp/SecurityInfo.zip \
  && unzip /tmp/SecurityInfo.zip -d plugins/ \
  && rm /tmp/SecurityInfo.zip

RUN curl -sSL "https://plugins.matomo.org/api/2.0/plugins/ProtectTrackID/download/3.2.0" \
  -o /tmp/ProtectTrackID.zip \
  && unzip /tmp/ProtectTrackID.zip -d plugins/ \
  && rm /tmp/ProtectTrackID.zip

RUN curl -sSL "https://plugins.matomo.org/api/2.0/plugins/BotTracker/download/5.2.18" \
  -o /tmp/BotTracker.zip \
  && unzip /tmp/BotTracker.zip -d plugins/ \
  && rm /tmp/BotTracker.zip

# Copy premium plugins from build context (requires valid license in Matomo instance)
COPY plugins/Funnels plugins/Funnels
COPY plugins/UsersFlow plugins/UsersFlow
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

COPY --from=gosu /gosu /usr/local/bin/
COPY --from=download --chown=nobody:nogroup /dist/matomo /var/www/matomo
COPY --from=download --chown=nobody:nogroup /dist/mmdb /var/mmdb

RUN apk --update --no-cache add \
    bash \
    ca-certificates \
    curl \
    libmaxminddb \
    nginx \
    nginx-mod-http-brotli \
    openssl \
    php85 \
    php85-bcmath \
    php85-cli \
    php85-ctype \
    php85-curl \
    php85-dom \
    php85-iconv \
    php85-fpm \
    php85-gd \
    php85-gmp \
    php85-json \
    php85-ldap \
    php85-mbstring \
    php85-openssl \
    php85-pdo \
    php85-pdo_mysql \
    php85-pecl-maxminddb \
    php85-redis \
    php85-session \
    php85-simplexml \
    php85-xml \
    php85-zlib \
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
