---
description: Run recon against a host whose scope is already confirmed
---

Load the `scope` skill with the `skill` tool and follow it, using `$1` as the
target. Then continue from **Step 5** — the scope gate is already passed for
this host, so go straight to DNS resolution, port scan, HTTP probing, crawling
and content discovery per `docs/recon-playbook.md`.

Two checks before you start:

- Read `recon/$1/scope.md`. If any placeholder is still open, stop and ask —
  unenforced scope invalidates everything downstream.
- Read `recon/$1/notes.md` if it exists. If recon already ran here, don't rerun
  it blindly — report what's covered and ask what's left.

Log the outcome in `notes.md`, dead ends especially. Treat nuclei output as a
hypothesis; nothing goes into `findings/` without manual verification.