---
name: scope
description: Take a URL or hostname and run the full scope-and-recon workflow for it. Load when the operator pastes a target URL, names a host to hunt, asks to scope something, asks to recon a host, or asks "what's on this domain". Normalizes the input, scaffolds recon/<host>/, runs passive enumeration automatically, then stops for scope confirmation before any traffic reaches the target.
---

# Scope & recon workflow

Takes a URL or hostname and drives it from "here's a target" to "here's a
recon'd attack surface sitting in `recon/<host>/`".

**This is an orchestration layer, not a second copy of the playbook.** The
commands live in `docs/recon-playbook.md`, the rules in `AGENTS.md`, the
environment facts in `docs/environment.md`. Read those; don't restate them here.

## The one thing you must not do

**Never send a single packet to a host before the operator confirms it's in
scope.** Passive enumeration is fine automatically because it targets third-party
APIs and certificate logs, not the victim. Port scanning, HTTP probing and fuzzing
are not.

The gate in Step 3 exists because only the operator knows what's in the program's
boundary. A subdomain that resolves and answers is still out of scope if the
program didn't list it. Do not infer authorization from a host being reachable.

## Step 1 — Normalize the input

Accept whatever they paste. Reduce it to a bare hostname plus an optional port:

| Input | Hostname | Port |
| --- | --- | --- |
| `https://api.example.com/v1/users?x=1` | `api.example.com` | — |
| `http://dev-v2.example.com:8443/admin` | `dev-v2.example.com` | `8443` |
| `example.com` | `example.com` | — |
| `https://user:pw@example.com/x` | `example.example.com` → strip userinfo, warn | — |

Rules:

- Strip scheme, path, query, fragment, and userinfo.
- **A hyphenated label is part of the hostname** — `dev-v2.example.com` stays
  whole. `AGENTS.md` requires keeping it.
- A `:port` suffix is **not** part of it. Record the port, use the bare host as
  the folder name. `new-target.ps1` rejects colons by design.
- Bare IPs are allowed but the folder should be the hostname that resolved to it.
  If you only have the IP, say so and ask before creating the folder.
- Lowercase it. Reject anything with a space, slash, or `@` left in it.

## Step 2 — Scaffold

```powershell
.\scripts\new-target.ps1 -Target <hostname> -Program "<program>" -OutOfScope "<hosts>"
```

If `recon/<hostname>/` already exists, **read it instead of overwriting**. Report
what's already there — an existing `notes.md` usually means work in progress, and
re-running recon over it wastes the session. Ask whether to continue or start
fresh.

Never invent a program name or scope. If the operator didn't give one, ask —
an empty `<program name and ID>` in `scope.md` is a visible, correct prompt.

## Step 3 — Passive recon (automatic, safe)

No packets to the target. Run this without asking.

**Get per-target scratch first.** Never work in a shared `/tmp/work` — two
targets and two sessions collide there, and the result is one target's results
silently filed under another's name.

```sh
SCRATCH=$(sh "/mnt/d/Bug Bounty/scripts/scratch.sh" init "$TARGET")
cd "$SCRATCH"
```

`init` **refuses** if the directory already has content, so a dirty scratch can
never be mistaken for a fresh one. If it refuses, work in it deliberately or
`sh scratch.sh reset "$TARGET"` first.

Then:

```sh
. /etc/profile.d/gobin.sh

subfinder -d "$TARGET" -silent -o sf.txt
assetfinder --subs-only "$TARGET" > af.txt
amass enum -passive -d "$TARGET" -o amass.txt
waybackurls "$TARGET" | awk -F/ '{print $3}' | sort -u > wb_hosts.txt

cat sf.txt af.txt amass.txt wb_hosts.txt | sed 's/\.$//' | sort -u > subs_all.txt
```

**Filter on the registrable domain, then verify.** `grep 'example\.com$'` is not a
membership test — it also matches `notexample.com`. Use:

```sh
cat sf.txt af.txt amass.txt wb_hosts.txt \
  | sed 's/\.$//' | tr 'A-Z' 'a-z' \
  | grep -E "(^|\.)${TARGET#*.}\$" | sort -u > subs_all.txt
sh "/mnt/d/Bug Bounty/scripts/scratch.sh" check "$TARGET" subs_all.txt
```

`check` fails loudly if any line sits off the target's domain. Run it before
anything gets filed.

Save the union to `recon/<host>/subdomains.txt`.

Then read the results and **summarize what a human would want to decide on**:
how many names, how many distinct registrable domains they sit under, and any
obvious staging/dev/qa/internal naming. A short list is fine; a 4,000-line dump
is not.

## Step 4 — THE GATE. Stop and ask.

Present this and wait. Do not proceed on an assumption.

> Passive enumeration found **N** subdomains for `<host>`.
>
> Before any traffic reaches it I need:
> 1. Is `<host>` in scope for which program?
> 2. Rate limit — requests/sec or concurrent connections?
> 3. Anything explicitly out of scope (third-party SaaS, other domains)?
> 4. Testing hours, if not 24/7?
> 5. Any endpoints flagged "do not test"?
>
> Confirm and I'll run DNS resolution, port scan, HTTP probing, crawling and
> content discovery.

Write their answers into `recon/<host>/scope.md`. If they say it's out of scope,
**stop there** — record it and don't touch the host.

## Step 5 — Active recon (only after the gate)

Follow `docs/recon-playbook.md` Phases 2–7 in order. Each phase depends on the
last: you cannot port scan an unresolved host, or probe HTTP on a port you
haven't found.

Two things that are easy to get wrong:

- **Review CNAMEs before scanning anything.** `dnsx -a` gives the CNAME chain. A
  name pointing at Cloudflare, Azure Front Door, or a vendor's subdomain is
  usually outside the boundary. Flag those to the operator and leave them
  unscanned.
- **Respect the stated rate limit.** Every tool in the playbook has a rate flag
  and none should run without one. If scope.md says 2 req/s and the playbook
  says 50, scope.md wins.

If the kali MCP errors, that is almost never your command — run
`.\scripts\check-kali.ps1 -Fix` rather than debugging the command.

## Step 6 — Collect and record

Copy finished files from the per-target scratch into `recon/<host>/` — the
quoted path is mandatory, `/mnt/d/Bug Bounty` has a space in it.

**Name the files explicitly. Never `cp /tmp/work/*.txt`** — that glob would
sweep another target's leftovers into this target's durable record, which is the
exact failure this workspace was hit by on 2026-10-16.

```sh
OUT="/mnt/d/Bug Bounty/recon/$TARGET"
sh "/mnt/d/Bug Bounty/scripts/scratch.sh" check "$TARGET" subs_all.txt
cp -v subs_all.txt "$OUT/subdomains.txt"
```

Then append to `recon/<host>/notes.md`:

- What ran, and roughly how long
- Which hosts resolved **outside** the boundary
- Anything rate-limited or cut short
- **Dead ends** — this matters most. A future session should never retry what
  already failed.
- What to hunt next

Never write a live token into `notes.md`.

## Step 7 — Report back

Short and concrete:

- The target, its folder, and whether scope is confirmed
- Subdomain count, resolved count, and open ports
- What answered on 80/443, with titles and stack
- Anything that looks like out-of-scope infrastructure
- The 2–3 most promising attack surfaces, tied to the right note — IDOR needs
  two accounts, OAuth needs the discovery endpoint first, etc.

Nuclei output is a hypothesis. Nothing goes into `findings/` without manual
verification.

## If recon was already done

Don't rerun blindly. Read `recon/<host>/notes.md` first, see what's already
covered, and ask what's left. Re-scanning a host that was scanned yesterday
wastes hours and risks the rate limit.