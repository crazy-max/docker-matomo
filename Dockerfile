FROM alpine:3.7
MAINTAINER CrazyMax <crazy-max@users.noreply.github.com>

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

LABEL org.label-schema.build-date=$BUILD_DATE \
  org.label-schema.name="matomo" \
  org.label-schema.description="Matomo (formerly Piwik) based on Alpine Linux and Nginx" \
  org.label-schema.version=$VERSION \
  org.label-schema.url="https://github.com/crazy-max/docker-matomo" \
  org.label-schema.vcs-ref=$VCS_REF \
  org.label-schema.vcs-url="https://github.com/crazy-max/docker-matomo" \
  org.label-schema.vendor="CrazyMax" \
  org.label-schema.schema-version="1.0"

RUN apk --update --no-cache add \
    geoip inotify-tools nginx nginx-mod-http-geoip ssmtp supervisor tzdata \
    php7 php7-cli php7-ctype php7-curl php7-dom php7-iconv php7-fpm php7-gd php7-json php7-ldap php7-mbstring \
    php7-opcache php7-openssl php7-pdo php7-pdo_mysql php7-redis php7-session php7-simplexml php7-xml php7-zlib \
  && rm -rf /var/cache/apk/* /var/www/* /tmp/*

ENV MATOMO_VERSION="3.3.0" \
  CRONTAB_PATH="/var/spool/cron/crontabs"

RUN apk --update --no-cache add -t build-dependencies \
    ca-certificates gnupg libressl tar wget \
  && cd /tmp \
  && wget -q https://builds.matomo.org/piwik-${MATOMO_VERSION}.tar.gz \
  && wget -q https://builds.matomo.org/piwik-${MATOMO_VERSION}.tar.gz.asc \
  && wget -q https://builds.matomo.org/signature.asc \
  && gpg --import signature.asc \
  && gpg --verify piwik-${MATOMO_VERSION}.tar.gz.asc piwik-${MATOMO_VERSION}.tar.gz \
  && tar -xzf piwik-${MATOMO_VERSION}.tar.gz --strip 1 -C /var/www \
  && mkdir -p /etc/nginx/geoip \
  && cd /etc/nginx/geoip \
  && wget -q https://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz \
  && gzip -d GeoLiteCity.dat.gz && mv GeoLiteCity.dat GeoIPCity.dat \
  && wget -q http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz \
  && gzip -d GeoIP.dat.gz && mv GeoIP.dat GeoIPCountry.dat \
  && cp -f /etc/ssmtp/ssmtp.conf /etc/ssmtp/ssmtp.conf.or \
  && apk del build-dependencies \
  && rm -rf /root/.gnupg /tmp/* /var/cache/apk/*

ADD entrypoint.sh /entrypoint.sh
ADD assets /

RUN chmod a+x /entrypoint.sh /usr/local/bin/* \
  && chown -R nginx. /etc/nginx/geoip /var/lib/nginx /var/log/nginx /var/log/php7 /var/tmp/nginx /var/www

EXPOSE 80
WORKDIR "/var/www"
VOLUME [ "/data" ]

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "/usr/bin/supervisord", "-c", "/etc/supervisord.conf" ]
