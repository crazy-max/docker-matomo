#!/bin/sh

function runas_user() {
  su - ${USERNAME} -s /bin/sh -c "$1"
}

TZ=${TZ:-"UTC"}
LOG_LEVEL=${LOG_LEVEL:-"WARN"}
MEMORY_LIMIT=${MEMORY_LIMIT:-"256M"}
UPLOAD_MAX_SIZE=${UPLOAD_MAX_SIZE:-"16M"}
OPCACHE_MEM_SIZE=${OPCACHE_MEM_SIZE:-"128"}

SSMTP_PORT=${SSMTP_PORT:-"25"}
SSMTP_HOSTNAME=${SSMTP_HOSTNAME:-"$(hostname -f)"}
SSMTP_TLS=${SSMTP_TLS:-"NO"}

# Timezone
echo "Setting timezone to ${TZ}..."
ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime
echo ${TZ} > /etc/timezone

# Create docker user
echo "Creating ${USERNAME} user and group (uid=${UID} ; gid=${GID})..."
addgroup -g ${GID} ${USERNAME}
adduser -D -s /bin/sh -G ${USERNAME} -u ${UID} ${USERNAME}

# Init
echo "Initializing files and folders..."
mkdir -p /data/config /data/misc /data/plugins /data/session /var/log/supervisord
chown -R ${USERNAME}. /data /var/lib/nginx /var/tmp/nginx /var/www

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
sed -e "s/@UPLOAD_MAX_SIZE@/$UPLOAD_MAX_SIZE/g" \
  /tpls/etc/nginx/nginx.conf > /etc/nginx/nginx.conf

# SSMTP
echo "Setting SSMTP configuration..."
if [ -z "$SSMTP_HOST" ] ; then
  echo "WARNING: SSMTP_HOST must be defined if you want to send emails"
  cp -f /etc/ssmtp/ssmtp.conf.or /etc/ssmtp/ssmtp.conf
else
  cat > /etc/ssmtp/ssmtp.conf <<EOL
mailhub=${SSMTP_HOST}:${SSMTP_PORT}
hostname=${SSMTP_HOSTNAME}
FromLineOverride=YES
AuthUser=${SSMTP_USER}
AuthPass=${SSMTP_PASSWORD}
UseTLS=${SSMTP_TLS}
UseSTARTTLS=${SSMTP_TLS}
EOL
fi

# Init Matomo
echo "Initializing Matomo files / folders..."
cp -Rf /var/www/config /data/
chown -R ${USERNAME}. /data /var/www

# Upgrade Matomo
if [ -f /data/config/config.ini.php ]; then
  echo "Upgrading and setting Matomo configuration..."
  runas_user "php /var/www/console core:update"
  runas_user "php /var/www/console config:set --section='General' --key='minimum_memory_limit' --value='-1'"
fi

# Matomo log level
if [ -f /data/config/config.ini.php ]; then
  echo "Setting Matomo log level to $LOG_LEVEL..."
  runas_user "php /var/www/console config:set --section='log' --key='log_level' --value='$LOG_LEVEL'"
fi

# Check plugins
echo "Checking Matomo plugins..."
plugins=$(ls -l /data/plugins | egrep '^d' | awk '{print $9}')
for plugin in ${plugins}; do
  if [ -d /var/www/plugins/${plugin} ]; then
    rm -rf /var/www/plugins/${plugin}
  fi
  ln -sf /data/plugins/${plugin} /var/www/plugins/${plugin}
  chown -h ${USERNAME}. /var/www/plugins/${plugin}
done

# Check user folder
echo "Checking Matomo user-misc folder..."
if [ ! -d /data/misc/user ]; then
  if [[ ! -L /var/www/misc/user && -d /var/www/misc/user ]]; then
    mv -f /var/www/misc/user /data/misc/
  fi
  ln -sf /data/misc/user /var/www/misc/user
  chown -h ${USERNAME}. /var/www/misc/user
fi

# Crons
rm -rf ${CRONTAB_PATH}
mkdir -m 0644 -p ${CRONTAB_PATH}
if [ ! -z "$CRON_GEOIP" ]; then
  echo "Creating GeoIP cron task with the following period fields : $CRON_GEOIP"
  printf "${CRON_GEOIP} geoip > /proc/1/fd/1 2>/proc/1/fd/2" > ${CRONTAB_PATH}/geoip
fi
if [ ! -z "$CRON_ARCHIVE" ]; then
  echo "Creating Matomo archive cron task with the following period fields : $CRON_ARCHIVE"
  printf "${CRON_ARCHIVE} matomo_archive > /proc/1/fd/1 2>/proc/1/fd/2" > ${CRONTAB_PATH}/matomo
fi
if [ -z "$CRON_GEOIP" -a -z "$CRON_ARCHIVE" ]; then
  rm -f /etc/supervisord/cron.conf
fi

# Fix perms
echo "Fixing permissions..."
chmod -R 0644 ${CRONTAB_PATH}
chown -R ${USERNAME}. /data /var/lib/nginx /var/tmp/nginx /var/www

exec "$@"
