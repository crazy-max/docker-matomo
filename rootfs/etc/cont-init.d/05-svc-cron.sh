#!/usr/bin/with-contenv sh
# shellcheck shell=sh

CRONTAB_PATH="/var/spool/cron/crontabs"
SIDECAR_CRON=${SIDECAR_CRON:-0}

# Continue only if sidecar cron container
if [ "$SIDECAR_CRON" != "1" ]; then
  exit 0
fi

echo ">>"
echo ">> Sidecar cron container detected for Matomo"
echo ">>"

# Init
rm -rf ${CRONTAB_PATH}
mkdir -m 0644 -p ${CRONTAB_PATH}
touch ${CRONTAB_PATH}/matomo

# Cron
if [ -n "$CRON_ARCHIVE" ]; then
  echo "Creating Matomo archive cron task with the following period fields: $CRON_ARCHIVE"
  echo "${CRON_ARCHIVE} /usr/local/bin/matomo_archive" >> ${CRONTAB_PATH}/matomo
else
  echo "CRON_ARCHIVE env var empty..."
fi

# Fix perms
echo "Fixing crontabs permissions..."
chmod -R 0644 ${CRONTAB_PATH}

# Create service
mkdir -p /etc/services.d/cron
cat > /etc/services.d/cron/run <<EOL
#!/usr/bin/execlineb -P
with-contenv
exec busybox crond -f -L /dev/stdout
EOL
chmod +x /etc/services.d/cron/run
