#!/usr/bin/env bash
# Detonate the lab: drop the neutered shells, the allowlist concealment artifact,
# and plant the redirect in all three homes (a .php, a read-only .js, the database).
# Everything points only at the local sink. Nothing here is functional malware.
set -euo pipefail
cd "$(dirname "$0")"
set -a; . ./.env 2>/dev/null || true; set +a
WP_PORT="${WP_PORT:-8018}"; SINK_PORT="${SINK_PORT:-8019}"
DC="docker compose"

echo "[*] shells + allowlist concealment artifact into wp-content ..."
$DC exec -T wpcli sh -c '
  cp /seed/wp-lab-shell.php /seed/wp-lab-boot.php /seed/wp-lab-stager.php /var/www/html/wp-content/
  cp /seed/allow.htaccess /var/www/html/wp-content/allow.htaccess
'

echo "[*] home #1 (php file layer): appended-redirect php ..."
$DC exec -T wpcli sh -c "sed 's/__SINK_PORT__/${SINK_PORT}/g' /seed/redirect-snippet.php > /var/www/html/wp-content/lab-appended.php"

echo "[*] home #2 (js layer, set read-only 444): appending redirect to a front-end core js ..."
$DC exec -T wpcli sh -c "
  JS=/var/www/html/wp-includes/js/wp-emoji-release.min.js
  sed 's/__SINK_PORT__/${SINK_PORT}/g' /seed/redirect-snippet.js >> \$JS
  chmod 444 \$JS
"

echo "[*] home #3 (database): poisoned option + post ..."
$DC exec -T wpcli sh -c "
  wp option update lab_redirect_marker 'http://localhost:${SINK_PORT}/promo' --allow-root >/dev/null
  wp post create --post_title='Lab poisoned post' --post_status=publish --post_content='<script>window.location.href=\"http://localhost:${SINK_PORT}/promo\";</script>' --allow-root >/dev/null
"

cat <<EOF

[+] Detonated. The redirect now lives in THREE homes at once:
      1. wp-content/lab-appended.php          (file layer)
      2. wp-includes/js/wp-emoji-release.min.js  (read-only 444 js)
      3. the database (option + post)

    WordPress:  http://localhost:${WP_PORT}
    Sink logs:  docker compose logs -f sink

    The gotcha, live:
      curl -s http://localhost:${WP_PORT}/ | grep -i 'window.location' || echo '  curl sees clean HTML'
    ...but open the site in a real browser and the read-only .js still redirects to the sink.

    Detection drill:
      docker compose exec -T wpcli grep -rIl 'window.location' /var/www/html | sort
      docker compose exec -T wpcli grep -rIl 'ORB YANZ\|WebShell by boot\|wsoyanz' /var/www/html/wp-content

    Clean up with ./reset.sh
EOF
