# Changelog

## 3.5.0-RC1 (2018/05/09)

* Upgrade to Matomo 3.5.0

## 3.4.0-RC2 (2018/04/26)

* Use IPv6 GeoIP databases (Issue #4)

## 3.4.0-RC1 (2018/03/29)

* Upgrade to Matomo 3.4.0

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
