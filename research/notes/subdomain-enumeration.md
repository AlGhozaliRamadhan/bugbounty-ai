---
title: Subdomain enumeration tooling and methods
date: 2026-10-16
type: reference
status: current
verified: 2026-10-16
sources:
  - https://pentester.land/sitemap.xml (34 KB, full URL index)
  - https://pentester.land/blog/subdomains-enumeration-cheatsheet/ (GET, 2018-11-14)
  - https://pentester.land/ (JS-rendered - see Access note)
---

# Subdomain enumeration

**Fresh lookup, 2026-10-16.** Method list from Pentester Land's cheat sheet
(2018-11-14 — the method taxonomy is stable even though individual tools have
moved on).

> **Access note:** Pentester Land's pages are client-side rendered. The raw HTML
> of `pentester.land/` contains **zero `href` attributes**, so "scrape the HTML"
> does not work and never did. Use `https://pentester.land/sitemap.xml` — it
> returns the full URL index (190 URLs as of this lookup). This corrects
> `sources.md`.

## Use multiple techniques — that's the whole point

The cheat sheet's opening argument is still correct: **the more techniques you
use, the more chances you find something others missed.** A single tool finds a
single provider's data. Different tools index different sources, and forgotten
infrastructure tends to appear in exactly one of them.

Some researchers use only amass + subfinder + massdns. That's fine on a VPS with
bandwidth. On a slow connection, or without a VPS, use whatever works — the
marginal subdomain is the whole value.

## Method taxonomy

Passive / no traffic to the target:

- Scraping search engines and archives
- **Certificate Transparency** (`crt.sh`) — the single highest-yield passive source
- **DNS brute force** against a wordlist
- Permutations and alterations of known subdomains (`altdns`)
- Public datasets and DNS aggregators
- Git repositories — search for the domain in source
- Text parsing: HTML, JavaScript, documents
- Online DNS tools
- SSL certificates, SAN entries

Low-traffic active:

- VHost discovery
- ASN discovery (`bgp.he.net` → `amass -asn`)
- Reverse DNS
- Zone transfer (`AXFR`) — try it, it still works sometimes
- DNSSEC zone walking
- DNS cache snooping
- CSP and other HTTP response headers (`Content-Security-Policy` leaks third-party and internal hostnames)

## Tools worth knowing

| Tool | Source | Note |
| --- | --- | --- |
| `subfinder` | ProjectDiscovery | Broad passive provider coverage. Fast. Present here. |
| `amass` | OWASP | Passive mode + ASN discovery. Present here. |
| `assetfinder` | Tomnomnom | Cheap, different sources. Present here. |
| `altdns` | infosec-au | Permutations of known subdomains. Finds staging/dev/staging2 variants. |
| `assets-from-spf` | yamakira | Parses netblocks and domains out of SPF records. |
| `BiLE-suite` | sensepost | HTML parsing, reverse DNS, TLD expansion, horizontal correlation. |
| `puredns` | sitedown | Massdns-based resolution, fast. **Not installed here.** |
| `massdns` | MiTM | Brute-force resolver at scale. **Not installed here.** |

`altdns` specifically earns its place: `./altdns.py -i known-subdomains.txt -o new_subdomains.txt -r -s resolved.txt`
takes what you already found and permutes it — `dev`, `staging`, `qa`, `uat`,
`internal`, and numeric variants are where forgotten environments live.

## The pipeline here

Follow `docs/recon-playbook.md` Phase 1–2. Union `subfinder`, `assetfinder`,
`amass -passive`, and `waybackurls` hostnames, then resolve with `dnsx -a -resp`.

Two things that matter more than tool choice:

**Review CNAMEs before scanning.** `dnsx -a` gives you the CNAME chain. A
hostname pointing at Cloudflare, Azure Front Door, or a vendor's subdomain is
usually outside the program's boundary. Flag it, don't scan it. See the scope
gate in `AGENTS.md`.

**Most enumerated names don't resolve.** That's normal, not a failure. Filter
before you port scan.

## CT logs directly

```bash
curl -s "https://crt.sh/?q=%25.target.com&output=json" | jq -r '.[].name_value' | tr '\n' '\n' | sort -u
```

Cheap, no traffic to the target, and finds historic certificates for
decommissioned infrastructure — which sometimes still resolves.

## Historical sources

`gau` and `waybackurls` produce hostnames as a side effect of collecting URLs.
Both need `. /etc/profile.d/gobin.sh` first — they're in `/root/go/bin`, which
`sh` doesn't have on PATH. See `docs/environment.md`.

## Rate limits

Passive enumeration sends nothing to the target. DNS brute force and vhost
discovery do. Wordlist size directly controls request volume — start with
`common.txt`, and escalate only if the program allows it. See `docs/toolchain.md`.

## Freshness warning

The method taxonomy is stable; the **tool roster** in a 2018 cheat sheet is not.
Several tools listed there are archived, renamed, or superseded. Check what
`docs/environment.md` says is actually installed before planning around any of
it, and install missing ones with `.\scripts\setup-kali.ps1 -Packages <name>`.