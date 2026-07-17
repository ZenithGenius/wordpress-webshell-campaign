#!/usr/bin/env bash
# Undo everything the lab modules planted: the exploit-dropped shell, the shells and
# concealment from trigger.sh, the read-only .js, and both the trigger and living-off-
# the-land database injections. Cleans the way the real engagement had to.
set -euo pipefail
cd "$(dirname "$0")"
set -a; . ./.env 2>/dev/null || true; set +a
SINK_PORT="${SINK_PORT:-8019}"
DC="docker compose"

echo "[*] removing shells (incl. exploit-dropped) + concealment + appended php ..."
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

echo "[*] cleaning the database (option, poisoned post, and living-off-the-land injection) ..."
$DC exec -T wpcli sh -c "
  wp option delete lab_redirect_marker --allow-root >/dev/null 2>&1 || true
  for id in \$(wp post list --post_status=publish --s='Lab poisoned post' --field=ID --allow-root 2>/dev/null); do
    wp post delete \"\$id\" --force --allow-root >/dev/null
  done
"
# strip the living-off-the-land injection from every post using wp-cli (no mysql CLI / TLS)
$DC exec -T -e SINK_PORT="${SINK_PORT}" wpcli sh -s <<'INNER'
for id in $(wp post list --post_status=publish --field=ID --allow-root); do
  wp post get "$id" --field=post_content --allow-root > /tmp/c
  if grep -q "${SINK_PORT}/promo" /tmp/c; then
    sed -i "s#<script>window.location.href=\"http://localhost:${SINK_PORT}/promo\";</script>##g" /tmp/c
    wp post update "$id" /tmp/c --allow-root >/dev/null
  fi
done
rm -f /tmp/c
INNER

echo
echo "[+] Reset complete. Verify nothing specific remains:"
echo "    files: docker compose exec -T wpcli grep -rIl 'localhost:${SINK_PORT}/promo' /var/www/html/wp-content"
echo "    db:    docker compose exec -T wpcli sh -c 'for id in \$(wp post list --post_status=publish --field=ID --allow-root); do wp post get \$id --field=post_content --allow-root | grep -q promo && echo \$id; done'"
