#!/usr/bin/with-contenv bashio
# ==============================================================================
# Home Assistant Community Add-on: Nginx Proxy Manager
# This file init the MySQL database
# ==============================================================================
declare host
declare password
declare port
declare username
declare backup

# Require MySQL service to be available
if ! bashio::services.available "mysql"; then
    bashio::log.error \
        "This add-on now requires the MariaDB core add-on 2.0 or newer!"
    bashio::exit.nok \
        "Make sure the MariaDB add-on is installed and running"
fi

host=$(bashio::services "mysql" "host")
password=$(bashio::services "mysql" "password")
port=$(bashio::services "mysql" "port")
username=$(bashio::services "mysql" "username")

#Drop database based on config flag
if bashio::config.true 'reset_database'; then
    bashio::log.warning 'Recreating database'
    echo "DROP DATABASE IF EXISTS nginxproxymanager;" \
    | mysql -h "${host}" -P "${port}" -u "${username}" -p"${password}"

    #Remove reset_database option
    bashio::addon.option 'reset_database'
fi

# Create database if not exists
echo "CREATE DATABASE IF NOT EXISTS nginxproxymanager;" \
    | mysql -h "${host}" -P "${port}" -u "${username}" -p"${password}"

# Check if older MySQL folder exists
if bashio::fs.directory_exists "/data/mysql"; then
    bashio::log.info "Found previous MySQL database, starting migration..."

    backup="/backup/nginx-proxy-manager-$(date +%F).sql"
    bashio::log.info "A backup of your database will be stored in: ${backup}"

    # Start internal MySQL server temperorary
    bashio::log.info "Initializing previous database..."

    # Start MySQL.
    s6-setuidgid mysql /usr/bin/mysqld --datadir /data/mysql --tmpdir /tmp/ &
    rc="$?"
    pid="$!"
    if [ "$rc" -ne 0 ]; then
        bashio::exit.nok "Failed to start the previous database."
    fi

    # Wait until it is ready.
    for _ in $(seq 1 30); do
        if echo 'SELECT 1' | mysql &> /dev/null; then
            break
        fi
        sleep 1
    done

    # Check data integrity and fix corruptions.
    mysqlcheck \
        --no-defaults \
        --check-upgrade \
        --auto-repair \
        --databases mysql \
        --skip-write-binlog \
        > /dev/null \
        || true

    mysqlcheck \
        --no-defaults \
        --all-databases \
        --fix-db-names \
        --fix-table-names \
        --skip-write-binlog \
        > /dev/null \
        || true

    mysqlcheck \
        --no-defaults \
        --check-upgrade \
        --all-databases \
        --auto-repair \
        --skip-write-binlog \
        > /dev/null \
        || true

    # Dump current database into backups folder
    bashio::log.info "Backing up previous database..."

    mysqldump --single-transaction --quick --no-create-db --lock-tables nginxproxymanager \
        > "${backup}"

    # Stop the MySQL server
    kill -s TERM "$pid" || true

    # Load up database to the core mariadb
    mysql -h "${host}" -P "${port}" -u "${username}" -p"${password}" \
        nginxproxymanager < "${backup}"

    # Delete local MySQL data folder
    rm -f -r /data/mysql
fi
