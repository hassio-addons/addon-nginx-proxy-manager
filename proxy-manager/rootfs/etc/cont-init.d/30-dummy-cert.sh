#!/usr/bin/with-contenv bash
# ==============================================================================
# Community Hass.io Add-ons: Nginx Proxy Manager
# This file generates a dummy SSL certificate
# ==============================================================================
# shellcheck disable=SC1091
source /usr/lib/hassio-addons/base.sh

if [[ ! -f /data/nginx/dummycert.pem ]] || [[ ! -f /data/nginx/dummykey.pem ]]
then
  hass.log.info "Generating dummy SSL certificate"
  openssl req \
    -new \
    -newkey rsa:2048 \
    -days 3650 \
    -nodes \
    -x509 \
    -subj '/O=Nginx Proxy Manager/OU=Dummy Certificate/CN=localhost' \
    -keyout /data/nginx/dummykey.pem \
    -out /data/nginx/dummycert.pem \
    || hass.die "Could not generate dummy certificate"
fi
