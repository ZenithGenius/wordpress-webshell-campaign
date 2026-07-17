---
title: "Indicators of Compromise"
description: "Defanged indicators and YARA rules for the persistent WordPress webshell campaign: shells, redirect and C2 infrastructure, rogue-admin tradecraft, and detection."
---

# Indicators of Compromise

Attacker indicators for the persistent WordPress webshell campaign, published for threat-intelligence value and **defanged** (`[.]`, `hxxp`). Victim data is intentionally omitted. Refang before use in tooling.

*Shell filenames are random per host; treat them as examples of a pattern, not fixed names. Hunt on behavior and strings, not on filename or hash alone.*

## Webshells and implants

| Path (example) | Family | Auth gate | Role |
|---|---|---|---|
| `wp-content/upgrade/wp/pdNIsBpOfQ.php` | WSO "orb yanz" | cookie `_d41` | Interactive shell + `shell_exec` |
| `wp-content/plugins/wp/oXwAYNxH.php` | WebShell by boot | `cc=abcd` session | File manager (no exec) |
| `stats/2023-11/OiFZvJcyL.php` | Tiny File Manager | app login | File manager |
| `rpx/srdb-tests/FHmxCj.php` | terminal shell | minimal | Command execution |
| `wp-content/uploads/PIManVZAq.php` | remote stager | none local | `eval` of off-host payload |
| `stats/2025-5/eOiNc.php` | remote loader | none local | Fetch + execute remote |
| theme `.../wp-blog-header.php` | sabotage | none | Overwrites `.htaccess` + `index.php`, sets `0444` |
| `private/wp-blog-header.php`, `private/wp-cron.php` | remote stager | none | Off-web-root re-entry, byte-identical pair |
| `wp-content/plugins/qcwignbeou/` | camouflage | n/a | Trojanized "Protect Uploads 0.3" copy, inactive |
| `wp-content/plugins/fxszduhyot/` | camouflage | n/a | Trojanized "Protect Uploads 0.3" copy, inactive |

## Signature strings and gates

```
wsoyanz                              XOR key in WSO decode chain
WSOX ENC                             WSO marker
PRIV8 WEB SHELL ORB YANZ BYPASS      WSO banner
WebShell by boot                     boot-family panel title
Tiny File Manager                    third-party file manager (abused)
_d41 = fa704e7366d666bd              WSO cookie gate (name is host-derived)
cc=abcd                              boot-family session password
type=1 .. type=7                     WSO panel action parameters
```

## Redirect and C2 infrastructure

```
SEO / shortener redirect:
  ushort[.]company
  urshort[.]com
  u-short[.]net                      (hyphenated variant; match  ur?short  + hyphen form)

Mobile popunder:
  olame[.]live                       (~10 numbered paths, e.g. /AEA0c10 .. /FFm9c69)

Additional landing:
  muslmh[.]x-b[.]biz                 (observed alongside the shorteners)

Remote stager / C2:
  hxxps://github.eshree[.]top/fkolpsfd/olpfkchwa.txt     eval(base64) second stage
  hxxps://vpsdd.fnftus[.]top/test/gg.txt                 loader payload
  hxxps://vpsdd.fnftus[.]top/door/<doact>.txt            parameterized loader
  hxxp://remote2025.byhot[.]top/index.php                URL-exfil beacon
```

## Rogue administrator tradecraft

```
Accounts inserted directly into the database (not via WordPress UI):
  user_registered = 1970-10-10 10:10:10        impossible timestamp tell
  session_tokens source IP  = 31.207.38.194
  session User-Agent        = Mozilla/5.0 ... Chrome/90.0.4430.85 Safari/537.36
  files + users + sessions all created within the same minute (server-side write)
```

## Attacker / scanner IPs

```
129.0.226.200      direct POST to interactive shell
31.207.38.194      rogue-admin session source
172.190.142.176    scanning of web-root shell paths
```

## Web-server log patterns

```
GET/POST  .../<random>.php  with cookie  _d41=fa704e7366d666bd     -> WSO shell use
GET/POST  .../<random>.php?cc=abcd                                 -> boot-family shell use
requests carrying  type=1 .. type=7                                -> WSO panel actions
User-Agent containing  ushort / urshort / u-short  in WP self-requests
    (WordPress cron requests inherit a poisoned home/siteurl)
```

## MITRE ATT&CK

`T1190` Exploit Public-Facing Application ·
`T1505.003` Web Shell ·
`T1136.001` Create Account: Local Account (rogue admins) ·
`T1105` Ingress Tool Transfer (remote stagers) ·
`T1071.001` Application Layer Protocol: Web Protocols (C2 over HTTP) ·
`T1027` Obfuscated Files or Information (staged decode chains) ·
`T1564.003` Hide Artifacts (allowlist `.htaccess`) ·
`T1491.001` Internal Defacement / redirect injection ·
`T1485` Data Destruction (sabotage kill-switch)

## YARA: webshell families

```yara
rule WP_Webshell_Campaign_Shells
{
    meta:
        description = "WSO 'orb yanz' + WebShell by boot + remote stager family"
        author      = "Isaac Joumessi"
        reference   = "analysis/01-ir-war-story.md"
    strings:
        $wso_key   = "wsoyanz" ascii
        $wso_enc   = "WSOX ENC" ascii
        $wso_ban   = "ORB YANZ BYPASS" ascii
        $boot      = "WebShell by boot" ascii
        $boot_auth = "cc" ascii fullword
        $stager    = "eval(\"?>\".base64_decode(" ascii
        $php       = "<?php"
    condition:
        $php at 0 and
        ( any of ($wso_key, $wso_enc, $wso_ban, $boot) or
          ($stager and filesize < 20KB) )
}
```

## YARA: appended redirect payload

```yara
rule WP_Redirect_Injection_Hex_Location
{
    meta:
        description = "Hex window.location redirect appended to .php and .js"
        author      = "Isaac Joumessi"
        reference   = "analysis/01-ir-war-story.md"
    strings:
        // ob_start() wrapper prepended to thousands of PHP files
        $ob    = "ob_start();" ascii
        // hex-encoded 'http' start of the injected location string
        $hexh  = "\\x68\\x74\\x74\\x70" ascii
        $loc   = "window.location" ascii nocase
        $refr  = "http-equiv=\"refresh\"" ascii nocase
        $stem  = /ur?short|u-short|olame/ ascii nocase
    condition:
        ($ob and $hexh) or
        (($loc or $refr) and $stem)
}
```

Refang all domains and URLs before loading into detection tooling. These indicators reflect what was observed during the engagement and are shared for defensive use only.
