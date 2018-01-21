#!/bin/sh

if [ -f /var/www/config/config.ini.php ]; then
  cd /var/www
  php console core:archive --url=${SITE_URL}
fi
