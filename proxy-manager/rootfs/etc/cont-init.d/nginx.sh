#!/usr/bin/with-contenv bashio
# ==============================================================================
# Home Assistant Community Add-on: NGINX Proxy Manager
# Configures NGINX for use with the NGINX Proxy Manager
# ==============================================================================
declare hassio_dns

hassio_dns=$(bashio::dns.host)
sed -i "s/%%hassio_dns%%/${hassio_dns}/g" \
    /etc/nginx/conf.d/include/resolvers.conf
