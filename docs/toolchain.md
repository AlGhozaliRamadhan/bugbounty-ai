---
title: Toolchain and wordlist selection
date: 2026-10-16
type: reference
status: current
verified: 2026-10-16
---

# Toolchain — which tool, and which flags

**What's installed and at what version is in [`environment.md`](environment.md).
Don't duplicate that list here; it goes stale.** This doc is about *choosing* a
tool and getting the flags right.

## Picking a tool

| Job | Use | Why over the alternative |
| --- | --- | --- |
| Subdomains (fast) | `subfinder -d <domain> -silent` | Broad passive provider coverage, fast. |
| Subdomains (archives) | `amass enum -passive` | Historical data the live APIs don't have. |
| Subdomains (backup) | `assetfinder --subs-only` | Cheap, different sources. Run all three and union. |
| DNS resolution | `dnsx -a -resp` | Gives CNAME and IP in one pass — you need both for scope checks. |
| Fast port sweep | `naabu -top-ports 1000 -rate 1000` | Cheap first pass before committing to `-p-`. |
| Full port scan | `nmap -sS -T3 -p- --open` | Definitive. Works here because Kali is root. |
| Service versions | `nmap -sV` | Reliable; better than guessing from a banner. |
| HTTP probing | `httpx -title -tech-detect -sc` | Mass-parallel, outputs clean URL list. |
| Crawling | `katana -d 3 -jc` | JS-aware. Finds endpoints a plain crawler misses. |
| Historical URLs | `gau --providers wayback,commoncrawl,otx,urlscan` | Finds forgotten endpoints still live. |
| Content discovery | `ffuf` | Best filter control (`-fc 404`, `-mc`) and predictable output. |
| Content discovery (alt) | `feroxbuster --rate-limit` | Recursive by default, good with `--depth`. |
| Content discovery (alt) | `gobuster dir`, `dirb` | Fine, but coarser filtering. |
| Template triage | `nuclei -rate-limit` | Severity-gated, scriptable. Verify every hit. |
| Technology fingerprint | `whatweb -a 3` | Aggressiveness levels; `-a 3` is the useful one. |
| XSS | `dalfox`, `gf xss` | `gf` filters fast, `dalfox` confirms with a real payload. |
| SQLi | `sqlmap` | Last resort. Manual testing first. |
| WordPress | `wpscan` | Present. Confirm it's WordPress before running it. |

## Rate limiting is mandatory

An unthrottled scan against a scope the program cares about is how access gets
revoked. **Every tool that takes a rate flag must have one set.**

| Tool | Flag | Sensible default |
| --- | --- | --- |
| `ffuf` | `-rate` | `50` |
| `feroxbuster` | `--rate-limit` | `50` |
| `gobuster` | `-t` | `20` |
| `nuclei` | `-rate-limit`, `-rl` | `50` |
| `naabu` | `-rate` | `1000` |
| `nmap` | `-T` | `T3` |
| `nikto` | `-maxtime` | `5m` |
| `katana` | `-c` | `5` |

Check `recon/<host>/scope.md` for the program's stated limit before running
anything. If scope.md says 2 req/s and you set 50, you're the problem.

## Wordlist selection

Paths verified in `docs/environment.md`. Choosing between them:

| Size | Wordlist | When |
| --- | --- | --- |
| 38 KB | `seclists/Discovery/Web-Content/common.txt` | First pass. Always start here. |
| ~35 KB | `wordlists/dirb/common.txt` | The `gobuster`/`dirb` default. |
| Medium | `seclists/Discovery/Web-Content/raft-medium-directories.txt` | When common.txt is exhausted. |
| Large | `seclists/Discovery/Web-Content/raft-large-directories.txt` | Late, and only when you have budget for the rate. |
| Extensions | `wordlists/dirb/extensions_common.txt` | `-e` input for ffuf/gobuster. |

Rules:

- **Always extend extensions.** `ffuf -e .php,.html,.json,.txt,.bak,.old,.zip`.
  Backups and stray configs are half of what directory brute force finds.
- **`rockyou` ships gzipped only.** `gunzip` it into the per-target scratch dir
  first. There's no plain `rockyou.txt`, which is exactly what `john_crack`
  defaults to.
- **Don't re-run a wordlist that already came back empty.** Record it in
  `notes.md` and move up a size.
- **Copy wordlists into the per-target scratch dir before use.** Reading them
  across `/mnt/d` is slow.

## Flags worth knowing

```sh
# ffuf: filter noise properly. -mc all -fc 404 is the workhorse combo.
ffuf -u https://host/FUZZ -w common.txt -mc all -fc 404 -rate 50 -s

# ffuf: recurse one level and follow extensions
ffuf -u https://host/FUZZ -w raft-medium-directories.txt \
     -e .php,.json -mc all -fc 404 -rate 50 -recursion -recursion-depth 2 -s

# ffuf: match a specific status + size for parameter fuzzing
ffuf -u "https://host/api?FUZZ=1" -w params.txt -mc 200 -fs 1234 -rate 30 -s

# httpx: include IP and CNAME so you can catch out-of-scope hosts
httpx -l hosts.txt -sc -ip -cname -title -o live.txt

# nmap: full sweep into the target folder (path quoted — space in it)
nmap -sS -T3 -p- --open -oN "/mnt/d/Bug Bounty/recon/$TARGET/ports.txt" "$TARGET"

# nuclei: severity gate + rate. Never run unthrottled.
nuclei -l live.txt -severity medium,high,critical -rate-limit 50 -rl 50
```

## Tools that are referenced but absent

Don't plan around these — they aren't installed: `metasploit`, `hydra`, `john`,
`enum4linux`, `masscan`, `gospider`, `theharvester`, `interactsh-client`,
`uncover`, `dirsearch`, `alterx`, `findomain`, `kxss`.

The first four also back MCP tools that **fail outright** — `metasploit_run`,
`hydra_attack`, `john_crack`, `enum4linux_scan`. Use `execute_command` with a
present tool instead.

Install more with `.\scripts\setup-kali.ps1 -Packages <name>`.

## Verifying a tool before you depend on it

```sh
command -v <tool>          # is it there
<tool> --version           # what version
which -a <tool>            # collision check if it behaves oddly
```

`server_health`'s `tools_status` is **not** a presence check — it only reports
on `dirb`, `gobuster`, `nikto`, `nmap`, and it reported `dirb: true` correctly
only by luck. Use `command -v`.

## Chaining

The useful combinations, in order of value:

```sh
# subdomains → resolve → HTTP probe → crawl → parameters
# This is the spine of the whole recon pipeline.

# URLs → parameter list → injection filters
cat urls.txt | gf qurl | grep -E '\?' | sort -u > params.txt
cat params.txt | gf xss > xss_candidates.txt
cat params.txt | gf sqli > sqli_candidates.txt
```

Run `gf` only after `. /etc/profile.d/gobin.sh` — it's in `/root/go/bin`, which
`sh` doesn't have on PATH.