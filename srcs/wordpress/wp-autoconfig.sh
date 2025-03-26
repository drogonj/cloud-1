#!/bin/bash
set -eo pipefail

echo "🔧 Démarrage de la configuration WordPress..."

required_vars=("WP_ADMIN_PASSWORD" "WP_ADMIN" "WP_USER" "WP_USER_PASSWORD" "TITLE" 
               "MARIADB_DATABASE" "MARIADB_USER" "MARIADB_USER_PASSWORD" "HOSTNAME")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "❌ Variable $var non définie" >&2
        exit 1
    fi
done

# Exécution en tant que www-data
run_as_wwwdata() {
    su -s /bin/bash -c "$*" www-data
}

# Téléchargement de WordPress si nécessaire
if [ ! -f /var/www/html/wp-settings.php ]; then
    echo "⬇️ Téléchargement de WordPress..."
    run_as_wwwdata "wp core download --path=/var/www/html"
fi

sleep 5

if [ ! -f /var/www/html/wp-config.php ]; then
    echo "📝 Creating wp-config.php"
    run_as_wwwdata "wp config create \
        --path=/var/www/html \
        --dbname=\"$MARIADB_DATABASE\" \
        --dbuser=\"$MARIADB_USER\" \
        --dbpass=\"$MARIADB_USER_PASSWORD\" \
        --dbhost=\"mariadb\""

    echo "🚀 Installation de WordPress"
    run_as_wwwdata "wp core install \
        --path=/var/www/html \
        --url=\"$HOSTNAME\" \
        --title=\"$TITLE\" \
        --admin_user=\"$WP_ADMIN\" \
        --admin_password=\"$WP_ADMIN_PASSWORD\" \
        --admin_email=\"$WP_ADMIN@$HOSTNAME.org\" \
        --skip-email"

    echo "👤 Création de l'utilisateur"
    run_as_wwwdata "wp user create \
        --path=/var/www/html \
        \"$WP_USER\" \
        \"$WP_USER@$HOSTNAME.org\" \
        --role=author \
        --user_pass=\"$WP_USER_PASSWORD\""

    echo "🔄 Mise à jour des plugins et thèmes"
    run_as_wwwdata "wp plugin update --all --path=/var/www/html"
    run_as_wwwdata "wp theme update --all --path=/var/www/html"
fi

chown -R www-data:www-data /var/www/html
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;
chmod 600 /var/www/html/wp-config.php

echo "✅ Configuration terminée avec succès"
exec php-fpm -F