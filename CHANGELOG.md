# Changelog

## 3.3.0-RC5 (2018/02/05)

* Redirect Nginx and PHP-FPM to stdout
* Ability to set a custom UID / GID
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
