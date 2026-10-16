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

The split is deliberate: **`scope.md`, `notes.md`, and `findings/` are the
durable record.** Everything else is regenerable output or potentially sensitive
material, and is gitignored.

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

In practice that means building in Kali's `/tmp/work` and copying the finished
file across, because `/mnt/d` is slow:

```bash
mkdir -p /tmp/work && cd /tmp/work
# ... run tools against ./ ...
cp -v results.txt "/mnt/d/Bug Bounty/recon/api.example.com/"
```

The quoted path is mandatory — `/mnt/d/Bug Bounty` has a space in it.