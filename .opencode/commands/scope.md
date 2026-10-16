---
description: Scaffold a recon target and fill in its scope gate
---

Scaffold `recon/$1/` and get the scope gate complete before anything touches the host.

1. Run `.\scripts\new-target.ps1 -Target $1`. Ask me for the program name and any
   explicitly out-of-scope hosts if I haven't given them.

2. Read `recon/$1/scope.md`. Every `<placeholder>` is a question only I can
   answer — list them and ask. Do not guess, and do not leave one unfilled.

3. Record what I tell you. Where the program excludes something, write it into
   "Known issues and exclusions" — that section is Gate 0 for the CVE workflow
   and saves building a full applicability proof for a bug that won't be paid.

4. Resolve the host and note the CDN/WAF if there is one. A CDN in front changes
   how you read every later response, so it gets recorded once, here.

5. Stop and tell me the scope is clear. Do not begin recon in the same step
   without me confirming — recon against an unscoped host is the one mistake
   that can't be undone.

If `$1` is already scaffolded, read the existing `scope.md` and report which
placeholders are still open instead of overwriting it.