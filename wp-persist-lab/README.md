# WordPress Persistent-Compromise Lab

A safe, local reproduction of the campaign from the [war story](../analysis/01-ir-war-story.md) and [actor profile](../analysis/02-actor-campaign.md). It recreates the parts that make the incident instructive: the redirect living in three places at once, the read-only JavaScript, the allowlist concealment, a webshell detection surface, and a stager that beacons to command-and-control. Then it lets you clean it.

## What is and is not real here

This lab teaches detection and cleanup. It is not a webshell kit.

- The "shells" (`wp-lab-shell.php`, `wp-lab-boot.php`, `wp-lab-stager.php`) are **neutered stand-ins**. They carry the family signature strings so YARA and string hunts fire, but every capability is removed: no file access, no command execution, no decode chain, no `eval`.
- The injected redirect and the stager point only at a **local sink** container that serves inert text. Nothing ever contacts the real shortener or C2 infrastructure.
- Everything binds to `127.0.0.1`. Nothing malicious leaves the host.

## Requirements

Docker with the Compose plugin. First run pulls the WordPress and MariaDB images.

## Run it

```bash
cd wp-persist-lab
docker compose up -d --build     # start: wordpress, db, wp-cli (auto-installs), sink
# wait until the installer reports ready:
docker compose logs -f wpcli     # look for "WordPress ready", then Ctrl-C

./trigger.sh                     # detonate: plant the redirect in all three homes + drop shells
./reset.sh                       # clean it all up
docker compose down -v           # tear the lab down
```

WordPress: `http://localhost:8018` (admin / labadmin). Sink: `http://localhost:8019`. Change ports in `.env` if they collide.

## What `trigger.sh` does

It plants the same redirect payload in three independent homes, exactly the property that defeated single-pass cleanup in the real incident:

1. **File layer**: `wp-content/lab-appended.php` (stands in for the block appended to thousands of `.php`).
2. **Read-only JavaScript**: appends the redirect to `wp-includes/js/wp-emoji-release.min.js` and sets it `444`, so it cannot be overwritten until you `chmod` it back.
3. **Database**: a poisoned option and a poisoned post.

It also drops the neutered shells and the allowlist concealment artifact (`allow.htaccess`), and points a stager at the sink.

## The gotcha, live

```bash
# curl fetches HTML and stops; it never runs the JS, so it looks clean:
curl -s http://localhost:8018/ | grep -i 'window.location' || echo 'curl sees clean HTML'

# but the read-only .js the browser loads carries the redirect:
curl -s http://localhost:8018/wp-includes/js/wp-emoji-release.min.js | grep -o 'window.location.href = "[^"]*"'
```

Open `http://localhost:8018/` in a real browser: it redirects to the sink, because the payload is in the JavaScript and the database, not the initial HTML. This is why verification in the real incident had to use a browser, not `curl`.

## Detection and cleanup drill

```bash
# find the shells by signature (not by filename or hash):
docker compose exec -T wpcli grep -rIl 'ORB YANZ\|WebShell by boot\|wsoyanz' /var/www/html/wp-content

# find the injected redirect by its specific marker, not the generic string:
docker compose exec -T wpcli grep -rIl 'localhost:8019/promo' /var/www/html
```

Note that a naive `grep window.location` matches dozens of legitimate WordPress core scripts. Match the specific indicator, the same lesson as `ur?short` versus a single literal in the war story.

`./reset.sh` performs the cleanup the real engagement had to: remove the shells and concealment, `chmod 644` the read-only `.js` before stripping it, and clear the database option and post.

## Files

```
docker-compose.yml   wordpress + mariadb + wp-cli installer + sink, on one 127.0.0.1 network
.env                 host ports (WP_PORT, SINK_PORT)
setup/wp-setup.sh    one-time WordPress install, then idle for exec
sink/                local, inert stand-in for the shortener + C2 infrastructure
seed/                neutered shells, allowlist artifact, redirect snippets
trigger.sh reset.sh  detonate / clean
```
