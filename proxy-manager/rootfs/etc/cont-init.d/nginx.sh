#!/usr/bin/with-contenv bashio
# ==============================================================================
# Community Hass.io Add-ons: AdGuard Home
# Configures NGINX for use with the AdGuard Home server
# ==============================================================================
declare hassio_dns

hassio_dns=$(bashio::dns.host)
sed -i "s/%%hassio_dns%%/${hassio_dns}/g" \
    /etc/nginx/conf.d/include/resolvers.conf
