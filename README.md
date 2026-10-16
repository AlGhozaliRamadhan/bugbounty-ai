# Bug Bounty AI

A template for running authorized bug bounty work with a local AI coding agent.
Works with Claude Code, OpenCode, Codex, Cursor, or anything else that reads a
markdown instruction file and can shell out.

The agent drives [Kali](https://kali.org) over MCP. Kali holds the tools; the
workspace holds the rules about which tool runs, in what order, against what,
and what gets written down afterward. Everything runs on your own machine. There
is no hosted piece and nothing is sent anywhere.

## It learns from its own mistakes

`research/notes/_lessons.md` holds ten numbered lessons, each one written after
something actually went wrong. A `HEAD` request that answered for a 404. A `200`
that was an error page wearing a success status. A source URL that 404'd the
next time somebody followed it. Each entry carries the cause and the fix, because
a lesson you cannot act on is just an anecdote.

Some of them changed the tooling. One target's `subfinder` output got read into
another target's run, because both sessions shared `/tmp/work` and both wrote a
file called `sf.txt`. Nothing errored. The file had a current mtime and a
plausible line count, and the pipeline carried the wrong hostnames all the way to
the results. The fix was `scripts/scratch.sh`: one scratch directory per target,
refused if it already has content, and every results file checked against the
target's registrable domain before it gets filed.

That failure mode reads like a clean run from the outside, which is exactly why it
needed a script rather than a reminder. The lesson file is what gets read once.
The script is why it does not happen twice.

`AGENTS.md` routes every agent to that file before it touches a tool, and
`docs/toolchain.md` records which tool does what so the choice is not improvised
each session.

## Why the rules exist

An agent driving a security toolchain fails in ways that have nothing to do with
the toolchain:

- It recons hosts nobody authorized. Scope is a legal boundary, and a subdomain
  that *looks* related is not the same as one the program listed.
- It answers from memory. Vulnerability knowledge goes stale quietly, and
  confident recall is worse than an honest gap because you cannot tell them apart
  from the outside.
- It loses the thread. Ten minutes of enumeration gives you hundreds of files and
  no record of which lead was worth following.
- It writes findings like a form letter, and the report is the part that gets you
  paid.

Each one gets a mechanism rather than a prompt: a scope gate that stops the run,
a research protocol that wants a citation, one folder per hostname, and a report
structure reviewed before submission.

## What it will not do

- Nothing runs unattended against a live host. You are in the loop on every scan.
- Scope is never inferred. A hostname that is not in `recon/<host>/scope.md` is
  out of scope.
- No exploit generation. Proving impact with the smallest sample that shows it is
  the job; weaponizing it and leaving artifacts behind is not.
- No target data in this repository.

## Using this template

Use the template button on GitHub, or clone it and delete what you do not need.
Then run one command.

```powershell
.\scripts\doctor.ps1
```

It checks that the required files are present, that `recon/` is actually
gitignored, that `opencode.json` points at this checkout rather than the machine
the template was authored on, and that WSL and the Kali bridge are reachable. Each
line is `OK`, `WARN`, or `FAIL`, and nothing stops the run: a missing wordlist is
information, not a reason to fail somebody's setup.

```
Repository
  OK    all 20 required files present

Git safety
  OK    recon/ is ignored, target data cannot be staged
  OK    no target data tracked

Configuration
  WARN  bridge path points at a different machine
              opencode.json has:  /mnt/d/Bug Bounty/scripts/kali-mcp-bridge.sh
        this checkout is:   /mnt/c/Users/you/bugbounty-ai
```

Two things a fresh clone almost always needs. The doctor will name both:

- **Fix the path.** `opencode.json` ships pointing at `D:\Bug Bounty`, which Kali
  sees as `/mnt/d/Bug Bounty`. Edit the `command` array to match wherever you
  cloned it. If your path has no space in it you can drop the quoting throughout
  the docs too.
- **Install Kali into WSL**, if you have not already. The helpers assume a distro
  named `kali-linux`, running as root.

`.\scripts\check-kali.ps1` goes deeper. It probes the MCP API server with a real
command round-trip and inventories all 22 tools, which takes a while because each
one costs a WSL hop.

Replace this README once you are set up. It describes the template, and your fork
is yours.

### Which agent am I running?

The rules are portable. Only the wiring is agent-specific.

| File | What it is | Who needs it |
| --- | --- | --- |
| `AGENTS.md` | The rules and the routing table | Everyone. This is the portable instruction format. |
| `CLAUDE.md` | Pointer to `AGENTS.md` | Claude Code, which looks for this filename |
| `opencode.json` | Wires the `kali` MCP server | OpenCode |
| `.opencode/commands/` | `/doctor`, `/scope`, `/recon`, `/report`, `/lookup` | OpenCode |
| `.opencode/skills/` | The `doctor` and `scope` workflows | OpenCode, or port them |

If your agent wants a different filename, add a stub that says "read
`AGENTS.md`" and leave the rules themselves in one place.

With no slash-command support, the scope and recon workflows are written out as
numbered phases in [`docs/recon-playbook.md`](docs/recon-playbook.md), and
`scripts/doctor.ps1` runs on its own with no agent involved.

## Layout

```
AGENTS.md              the rules + routing table. Portable, read by every agent.
CLAUDE.md              pointer to AGENTS.md
opencode.json          wires the kali MCP server
.opencode/             commands and skills
docs/                  operational knowledge: playbooks, toolchain, report craft
research/notes/        external knowledge: dated, sourced, freshness-tracked
recon/<hostname>/      one folder per host. Local only, never committed.
scripts/               PowerShell helpers, plus the Kali-side scratch guard
```

`docs/` and `research/notes/` are kept apart on purpose. `docs/` is what we
decided: how recon runs, which tool does what, how a report gets written. It
changes when the practice does. `research/notes/` is what the outside world
decided: vulnerability classes, CVE applicability, where the sources actually
live. It changes when an upstream source does, which is why every note wants a
date and a URL.

## Quick start

```powershell
# 1. Check the setup. Run this first, every time.
.\scripts\doctor.ps1

# 2. Scaffold a target folder, named after the hostname
.\scripts\new-target.ps1 -Target api.example.com -Program "HackerOne #12345"

# 3. Fill in recon\api.example.com\scope.md BEFORE touching the host

# 4. Recon through the kali MCP, writing only into the target folder.
#    Tool inventory and wordlist paths: docs\environment.md

# 5. Log what you did, including the dead ends, in recon\api.example.com\notes.md
```

Tooling is not fully installed by default. `docs\environment.md` lists what is
verified present and what is missing. Add more with
`.\scripts\setup-kali.ps1 -Packages <name>`.

On OpenCode the same workflows run by name:

| Command | Does |
| --- | --- |
| `/doctor` | Check the setup and fix what is safe to fix |
| `/scope <url>` | Normalize the target, scaffold the folder, fill the gate, stop for confirmation |
| `/recon <host>` | Resume at active recon, scope already confirmed |
| `/report <host>` | Turn a confirmed bug into a submittable report |
| `/lookup <topic>` | Research protocol: check the index, verify sources, write the note |

## The scope gate

`recon/<host>/scope.md` is read first and passed before anything touches a host.
It records what the program authorizes, what it excludes, and what it will not
pay for.

The rule that gets broken most often: a subdomain found during recon is not in
scope because you found it. Most programs exclude unlisted hosts, third-party
SaaS, and anything under a different registrable domain.

## Targets stay local

Everything under `recon/<host>/` is gitignored: `scope.md`, `notes.md`,
`findings/`, and every raw dump. Unpublished recon and the name of the program
paying for the finding are not yours to publish.

```powershell
git status --ignored --short recon/   # confirm a target folder stays ignored
```

Public here is the method. The templates under `docs/templates/` are meant to be
copied.

Two habits carry over to any workspace:

1. Look it up, don't recall it. Check `research/notes/_index.md` first, and say
   whether an answer came from a fresh source or from memory.
2. Stay in your lane. Found a real problem next to the task? Report it and ask.

## Authorization

Use this against hosts you are explicitly authorized to test, under that
program's terms. The defaults in `AGENTS.md` assume a private program: no DoS, no
social engineering, no persistence, no leftover artifacts, respect the stated
rate limits. Those are a floor. A program's own rules win wherever they are
stricter.
