#!/command/with-contenv bashio
# ==============================================================================
# Home Assistant Community Add-on: NGINX Proxy Manager
# Configures NGINX for use with the NGINX Proxy Manager
# ==============================================================================
declare dns_host

dns_host=$(bashio::dns.host)
sed -i "s/%%dns_host%%/${dns_host}/g" \
    /etc/nginx/conf.d/include/resolvers.conf
