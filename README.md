# WordPress Webshell Campaign

A technical case study of a persistent, reinfecting WordPress compromise across several sites sharing one FTP-only VPS: one threat actor, multiple webshell families, a sabotage kill-switch, and a redirect payload that lived in `.php`, read-only `.js`, and the database at the same time. Cleaned blind over FTP, twice.

> **Ethics.** Investigated under authorization. All affected parties are anonymized throughout: no real names, domains, hostnames, credentials, or victim IPs appear anywhere in this repository. Attacker indicators are published, defanged, for community threat intelligence.

## The series

One incident, three standalone writeups:

1. **[The war story](./analysis/01-ir-war-story.md)** — defender's account: the three-homes payload, the shell zoo, the kill-switch, and cleaning it blind over FTP. *Available now.*
2. **The threat-actor campaign profile** — infrastructure, TTPs, MITRE ATT&CK, victimology. *Coming next.*
3. **The reproduction lab** — rebuild it safely in Docker. *Coming after.*

## Indicators

- [Indicators of compromise and YARA rules](./analysis/IOCs.md) (defanged)

## Read online

Published via GitHub Pages once enabled: `https://zenithgenius.github.io/wordpress-webshell-campaign/`

## Credits

Analysis by Isaac Joumessi. For educational and defensive use only.
