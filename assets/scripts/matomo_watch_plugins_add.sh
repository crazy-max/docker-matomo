#!/bin/sh

inotifywait -e create -m /data/plugins/ |
while read -r directory events plugin; do
  if [ -d /var/www/plugins/${plugin} ]; then
    rm -rf /var/www/plugins/${plugin}
  fi
  ln -sf /data/plugins/${plugin} /var/www/plugins/${plugin}
done
