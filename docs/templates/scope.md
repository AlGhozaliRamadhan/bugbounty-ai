---
title: Scope template
date: 2026-10-16
type: template
status: current
verified: 2026-10-16
---

# Canonical `scope.md` template

`scripts/new-target.ps1` copies this into `recon/<host>/scope.md` and fills the
`{{...}}` placeholders. Keep this file and the script in sync — the script is the
thing that runs, this is the thing that explains what the script produces.

**Fill this in before any active testing.** Recon output collected outside the
agreed boundary is not evidence, and a bug found out of scope is a liability
rather than a payout.

## Placeholders the script substitutes

| Token | Replaced with |
| --- | --- |
| `{{HOST}}` | the hostname passed to `-Target` |
| `{{PROGRAM}}` | the `-Program` value, or a `<...>` prompt |
| `{{DATE}}` | today's date, `yyyy-MM-dd` |

Everything else is left as a literal prompt for you to answer.

## The template

```markdown
# Scope - {{HOST}}

**Program:** {{PROGRAM}}
**Created:** {{DATE}}
**Last reviewed:** {{DATE}}

## In scope

- {{HOST}}

## Out of scope

- <explicitly excluded hosts, third-party SaaS, other registrable domains>

## Rules of engagement

- Rate limit: <requests/sec or concurrent connections allowed>
- Testing hours: <24/7, or business hours only>
- Allowed: <automated scanners? directory fuzzing?>
- Not allowed: <DoS, social engineering, physical testing, ...>
- Disclosure: <private report / public, safe harbor status>

## Known issues and exclusions

- <CVEs the program says are already reported or out of scope>
- <endpoints marked "do not test" — admin panels, third-party integrations>
- <bug bounty platform scanners that will file duplicates if you do>

## Resolution

- Resolves to: <ip, CNAME chain>
- CDN / WAF in front: <Cloudflare, Akamai, none, ...>
- Notes: <anything that changes how you should test>

## Change log

| Date | Change | Why |
| --- | --- | --- |
| {{DATE}} | Initial scope | Target scaffolded |
```

## Why each section exists

- **In scope** — the only list that authorizes a connection. A hostname found by
  recon is *not* on this list until you put it here.
- **Out of scope** — where you most often get burned. Third-party SaaS and other
  registrable domains are almost always excluded, and hitting them is your bug,
  not the program's.
- **Rules of engagement** — the rate limit decides whether your fuzzing is
  testing or abuse. When in doubt, lower the rate.
- **Known issues and exclusions** — this is Gate 0 for the CVE workflow. Saves
  you from building a complete applicability proof for a bug that won't be paid.
- **Resolution** — a CDN or WAF in front changes which techniques work and how
  you interpret responses. Record it once here rather than rediscovering it.
- **Change log** — scope shifts mid-engagement. Keep the history so you can
  prove which boundary applied when.