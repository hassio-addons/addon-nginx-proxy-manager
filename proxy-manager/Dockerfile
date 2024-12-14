ARG BUILD_FROM=ghcr.io/hassio-addons/base-nodejs:0.2.5
# hadolint ignore=DL3006
FROM ${BUILD_FROM}

# Required for webpack config of NPM
ENV NODE_OPTIONS="--openssl-legacy-provider"

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Copy Python requirements file & patches
COPY requirements.txt /tmp/
COPY patches/*.patch /usr/src/

# Setup base
ARG NGINX_PROXY_MANAGER_VERSION="v2.10.4"
# hadolint ignore=DL3003,DL3042
RUN \
    apk add --no-cache \
        libcrypto3=3.1.7-r1 \
        libssl3=3.1.7-r1 && \
    apk add --no-cache --virtual .build-dependencies \
        build-base=0.5-r3 \
        git=2.43.5-r0 \
        libffi-dev=3.4.4-r3 \
        openssl-dev=3.1.7-r1 \
        patch=2.7.6-r10 \
        python3-dev=3.11.11-r0 \
    \
    && apk add --no-cache \
        apache2-utils=2.4.62-r0 \
        certbot=2.7.4-r0 \
        libcap=2.69-r1 \
        logrotate=3.21.0-r1 \
        nginx-mod-stream=1.24.0-r16 \
        nginx=1.24.0-r16 \
        openssl=3.1.7-r1 \
        py3-pip=23.3.1-r0 \
        python3=3.11.11-r0 \
    \
    && pip3 install -r /tmp/requirements.txt \
    \
    && yarn global add modclean \
    \
    && curl -J -L -o /tmp/nginxproxymanager.tar.gz \
        "https://github.com/NginxProxyManager/nginx-proxy-manager/archive/${NGINX_PROXY_MANAGER_VERSION}.tar.gz" \
    && mkdir /app \
    && tar zxvf \
        /tmp/nginxproxymanager.tar.gz \
        --strip 1 -C /app \
    \
    && for i in /usr/src/*.patch; do \
        patch -d /app -p 1 < "${i}"; done \
    \
    && cd /app/frontend \
    && yarn install \
    && yarn build \
    && rm -rf node_modules \
    \
    && mkdir -p /opt/nginx-proxy-manager/frontend \
    && cp -r /app/frontend/dist/. /opt/nginx-proxy-manager/frontend/ \
    \
    && cd /app/backend \
    && yarn install \
    && rm -rf node_modules \
    && cp -r /app/backend/. /opt/nginx-proxy-manager/ \
    \
    && cp -R /app/global/. /opt/nginx-proxy-manager/global/ \
    \
    && cd /opt/nginx-proxy-manager \
    && yarn install \
    && rm -rf /etc/services.d/frontend \
    && rm -rf /opt/nginx-proxy-manager/config \
    \
    && rm -f -r /etc/nginx \
    && cp -r /app/docker/rootfs/etc/nginx /etc/nginx \
    && rm -f /etc/nginx/conf.d/dev.conf \
    \
    && cp /app/docker/rootfs/etc/letsencrypt.ini /etc \
    && cp /app/docker/rootfs/etc/logrotate.d/nginx-proxy-manager /etc/logrotate.d \
    \
    && sed -i "s#user npm;#user root;#" /etc/nginx/nginx.conf \
    && sed -i "s#root /app/frontend;#root /opt/nginx-proxy-manager/frontend;#" \
        /etc/nginx/conf.d/production.conf \
    && sed -i "s#table.string('id').notNull().primary();#table.string('id', 32).notNull().primary();#" \
        /opt/nginx-proxy-manager/migrations/20190227065017_settings.js \
    \
    && mkdir -p \
        /run/nginx \
    \
    && modclean \
        --path /opt/nginx-proxy-manager \
        --no-progress \
        --keep-empty \
        --run \
    \
    && yarn global remove modclean \
    && yarn cache clean \
    \
    && apk del --purge .build-dependencies \
    \
    && rm -f -r \
        /app \
        /etc/init.d/nginx \
        /etc/logrotate.d/nginx \
        /opt/nginx-proxy-manager/node_modules/bcrypt/build \
        /root/.cache \
        /root/.node-gyp \
        /tmp/.[!.]* \
        /tmp/* \
        /usr/lib/node_modules \
        /usr/local/share/.cache \
        /var/lib/nginx \
        /var/log/nginx \
        /var/tmp/nginx \
        /var/www

# Copy root filesystem
COPY rootfs /

# Build arguments
ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_DESCRIPTION
ARG BUILD_NAME
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION

# Labels
LABEL \
    io.hass.name="${BUILD_NAME}" \
    io.hass.description="${BUILD_DESCRIPTION}" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="Franck Nijhof <frenck@addons.community>" \
    org.opencontainers.image.title="${BUILD_NAME}" \
    org.opencontainers.image.description="${BUILD_DESCRIPTION}" \
    org.opencontainers.image.vendor="Home Assistant Community Add-ons" \
    org.opencontainers.image.authors="Franck Nijhof <frenck@addons.community>" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.url="https://addons.community" \
    org.opencontainers.image.source="https://github.com/${BUILD_REPOSITORY}" \
    org.opencontainers.image.documentation="https://github.com/${BUILD_REPOSITORY}/blob/main/README.md" \
    org.opencontainers.image.created=${BUILD_DATE} \
    org.opencontainers.image.revision=${BUILD_REF} \
    org.opencontainers.image.version=${BUILD_VERSION}
