#!/usr/bin/with-contenv sh

runas_user() {
  yasu matomo:matomo "$@"
}

TZ=${TZ:-UTC}
MEMORY_LIMIT=${MEMORY_LIMIT:-256M}
UPLOAD_MAX_SIZE=${UPLOAD_MAX_SIZE:-16M}
CLEAR_ENV=${CLEAR_ENV:-yes}
OPCACHE_MEM_SIZE=${OPCACHE_MEM_SIZE:-128}
LISTEN_IPV6=${LISTEN_IPV6:-true}
REAL_IP_FROM=${REAL_IP_FROM:-0.0.0.0/32}
REAL_IP_HEADER=${REAL_IP_HEADER:-X-Forwarded-For}
LOG_IP_VAR=${LOG_IP_VAR:-remote_addr}

SHORTCODE_DOMAIN=${SHORTCODE_DOMAIN:-invalid}
LOG_LEVEL=${LOG_LEVEL:-WARN}

# Timezone
echo "Setting timezone to ${TZ}..."
ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime
echo ${TZ} > /etc/timezone

# PHP
echo "Setting PHP-FPM configuration..."
sed -e "s/@MEMORY_LIMIT@/$MEMORY_LIMIT/g" \
  -e "s/@UPLOAD_MAX_SIZE@/$UPLOAD_MAX_SIZE/g" \
  -e "s/@CLEAR_ENV@/$CLEAR_ENV/g" \
  /tpls/etc/php7/php-fpm.d/www.conf > /etc/php7/php-fpm.d/www.conf

echo "Setting PHP INI configuration..."
sed -i "s|memory_limit.*|memory_limit = ${MEMORY_LIMIT}|g" /etc/php7/php.ini
sed -i "s|;date\.timezone.*|date\.timezone = ${TZ}|g" /etc/php7/php.ini

# OpCache
echo "Setting OpCache configuration..."
sed -e "s/@OPCACHE_MEM_SIZE@/$OPCACHE_MEM_SIZE/g" \
  /tpls/etc/php7/conf.d/opcache.ini > /etc/php7/conf.d/opcache.ini

# Nginx
echo "Setting Nginx configuration..."
sed -e "s#@UPLOAD_MAX_SIZE@#$UPLOAD_MAX_SIZE#g" \
  -e "s#@REAL_IP_FROM@#$REAL_IP_FROM#g" \
  -e "s#@REAL_IP_HEADER@#$REAL_IP_HEADER#g" \
  -e "s#@LOG_IP_VAR@#$LOG_IP_VAR#g" \
  -e "s#@SHORTCODE_DOMAIN@#$SHORTCODE_DOMAIN#g" \
  /tpls/etc/nginx/nginx.conf > /etc/nginx/nginx.conf

if [ "$LISTEN_IPV6" != "true" ]; then
  sed -e '/listen \[::\]:/d' -i /etc/nginx/nginx.conf
fi

# GeoIP2 databases
if [ ! "$(ls -A /data/geoip)" ]; then
  runas_user cp -f /var/mmdb/*.mmdb /data/geoip/
fi

# Create symlinks for GeoIP 2 databases to Matomo
if [ -e "/data/geoip/GeoLite2-ASN.mmdb" ]; then
  echo "Symlink GeoLite2-ASN.mmdb to Matomo"
  ln -sf "/data/geoip/GeoLite2-ASN.mmdb" "/var/www/matomo/misc/GeoLite2-ASN.mmdb"
fi
if [ -e "/data/geoip/GeoLite2-City.mmdb" ]; then
  echo "Symlink GeoLite2-City.mmdb to Matomo"
  ln -sf "/data/geoip/GeoLite2-City.mmdb" "/var/www/matomo/misc/GeoLite2-City.mmdb"
fi
if [ -e "/data/geoip/GeoLite2-Country.mmdb" ]; then
  echo "Symlink GeoLite2-Country.mmdb to Matomo"
  ln -sf "/data/geoip/GeoLite2-Country.mmdb" "/var/www/matomo/misc/GeoLite2-Country.mmdb"
fi

# Check config
echo "Checking Matomo config..."
if [ ! -f "/data/config/config.ini.php" ] && [ -f "/var/www/matomo/config/config.ini.php" ]; then
  runas_user cp "/var/www/matomo/config/config.ini.php" "/data/config/config.ini.php"
fi
ln -sf "/data/config/config.ini.php" "/var/www/matomo/config/config.ini.php"

# Check data-plugins folder
echo "Checking Matomo plugins folder..."
if [ ! -d /data/plugins ]; then
  runas_user mkdir -p /data/plugins
fi
if [ ! -L /var/www/matomo/data-plugins ] && [ -d /var/www/matomo/data-plugins ]; then
  rm -rf /var/www/matomo/data-plugins
fi
ln -sf /data/plugins /var/www/matomo/data-plugins
printf "/var/www/matomo/data-plugins/;data-plugins" > /var/run/s6/container_environment/MATOMO_PLUGIN_DIRS
printf "/var/www/matomo/data-plugins/" > /var/run/s6/container_environment/MATOMO_PLUGIN_COPY_DIR

# Check user folder
echo "Checking Matomo user-misc folder..."
if [ ! -d /data/misc/user ]; then
  if [ ! -L /var/www/matomo/misc/user ] && [ -d /var/www/matomo/misc/user ]; then
    runas_user cp -Rf /var/www/matomo/misc/user /data/misc/
    rm -rf /var/www/matomo/misc/user
  fi
elif [ ! -L /var/www/matomo/misc/user ] && [ -d /var/www/matomo/misc/user ]; then
  rm -rf /var/www/matomo/misc/user
fi
runas_user mkdir -p /data/misc/user
ln -sf /data/misc/user /var/www/matomo/misc/user

# Check tmp folder
echo "Checking Matomo tmp folder..."
if [ ! -d /data/tmp ]; then
  runas_user mkdir -p /data/tmp
fi
if [ ! -L /var/www/matomo/tmp ] && [ -d /var/www/matomo/tmp ]; then
  rm -rf /var/www/matomo/tmp
fi
ln -sf /data/tmp /var/www/matomo/tmp
