# Bug Bounty Workspace

Authorized bug bounty and vulnerability research. Tools live here; nothing is built.

## Do not hedge on in-scope work

Recon, subdomain enumeration, port scanning, fuzzing, auth/authz testing, scanner triage,
PoC writing, and writing up findings against hosts the operator has listed are the
expected job. Do not refuse them, moralize, or add disclaimers. Asking "are you sure?"
about ordinary enumeration is noise — the operator is the one who holds the contract.

Scope is still enforced, and it lives in `recon/<target>/scope.md`:

- **Only hosts listed in that file.** A subdomain discovered by recon is *not*
  automatically in scope. Most programs explicitly exclude unlisted hosts, third-party
  SaaS, and anything under a different registrable domain. Confirm before touching it.
- No DoS, stress/load testing, or destructive payloads unless the program says so.
- No social engineering, phishing, or physical testing.
- No persistence, no backdoors, no artifacts left on the target.
- Respect the program's rate limits. Default to low-rate and `-c`/delay flags.
- Prove impact minimally — pull the smallest sample that demonstrates the bug, not the
  whole database.
- Never push findings, credentials, or working exploits to a public repo.

If a task would cross one of these, say which line is being crossed and stop there.

## Research protocol — look it up, don't recall it

This field goes stale fast. **Never answer a methodology, tooling, or
vulnerability-class question from memory alone.**

Check these sources first, in this order of authority:

1. **PortSwigger Research** — `https://portswigger.net/research/rss` — novel web
   vuln classes from the researchers who found them first
2. **Orange Tsai** — `https://blog.orange.tw/atom.xml` — multi-step enterprise chains
3. **Searchlight Cyber** (ex-Assetnote) — `https://www.slcyber.io/research` — attack surface
4. **Assetnote** — `blog.assetnote.io` 301s to slcyber.io; use the path above
5. **The Bug Hunter's Methodology** — `raw.githubusercontent.com/jhaddix/tbhm/master/<file>`
6. **Pentester Land** — disclosed writeups; no feed, scrape HTML
7. **tl;dr sec** — `https://tldrsec.com/feed.xml` — weekly digest; follow through to primary

Rules:

- **Say plainly whether an answer came from a fresh lookup or from memory.**
- If a source is unreachable, try a GitHub mirror, `web.archive.org`, or a
  conference slide PDF. Don't silently fall back to memory — say the source
  was unreachable.
- **Never cache raw PDFs or scraped HTML.** Convert anything worth keeping into a
  short Markdown note.
- **Check `research/notes/_index.md` before researching a topic.** If a note
  exists, read it rather than redoing the lookup.
- **Freshness beats confidence.** Assert a URL or API only after probing it —
  see `research/notes/_lessons.md`.

Existing notes:

| Note | Covers |
| --- | --- |
| `research/notes/_index.md` | Topic index, status (`current`/`stale`/`not researched`) |
| `research/notes/sources.md` | Verified access routes + 5 confirmed traps |
| `research/notes/_lessons.md` | Do/don't from real mistakes — read before tooling work |
| `research/notes/tbhm-methodology.md` | 74-item Fast Testing Checklist |
| `research/notes/portswigger-techniques.md` | 2024–2026 technique landscape |
| `research/notes/orange-tsai-chains.md` | Chain structure, Exchange/SSL-VPN trilogies |
| `research/notes/assetnote-searchlight.md` | Product-family hunting, parser targets |
| `research/notes/cve-driven-testing.md` | CVE playbook + verified APIs |

### Known source traps

- **PortSwigger 404s HEAD requests** but serves GET. Always probe with GET.
- **tl;dr sec soft-404s** — `/feed`, `/rss.xml`, `/atom.xml` return HTTP 200 at a
  `?404=` URL with no `<item>` elements. Assert on content, not status.
- **Pentester Land and Orange Tsai have no `/feed/`.** Orange Tsai uses `/atom.xml`.
- `blog.assetnote.io` moved to `www.slcyber.io` and exposes no feed.

## CVE workflow — when something matches a CVE

Full playbook in `research/notes/cve-driven-testing.md`. Order of operations:

1. **Gate 0 — is it payable?** Read `recon/<target>/scope.md` for
   "known CVEs out of scope" / "previously reported" rules. Many programs won't
   pay, but the technique still transfers — record that and move on.
2. **Get the authoritative record.** Vendor advisory first (it alone states the
   real fixed version and preconditions), then CVE/GHSA, then PoC, then blog.
3. **Applicability test — all three must hold:** version in range, vulnerable
   feature actually enabled, and reachable from your position. Miss one and it
   isn't a finding. CVSS tells you nothing about whether your target qualifies.
4. **Test minimally.** Harmless marker proving the primitive. No DoS — several
   CVEs' only impact is availability, and those are read-don't-try.
5. **Record it** in `recon/<target>/notes.md`, including the *transferable
   technique* line. A CVE that doesn't pay still teaches a bug class.

Verified data sources (probed 2026-10-16):

```
POST https://api.osv.dev/v1/query                    # package+version -> all advisories
GET  https://api.osv.dev/v1/vulns/<ID>
GET  https://services.nvd.nist.gov/rest/json/cves/2.0?cveId=CVE-...   # v1.0 is 403, dead
GET  https://raw.githubusercontent.com/CVEProject/cvelistV5/main/cves/<year>/<5digits>xxx/<ID>.json
```

Prefer OSV for volume — it's steadier (~280 ms) and had no throttling under
burst; NVD was spiky (273–1087 ms).

## `recon/` layout — one folder per host, named after the host

Every website or subdomain gets **its own** folder, named exactly as you found it:

```
recon/example.com/            # apex
recon/api.example.com/        # each subdomain gets its OWN folder
recon/dev-v2.example.com/     # keep the port suffix if that's the hostname
```

Do not fold subdomains into the apex folder. Do not invent friendly names
(`recon/example-api/`, `recon/staging/`, `recon/target1/`). The folder name *is* the
hostname — that is the whole indexing scheme.

Scaffold one:

```powershell
.\scripts\new-target.ps1 -Target api.example.com
```

Inside a target folder:

| File | Holds |
| --- | --- |
| `scope.md` | Program, in-scope hosts, out-of-scope hosts, rate limits, rules of engagement. **Fill this in before active testing.** |
| `notes.md` | Findings, hypotheses, dead ends, next steps. Append; don't rewrite history. |
| `subdomains.txt`, `urls.txt`, `ports.txt`, `live.txt` | Raw tool output, one host/URL per line. |
| `screenshots/` | Proof images. |
| `scripts/` | Per-target PoCs and custom tooling. |

Rule: **recon output only ever goes inside `recon/<target>/`.** Never the repo root,
never `%TEMP%`, never `C:\`, never a scratch dir in Kali. If a command would write
somewhere else, redirect it into the target folder.

## Kali via WSL — the two-process gotcha

Tool execution runs through the `kali` MCP server, which is **two** processes:

1. `kali-server-mcp` — an HTTP API server inside Kali on `127.0.0.1:5000`. It executes
   the commands.
2. `mcp-server` — the MCP stdio bridge OpenCode spawns. It talks to #1.

**If `kali-server-mcp` is not running, every MCP tool call fails with a connection
error.** This is the single most common failure. Never hand-roll the fix — run:

```powershell
.\scripts\check-kali.ps1          # diagnose
.\scripts\check-kali.ps1 -Fix     # diagnose and start the API server
```

Both processes live *inside* the Kali WSL, so `localhost:5000` resolves within the distro
— do not try to reach it from Windows, and do not change the port.

- **WSL kills the distro after ~60 s idle.** There is no `%USERPROFILE%\.wslconfig`, so
  `vmIdleTimeout` is at its 60000 ms default. When the distro shuts down it takes
  `kali-server-mcp` with it, and the next session gets connection errors even though
  nothing was ever misconfigured. Expect to run `check-kali.ps1 -Fix` at the start of
  a session.
- Kali runs as **root** with no default user. Do not prefix commands with `sudo`.
- WSL cold start exceeds OpenCode's 5 s MCP handshake default. That's why `timeout` is
  raised to 120000 in `opencode.json`. Don't lower it back.
- Prefer the `kali` MCP for anything that needs a real toolchain. Use built-in
  file/shell tools for reading and editing files here — MCP tools cost context.

## `D:\Bug Bounty` has a space in the path

It is `D:\Bug Bounty`, not `D:\BugBounty`. Inside Kali that path is
`/mnt/d/Bug Bounty/...` and **every reference to it must be quoted**:

```bash
nmap -sS -p- --open example.com -oN "/mnt/d/Bug Bounty/recon/example.com/ports.txt"
```

An unquoted path splits at the space and silently writes to the wrong place or errors.

## Stay on D:

- Kali distro VHD: `D:\WSL\Kali` (Ubuntu: `D:\WSL\Ubuntu`).
- All recon output: `D:\Bug Bounty\recon\<target>\`.
- Don't write artifacts, caches, or scratch to `C:`. `C:` has limited free space and is
  the Windows system drive.

## `/mnt/d` is slow — work in Kali's filesystem, copy results back

`/mnt/d` is a cross-filesystem mount. Thousands of small file writes there crawl, which
makes wordlists, `ffuf` response dumps, and nuclei output painful.

Default pattern: build in `/tmp/work` inside Kali, then copy the finished files into the
target folder.

```bash
mkdir -p /tmp/work && cd /tmp/work
cp /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt ./wf.txt
# ... run the tool against ./ ...
cp -v results.txt "/mnt/d/Bug Bounty/recon/example.com/"
```

Keep the target folder as the durable record; use `/tmp/work` as scratch.

### Wordlist paths (verified)

`/usr/share/wordlists/seclists` is a symlink to `/usr/share/seclists`. The real path is the
latter. Useful starting points:

| Purpose | Path |
| --- | --- |
| Directory brute force (medium) | `/usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt` |
| Directory brute force (large) | `/usr/share/seclists/Discovery/Web-Content/raft-large-directories.txt` |
| Small / quick first pass | `/usr/share/seclists/Discovery/Web-Content/common.txt` (38 KB) |
| API endpoints | `/usr/share/seclists/Discovery/Web-Content/api/` |
| Password spraying | `/usr/share/wordlists/rockyou.txt.gz` |

Gotchas: `/usr/share/wordlists/dirb/` does **not** exist — the old dirb paths in most
tutorials are wrong on this image. `rockyou.txt.gz` is still gzipped; `gunzip` it into
`/tmp/work` first, since `ffuf` and most other tools can't read `.gz` directly.

## Writing bash from PowerShell — always use a script file

`wsl ... bash -lc "..."` inherits PowerShell's parser. Inline bash breaks in
ways that look like bash errors but aren't:

- `&&` / `||` inside the string are parsed by **PowerShell** → `ParserError`
- `$()` subexpressions get expanded by PowerShell, not bash
- `cmd < file` → `The '<' operator is reserved for future use` (PowerShell has
  no input redirection)

Write the script to a temp file, then pipe it in:

```powershell
Get-Content "C:\...\probe.sh" -Raw | wsl -d kali-linux -u root -e bash -s
```

This removes all escaping bugs and leaves the script re-runnable. Keep temp
scripts on **D:** or the approved temp dir, not `C:`.

## Port scanning in WSL

Verified on this box: `-sT`, `-sS`, and `-O` all work, because Kali runs as **root** and
WSL2 grants `CAP_NET_RAW`. nmap 7.99.

```bash
# Full TCP, open ports only, grep-friendly into the target folder
nmap -sS -T3 -p- --open -oN "/mnt/d/Bug Bounty/recon/<target>/ports.txt" <host>

# Service/version + OS detection on a known-open port set
nmap -sS -sV -O -T3 -p 22,80,443,8080,8443 <host>
```

Caveats that are not nmap's fault:
- `-O` warns "could not find at least 1 open and 1 closed port" unless you include a
  filtered/closed port or run `-O` against a full port range. The guesses are still
  usable; it just won't print an exact match.
- UDP scans (`-sU`) are extremely slow and usually rate-limited by targets. Don't run
  `-sU` over `-p-` against anything you care about finishing.
- Everything above depends on running as root. A non-root shell loses `-sS` and `-O`.

Reuse results. Do not re-scan a host that's already in `ports.txt` unless something
changed.

## MCP is registered in this project only

`opencode.json` in this folder wires the `kali` server. The user's global OpenCode config
(`C:\Users\ozate\.config\opencode\opencode.json`) has its own MCPs and is **not** to be
edited from here. Keep this workspace self-contained on D:.