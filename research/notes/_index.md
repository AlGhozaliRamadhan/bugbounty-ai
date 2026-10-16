---
title: Research notes index
date: 2026-10-16
type: index
status: current
verified: 2026-10-16
sources:
  - live lookups from this workspace
---

# Research notes index

One file per topic, `research/notes/<topic>.md`, dated and sourced.
**Check this list before researching a topic** — if a note exists, read it
rather than re-running the lookup.

Status values: `current`, `stale` (>6 months old, re-verify), `not researched`.

## Written

| Note | Covers | Status | Sources used |
| --- | --- | --- | --- |
| [sources.md](sources.md) | Access routes, feed paths, and 5 confirmed traps for all research sources | current | live probes |
| [_lessons.md](_lessons.md) | **Do/don't from real mistakes.** Read before any tooling work | current | this workspace |
| [tbhm-methodology.md](tbhm-methodology.md) | Bounty-hunting frame, discovery/mapping tactics, auth+session flaw list, **full 74-item Fast Testing Checklist** | current | TBHM git |
| [portswigger-techniques.md](portswigger-techniques.md) | 2024–2026 technique landscape: SAML bypass, cookie-prefix bypass, desync, URL validation, CSS exfil, WebSocket blind spots | current | PortSwigger RSS + deep reads |
| [orange-tsai-chains.md](orange-tsai-chains.md) | Multi-step chain structure — Exchange & SSL-VPN trilogies, argument injection, LFI filter chains | current | Orange Tsai Atom (100 entries) |
| [assetnote-searchlight.md](assetnote-searchlight.md) | Product-family hunting, parser targets, impact-framing. **Includes the Assetnote→Searchlight URL move** | current | slcyber.io/research |
| [cve-driven-testing.md](cve-driven-testing.md) | **CVE playbook** — payable-gate check, applicability test, verified OSV/NVD/cvelistV5 endpoints | current | live API probes |
| [idor-bola.md](idor-bola.md) | IDOR/BOLA — horizontal and vertical, parameter tampering, why two accounts are mandatory, what pays | current | PortSwigger Academy |
| [oauth-oidc.md](oauth-oidc.md) | OAuth 2.0 and OIDC — discovery endpoint, `redirect_uri` manipulation, Dynamic Client Registration SSRF, WebFinger enumeration | current | PortSwigger Academy + Academy research paper |
| [race-conditions.md](race-conditions.md) | TOCTOU patterns, cache-poisoning escalation, CSP `strict-dynamic` gadget hijack, Turbo Intruder barriers | current | Searchlight research |
| [subdomain-enumeration.md](subdomain-enumeration.md) | Method taxonomy, tool roster, CT logs, permutations. **Includes the Pentester Land JS-rendering trap** | current | Pentester Land + live probes |
| [fuzzing-parameter-discovery.md](fuzzing-parameter-discovery.md) | ffuf filters (match vs filter), the four fuzzing jobs, recursion limits, vhost discovery | current | ffuf README |
| [report-structure.md](report-structure.md) | HackerOne severity policy, report structure, what causes rejection, after-triage workflow | current | HackerOne help centre |
| [tldrsec-digest.md](tldrsec-digest.md) | Weekly digest — feed route, recent issues, the AI-security through-line | current | live feed |

## Not yet researched

| Topic | Likely sources |
| --- | --- |
| SSRF in depth — internal metadata, protocol smuggling, blind detection | PortSwigger, Orange Tsai |
| XSS filter bypass and CSP bypass techniques in depth | PortSwigger XSS cheat sheet |
| GraphQL-specific testing — authz, batching, introspection | PortSwigger API testing |
| Business logic flaw taxonomy | TBHM ch. 04 + Pentester Land writeups |
| Prototype pollution and JS supply chain | Orange Tsai, Searchlight |
| WebSocket testing methodology | PortSwigger WebSocket research |
| Report writing: worked examples of paid vs rejected | Pentester Land writeup archive |

## Conventions

```yaml
---
title: <topic>
date: <YYYY-MM-DD>        # when written
type: reference | technique | finding | index | template
status: current | stale | not researched
verified: <YYYY-MM-DD>    # last re-checked against a live source
sources:
  - <url> (<access route used>)
---
```

Notes are append-friendly. When re-verifying a stale topic, keep the original
`date`, bump `verified`, and append a dated revision note — do not silently
rewrite history.

**`date` and `verified` are different fields.** `date` is when you wrote it;
`verified` is when you last re-checked it against a live source. Never put prose
in either — `sources.md` once had `verified: 2026-10-16 (all routes probed)`
which breaks anything parsing it as a date.

## House rules for these notes

- **No raw PDFs or scraped HTML cached.** Convert to a short Markdown note.
  TBHM ships `How Do I shot Web-.pdf`, but the Markdown chapters cover the same
  ground and are linkable per-section — use those instead of the PDF.
- **Label fresh lookups vs memory** in any answer derived from these notes.
- **Record access routes that trap you**, not just the ones that work. The
  tl;dr sec soft-404, the PortSwigger HEAD-404, and Pentester Land's
  client-side rendering are all worth more to a future session than a URL list.
- If a lookup contradicts a note, **fix the note**. A wrong access route costs
  every future session a lookup — that is the entire failure `sources.md`
  exists to prevent.