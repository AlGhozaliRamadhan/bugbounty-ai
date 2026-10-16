---
title: Report writing and severity
date: 2026-10-16
type: reference
status: current
verified: 2026-10-16
---

# Report writing and severity

How to write a report that gets paid, and how to rate one honestly. Template:
[`templates/finding.md`](templates/finding.md).

## Severity is not CVSS

CVSS describes technical characteristics. Programs pay on **business impact**,
and the two disagree constantly. A CVSS 6.1 memory-disclosure bug on an
internal-only service may pay nothing; a CVSS 4.3 IDOR on the billing endpoint
may pay well.

Rate against these questions, in order:

1. **What can an attacker do?** Read one record? Read everything? Change
   someone else's data? Execute code?
2. **What do they need first?** Nothing is unauthenticated. A normal user
   account? A specific role? An admin? A leaked token?
3. **How much data?** One record is a bug. Bulk extraction is a breach.
4. **Is it reachable by an attacker at all?** Pre-auth on a login page beats
   post-auth on an internal tool.

| Rating | Typical shape |
| --- | --- |
| **Critical** | Unauthenticated RCE, full-database exfiltration, auth bypass into any account, arbitrary file write on a public host. |
| **High** | Authenticated RCE, IDOR exposing another user's sensitive data at scale, privilege escalation across roles, SSRF reaching cloud metadata. |
| **Medium** | Single-record IDOR on low-sensitivity data, stored XSS requiring a victim click, open redirect on a trusted domain, CSRF on a state-changing action with real impact. |
| **Low** | Information disclosure with limited value, missing security headers with a plausible path, verbose errors leaking internal detail. |
| **Info** | No demonstrated security impact. Still worth reporting sometimes — hardening credit, or building a relationship with the program. |

When a rating is arguable, **report the lower one and explain the case for the
higher in Impact.** Triagers down-rate far more often than they up-rate, and a
report that argues for its own severity persuades better than one that
overclaims.

## What gets paid, what doesn't

Pays:

- A clear path from unauthenticated-or-low-priv to a concrete impact.
- Minimal proof — you did the triage work for them.
- A realistic remediation.

Doesn't pay:

- Best-practice findings with no demonstrated impact.
- Self-inflicted findings: you created the object, then accessed it, and call it
  IDOR. (Unless the point is that any user can create such an object.)
- Findings outside `scope.md`.
- Duplicates of a publicly reported bug.
- Scanner output with no manual verification.
- Anything requiring DoS to demonstrate.

## Structure that works

1. **Title** — the class and the object. `IDOR on invoice API exposes other users' billing data`.
2. **Summary** — two sentences, no jargon. This is what gets read first.
3. **Severity** — with the reasoning, not just the label.
4. **Steps to reproduce** — numbered, complete, cold-start. Include the account
   and its role; this is the step people omit and the step that causes "can't
   reproduce".
5. **Proof** — request/response pairs, redacted.
6. **Impact** — who is affected, how much, and what it means.
7. **Remediation** — concrete, and checkable after the fix.

## Writing it cold

A triager has no context and no patience. Every fact they need must be in the
report:

- The exact URL and method, not "the invoices endpoint".
- The role of the account you used, and that you used two.
- What "unexpected" looks like — the ownership field that doesn't match.
- What you did **not** test, so they know the bound of your work.

"Using account A, I requested an invoice belonging to account B and received
account B's data. I did not attempt bulk enumeration."

That last sentence matters. It shows restraint, which makes the rest of the
report easier to believe.

## Redaction

Never include a live credential in a report or in `notes.md`:

- Session cookies and bearer tokens → `REDACTED`
- Real user data → your own synthetic test account, or a redacted sample
- Internal hostnames that aren't the finding → omit

Reports get shared with people outside the program. Assume every report you
write is forwarded.

## Minimal-impact proof

The scope rule in `AGENTS.md` says it, and it matters practically:

- One record proves IDOR. Two hundred proves you don't understand the boundary.
- The smallest sample that demonstrates the primitive is the professional choice.
- Never pull a full table, never enumerate a whole directory, never bulk-test
  accounts. If the impact claim requires bulk to be true, it isn't true.

## Before you submit

- [ ] Every step works from a clean session with no prior context
- [ ] Account and role stated for every authenticated step
- [ ] Credentials redacted
- [ ] Severity argued, not asserted
- [ ] Remediation is concrete and verifiable
- [ ] Scope re-checked against `scope.md` as it stands *now*
- [ ] Finding saved to `recon/<host>/findings/`
- [ ] `notes.md` updated with what you found and what you deliberately skipped

## After triage

Record the verdict in the finding's `Status` field and in `notes.md`. If it's a
duplicate, note *why* the original was reported and you weren't — usually a
different entry point, which is reusable. If a fix is claimed, retest it;
partial fixes are common and a partial fix is a new report.