---
title: Engagement workflow
date: 2026-10-16
type: reference
status: current
verified: 2026-10-16
---

# Engagement workflow

The shape of a bounty engagement and the gate that stops you at each step.
Detailed commands live in [`recon-playbook.md`](recon-playbook.md); this is the
map.

```
scope gate → recon → map → hunt → prove → report → retest
     ↑                                                    │
     └────────────── scope changed ───────────────────────┘
```

## 1. Scope gate

**Nothing touches a host before this passes.**

1. Scaffold: `.\scripts\new-target.ps1 -Target <host>`
2. Fill in `recon/<host>/scope.md` — every field, not just the hostname.
3. Confirm the host resolves where you expect. A CDN or WAF in front changes
   how you interpret every later response, so record it once here.

Stop conditions:

- The program does not cover this host → **stop.** Finding it via recon does not
  put it in scope.
- The program's rules forbid what you were asked to do → say which line is
  crossed, and stop.
- Scope is ambiguous → **ask.** Don't assume the permissive reading.

## 2. Recon

Passive and low-rate first, then active. Full pipeline and commands in
[`recon-playbook.md`](recon-playbook.md).

Order matters: you cannot port scan a host you haven't resolved, and you cannot
probe HTTP on a port you haven't found.

1. **Passive enumeration** — subdomains from provider APIs and archives. No
   packets to the target, so no rate-limit risk.
2. **Resolution** — separate resolvable hosts from dead names. A large fraction
   of enumerated subdomains don't resolve.
3. **Port scan** — fast sweep first, then a full `nmap -p-` on survivors only.
4. **HTTP probe** — status, title, technology, and crucially the IP/CNAME so you
   can spot hosts outside the boundary.
5. **URL collection** — crawler plus historical archives. Archived URLs expose
   forgotten endpoints and parameters.

Stop conditions:

- Rate limit reached → **back off.** Do not "just a bit more".
- A host resolves outside the declared infrastructure → **flag it**, don't scan it.
- Traffic feels wrong (errors, slowdowns, alerts) → **stop and tell the operator.**

## 3. Map the application

Before hunting anything, understand what you've got:

- What does it do, and who are the roles? Two accounts in different roles is the
  minimum useful setup — most authz bugs require the comparison.
- What data does it hold, and whose is it?
- What's the attack surface: API, GraphQL, file upload, exports, webhooks,
  integrations, admin panels, forgotten subdomains?

Write this down in `notes.md`. Hunting without a role map means you can't tell
whether an access-control check is missing.

## 4. Hunt

Two modes, and you need both:

- **Mechanical** — run the Fast Testing Checklist in
  [`../research/notes/tbhm-methodology.md`](../research/notes/tbhm-methodology.md).
  74 items, predictable, catches the usual.
- **Hypothesis-driven** — pick one idea and go deep. "If I can control the
  `redirect_uri` in the OAuth flow, what does the token exchange do?" One thread,
  followed to the end, beats scattered poking.

Check [`../research/notes/_index.md`](../research/notes/_index.md) first — the
topic may already be researched.

Stop conditions:

- You need a new permission → **ask** the operator.
- The test starts affecting real user data → **stop**, narrow it to a synthetic
  record you created.

## 5. Prove

A finding needs a minimal, reproducible proof. That means:

- The smallest sample that demonstrates impact. One other user's record, not two
  hundred.
- A reproduction a stranger can follow from scratch.
- Redacted credentials. `REDACTED`, never a live token.
- No destructive payloads, no availability impact, no artifacts left behind.

Full rubric in [`report-writing.md`](report-writing.md).

Stop conditions:

- Proving it further would require pulling bulk data → **stop.** You have the proof.
- The only way to demonstrate impact is DoS → **stop.** That is out of scope for
  essentially every program.

## 6. Report

Write it while the context is fresh. Use
[`templates/finding.md`](templates/finding.md).

What makes a report get paid:

- **Summary in plain language**, jargon-free, in the first two sentences.
- **Impact stated in the program's language** — users, money, data. Not
  technical excitement.
- **A reproduction that works cold.** Include the account and role you used.
- **A concrete remediation**, and something the retester can check afterwards.

Overclaiming is the most common reason a real bug gets downgraded. "Read one
other user's invoice" is a precise claim. "Access all user data" is a different
claim and needs different evidence.

## 7. Retest

Bug bounty work isn't finished when it's reported.

- Check for a triage verdict and record it in the finding.
- If it's a duplicate, learn why the original wasn't found — usually a different
  entry point. Note it; it's reusable.
- Retest when a fix is claimed. Fixes are frequently partial, and a partial fix
  is a new report.
- **Update `notes.md`** with what happened. That's the part that compounds.

## Across sessions

Bounty work spans sessions, and context doesn't survive. Keep state in files:

- `recon/<host>/notes.md` — the running log, append-only.
- `recon/<host>/findings/` — confirmed bugs.
- `recon/<host>/scope.md` — the boundary, with a change log.

If you can't reconstruct where you were from those three files, that's a defect
in the record, not a memory problem. Write it down.