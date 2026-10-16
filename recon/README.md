# recon/ layout

One folder per host. **The folder name is the hostname, exactly as you found
it.** That is the whole indexing scheme — there is no manifest, no database, and
no friendly aliases.

```text
recon/example.com/            apex
recon/api.example.com/        each subdomain gets its OWN folder
recon/dev-v2.example.com/     keep the port suffix if that's the hostname
```

Do not invent friendly names like `recon/example-api/`, `recon/staging/`, or
`recon/target1/`. `recon/staging/` tells the next session nothing;
`recon/staging.example.com/` tells it everything.

## Inside a target folder

| File / dir | Holds | Tracked in git |
| --- | --- | --- |
| `scope.md` | **The scope gate.** In-scope hosts, rules of engagement, exclusions. | yes |
| `notes.md` | Append-only running log: what was tried, what worked, what died. | yes |
| `findings/` | Confirmed bugs, one `.md` per finding from `docs/templates/finding.md`. | yes |
| `subdomains.txt` | One subdomain per line. | no |
| `urls.txt` | One URL per line. | no |
| `ports.txt` | Raw nmap output. | no |
| `live.txt` | Hosts that answered on 80/443. | no |
| `screenshots/` | Proof images. | no |
| `poc/` | Raw PoC output, `curl` transcripts. | no |
| `scripts/` | One-off scripts written for this host. | no |

`scope.md`, `notes.md`, and `findings/` are the durable record *on disk*. All of
it is gitignored — this repo is public, and unpublished recon plus the name of
the program paying for it never leaves the machine.

## Why `notes.md` is append-only

It records dead ends as well as wins, and it never gets rewritten. A finding
that took four attempts has four entries, and the fourth one explains what
changed. Overwriting history destroys the thing that makes the next session
fast.

## Scaffolding

```powershell
.\scripts\new-target.ps1 -Target api.example.com -Program "HackerOne #12345"
.\scripts\new-target.ps1 -Target api.example.com -OutOfScope "cdn.vendor.com,accounts.google.com"
```

Then **fill in `scope.md` before touching the host.**

## Where output must land

Recon output goes inside `recon/<target>/` and nowhere else — never the repo
root, never `%TEMP%`, never `C:`, never a scratch dir in Kali.

In practice that means building in Kali's per-target scratch dir and copying the
finished file across, because `/mnt/d` is slow:

```bash
SCRATCH=$(sh "/mnt/d/Bug Bounty/scripts/scratch.sh" init api.example.com)
cd "$SCRATCH"
# ... run tools against ./ ...
sh "/mnt/d/Bug Bounty/scripts/scratch.sh" check api.example.com results.txt
cp -v results.txt "/mnt/d/Bug Bounty/recon/api.example.com/"
```

The quoted path is mandatory — `/mnt/d/Bug Bounty` has a space in it.

Scratch is **per target**, never one shared `/tmp/work`. `init` refuses to reuse
a non-empty directory, and `check` fails if a results file holds hostnames off
the target's domain. Both guards exist because a shared scratch once fed a
previous target's `sf.txt` into a different target's results. See
[`../docs/environment.md`](../docs/environment.md) for the full account.