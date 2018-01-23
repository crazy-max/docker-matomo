#!/bin/sh

function runas_nginx() {
  su - nginx -s /bin/sh -c "$1"
}

CRONTAB_PATH=${CRONTAB_PATH:-"/var/spool/cron/crontabs"}
SCRIPTS_PATH=${SCRIPTS_PATH:-"/usr/local/bin"}
CRON_GEOIP=${CRON_GEOIP:-"0 2 * * *"}
CRON_ARCHIVE=${CRON_ARCHIVE:-"*/15 * * * *"}
LOG_LEVEL=WARN
MEMORY_LIMIT=${MEMORY_LIMIT:-"256M"}
UPLOAD_MAX_SIZE=${UPLOAD_MAX_SIZE:-"16M"}
OPCACHE_MEM_SIZE=${OPCACHE_MEM_SIZE:-"128M"}

# Timezone
ln -snf /usr/share/zoneinfo/${TZ:-"UTC"} /etc/localtime
echo ${TZ:-"UTC"} > /etc/timezone

# PHP
echo "sendmail_path=/usr/sbin/ssmtp -t" > /etc/php7/conf.d/sendmail-ssmtp.ini
cp -f /tpls/etc/php7/php-fpm.d/www.conf /etc/php7/php-fpm.d/www.conf
sed -i -e "s/@MEMORY_LIMIT@/$MEMORY_LIMIT/g" /etc/php7/php-fpm.d/www.conf \
  -e "s/@UPLOAD_MAX_SIZE@/$UPLOAD_MAX_SIZE/g" /etc/php7/php-fpm.d/www.conf

# OpCache
cp -f /tpls/etc/php7/conf.d/opcache.ini /etc/php7/conf.d/opcache.ini
sed -i -e "s/@OPCACHE_MEM_SIZE@/$OPCACHE_MEM_SIZE/g" /etc/php7/conf.d/opcache.ini

# Nginx
cp -f /tpls/etc/nginx/nginx.conf /etc/nginx/nginx.conf
sed -i -e "s/@UPLOAD_MAX_SIZE@/$UPLOAD_MAX_SIZE/g" /etc/nginx/nginx.conf

# SSMTP
if [ -z "$SSMTP_HOST" -o -z "$SSMTP_USER" -o -z "$SSMTP_PASSWORD" ] ; then
  echo "SSMTP_HOST, SSMTP_AUTH_USER and SSMTP_AUTH_PASSWORD must be defined if you want to send emails"
  cp -f /etc/ssmtp/ssmtp.conf.or /etc/ssmtp/ssmtp.conf
else
  cp -f /tpls/etc/ssmtp/ssmtp.conf /etc/ssmtp/ssmtp.conf
  sed -i -e "s/@SSMTP_HOST@/$SSMTP_HOST/g" /etc/ssmtp/ssmtp.conf \
    -e "s/@SSMTP_PORT@/${SSMTP_PORT:-"25"}/g" /etc/ssmtp/ssmtp.conf \
    -e "s/@SSMTP_HOST@/$SSMTP_HOST/g" /etc/ssmtp/ssmtp.conf \
    -e "s/@SSMTP_HOSTNAME@/${SSMTP_HOSTNAME:-"$(hostname -f)"}/g" /etc/ssmtp/ssmtp.conf \
    -e "s/@SSMTP_USER@/$SSMTP_USER/g" /etc/ssmtp/ssmtp.conf \
    -e "s/@SSMTP_PASSWORD@/$SSMTP_PASSWORD/g" /etc/ssmtp/ssmtp.conf \
    -e "s/@SSMTP_TLS@/${SSMTP_TLS:-"NO"}/g" /etc/ssmtp/ssmtp.conf
fi

# Matomo
cp -f /tpls/bootstrap.php /var/www/bootstrap.php
cp -Rf /var/www/config /data
chown -R nginx. /data /var/www
if [ -f /data/config/config.ini.php ]; then
  runas_nginx "php /var/www/console core:update"
  runas_nginx "php /var/www/console config:set --section='General' --key='minimum_memory_limit' --value='-1'"
  runas_nginx "php /var/www/console config:set --section='General' --key='enable_browser_archiving_triggering' --value='0'"
fi

plugins=$(ls -l /data/plugins | egrep '^d' | awk '{print $9}')
for plugin in ${plugins}; do
  if [ -d /var/www/plugins/${plugin} ]; then
    rm -rf /var/www/plugins/${plugin}
  fi
  ln -sf /data/plugins/${plugin} /var/www/plugins/${plugin}
  chown -h nginx. /var/www/plugins/${plugin}
done

if [ ! -d /data/misc/user ]; then
  if [ -d /var/www/misc/user ]; then
    mv /var/www/misc/user /data/misc/user
  fi
  ln -sf /data/misc/user /var/www/misc/user
  chown -h nginx. /var/www/misc/user
fi

# Crons
rm -rf ${CRONTAB_PATH}
mkdir -m 0644 -p ${CRONTAB_PATH}
printf "${CRON_GEOIP} geoip > /proc/1/fd/1 2>/proc/1/fd/2" > ${CRONTAB_PATH}/geoip
printf "${CRON_ARCHIVE} matomo_archive > /proc/1/fd/1 2>/proc/1/fd/2" > ${CRONTAB_PATH}/matomo

# Init and perms
mkdir -p /var/log/supervisord
chmod -R 0644 ${CRONTAB_PATH}
chown -R nginx. /data /var/www

exec "$@"
