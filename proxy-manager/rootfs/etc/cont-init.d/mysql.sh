#!/command/with-contenv bashio
# ==============================================================================
# Home Assistant Community Add-on: Nginx Proxy Manager
# This file init the MySQL database
# ==============================================================================
declare host
declare password
declare port
declare username

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
