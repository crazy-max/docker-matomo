#!/bin/sh

inotifywait -e close_write,moved_to,create -m /data/config/ |
while read -r directory events filename; do
  if [ "$filename" = "config.ini.php" ]; then
    plugins=$(ls -l /var/www/plugins | egrep '^l' | awk '{print $9}')
    for plugin in ${plugins}; do
      echo "Check plugin $plugin"
      if ! grep -Fxq "PluginsInstalled[] = \"${plugin}\"" /data/config/config.ini.php; then
        echo "Remove orphan plugin $plugin"
        rm -f /var/www/plugins/${plugin}
        rm -rf /data/plugins/${plugin}
      fi
    done
  fi
done
