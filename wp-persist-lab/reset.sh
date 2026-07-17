#!/usr/bin/env bash
# Undo everything trigger.sh planted, the way the real cleanup had to: remove the
# shells, chmod the read-only .js back before overwriting it, and clean the database.
set -euo pipefail
cd "$(dirname "$0")"
DC="docker compose"

echo "[*] removing shells + concealment artifact + appended php ..."
$DC exec -T wpcli sh -c '
  cd /var/www/html/wp-content
  rm -f wp-lab-shell.php wp-lab-boot.php wp-lab-stager.php lab-appended.php allow.htaccess
'

echo "[*] restoring the read-only .js (chmod 644, strip the appended redirect) ..."
$DC exec -T wpcli sh -c '
  JS=/var/www/html/wp-includes/js/wp-emoji-release.min.js
  chmod 644 "$JS"
  sed -i "/lab-redirect-marker home2-js/,\$d" "$JS"
'

echo "[*] cleaning the database (option + poisoned post) ..."
$DC exec -T wpcli sh -c '
  wp option delete lab_redirect_marker --allow-root >/dev/null 2>&1 || true
  for id in $(wp post list --post_status=publish --s="Lab poisoned post" --field=ID --allow-root 2>/dev/null); do
    wp post delete "$id" --force --allow-root >/dev/null
  done
'

echo
echo "[+] Reset complete. Verify nothing remains:"
echo "    docker compose exec -T wpcli grep -rIl 'window.location' /var/www/html   # expect no output"
