ARG BUILD_FROM=ghcr.io/hassio-addons/debian-base:9.4.0
# hadolint ignore=DL3006
FROM ${BUILD_FROM}

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Copy patches
COPY patches/*.patch /usr/src/

# Setup base
ARG CERTBOT_VERSION="5.8.0"
ARG NGINX_PROXY_MANAGER_VERSION="v2.15.1"
# hadolint ignore=DL3003,DL3042
RUN \
    apt-get update \
    \
    && apt-get install -y --no-install-recommends \
        apache2-utils=2.4.68-1~deb13u1 \
        libcap2-bin=1:2.75-10+deb13u1+b3 \
    # logrotate has been rebuilt on aarch64 but not amd64, so its version
    # carries a binNMU suffix on one architecture only. Match the Debian
    # revision and let the suffix vary.
        logrotate=3.22.0-1* \
        nodejs=20.19.2+dfsg-1+deb13u2 \
        openssl=3.5.6-1~deb13u2 \
        python3=3.13.5-1 \
        python3-venv=3.13.5-1 \
    \
    && apt-get install -y --no-install-recommends \
        build-essential=12.12 \
        git=1:2.47.3-0+deb13u1 \
        gnupg=2.4.7-21+deb13u1 \
        libffi-dev=3.4.8-2 \
        libssl-dev=3.5.6-1~deb13u2 \
        npm=9.2.0~ds1-3 \
        patch=2.8-2 \
        python3-dev=3.13.5-1 \
    \
    # Debian ships nginx 1.26.3, which is older than both the Alpine build this
    # app used to ship and the OpenResty 1.29.2 upstream builds on. Take nginx
    # from the nginx project's own repository instead. It compiles the stream
    # module in statically, so no load_module directive is needed.
    && curl -fsSL https://nginx.org/keys/nginx_signing.key \
        | gpg --dearmor > /usr/share/keyrings/nginx-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg]" \
        "http://nginx.org/packages/mainline/debian trixie nginx" \
        > /etc/apt/sources.list.d/nginx.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        nginx=1.31.5-1~trixie \
    \
    && npm install --global yarn@1.22.22 \
    \
    && python3 -m venv /opt/certbot \
    && /opt/certbot/bin/pip install --no-cache-dir \
        "certbot==${CERTBOT_VERSION}" \
    && ln -s /opt/certbot/bin/certbot /usr/bin/certbot \
    \
    && /opt/certbot/bin/python -c "from importlib.metadata import version; \
        print('\n'.join(f'{p}=={version(p)}' \
        for p in ('acme', 'certbot', 'josepy')))" \
        > /etc/certbot-constraints.txt \
    \
    && curl -fsSL -o /tmp/nginxproxymanager.tar.gz \
        "https://github.com/NginxProxyManager/nginx-proxy-manager/archive/${NGINX_PROXY_MANAGER_VERSION}.tar.gz" \
    && mkdir /app \
    && tar zxf \
        /tmp/nginxproxymanager.tar.gz \
        --strip 1 -C /app \
    \
    && for i in /usr/src/*.patch; do \
        patch -d /app -p 1 --forward --no-backup-if-mismatch < "${i}" \
        || exit 1; done \
    \
    && cd /app/frontend \
    && yarn install --frozen-lockfile --network-timeout 100000 \
    && yarn locale-compile \
    && yarn build \
    && rm -rf node_modules \
    \
    && mkdir -p /opt/nginx-proxy-manager/frontend \
    && cp -r /app/frontend/dist/. /opt/nginx-proxy-manager/frontend/ \
    \
    && cp -r /app/backend/. /opt/nginx-proxy-manager/ \
    \
    && sed -i "s#\"version\": \"[^\"]*\"#\"version\": \"${NGINX_PROXY_MANAGER_VERSION#v}\"#" \
        /opt/nginx-proxy-manager/package.json \
    && grep -q "\"version\": \"${NGINX_PROXY_MANAGER_VERSION#v}\"" \
        /opt/nginx-proxy-manager/package.json \
    \
    && cd /opt/nginx-proxy-manager \
    && yarn install --frozen-lockfile \
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
    && sed -i "s#su npm npm#su root root#" \
        /etc/logrotate.d/nginx-proxy-manager \
    && sed -i "s#root /app/frontend;#root /opt/nginx-proxy-manager/frontend;#" \
        /etc/nginx/conf.d/production.conf \
    && sed -i "s#table.string('id').notNull().primary();#table.string('id', 32).notNull().primary();#" \
        /opt/nginx-proxy-manager/migrations/20190227065017_settings.js \
    \
    && mkdir -p \
        /run/nginx \
    \
    && yarn cache clean \
    && npm uninstall --global yarn \
    \
    && apt-get purge -y --auto-remove \
        build-essential \
        git \
        gnupg \
        libffi-dev \
        libssl-dev \
        npm \
        patch \
        python3-dev \
    && apt-get clean \
    \
    && rm -f -r \
        /app \
        /etc/init.d/nginx \
        /etc/logrotate.d/nginx \
        /opt/nginx-proxy-manager/node_modules/bcrypt/build \
        /root/.cache \
        /root/.node-gyp \
        /root/.npm \
        /tmp/.[!.]* \
        /tmp/* \
        /usr/lib/node_modules \
        /usr/local/share/.cache \
        /var/cache/nginx \
        /var/lib/apt/lists/* \
        /var/lib/nginx \
        /var/log/nginx \
        /var/tmp/nginx \
        /var/www

# Keep pip from replacing the Certbot stack that ships with the image
ENV PIP_CONSTRAINT=/etc/certbot-constraints.txt

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
    org.opencontainers.image.vendor="Home Assistant Community Apps" \
    org.opencontainers.image.authors="Franck Nijhof <frenck@addons.community>" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.url="https://frenck.dev/home-assistant-apps" \
    org.opencontainers.image.source="https://github.com/${BUILD_REPOSITORY}" \
    org.opencontainers.image.documentation="https://github.com/${BUILD_REPOSITORY}/blob/main/README.md" \
    org.opencontainers.image.created=${BUILD_DATE} \
    org.opencontainers.image.revision=${BUILD_REF} \
    org.opencontainers.image.version=${BUILD_VERSION}
