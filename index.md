# WordPress Webshell Campaign

A persistent, reinfecting compromise across several WordPress sites sharing one FTP-only VPS. One threat actor, multiple webshell families, and a redirect payload that lived in three places at once. Cleaned blind over FTP, then cleaned again when it came back.

*A single nonprofit's site was the anchor of a wider campaign across tenants on the same host. All affected parties are anonymized; attacker indicators are published defanged for threat intelligence.*

```mermaid
flowchart LR
    V[Shared FTP-only VPS<br/>several WordPress tenants] --> ACT((One actor))
    ACT --> S[Webshell families<br/>WSO, boot, file-managers, stagers]
    ACT --> K[Sabotage kill-switch<br/>overwrites .htaccess + index.php]
    ACT --> R[SEO / phishing redirect<br/>in .php + read-only .js + database]
    S --> P[Persistence + re-entry]
    R --> M[Monetized traffic<br/>shorteners + popunders]
    P -. reinfection .-> ACT
```

## Read the series

This one incident is written up as three standalone pieces. Each answers a different question and does not repeat the others.

**1. [The war story: a compromise that would not die](./analysis/01-ir-war-story.md)**. *The defender's account.* How the payload hid in three places, why single-pass cleanup failed, the shell zoo, the sabotage kill-switch, and how it was all cleaned blind over FTP with no shell. **Available now.**

**2. [The threat-actor campaign profile](./analysis/02-actor-campaign.md)**. *The intel view.* Infrastructure map, shell-family fingerprints, reverse-engineering the PHP implants, rogue-admin tradecraft, MITRE ATT&CK, and victimology across the VPS. *Available now.*

**3. [The reproduction lab](https://github.com/ZenithGenius/wordpress-webshell-campaign/tree/main/wp-persist-lab)**. *Hands-on.* Rebuild the compromise safely in an isolated Docker stack: the redirect in three homes, read-only JavaScript, neutered shells, and a local sink standing in for the shortener and C2. Detonate, detect, clean. *Available now.*

## Deep dives

Focused technical companions to the series.

**[Deobfuscating the toolkit](./analysis/03-deobfuscation.md).** *Reversing.* A static, sample-by-sample walkthrough of the real implants: the WSO five-stage decode, character-arithmetic function names, comment-noise wrapping, the remote stager, and the goto-flattened sabotage.

**[Tracing the operator](./analysis/04-tracing.md).** *Attribution.* Clustering the infrastructure and tradecraft into one operator, with reused handles, builder-kit fingerprints, a timeline, and an honest account of what cannot be proven.

**[Cleaning without a shell](./analysis/05-ftp-ir-tooling.md).** *Methodology.* The FTP-only IR toolkit behind the war story: token-locked throwaway tools, mtime cutover scanning, read-only JavaScript, and safe database cleanup.

## Indicators

[Indicators of compromise and YARA rules](./analysis/IOCs.md), defanged, for detection and threat intelligence.

---

*Investigated under authorization. The affected parties are anonymized throughout. Attacker indicators are published, defanged, for community threat intelligence.*
