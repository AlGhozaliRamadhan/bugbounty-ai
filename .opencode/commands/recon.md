---
description: Run the recon pipeline against an in-scope host
---

Run recon against `$1`, following `docs/recon-playbook.md`.

Gate before you start:

- Read `recon/$1/scope.md`. If any placeholder is still open, stop and tell me
  which ones — unenforced scope invalidates everything downstream.
- Confirm the host is on the in-scope list. A subdomain found by recon is not
  automatically in scope.
- Note the stated rate limit. Every tool in the playbook sets one; keep it.

Then work the phases in order — they depend on each other (you cannot port scan
an unresolved host, you cannot probe HTTP on a port you haven't found):

1. Passive subdomains — `subfinder`, `assetfinder`, `amass -passive`, `waybackurls`
2. Resolve — `dnsx -a -resp`, and review CNAMEs for out-of-scope hosts
3. Ports — `naabu -top-ports 1000` fast, then `nmap -sS -T3 -p-` on survivors
4. HTTP probe — `httpx`, keeping `-cname`/`-ip` to catch third-party hosts
5. URLs and parameters — `katana`, `gau`, then `gf qurl`
6. Content discovery — `ffuf` with extensions, rate-limited
7. Triage — `nuclei`, `whatweb`, `wafw00f`

Execution notes that are not optional:

- `execute_command` runs `/bin/sh` (dash), not bash. `source` fails — use
  `. /etc/profile.d/gobin.sh` for `gau`, `waybackurls`, `gf`, `jaeles`.
- Build in `/tmp/work` inside Kali, then copy finished files to the target
  folder. `/mnt/d` is slow.
- `/mnt/d/Bug Bounty/...` must stay quoted. The space in the path splits it.
- Prefer `execute_command` over the named `*_scan` MCP tools. `metasploit_run`,
  `hydra_attack`, `john_crack`, `enum4linux_scan` fail outright — those
  dependencies aren't installed.
- Never send `sudo`; Kali is already root.

When you finish, append to `recon/$1/notes.md`: what ran, what was rate-limited,
which hosts fell outside the boundary, and any dead ends. Dead ends matter most —
they stop the next session repeating work that already failed.

Treat nuclei output as a hypothesis, not a finding. Nothing goes into `findings/`
without manual verification.