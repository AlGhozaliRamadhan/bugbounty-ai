---
title: Report structure and triage
date: 2026-10-16
type: reference
status: current
verified: 2026-10-16
sources:
  - https://docs.hackerone.com/en/articles/8495674-defining-severity (GET)
  - https://hackerone.com/amazonvrp (program bounty policy - CVSS 3.0)
  - https://pentester.land/sitemap.xml
---

# Report structure and triage

**Fresh lookup, 2026-10-16.** Platform policy from HackerOne's help centre;
severity rubric and structure guidance in `docs/report-writing.md`.

## Severity on HackerOne (verified policy)

Reports are marked with a severity level: **None, Low, Medium, High, Critical**.

- Researchers can select manually based on judgement, or use a **CVSS calculator**.
- HackerOne offers **CVSS 3.0**, **CVSS 3.1**, and **CVSS 4.0** implementations;
  a program configures which it uses.
- **From 2026-09-21, severity is required** for Bug Bounty, Vulnerability
  Disclosure, and Challenge programs. Programs can opt out of the requirement.
- Severity drives bounty ranges and routing. It also appears on Hacktivity.
- Asset-level metrics and maximum severity factor into the score when a report is
  linked to an asset.
- CVSS method changes are **not retroactive** — only reports submitted after the
  change use the new method.

Concrete example of how a program actually pays: the Amazon Vulnerability
Research Program states HackerOne uses **CVSS 3.0** to calculate severity for
rewards. So on some programs the CVSS vector is not advisory — it *is* the
bounty calculation. Read the specific program's policy.

## Structure that works

The platform doesn't prescribe a template; triagers impose the real format by
what they can act on. The order below survives because each section answers a
question the reader has in sequence.

1. **Title** — class plus object. `IDOR on invoice API exposes other users' billing data`.
2. **Summary** — two sentences, no jargon. They decide whether to keep reading here.
3. **Severity** — with reasoning, not a bare label.
4. **Steps to reproduce** — numbered, cold-start, complete.
5. **Proof** — request/response, credentials redacted.
6. **Impact** — in the program's language: users, money, data.
7. **Remediation** — concrete and verifiable after the fix.

## What actually causes rejection

- **Can't reproduce.** Overwhelmingly the most common. Usually a missing step:
  the account used, its role, the exact parameter, or a request that only works
  with a state a triager doesn't have. If your repro needs a specific session,
  you haven't finished the proof.
- **No demonstrated impact.** Best-practice findings with nothing downstream.
- **Out of scope** — including anything not in `scope.md` as it stands *now*.
- **Duplicate.** Common where a public writeup or another researcher's report
  covered the same path. Finding it again doesn't pay.
- **Self-inflicted.** Accessing an object you created, or finding an "issue"
  caused by your own request.
- **Scanner output unverified.** Submitting a nuclei hit verbatim is the fastest
  way to lose credibility.

## What gets it paid

- **You did the triage work.** Impact spelled out, minimal PoC, no ambiguity
  about what's reachable.
- **A cold-start repro.** Every fact needed is in the report.
- **Minimal-impact proof.** One record, not two hundred.
- **A realistic fix**, plus something a retester can check.

## Writing for a triager with no context

They have your report, thirty others, and no memory of your session.

- Give the exact URL and method — not "the invoices endpoint".
- State the role of every account you used, and that you used two.
- Show what "unexpected" looks like: the ownership field that doesn't match.
- Say what you did **not** test. "I did not attempt bulk enumeration" shows
  restraint, which makes everything else easier to believe.

## Severity discipline

Severity is not CVSS — CVSS describes technical characteristics, programs pay on
business impact, and they disagree constantly. Rate against: what an attacker can
do, what they need first (nothing? a normal account? admin?), how much data, and
whether it's reachable at all.

When a rating is arguable, **report the lower one and argue for the higher in the
Impact section.** Triagers down-rate far more than they up-rate, and a report
that argues its own case persuades better than one that overclaims.

Full rubric in `docs/report-writing.md`.

## After submission

- **Triage verdict** — record it in the finding's `Status` field and in `notes.md`.
- **Duplicate** — note *why* the original was reported and you weren't.
  Usually a different entry point, which is reusable on other targets.
- **Fixed** — **retest.** Fixes are frequently partial, and a partial fix is a
  new report. `docs/workflow.md` treats this as a phase, not an afterthought.

## Where the format is enforced

The submission form itself is part of the report: asset, weakness, severity, and
CVSS vector are structured fields on HackerOne. Fill them accurately — a correct
weakness classification routes your report correctly, and a wrong one can bury it
in the wrong queue.

## Platform notes worth checking per program

- Required severity (now mandatory on HackerOne since 2026-09-21)
- Which CVSS version the program uses
- Whether a safe harbour exists
- Whether duplicates from public sources are paid
- Minimum bounty, and whether "informative" pays anything

Each of these changes over time and differs per program. Read the program's own
policy page — don't work from memory or from another program.