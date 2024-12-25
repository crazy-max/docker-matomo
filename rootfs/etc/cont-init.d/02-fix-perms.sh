#!/usr/bin/with-contenv sh
# shellcheck shell=sh

echo "Fixing perms..."
mkdir -p /data/config \
  /data/geoip \
  /data/misc \
  /data/plugins \
  /data/session \
  /data/tmp \
  /var/lib/nginx \
  /var/log/nginx \
  /var/log/php82 \
  /var/run/nginx \
  /var/run/php-fpm
chown matomo:matomo \
  /data \
  /data/config \
  /data/geoip \
  /data/misc \
  /data/plugins \
  /data/session \
  /data/tmp \
  /var/www/matomo/plugins \
  /var/www/matomo/matomo.js \
  /var/www/matomo/piwik.js \
  /var/www/matomo/vendor/tecnickcom/tcpdf/fonts
chown -R matomo:matomo \
  /tpls \
  /var/lib/nginx \
  /var/log/nginx \
  /var/log/php82 \
  /var/run/nginx \
  /var/run/php-fpm \
  /var/www/matomo/config \
  /var/www/matomo/js
