#!/usr/bin/with-contenv sh
# shellcheck shell=sh

SIDECAR_CRON=${SIDECAR_CRON:-0}

if [ "$SIDECAR_CRON" = "1" ]; then
  exit 0
fi

LOG_LEVEL=${LOG_LEVEL:-WARN}

# Check if already installed
if [ -f "/data/config/config.ini.php" ]; then
  echo "Setting Matomo log level to $LOG_LEVEL..."
  console config:set --section=log --key=log_level --value="$LOG_LEVEL"

  echo "Upgrading and setting Matomo configuration..."
  console core:update --yes --no-interaction
  console config:set --section=General --key=minimum_memory_limit --value=-1
else
  echo ">>"
  echo ">> Open your browser to install Matomo through the wizard"
  echo ">>"
fi

mkdir -p /etc/services.d/nginx
cat > /etc/services.d/nginx/run <<EOL
#!/usr/bin/execlineb -P
with-contenv
s6-setuidgid ${PUID}:${PGID}
nginx -g "daemon off;"
EOL
chmod +x /etc/services.d/nginx/run

mkdir -p /etc/services.d/php-fpm
cat > /etc/services.d/php-fpm/run <<EOL
#!/usr/bin/execlineb -P
with-contenv
s6-setuidgid ${PUID}:${PGID}
php-fpm82 -F
EOL
chmod +x /etc/services.d/php-fpm/run
