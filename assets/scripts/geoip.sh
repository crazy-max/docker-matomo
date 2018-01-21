#!/bin/sh

echo "Updating GeoLiteCity..."
wget -q https://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz -P /etc/nginx/geoip/
gzip -d /etc/nginx/geoip/GeoLiteCity.dat.gz
mv /etc/nginx/geoip/GeoLiteCity.dat /etc/nginx/geoip/GeoIPCity.dat
echo $(date -r /etc/nginx/geoip/GeoIPCity.dat)

echo "Updating GeoLiteCountry..."
wget -q http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz -P /etc/nginx/geoip/
gzip -d /etc/nginx/geoip/GeoIP.dat.gz
mv /etc/nginx/geoip/GeoIP.dat /etc/nginx/geoip/GeoIPCountry.dat
echo $(date -r /etc/nginx/geoip/GeoIPCountry.dat)
