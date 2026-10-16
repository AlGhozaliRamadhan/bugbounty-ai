---
title: Research notes index
date: 2026-10-16
type: index
---

# Research notes index

One file per topic, `research/notes/<topic>.md`, dated and sourced.
**Check this list before researching a topic** — if a note exists, read it
rather than re-running the lookup.

## Written

| Note | Covers | Sources used |
| --- | --- | --- |
| [sources.md](sources.md) | Access routes, feed paths, and 5 confirmed traps for all 6 research sources | live probes |
| [tbhm-methodology.md](tbhm-methodology.md) | Bounty-hunting frame, discovery/mapping tactics, auth+session flaw list, **full 74-item Fast Testing Checklist** | TBHM git |
| [portswigger-techniques.md](portswigger-techniques.md) | 2024–2026 technique landscape: SAML auth bypass, cookie-prefix bypass, desync, URL validation, CSS exfil, WebSocket blind spots | PortSwigger RSS + 2 deep reads |
| [orange-tsai-chains.md](orange-tsai-chains.md) | Multi-step chain structure — Exchange & SSL-VPN trilogies, argument injection, LFI filter chains | Orange Tsai Atom (100 entries) |
| [assetnote-searchlight.md](assetnote-searchlight.md) | Product-family hunting, parser targets, impact-framing. **Includes the Assetnote→Searchlight URL move** | slcyber.io/research |
| [cve-driven-testing.md](cve-driven-testing.md) | **CVE playbook** — payable-gate check, applicability test, verified OSV/NVD/cvelistV5 endpoints | live API probes |
| [_lessons.md](_lessons.md) | **Do/don't from real mistakes.** Probe before asserting, GET not HEAD, assert on content not status, write bash to a file | this session |

## Not yet researched

| Topic | Likely sources |
| --- | --- |
| IDOR / BOLA testing, in depth | Pentester Land writeup patterns |
| Subdomain enumeration tooling | Assetnote (pre-move archive via web.archive.org) |
| Fuzzing / parameter discovery | TBHM + ffuf/katana wordlist strategy |
| Race conditions | Searchlight "A JPEG, a Race, and a Ghost" |
| OAuth / OIDC flaws | PortSwigger, Pentester Land |
| Writeup triage and report structure | Pentester Land + Bugcrowd guidance TBHM links |
| tl;dr sec digest — current week | `tldrsec.com/feed.xml` |

Status values: `current`, `stale` (>6 months old, re-verify), `not researched`.

## Conventions

```yaml
---
title: <topic>
date: <YYYY-MM-DD>        # when researched
type: reference | technique | finding
verified: <YYYY-MM-DD>    # last re-checked against a live source
sources:
  - <url> (<access route used>)
---
```

Notes are append-friendly. When re-verifying a stale topic, keep the original
date, bump `verified`, and append a dated revision note — do not silently
rewrite history.

## House rules for these notes

- **No raw PDFs or scraped HTML cached.** Convert to a short Markdown note.
  TBHM ships `How Do I shot Web-.pdf`, but the Markdown chapters cover the same
  ground and are linkable per-section — use those instead of the PDF.
- **Label fresh lookups vs memory** in any answer derived from these notes.
- **Record access routes that trap you**, not just the ones that work — the
  tl;dr sec soft-404 and the PortSwigger HEAD-404 are worth more to a future
  session than a list of URLs.