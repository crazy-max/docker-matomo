#!/bin/sh

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
if [ -f /var/www/config/config.ini.php ]; then
  php /var/www/console config:set --section="General" --key="minimum_memory_limit" --value="-1" # Use PHP memory_limit
  php /var/www/console config:set --section="General" --key="enable_browser_archiving_triggering" --value="0" # Disable browsers to trigger the Matomo archiving process
fi

# Crons
rm -rf ${CRONTAB_PATH}
mkdir -m 0644 -p ${CRONTAB_PATH}
printf "${CRON_GEOIP} geoip > /proc/1/fd/1 2>/proc/1/fd/2" > ${CRONTAB_PATH}/geoip
printf "${CRON_ARCHIVE} matomo_archive > /proc/1/fd/1 2>/proc/1/fd/2" > ${CRONTAB_PATH}/matomo

# Init and perms
mkdir -p /var/log/supervisord
mkdir -p /var/www/tmp/cache/tracker
chmod -R 0644 ${CRONTAB_PATH}
chown -R nginx. /var/lib/nginx
chown -R nginx. /var/www

exec "$@"
