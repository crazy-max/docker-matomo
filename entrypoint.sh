#!/bin/sh

function runas_nginx() {
  su - nginx -s /bin/sh -c "$1"
}

MEMORY_LIMIT=${MEMORY_LIMIT:-256M}
UPLOAD_MAX_SIZE=${UPLOAD_MAX_SIZE:-16M}
OPCACHE_MEM_SIZE=${OPCACHE_MEM_SIZE:-128}
REAL_IP_FROM=${REAL_IP_FROM:-0.0.0.0/32}
REAL_IP_HEADER=${REAL_IP_HEADER:-X-Forwarded-For}
LOG_IP_VAR=${LOG_IP_VAR:-remote_addr}

LOG_LEVEL=${LOG_LEVEL:-WARN}
SIDECAR_CRON=${SIDECAR_CRON:-0}

SSMTP_PORT=${SSMTP_PORT:-25}
SSMTP_HOSTNAME=${SSMTP_HOSTNAME:-$(hostname -f)}
SSMTP_TLS=${SSMTP_TLS:-NO}

# PHP
echo "Setting PHP-FPM configuration..."
sed -e "s/@MEMORY_LIMIT@/$MEMORY_LIMIT/g" \
  -e "s/@UPLOAD_MAX_SIZE@/$UPLOAD_MAX_SIZE/g" \
  /tpls/etc/php7/php-fpm.d/www.conf > /etc/php7/php-fpm.d/www.conf

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
  /tpls/etc/nginx/nginx.conf > /etc/nginx/nginx.conf

# SSMTP
echo "Setting SSMTP configuration..."
if [ -z "$SSMTP_HOST" ] ; then
  echo "WARNING: SSMTP_HOST must be defined if you want to send emails"
else
  cat > /etc/ssmtp/ssmtp.conf <<EOL
mailhub=${SSMTP_HOST}:${SSMTP_PORT}
hostname=${SSMTP_HOSTNAME}
FromLineOverride=YES
UseTLS=${SSMTP_TLS}
UseSTARTTLS=${SSMTP_TLS}
EOL
  # Authentication to SMTP server is optional.
  if [ -n "$SSMTP_USER" ] ; then
    cat >> /etc/ssmtp/ssmtp.conf <<EOL
AuthUser=${SSMTP_USER}
AuthPass=${SSMTP_PASSWORD}
EOL
  fi
fi
unset SSMTP_HOST
unset SSMTP_USER
unset SSMTP_PASSWORD

# Init Matomo
echo "Initializing Matomo files / folders..."
mkdir -p /data/config /data/geoip /data/misc /data/plugins /data/session /data/tmp /etc/supervisord /var/log/supervisord

# Copy global config
cp -Rf /var/www/config /data/

# Check plugins
echo "Checking Matomo plugins..."
plugins=$(ls -l /data/plugins | egrep '^d' | awk '{print $9}')
for plugin in ${plugins}; do
  if [ -d /var/www/plugins/${plugin} ]; then
    rm -rf /var/www/plugins/${plugin}
  fi
  echo "  - Adding ${plugin}"
  ln -sf /data/plugins/${plugin} /var/www/plugins/${plugin}
done

# Check user folder
echo "Checking Matomo user-misc folder..."
if [ ! -d /data/misc/user ]; then
  if [[ ! -L /var/www/misc/user && -d /var/www/misc/user ]]; then
    mv -f /var/www/misc/user /data/misc/
  fi
elif [[ ! -L /var/www/misc/user && -d /var/www/misc/user ]]; then
  rm -rf /var/www/misc/user
fi
mkdir -p /data/misc/user
ln -sf /data/misc/user /var/www/misc/user

# Fix perms
echo "Fixing permissions..."
chown -R nginx. /data

# Sidecar cron container ?
if [ "$SIDECAR_CRON" = "1" ]; then
  echo ">>"
  echo ">> Sidecar cron container detected for Matomo"
  echo ">>"

  # Init
  rm /etc/supervisord/nginx.conf /etc/supervisord/php.conf
  rm -rf ${CRONTAB_PATH}
  mkdir -m 0644 -p ${CRONTAB_PATH}
  touch ${CRONTAB_PATH}/nginx

  # Archive
  if [ ! -z "$CRON_ARCHIVE" ]; then
    echo "Creating Matomo archive cron task with the following period fields: $CRON_ARCHIVE"
    echo "${CRON_ARCHIVE} /usr/local/bin/matomo_archive" >> ${CRONTAB_PATH}/nginx
  else
    echo "CRON_ARCHIVE env var empty..."
  fi

  # Fix perms
  echo "Fixing permissions..."
  chmod -R 0644 ${CRONTAB_PATH}
else
  rm /etc/supervisord/cron.conf

  # GeoIP2 databases
  if [ ! "$(ls -A /data/geoip)" ]; then
    cp -f /var/mmdb/*.mmdb /data/geoip/
  fi
  chown -R nginx. /data/geoip

  # Empty GeoIP2 Nginx config if no databases found
  if [ ! -f "/data/geoip/GeoLite2-ASN.mmdb" ]; then
    cat /dev/null > /etc/nginx/geoip2-asn.conf
  fi
  if [ ! -f "/data/geoip/GeoLite2-City.mmdb" ]; then
    cat /dev/null > /etc/nginx/geoip2-city.conf
  fi
  if [ ! -f "/data/geoip/GeoLite2-Country.mmdb" ]; then
    cat /dev/null > /etc/nginx/geoip2-country.conf
  fi

  # Check if already installed
  if [ -f /data/config/config.ini.php ]; then
    echo "Setting Matomo log level to $LOG_LEVEL..."
    runas_nginx "php /var/www/console config:set --section='log' --key='log_level' --value='$LOG_LEVEL'"

    echo "Upgrading and setting Matomo configuration..."
    runas_nginx "php /var/www/console core:update --yes --no-interaction"
    runas_nginx "php /var/www/console config:set --section='General' --key='minimum_memory_limit' --value='-1'"
  else
    echo ">>"
    echo ">> Open your browser to install Matomo through the wizard"
    echo ">>"
  fi
fi

exec "$@"
