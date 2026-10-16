# Bug Bounty Workspace

Authorized bug bounty and vulnerability research. Tools live here; nothing is built.

This file holds **hard rules and routing only**. Detail lives in `docs/` and
`research/notes/`. Keep it that way — an agent loads this file on every task,
including tasks that need none of the detail.

## Routing table — read before working

| The task is | Read first |
| --- | --- |
| Fresh clone, or "is this set up" / a tool is missing | the **`doctor` skill**, then `docs/environment.md` |
| A target URL or hostname is named | the **`scope` skill** — see below. It normalizes, scaffolds, and gates |
| Anything that touches a host | `recon/<target>/scope.md`. **Non-negotiable.** |
| The whole engagement shape, or where a gate stops you | `docs/workflow.md` |
| About to run recon | `docs/recon-playbook.md` — the runnable pipeline |
| Picking a tool, setting a rate flag, choosing a wordlist | `docs/toolchain.md` |
| Kali / WSL / MCP broken, tool missing, wordlist path | `docs/environment.md` — process model, recovery, verified tool inventory |
| Running bash through PowerShell | `docs/environment.md` § "Writing bash through PowerShell" |
| Scaffolding a target folder by hand | `.\scripts\new-target.ps1 -Target <host>` |
| Checking the setup after a clone | `.\scripts\doctor.ps1` — OK / WARN / FAIL, advisory |
| Have a finding to write up | `docs/report-writing.md` |
| Answering a methodology question | `research/notes/_index.md` — check before researching |
| Running tools, shell commands, probes | `research/notes/_lessons.md` — real mistakes |
| Checking a source URL or feed | `research/notes/sources.md` — access routes and traps |
| A question that matches a CVE | `research/notes/cve-driven-testing.md` |
| Web vuln technique landscape | `research/notes/portswigger-techniques.md` |
| Testing methodology / checklist | `research/notes/tbhm-methodology.md` |

Full doc index, including the research notes: `docs/index.md`.

**Commands.** `.opencode/commands/` are thin delegates to the skill and docs:

| Command | Does |
| --- | --- |
| `/doctor` | Load the `doctor` skill, check the setup and offer fixes |
| `/scope <url>` | Load the `scope` skill and run the whole flow |
| `/recon <host>` | Same, resuming at active recon — scope already confirmed |
| `/report <host>` | Turn a confirmed bug into a submittable report |
| `/lookup <topic>` | Research protocol — check the index, verify sources, write the note |

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
- **This repo is public. Nothing under `recon/<target>/` ever leaves the machine.**
  That includes `scope.md`, `notes.md`, and `findings/` — they hold unpublished
  recon and name the private program that pays. `.gitignore` blanket-ignores the
  whole target folder; don't un-ignore it, and check
  `git status --ignored --short recon/` before every commit.

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

The durable record of a target lives on disk, not in git. **Everything** under
`recon/<target>/` is gitignored — `scope.md`, `notes.md`, `findings/`, and every
raw dump — because this repo is public. `recon/README.md` stays tracked.

## Environment rules

- **If a `kali` MCP tool fails, it is almost never your command.** The MCP is
  two processes — an HTTP API server inside Kali (`127.0.0.1:5000`) that executes
  commands, and a stdio bridge OpenCode spawns. Nothing supervises the API
  server, so it can be dead while everything is configured correctly. Run
  `.\scripts\check-kali.ps1 -Fix`; never hand-roll a restart.
- **Prefer `execute_command` over the named `*_scan` MCP tools.** Four of them
  (`metasploit_run`, `hydra_attack`, `john_crack`, `enum4linux_scan`) fail
  outright because their dependencies aren't installed here, and `john_crack`
  defaults to a wordlist path that doesn't exist. Full tool list, process model,
  and the `pgrep` health-check trap: **`docs/environment.md`**.
- **`execute_command` runs under `/bin/sh` (dash), not bash.** `source` fails;
  use `. /etc/profile.d/gobin.sh`. `&&`, `||`, `$()` and pipes are fine. The
  Go tools aren't on `sh`'s PATH, so prefix that dot-source before using
  `gau`, `waybackurls`, `gf`, `jaeles`.
- **Tool availability: assume nothing.** Not everything is installed, and
  `server_health`'s `tools_status` is **not** a presence check — use
  `command -v`. The verified inventory is in `docs/environment.md`; check it
  before planning around any tool. Install more with
  `.\scripts\setup-kali.ps1 -Packages <name>`.
- **Kali inherits the whole Windows PATH** via WSL interop, including paths with
  spaces. Windows binaries are callable by bare name. Core tools still resolve
  to `/usr/bin` first, but run `which -a <tool>` if one behaves oddly.
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
- **`/mnt/d` is slow.** Build in the per-target scratch dir inside Kali
  (`sh "/mnt/d/Bug Bounty/scripts/scratch.sh" init <host>`), then copy finished
  files into the target folder. Thousands of small writes across the
  cross-filesystem mount crawl. Never work in a shared `/tmp/work` and never
  `cp /tmp/work/*.txt "$OUT/"` — that files one target's results under another.
- **Never write multi-line bash inline through PowerShell.** `wsl -e bash -lc
  "..."` puts the string through PowerShell's parser, so `&&`, `||`, `$()` and
  `<` break in ways that look like bash errors. For anything beyond one simple
  command, write a script file (no BOM) and pipe it to `bash -s`. Working recipe
  in `docs/environment.md`.
- **The `kali` MCP is registered in this project only.** `opencode.json` here
  wires it. The global config — `%USERPROFILE%\.config\opencode\opencode.json` —
  has its own MCPs and is **not** to be edited from here. Keep this workspace
  self-contained on D:.

Full environment reference — process model, recovery commands, wordlist paths,
nmap caveats, the complete tool inventory: **`docs/environment.md`**.

## House conventions

- Keep this file under ~200 lines and make it pointers, not an encyclopedia.
- Use MUST/SHOULD/NEVER and be specific — "use `raft-medium-directories.txt`",
  not "use a good wordlist". Vague rules don't get followed.
- Never cache raw PDFs or scraped HTML; convert to a dated Markdown note.
- Append to `notes.md` files; don't rewrite history.
- Two rules get violated most: **look it up, don't recall it**, and **stay in
  your lane** — if you notice a real problem adjacent to the task, report it
  and ask. Unrequested deep-dives waste the session.