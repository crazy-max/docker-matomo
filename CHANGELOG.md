# Changelog

## 3.9.1-RC2 (2019/04/14)

* Add `LOG_IP_VAR` environment variable

## 3.9.1-RC1 (2019/03/21)

* Matomo 3.9.1

## 3.9.0-RC1 (2019/03/19)

* Matomo 3.9.0
* Enable gzip for type application/javascript (PR #17)

## 3.8.1-RC3 (2019/03/06)

* Fix GeoIP2 autonomous system key (PR #16)

## 3.8.1-RC2 (2019/02/10)

* Add unifont for languages using [unicode characters](https://matomo.org/faq/how-to-install/faq_142/)

## 3.8.1-RC1 (2019/01/28)

* Matomo 3.8.1

## 3.8.0-RC1 (2019/01/21)

* Matomo 3.8.0
* Bind to unprivileged port : `8000`
* Remove legacy GeoIP

## 3.7.0-RC4 (2018/11/24)

* `/js/` tracking codes not working (Issue #11)

## 3.7.0-RC3 (2018/11/24)

* Add `REAL_IP_FROM` and `REAL_IP_HEADER` environment variables (Issue #8)
* Typo for some fastcgi_param

## 3.7.0-RC2 (2018/11/23)

* Add compatibility with [GeoIP 2 plugin](https://plugins.matomo.org/GeoIP2) (Issue #7)
* Add GeoIP 2 databases Country, City and ASN
* Add [ngx_http_geoip2_module](https://github.com/leev/ngx_http_geoip2_module) nginx module
* Move GeoIP databases to `/etc/nginx/geoip`

> :warning: **UPGRADE NOTES**
> GeoIP databases moved to `/etc/nginx/geoip`. You can safely remove `./data/geoip` folder.

## 3.7.0-RC1 (2018/11/19)

* Matomo 3.7.0
* Coding style

## 3.6.1-RC1 (2018/10/18)

* Matomo 3.6.1

## 3.6.0-RC2 (2018/09/16)

* Refactor sidecar cron to handle plugins

> :warning: **UPGRADE NOTES**
> Sidecar cron container is now handled with `SIDECAR_CRON` environment variable.
> See docker-compose example and README for more info.

## 3.6.0-RC1 (2018/08/29)

* Matomo 3.6.0
* Alpine 3.8
* PHP 7.2

## 3.5.1-RC2 (2018/06/03)

* Better handling of plugins on HA environments

## 3.5.1-RC1 (2018/05/25)

* Matomo 3.5.1

## 3.5.0-RC4 (2018/05/18)

* Replace `ARCHIVE_CONCURRENT_REQUESTS` with a generic var `ARCHIVE_OPTIONS`

## 3.5.0-RC3 (2018/05/13)

* Add option to set number of requests to process in parallel during cron archive
* Force overwriting GeoIP databases during update
* Move GeoIP databases to `/data/geoip`

## 3.5.0-RC2 (2018/05/10)

* No interaction and assume yes during core update

## 3.5.0-RC1 (2018/05/09)

* Matomo 3.5.0

## 3.4.0-RC2 (2018/04/26)

* Use IPv6 GeoIP databases (Issue #4)

## 3.4.0-RC1 (2018/03/29)

* Matomo 3.4.0

## 3.3.0-RC8 (2018/03/09)

* Remove ability to set a custom UID / GID (performance issue with overlay driver)
* Improve Nginx configuration

## 3.3.0-RC7 (2018/02/28)

* Permissions fix more efficient
* Cron now only available as a "sidecar" container (see docker-compose)
* Ability to set a custom UID / GID
* Use busybox cron
* Replace Nginx + Let's Encrypt with Traefik (see docker-compose)
* Disable auto restart and retries of "supervisored" programs (Docker Way)
* Remove SITE_URL env var

## 3.3.0-RC6 (2018/02/26)

* Add php7-ldap extension
* Check config file (Issue #2)
* Fix permission issues

## 3.3.0-RC5 (2018/02/05)

* Redirect Nginx and PHP-FPM to stdout
* Remove env file
* SSMTP authentication optional
* Store PHP session in data folder
* Disable browser archiving only if cron task enabled
* Matomo log level not dynamically retrieved
* Fix Matomo log level not set

## 3.3.0-RC4 (2018/02/04)

* Crons are disabled by default
* Fix permissions on plugins watcher
* Remove build dependencies
* Verify integrity of Matomo tarballs
* Publish image to Quay

## 3.3.0-RC3 (2018/01/23)

* Fix an issue while creating user symlink
* Need to create some folders at entrypoint

## 3.3.0-RC2 (2018/01/23)

* Add `bootstrap.php` to move user data in a persistent folder
* Use `inotifywatch` to check if a plugin installed/removed
* Preserve plugins and user folder across upgrades

## 3.3.0-RC1 (2018/01/21)

* Initial version
