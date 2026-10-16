# Bug Bounty Workspace

Authorized bug bounty and vulnerability research. Tools live here; nothing is built.

**This repository is local-only and must stay that way unless you explicitly say
otherwise.** There is no git remote configured, and there must never be a *public*
one — this tree will hold recon data, findings, and working PoCs. If you add a
remote, make it private and confirm it is private before the first push.

## Start here

Every agent reads [`AGENTS.md`](AGENTS.md) first. It holds the hard rules and a
routing table. This file is the human orientation.

## Layout

```
AGENTS.md              hard rules + routing table. Read first, every task.
CLAUDE.md              pointer to AGENTS.md (Claude Code only)
opencode.json          wires the `kali` MCP server, this project only
docs/                  how we work here — playbooks, toolchain, report craft
research/notes/        what we learned out there — dated, sourced, freshness-tracked
recon/<hostname>/      one folder per host, named exactly after the hostname
scripts/               PowerShell helpers
```

`docs/` and `research/notes/` are deliberately separate:

- **`docs/`** — operational knowledge. How recon runs here, which tool does what,
  how a report gets written. Changes when *we* change our practice.
- **`research/notes/`** — external knowledge. Vulnerability classes, source
  access routes, CVEs. Changes when the *outside world* changes. Every note
  carries a date and the URL it came from.

## Quick start

```powershell
# 1. Confirm the Kali environment is alive before anything else
.\scripts\check-kali.ps1          # add -Fix to start the MCP API server if it's down

# 2. Scaffold a target folder (named after the hostname)
.\scripts\new-target.ps1 -Target api.example.com -Program "HackerOne #12345"

# 3. Fill in recon\api.example.com\scope.md BEFORE testing anything.
#    This is the scope gate. It is not a formality.

# 4. Run recon using the kali MCP, writing into the target folder only.
#    Tool inventory and wordlist paths: docs\environment.md

# 5. Log what you did, including dead ends, in recon\api.example.com\notes.md
```

Tooling is not fully installed by default — `docs\environment.md` lists what is
verified present and what is absent. Add more with
`.\scripts\setup-kali.ps1 -Packages <name>`.

## What is tracked in git

Tracked — the durable record:

- `AGENTS.md`, `CLAUDE.md`, `opencode.json`, `.gitignore`, `.gitattributes`
- everything under `docs/` and `research/notes/`
- `recon/<host>/scope.md`, `notes.md`, and `findings/`

Ignored by design — bulky, regenerable, or sensitive:

- raw tool output (`subdomains.txt`, `urls.txt`, `ports.txt`, `live.txt`)
- `screenshots/`, per-target `scripts/` and `poc/`
- anything that looks like a credential: `*.key`, `*.pem`, `*cookie*.txt`,
  `*session*.json`, `.env`, `credentials*`

**Never commit a live token.** Session cookies and bearer tokens belong in a
gitignored local file, not in `notes.md`.

## The two rules that get broken most

1. **Look it up, don't recall it.** Bug bounty knowledge goes stale silently.
   Check `research/notes/_index.md` before researching, and state whether any
   answer came from a fresh lookup or from memory.
2. **Stay in your lane.** If you notice a real problem adjacent to the task,
   report it and ask. Don't expand into it.