#!/bin/sh

if [ -f /var/www/config/config.ini.php ]; then
  su - nginx -s /bin/sh -c "php /var/www/console core:archive --url=${SITE_URL}"
fi
