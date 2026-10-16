---
description: Turn a confirmed bug into a submittable report
---

Write up a finding for `$1` using `docs/report-writing.md` and
`docs/templates/finding.md`.

First, find what I actually have: read `recon/$1/notes.md` and anything in
`recon/$1/findings/`. If I haven't confirmed the bug yet, say so and help
confirm it — a report written from an unverified premise wastes the triager's
time and ours.

Before writing:

- Re-check the endpoint against `recon/$1/scope.md` **as it stands now**. Scope
  moves, and an out-of-scope finding is worth nothing.
- Redact every credential. `REDACTED`, never a live token. Reports get forwarded
  to people outside the program.

Draft the report with these sections: title, summary, severity, steps to
reproduce, proof, impact, remediation, timeline.

The parts that decide whether it gets paid:

- **Summary in plain language**, no jargon, first two sentences. The reader
  decides whether to continue based on this alone.
- **Reproduction that works cold.** Include the account and its role. "You must
  be logged in as a customer" is the step people omit, and it's the step that
  produces "can't reproduce".
- **Minimal proof.** One other user's record demonstrates IDOR; two hundred
  demonstrates negligence. Never pull bulk data.
- **Impact in the program's language** — users, money, data — not technical
  excitement.
- **Concrete remediation** that a retester can verify after the fix.

On severity: it is not CVSS. Rate against what an attacker can do, what they
need first, how much data is exposed, and whether it's reachable at all. When
it's arguable, report the lower number and argue for the higher in Impact —
triagers down-rate far more than they up-rate, and overclaiming loses real bugs.

Save to `recon/$1/findings/<kebab-case-slug>.md` and tell me the path. Update
`notes.md` with what was found and, explicitly, what you deliberately did not
test.