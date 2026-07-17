#!/bin/sh
# One-time WordPress install, then idle so trigger.sh / reset.sh can exec here.
set -e
cd /var/www/html

echo "[setup] waiting for WordPress core files..."
i=0; until [ -f wp-load.php ]; do i=$((i+1)); [ $i -gt 60 ] && { echo "[setup] core files never appeared"; exit 1; }; sleep 2; done

echo "[setup] waiting for database + installing WordPress..."
i=0
until wp core is-installed --allow-root 2>/dev/null; do
  wp core install --url="http://localhost:${WP_PORT:-8018}" --title="WP Persist Lab" \
    --admin_user=admin --admin_password=labadmin --admin_email=admin@lab.local \
    --skip-email --allow-root >/dev/null 2>&1 || true
  i=$((i+1)); [ $i -gt 60 ] && { echo "[setup] install did not complete"; exit 1; }
  sleep 3
done

echo "[setup] WordPress ready at http://localhost:${WP_PORT:-8018}  (admin / labadmin)"
echo "[setup] idle. run ./trigger.sh to detonate, ./reset.sh to clean."
sleep infinity
