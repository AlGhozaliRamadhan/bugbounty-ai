---
title: Finding template
date: 2026-10-16
type: template
status: current
verified: 2026-10-16
---

# Canonical finding template

Copy this into `recon/<host>/findings/<slug>.md` when you confirm something real.
Slug is a short kebab-case label — `idor-invoice-endpoint`, not `bug1.md`.

Severity guidance lives in [`../report-writing.md`](../report-writing.md). Read it
before you rate anything; the rubric is not guesswork about CVSS.

## The template

```markdown
# {{TITLE}}

| | |
| --- | --- |
| **Host** | {{HOST}} |
| **Endpoint** | {{METHOD}} {{URL_OR_ROUTE}} |
| **Severity** | {{CRITICAL\|HIGH\|MEDIUM\|LOW\|INFO}} |
| **Class** | {{e.g. IDOR, auth bypass, SSRF, stored XSS}} |
| **Status** | {{unreported \| submitted \| triaged \| duplicate \| fixed \| N/A}} |
| **Found** | {{YYYY-MM-DD}} |

## Summary

One or two sentences. What is wrong, in plain language, with no jargon and no
padding. The reader decides whether to keep reading based on this alone.

## Affected scope

- Is it all users, some users, or one account?
- Does it need any privilege at all? Say "none — unauthenticated" loudly if so.
- How many objects are exposed?

## Reproduction

Steps a stranger can follow without any context. Numbered, explicit, and
complete — including the account you used, which is often the part people omit.

1. Create/locate an account at role `<role>`.
2. `<method>` `<url>` with the headers below.
3. Observe `<response>`.
4. Repeat with an identifier belonging to another account.

## Proof

**Requests** (redact live tokens — use `REDACTED`, and never paste a working
session cookie into this file):

```http
GET /api/invoices/8821 HTTP/1.1
Host: {{HOST}}
Authorization: Bearer REDACTED
```

**Response**:

```http
HTTP/1.1 200 OK
Content-Type: application/json

{"id":8821,"owner":"someone-else@example.com","total":149.00}
```

**Why this is a bug**: the object returned belongs to `<owner>`, not to the
authenticated principal `<your account>`.

## Impact

State the consequence in terms the program cares about — confidentiality,
integrity, availability, money, users, data. Quantify it with the smallest
sample that proves it: `N` records is enough, not the whole table.

Do not overstate. "Read one other user's invoice" is a precise claim. "Access
all user data" is a different claim and needs the evidence to match.

## Remediation

The concrete fix, not "sanitize input". For IDOR: enforce authorization on
every access, don't rely on an unguessable ID. Say what to check after the fix.

## Evidence files

- Screenshots: `recon/{{HOST}}/screenshots/<file>.png`
- Raw output: `recon/{{HOST}}/poc/<file>.txt`

## Timeline

| Date | Event |
| --- | --- |
| {{YYYY-MM-DD}} | Found |
| {{YYYY-MM-DD}} | Confirmed minimal reproduction |
| {{YYYY-MM-DD}} | Reported |

## Notes

Transferable technique, dead ends, and anything a retester would need.
Append-only — don't rewrite earlier entries.
```

## Rules that matter more than the template

- **Redact live credentials.** A working session cookie in a report that gets
  shared leaks the test account. Use `REDACTED`.
- **Show the smallest proof.** One other user's record demonstrates IDOR. Two
  hundred demonstrates negligence. The scope rule in `AGENTS.md` says the same
  thing: prove impact minimally.
- **No destructive payloads.** Never pull a full database to prove access.
- **Never commit PoCs or findings.** This repo is public; every file under
  `recon/<target>/` is gitignored for that reason.
- **Record dead ends.** The next session should not retry what already failed.