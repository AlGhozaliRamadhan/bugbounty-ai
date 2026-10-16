---
title: Recon playbook
date: 2026-10-16
type: playbook
status: current
verified: 2026-10-16
---

# Recon playbook

The runnable pipeline, in order. Every command here uses a tool
[`environment.md`](environment.md) verified present on this machine, and every
script is **POSIX `sh`-safe** — `execute_command` runs dash, not bash.

## Before anything else

```text
1. scope.md filled in and the host is on the in-scope list
2. recon/<host>/ folder exists
3. WSL scratch ready:  mkdir -p /tmp/work && cd /tmp/work
```

Set the target once per session:

```sh
TARGET="example.com"
OUT="/mnt/d/Bug Bounty/recon/$TARGET"
mkdir -p /tmp/work && cd /tmp/work
```

`$OUT` **must stay quoted at every use.** `/mnt/d/Bug Bounty` has a space in it,
and an unquoted path splits and writes to the wrong place.

## The sh trap

`execute_command` runs `/bin/sh` (dash). Two consequences, both live:

- `source` does not exist. Use `. /etc/profile.d/gobin.sh`.
- `gau`, `waybackurls`, `gf`, and `jaeles` are `go install`-ed into
  `/root/go/bin`, which dash doesn't have on PATH.

Every script below that needs a Go tool starts with:

```sh
. /etc/profile.d/gobin.sh
```

`&&`, `||`, `$()`, pipes, and redirection all work fine — those only break when
passed inline through PowerShell, not here.

## Phase 1 — Passive subdomain enumeration

No packets to the target, so no rate-limit exposure. Do this first and always.

```sh
. /etc/profile.d/gobin.sh
TARGET="example.com"

subfinder -d "$TARGET" -silent -o sf.txt
assetfinder --subs-only "$TARGET" > af.txt
amass enum -passive -d "$TARGET" -o amass.txt          # -passive: archives only

cat sf.txt af.txt amass.txt | sed 's/\.$//' | sort -u > subs_raw.txt
wc -l < subs_raw.txt
```

Also pull historical hosts — these surface forgotten infrastructure:

```sh
. /etc/profile.d/gobin.sh
waybackurls "$TARGET" | awk -F/ '{print $3}' | sort -u > wb_hosts.txt
cat subs_raw.txt wb_hosts.txt | sort -u > subs_all.txt
```

## Phase 2 — Resolution

Most enumerated names don't resolve. Filter them before you scan anything.

```sh
TARGET="example.com"
dnsx -l subs_all.txt -silent -a -resp -o resolved.txt -json > dns.json
wc -l < resolved.txt
```

`-a` records CNAME. **Read those before scanning** — a CNAME pointing at a
third-party host (Cloudflare, Azure, a vendor's subdomain) is usually outside the
program boundary. Flag it, don't scan it.

```sh
# hosts resolving outside the expected range — review these by hand
cat dns.json | jq -r 'select(.a | length > 0) | "\(.host) -> \(.a|join(","))"' 2>/dev/null | head -40
```

## Phase 3 — Port scan

Two passes. A fast top-1000 sweep to find the live web surface, then a full
`-p-` on survivors only. Scanning every subdomain across 65535 ports is the
fastest way to get rate-limited.

```sh
TARGET="example.com"
OUT="/mnt/d/Bug Bounty/recon/$TARGET"

# Pass 1: fast, rate-limited
naabu -list resolved.txt -top-ports 1000 -rate 1000 -silent -o ports_quick.txt

# Pass 2: full range, hosts with something open
nmap -sS -T3 -p- --open -iL resolved.txt -oN "$OUT/ports.txt"
```

From `docs/environment.md`: `-sS` and `-O` work because Kali is root. `-sU` is
excluded — it's slow and targets rate-limit it. `-O` warns it can't find a
closed port unless you scan a full range; the guesses are still usable.

Service detection on what you found:

```sh
# extract open ports and build a -p argument per host
grep -oE '^[0-9.]+|[0-9]+/tcp' nmap_live.txt 2>/dev/null
nmap -sS -sV -T3 -p 80,443,8080,8443 -iL resolved.txt -oN "$OUT/ports.txt"
```

## Phase 4 — HTTP probe

```sh
httpx -l resolved.txt \
  -title -tech-detect -status-code -content-length \
  -follow-redirects -sc -ip -cname \
  -o "$OUT/live.txt"
```

`-cname` and `-ip` matter: they surface CDN-fronted and third-party hosts that
are outside the boundary. Review them before you go further.

Keep only what answered:

```sh
cat "$OUT/live.txt" | awk '{print $1}' | grep -E '^https?://' | sort -u > urls_base.txt
```

## Phase 5 — URL and parameter collection

```sh
. /etc/profile.d/gobin.sh

katana -list urls_base.txt -d 3 -jc -kf all -silent -o /tmp/work/katana.txt
gau --providers wayback,commoncrawl,otx,urlscan -subs "$TARGET" > /tmp/work/gau.txt
hakrawler -url "https://$TARGET" -depth 3 -plain > /tmp/work/hak.txt

cat /tmp/work/katana.txt /tmp/work/gau.txt /tmp/work/hak.txt \
  | grep -E '^https?://' | sort -u > "$OUT/urls.txt"
wc -l < "$OUT/urls.txt"
```

Extract parameters — this is the input to every later phase:

```sh
. /etc/profile.d/gobin.sh
cat "$OUT/urls.txt" | gf qurl | grep -E '\?' | sort -u > /tmp/work/params.txt
wc -l < /tmp/work/params.txt
```

## Phase 6 — Content discovery

Start small, then widen. Use a wordlist from `docs/environment.md`.

```sh
# Quick first pass, ~38 KB
ffuf -u "https://$TARGET/FUZZ" \
  -w /usr/share/seclists/Discovery/Web-Content/common.txt \
  -mc all -fc 404 -rate 50 -t 20 -s \
  -o /tmp/work/ffuf_quick.json

# Deeper, with extensions
ffuf -u "https://$TARGET/FUZZ" \
  -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt \
  -e .php,.html,.json,.txt,.bak,.old,.zip \
  -mc all -fc 404 -rate 50 -t 20 -s \
  -o /tmp/work/ffuf_medium.json
```

Alternatives: `feroxbuster` (recursive, `--rate-limit 50 --depth 3`),
`gobuster dir -w ... -t 20 --no-error`, `dirb`.

Rate flags are not optional. `-rate 50` on ffuf, `--rate-limit` on feroxbuster,
`-t 20` on gobuster. Without them you are the reason a program revokes access.

## Phase 7 — Triage

```sh
# Technology and WAF, per host
whatweb -a 3 "https://$TARGET"
wafw00f "https://$TARGET"

# Template-based triage, severity-gated, rate-limited
nuclei -l "$OUT/live.txt" -severity low,medium,high,critical \
  -rate-limit 50 -rl 50 -o /tmp/work/nuclei.txt

# Cautious, bounded
nikto -h "https://$TARGET" -maxtime 5m -nointeractive
```

**Scanner output is a hypothesis, not a finding.** Every nuclei hit needs manual
verification before it goes in `findings/`. Most are false positives, and
submitting unverified scanner output is a fast way to lose credibility.

## Phase 8 — Copy results back

```sh
TARGET="example.com"
OUT="/mnt/d/Bug Bounty/recon/$TARGET"

cp -v /tmp/work/nuclei.txt /tmp/work/params.txt "$OUT/"
cp -v /tmp/work/ffuf_medium.json "$OUT/"
```

Build in `/tmp/work`, copy the finished files across. `/mnt/d` is a
cross-filesystem mount and thousands of small writes there crawl.

## Phase 9 — Manual hunt

Automated triage finds the usual. The rest is
[`../research/notes/tbhm-methodology.md`](../research/notes/tbhm-methodology.md)
— the 74-item Fast Testing Checklist — plus whatever the technique notes cover.

Two accounts in different roles, created deliberately, is the minimum setup for
any authorization testing. Most authz bugs are a comparison, and you cannot
compare with one account.

## After recon

Log it in `recon/<host>/notes.md`: what ran, what was rate-limited, what
surprised you. Dead ends especially — a future session should never retry what
already failed.

## MCP tool choice

Prefer `execute_command` over the named `*_scan` tools for anything not in
Phase 1–7's happy path. `metasploit_run`, `hydra_attack`, `john_crack`, and
`enum4linux_scan` **fail outright** because their dependencies aren't installed.
`server_health`'s `tools_status` only covers four tools and isn't a presence
check — use `command -v`.