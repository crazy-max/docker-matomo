#!/bin/sh

function runas_nginx() {
  su - nginx -s /bin/sh -c "$1"
}

TZ=${TZ:-UTC}

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

SESSION_SAVE_HANDLER=${SESSION_SAVE_HANDLER:-files}
SESSION_SAVE_PATH=${SESSION_SAVE_PATH:-/data/tmp}

REDIS_HOST=${REDIS_HOST:-matomo_redis}
REDIS_PORT=${REDIS_PORT:-6379}

# Timezone
echo "Setting timezone to ${TZ}..."
ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime
echo ${TZ} > /etc/timezone

# PHP
echo "Setting PHP-FPM configuration..."
sed -e "s/@MEMORY_LIMIT@/$MEMORY_LIMIT/g" \
  -e "s/@UPLOAD_MAX_SIZE@/$UPLOAD_MAX_SIZE/g" \
  /tpls/etc/php7/php-fpm.d/www.conf > /etc/php7/php-fpm.d/www.conf

# OpCache
echo "Setting OpCache configuration..."
sed -e "s/@OPCACHE_MEM_SIZE@/$OPCACHE_MEM_SIZE/g" \
  /tpls/etc/php7/conf.d/opcache.ini > /etc/php7/conf.d/90-opcache.ini

# Redis
# session.save_handler = redis 
# session.save_path    = tcp://127.0.0.1:6379?database=10
if [ "$SESSION_SAVE_HANDLER" != 'files' ] ; then
  echo "Setting Redis configuration for session handler..."
  sed -e "s/@SESSION_SAVE_HANDLER@/$SESSION_SAVE_HANDLER/g" \
    -e "s/@SESSION_SAVE_PATH@/$SESSION_SAVE_PATH/g" \
    /tpls/etc/php7/conf.d/session.ini > /etc/php7/conf.d/99-session.ini
fi

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
AuthUser=${SSMTP_USER}
AuthPass=${SSMTP_PASSWORD}
UseTLS=${SSMTP_TLS}
UseSTARTTLS=${SSMTP_TLS}
EOL
fi
unset SSMTP_HOST
unset SSMTP_USER
unset SSMTP_PASSWORD

# Init Matomo
echo "Initializing Matomo files / folders..."
mkdir -p /data/config /data/misc /data/plugins /data/session /data/tmp /etc/supervisord /var/log/supervisord

# Copy global config
cp -Rf /var/www/config /data/

# Check plugins
echo "Checking Matomo plugins..."
if [[ ! -L /var/www/plugins && -d /var/www/plugins ]]; then
  cp -R /var/www/plugins/* /data/plugins
fi
rm -rf /var/www/plugins
ln -sf /data/plugins /var/www/plugins

# Check user folder
echo "Checking Matomo user-misc folder..."
if [ ! -d /data/misc/user ]; then
  if [[ ! -L /var/www/misc/user && -d /var/www/misc/user ]]; then
    mv -f /var/www/misc/user /data/misc/
  fi
  ln -sf /data/misc/user /var/www/misc/user
fi

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

  # GeoIP
  if [ ! -z "$CRON_GEOIP" ]; then
    echo "Creating GeoIP cron task with the following period fields : $CRON_GEOIP"
    echo "${CRON_GEOIP} /usr/local/bin/update_geoip" >> ${CRONTAB_PATH}/nginx
  else
    echo "CRON_GEOIP env var empty..."
  fi

  # Archive
  if [ ! -z "$CRON_ARCHIVE" ]; then
    echo "Creating Matomo archive cron task with the following period fields : $CRON_ARCHIVE"
    echo "${CRON_ARCHIVE} /usr/local/bin/matomo_archive" >> ${CRONTAB_PATH}/nginx
  else
    echo "CRON_ARCHIVE env var empty..."
  fi

  # Fix perms
  echo "Fixing permissions..."
  chmod -R 0644 ${CRONTAB_PATH}
else
  rm /etc/supervisord/cron.conf

  # Check if already installed
  if [ -f /data/config/config.ini.php ]; then
    echo "Setting Matomo log level to $LOG_LEVEL..."
    runas_nginx "php /var/www/console config:set --section='log' --key='log_level' --value='$LOG_LEVEL'"

    echo "Upgrading and setting Matomo configuration..."
    runas_nginx "php /var/www/console core:update --yes --no-interaction"
    runas_nginx "php /var/www/console config:set --section='General' --key='minimum_memory_limit' --value='-1'"
    # echo "Changing Matomo cache to redis@$REDIS_HOST:$REDIS_PORT"
    runas_nginx "php /var/www/console config:set --section='RedisCache' --key='timeout' --value='0'"
    runas_nginx "php /var/www/console config:set --section='RedisCache' --key='password' --value=''"
    runas_nginx "php /var/www/console config:set --section='RedisCache' --key='database' --value='42'"
    runas_nginx "php /var/www/console config:set --section='RedisCache' --key='host' --value='$REDIS_HOST'"
    runas_nginx "php /var/www/console config:set --section='RedisCache' --key='port' --value='$REDIS_PORT'"
    runas_nginx "php /var/www/console config:set --section='ChainedCache' --key='backends[]' --value='array'"
    runas_nginx "php /var/www/console config:set --section='ChainedCache' --key='backends[]' --value='redis'"
    runas_nginx "php /var/www/console config:set --section='Cache' --key='backend' --value='chained'"
  else
    echo ">>"
    echo ">> Open your browser to install Matomo through the wizard"
    echo ">>"
  fi
fi

exec "$@"
