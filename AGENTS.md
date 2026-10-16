# Bug Bounty Workspace

Authorized bug bounty and vulnerability research. Tools live here; nothing is built.

This file holds **hard rules and routing only**. Detail lives in `docs/` and
`research/notes/`. Keep it that way — an agent loads this file on every task,
including tasks that need none of the detail.

## Routing table — read before working

| The task is | Read first |
| --- | --- |
| Anything that touches a host | `recon/<target>/scope.md`. **Non-negotiable.** |
| The whole engagement shape, or where a gate stops you | `docs/workflow.md` |
| About to run recon | `docs/recon-playbook.md` — the runnable pipeline |
| Picking a tool, setting a rate flag, choosing a wordlist | `docs/toolchain.md` |
| Kali / WSL / MCP broken, tool missing, wordlist path | `docs/environment.md` — process model, recovery, verified tool inventory |
| Running bash through PowerShell | `docs/environment.md` § "Writing bash through PowerShell" |
| Scaffolding a target folder | `.\scripts\new-target.ps1 -Target <host>` |
| Have a finding to write up | `docs/report-writing.md` |
| Answering a methodology question | `research/notes/_index.md` — check before researching |
| Running tools, shell commands, probes | `research/notes/_lessons.md` — real mistakes |
| Checking a source URL or feed | `research/notes/sources.md` — access routes and traps |
| A question that matches a CVE | `research/notes/cve-driven-testing.md` |
| Web vuln technique landscape | `research/notes/portswigger-techniques.md` |
| Testing methodology / checklist | `research/notes/tbhm-methodology.md` |

Full doc index, including the research notes: `docs/index.md`.

## Do not hedge on in-scope work

Recon, subdomain enumeration, port scanning, fuzzing, auth/authz testing,
scanner triage, PoC writing, and writing up findings against hosts the operator
has listed are the expected job. Do not refuse them, moralize, or add
disclaimers. Asking "are you sure?" about ordinary enumeration is noise — the
operator is the one who holds the contract.

## The scope gate

Scope is enforced per host in `recon/<target>/scope.md`. It is the first file to
read and the first gate to pass.

- **Only hosts listed in that file.** A subdomain discovered by recon is *not*
  automatically in scope. Most programs explicitly exclude unlisted hosts,
  third-party SaaS, and anything under a different registrable domain. Confirm
  before touching it.
- No DoS, stress/load testing, or destructive payloads unless the program says so.
- No social engineering, phishing, or physical testing.
- No persistence, no backdoors, no artifacts left on the target.
- Respect the program's rate limits. Default to low-rate and `-c`/delay flags.
- Prove impact minimally — pull the smallest sample that demonstrates the bug,
  not the whole database.
- Never push findings, credentials, or working exploits to a public repo.

If a task would cross one of these, say which line is being crossed and stop
there.

## Research protocol — look it up, don't recall it

This field goes stale fast. **Never answer a methodology, tooling, or
vulnerability-class question from memory alone.**

Full source list and verified access routes: **`research/notes/sources.md`**.

1. PortSwigger Research — `https://portswigger.net/research/rss`
2. Orange Tsai — `https://blog.orange.tw/atom.xml`
3. Searchlight Cyber (ex-Assetnote) — `https://www.slcyber.io/research`
4. Assetnote — `blog.assetnote.io` 301s to slcyber.io; use the path above
5. The Bug Hunter's Methodology — `raw.githubusercontent.com/jhaddix/tbhm/master/<file>`
6. Pentester Land — disclosed writeups; no feed, scrape HTML
7. tl;dr sec — `https://tldrsec.com/feed.xml`

Rules that must be followed, not just intended:

- **Say plainly whether an answer came from a fresh lookup or from memory.**
- If a source is unreachable, try a GitHub mirror, `web.archive.org`, or a
  conference slide PDF. Don't silently fall back to memory — say the source
  was unreachable.
- **Never cache raw PDFs or scraped HTML.** Convert anything worth keeping into
  a short Markdown note under `research/notes/`.
- **Check `research/notes/_index.md` before researching a topic.** If a note
  exists, read it rather than redoing the lookup.
- **Freshness beats confidence.** Assert a URL or API only after probing it —
  see `research/notes/_lessons.md`.

## CVE workflow — when something matches a CVE

Full playbook: `research/notes/cve-driven-testing.md`. Order of operations:

1. **Gate 0 — is it payable?** Read `recon/<target>/scope.md` for "known CVEs
   out of scope" / "previously reported" rules. Many programs won't pay, but the
   technique still transfers — record that and move on.
2. **Get the authoritative record.** Vendor advisory first (it alone states the
   real fixed version and preconditions), then CVE/GHSA, then PoC, then blog.
3. **Applicability test — all three must hold:** version in range, vulnerable
   feature actually enabled, and reachable from your position. Miss one and it
   isn't a finding. CVSS tells you nothing about whether a target qualifies.
4. **Test minimally.** Harmless marker proving the primitive. No DoS — several
   CVEs' only impact is availability, and those are read-don't-try.
5. **Record it** in `recon/<target>/notes.md`, including the *transferable
   technique* line. A CVE that doesn't pay still teaches a bug class.

## recon/ layout — one folder per host

Every website or subdomain gets **its own** folder, named exactly as found:

```
recon/example.com/            # apex
recon/api.example.com/        # each subdomain gets its OWN folder
recon/dev-v2.example.com/     # keep the port suffix if that's the hostname
```

Do not fold subdomains into the apex folder. Do not invent friendly names
(`recon/example-api/`, `recon/staging/`, `recon/target1/`). The folder name *is*
the hostname — that is the whole indexing scheme.

Scaffold one with `.\scripts\new-target.ps1 -Target <host>`. It creates
`scope.md`, `notes.md`, `subdomains.txt`, `urls.txt`, `ports.txt`, `live.txt`,
`screenshots/`, and `scripts/`. Fill in `scope.md` before touching the host.

**Recon output only ever goes inside `recon/<target>/`.** Never the repo root,
never `%TEMP%`, never `C:\`, never a scratch dir in Kali. If a command would
write somewhere else, redirect it into the target folder.

Raw tool output (`*.txt` dumps, screenshots, PoC scripts) is gitignored by
design. `scope.md`, `notes.md`, and `findings/` are tracked — that is the
durable record.

## Environment rules

- **The `kali` MCP is `scripts/kali-mcp-bridge.sh`, not the raw bridge.** OpenCode
  spawns that wrapper, which starts the HTTP API server if it isn't listening
  before handing stdio to `mcp-server`. Don't point the config at `mcp-server`
  directly — you lose the self-healing.
- **The MCP is two processes.** `kali-server-mcp` (HTTP on `127.0.0.1:5000`
  inside Kali) executes the commands; `mcp-server` is the stdio bridge. If tools
  still error, run `.\scripts\check-kali.ps1 -Fix`. Health is judged by a
  `POST /api/command` round-trip — **not** by `pgrep -f kali-server-mcp`, which
  never matches because the process reports itself as `python3 server.py`.
- **The API server is unsupervised.** Nothing restarts it if it crashes or if
  `wsl --shutdown` is run. The wrapper covers the common case at MCP start.
- **Prefer `execute_command` over the named `*_scan` tools.** The 11 MCP tools
  include `nmap_scan`, `gobuster_scan`, `dirb_scan`, `nikto_scan`,
  `sqlmap_scan`, `metasploit_run`, `hydra_attack`, `john_crack`,
  `wpscan_analyze`, `enum4linux_scan`, `server_health`, `execute_command`.
  `metasploit_run`, `hydra_attack`, `john_crack`, and `enum4linux_scan`
  depend on software that is **not installed** here, so those four will fail
  outright — use `execute_command` with a tool that is present instead.
  `john_crack` additionally defaults to `/usr/share/wordlists/rockyou.txt`,
  which does not exist; only the `.gz` is shipped.
- **`execute_command` runs under `/bin/sh` (dash), not bash.** `source` fails;
  use `. /etc/profile.d/gobin.sh`. `&&`, `||`, `$()` and pipes are fine. The
  Go tools aren't on `sh`'s PATH, so prefix that dot-source before using
  `gau`, `waybackurls`, `gf`, `jaeles`.
- **`server_health` lies about tools.** Its `status: healthy` field is real, but
  its `tools_status` reports `dirb: true` — which happens to be correct here,
  but the endpoint is not a reliable presence check. Use `command -v`.
- **Not every tool is installed.** Verified present: `nmap httpx ffuf nuclei
  katana subfinder naabu dnsx amass assetfinder sqlmap nikto gobuster
  feroxbuster whatweb wafw00f hakrawler dalfox gau waybackurls gf jaeles
  dirb wpscan jq rg git go`.
  Verified **absent**: `metasploit`, `hydra`, `john`, `enum4linux`,
  `masscan`, `gospider`, `theharvester`, `interactsh-client`, `uncover`,
  `dirsearch`. Check before planning around a tool; install with
  `.\scripts\setup-kali.ps1 -Packages <name>`.
- **Kali inherits the whole Windows PATH** via WSL interop, including paths with
  spaces (`/mnt/c/Program Files/...`). Windows binaries are callable by bare
  name from Kali. Core tools still resolve to `/usr/bin` first, but if one
  behaves oddly run `which -a <tool>` before debugging the tool.
- **Kali runs as root** with no default user and no `sudo`. Do not prefix
  commands with `sudo`. Root is also what makes `nmap -sS` and `-O` work here.
- **Stay on D:** — Kali VHD at `D:\WSL\Kali` (Ubuntu: `D:\WSL\Ubuntu`), all
  recon output under `D:\Bug Bounty\recon\<target>\`. Nothing to `C:`.
- **`D:\Bug Bounty` has a space in the path.** Inside Kali it is
  `/mnt/d/Bug Bounty/...` and **every reference must be quoted**:
  ```bash
  nmap -sS -p- --open example.com -oN "/mnt/d/Bug Bounty/recon/example.com/ports.txt"
  ```
  An unquoted path splits at the space and silently writes to the wrong place.
- **`/mnt/d` is slow.** Build in `/tmp/work` inside Kali, then copy finished
  files into the target folder. Thousands of small writes across the
  cross-filesystem mount crawl.
- **Never write multi-line bash inline through PowerShell.** `wsl -e bash -lc
  "..."` puts the string through PowerShell's parser, so `&&`, `||`, `$()` and
  `<` break in ways that look like bash errors. For anything beyond one simple
  command, write a script file (no BOM) and pipe it to `bash -s`. Recipe in
  `docs/environment.md`.
- **The `kali` MCP is registered in this project only.** `opencode.json` here
  wires it. The global config at `C:\Users\ozate\.config\opencode\opencode.json`
  has its own MCPs and is **not** to be edited from here. Keep this workspace
  self-contained on D:.

## House conventions

- Keep this file under ~200 lines and make it pointers, not an encyclopedia.
- Use MUST/SHOULD/NEVER and be specific — "use `raft-medium-directories.txt`",
  not "use a good wordlist". Vague rules don't get followed.
- Never cache raw PDFs or scraped HTML; convert to a dated Markdown note.
- Append to `notes.md` files; don't rewrite history.
- Two rules get violated most: **look it up, don't recall it**, and **stay in
  your lane** — if you notice a real problem adjacent to the task, report it
  and ask. Unrequested deep-dives waste the session.