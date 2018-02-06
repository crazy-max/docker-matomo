<p align="center"><a href="https://github.com/crazy-max/docker-matomo" target="_blank"><img height="128"src="https://raw.githubusercontent.com/crazy-max/docker-matomo/master/.res/docker-matomo.jpg"></a></p>

<p align="center">
  <a href="https://microbadger.com/images/crazymax/matomo"><img src="https://images.microbadger.com/badges/version/crazymax/matomo.svg?style=flat-square" alt="Version"></a>
  <a href="https://travis-ci.org/crazy-max/docker-matomo"><img src="https://img.shields.io/travis/crazy-max/docker-matomo/master.svg?style=flat-square" alt="Build Status"></a>
  <a href="https://hub.docker.com/r/crazymax/matomo/"><img src="https://img.shields.io/docker/stars/crazymax/matomo.svg?style=flat-square" alt="Docker Stars"></a>
  <a href="https://hub.docker.com/r/crazymax/matomo/"><img src="https://img.shields.io/docker/pulls/crazymax/matomo.svg?style=flat-square" alt="Docker Pulls"></a>
  <a href="https://quay.io/repository/crazymax/matomo"><img src="https://quay.io/repository/crazymax/matomo/status?style=flat-square" alt="Docker Repository on Quay"></a>
  <a href="https://beerpay.io/crazy-max/docker-matomo"><img src="https://img.shields.io/beerpay/crazy-max/docker-matomo.svg?style=flat-square" alt="Beerpay"></a>
  <a href="https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=JP85E7WHT33FL"><img src="https://img.shields.io/badge/donate-paypal-7057ff.svg?style=flat-square" alt="Donate Paypal"></a>
</p>

## About

🐳 [Matomo](https://matomo.org/) (formerly Piwik) Docker image based on Alpine Linux and Nginx.<br />
If you are interested, [check out](https://hub.docker.com/r/crazymax/) my other 🐳 Docker images!

## Features

### Included

* Alpine Linux 3.7, Nginx, PHP 7.1
* Tarball authenticity checked during building process
* Config, plugins and user preferences in the same folder
* GeoLite data created by [MaxMind](http://www.maxmind.com) for geolocation
* Cron tasks to archive Matomo reports and update GeoLite data
* Plugins and config are kept across upgrades of this image
* [SSMTP](https://linux.die.net/man/8/ssmtp) for SMTP relay to send emails
* OPCache enabled to store precompiled script bytecode in shared memory
* Redis enabled and ready to enhance server performance

### From docker-compose

* Reverse proxy with [nginx-proxy](https://github.com/jwilder/nginx-proxy)
* Creation/renewal of Let's Encrypt certificates automatically with [letsencrypt-nginx-proxy-companion](https://github.com/JrCs/docker-letsencrypt-nginx-proxy-companion)
* [Redis](https://github.com/docker-library/redis) image ready to use as [Redis cache](https://matomo.org/faq/how-to/faq_20511/) or [QueuedTracking plugin](https://matomo.org/faq/how-to/faq_19738) for better scalability
* [MariaDB](https://github.com/docker-library/mariadb) image as database instance

## Docker

### Environment variables

* `TZ` : The timezone assigned to the container (default to `UTC`)
* `SITE_URL` : Your Matomo site URL
* `CRON_GEOIP` : Periodically update GeoIP data (disabled if empty)
* `CRON_ARCHIVE` : Periodically execute Matomo [archive](https://matomo.org/docs/setup-auto-archiving/#linuxunix-how-to-set-up-a-crontab-to-automatically-archive-the-reports) (disabled if empty)
* `LOG_LEVEL` : [Log level](https://matomo.org/faq/troubleshooting/faq_115/) of Matomo UI (default to `WARN`)
* `MEMORY_LIMIT` : PHP memory limit (default to `256M`)
* `UPLOAD_MAX_SIZE` : Upload max size (default to `16M`)
* `OPCACHE_MEM_SIZE` : PHP OpCache memory consumption (default to `128`)
* `SSMTP_HOST` : SMTP server host
* `SSMTP_PORT` : SMTP server port (default to `25`)
* `SSMTP_HOSTNAME` : Full hostname (default to `$(hostname -f)`)
* `SSMTP_USER` : SMTP username
* `SSMTP_PASSWORD` : SMTP password
* `SSMTP_TLS` : SSL/TLS (default to `NO`)

### Volumes

* `/data` : Contains config folder, installed plugins (not core ones), tmp folder and user folder to store your [custom logo](https://matomo.org/faq/new-to-piwik/faq_129/)

### Ports

* `80` : HTTP port

## Usage

Docker compose is the recommended way to run this image. You can use the following [docker compose template](docker-compose.yml). Edit this file with your preferences, then run :

```bash
docker-compose up -d
docker-compose logs -f
```

Or use the following minimal command :

```bash
docker run -d -p 80:80 --name matomo \
  -e TZ="Europe/Paris" \
  -e SITE_URL="https://matomo.example.com" \
  -v $(pwd)/data:/data \
  crazymax/matomo:latest
```

## Configuration

### Disable Matomo archiving from browser

If you have enabled `CRON_ARCHIVE` to automatically archive the reports, you have to disable Matomo archiving to trigger from the browser. Go to **System > General settings** :

![Disable Matomo archiving from browser](.res/disable-archive-reports-browser.png)

### Change location provider

As GeoIP module for Nginx is installed and uses GeoIP data, you have to select **GeoIP (HTTP Server Module)** in **System > Geolocation** :

![Change location provider](.res/location-provider.png)

### Behind a reverse proxy ?

If you are running Matomo [behind a reverse proxy](https://matomo.org/faq/how-to-install/faq_98/), add this to your config.ini.php :

```
[General]
assume_secure_protocol = 1 # 0=http 1=https
proxy_client_headers[] = HTTP_X_FORWARDED_FOR
proxy_client_headers[] = HTTP_X_REAL_IP
proxy_host_headers[] = HTTP_X_FORWARDED_HOST
```

### Redis cache

To use [Redis as a cache](https://matomo.org/faq/how-to/faq_20511/) (useful if your Matomo environment consists of multiple servers), add this to your config.ini.php :

```
[Cache]
backend = chained

[ChainedCache]
backends[] = array
backends[] = redis

[RedisCache]
host = "redis" # Docker service name for Redis 
port = 6379
timeout = 0.0
password = ""
database = 14
```

In case you are using queued tracking: Make sure to configure a different database! Otherwise queued requests will be flushed.

## Upgrade

You can upgrade Matomo automatically through the UI, it works well. But i recommend to recreate the container whenever i push an update :

```bash
docker-compose pull
docker-compose up -d
```

## How can i help ?

All kinds of contributions are welcomed :raised_hands:!<br />
The most basic way to show your support is to star :star2: the project, or to raise issues :speech_balloon:<br />
But we're not gonna lie to each other, I'd rather you buy me a beer or two :beers:!

[![Beerpay](https://beerpay.io/crazy-max/docker-matomo/badge.svg?style=beer-square)](https://beerpay.io/crazy-max/docker-matomo)
or [![Paypal](.res/paypal.png)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=JP85E7WHT33FL)

## License

MIT. See `LICENSE` for more details.
