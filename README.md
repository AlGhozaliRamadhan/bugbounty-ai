# Bug Bounty AI

A workspace for running authorized bug bounty work with a local AI coding agent.
Works with Claude Code, OpenCode, Codex, Cursor, or anything else that reads a
markdown instruction file and can shell out.

The agent drives [Kali](https://kali.org) over MCP. Kali holds the tools; this
repo holds the rules about which tool runs, in what order, against what, and
what gets written down afterward. Everything runs on your own machine, and
nothing is sent anywhere.

## Why an agent needs scaffolding, not a better model

An agent pointed at a bug bounty program fails in ways that have nothing to do
with its intelligence:

**It recons hosts nobody authorized.** The program lists the assets it wants
tested. Recon finds more, and more is not the same as in scope. Third-party SaaS,
marketing subdomains, an acquisition's old infrastructure: all of it resolves and
all of it can be out of scope. The agent has no way to tell a listed hostname from
a plausible one, so it picks, and the legal boundary is where it guesses.

**It answers from memory.** "How does this auth flow work" gets a confident
paragraph with no source. Techniques get patched. Advisory URLs 404. OAuth flows
change between library versions. The reply looks identical whether it came from
the current advisory or from a training set that predates the CVE, which means
nobody, including the agent, can tell which one they are reading.

**It loses the thread.** Ten minutes of passive enumeration gives you a few
hundred subdomains and a directory of files with names like `sf.txt`. Which lead
was worth following? What did the last session already try? What came back empty
after twenty minutes and shouldn't be retried? None of that survives, so the next
session starts from zero and often repeats the same dead end.

**It writes findings like a form letter.** This is the one that costs money. The
report is the deliverable, and a report that reads like every other report gets
triaged, not paid.

## What you actually get

44 files, and each group answers one of those four problems.

| | What it does |
| --- | --- |
| `AGENTS.md` | The rules, plus a routing table that tells an agent which of the other 43 files to open for the task in front of it |
| `recon/<host>/scope.md` | The scope gate. Read first, passed before anything touches a host. A hostname that is not in this file is out of scope, and nothing infers otherwise |
| `research/notes/` | 15 notes on vulnerability classes, CVE applicability, and where the research sources actually live. Each dated, because the sources move |
| `research/notes/_lessons.md` | 10 recorded mistakes, each with its cause and its fix |
| `docs/` | 8 operational docs: the runnable recon pipeline, which tool for which job, how a report gets written |
| `scripts/doctor.ps1` | One command that checks the whole setup and tells you what is actually wrong |
| `scripts/setup-kali.ps1` | Installs 33 recon and wordlist packages plus the official Kali MCP server, and starts it |
| `scripts/scratch.sh` | Prevents one target's output being filed under another |

Three design choices worth knowing about, because they are the difference
between this and a folder of prompts:

**The rules live in one file.** `AGENTS.md` is the portable instruction format.
Claude Code, OpenCode, Codex and Cursor all read it. The agent-specific files
(`CLAUDE.md`, `opencode.json`, `.opencode/commands/`) are wiring, never copies of
the rules. Fork the wiring if you must, never the rules.

**The scope gate is a stop, not a suggestion.** The agent runs passive
enumeration freely, because that hits third-party APIs and certificate logs
rather than the victim. Port scanning, HTTP probing and fuzzing halt until you
confirm the host is authorized. Only you know where the program's boundary sits.

**It learns from its own mistakes.** Ten lessons sit in
`research/notes/_lessons.md`, and `AGENTS.md` routes every agent to that file
before it touches a tool. Some of those lessons changed the code. One target's
`subfinder` output got read into another target's run, because both sessions
shared `/tmp/work` and both wrote a file called `sf.txt`. Nothing errored. The
file had a current mtime and a plausible line count, and the wrong hostnames
carried all the way to the results. `scripts/scratch.sh` exists to make that
impossible: one scratch directory per target, refused if it already has content,
and every results file checked against the target's registrable domain before it
gets filed. That failure reads like a clean run from the outside, which is
exactly why it needed a script rather than a reminder.

## Install

### Requirements

| | |
| --- | --- |
| OS | Windows 10 or 11, with WSL 2 |
| Shell | PowerShell 5.1 or PowerShell 7+ |
| Disk | `seclists` alone is 1.9 GB installed. `setup-kali.ps1 -Full` pulls `kali-linux-full` at roughly 25 GB |
| Agent | Anything that reads `AGENTS.md` and can run shell commands |

Linux and macOS work with the docs and notes. The PowerShell helpers and the
`kali` MCP wiring are Windows-specific, because that is where this was built.

### Steps

**1. Get Kali into WSL.** One time. If the distro is already there, skip it.

```powershell
wsl --install kali-linux --no-launch
```

Add `--location D:\WSL\Kali` to put the virtual disk somewhere other than `C:`.
WSL is slow across `/mnt/d`, and a Kali image is large. Restart Windows after this
if it asks.

**2. Clone and install the toolset.** This takes a while. It installs 33 packages
across recon, web probing, wordlists and plumbing, then installs `mcp-kali-server`
and starts it.

```powershell
git clone https://github.com/AlGhozaliRamadhan/bugbounty-ai.git
cd bugbounty-ai
.\scripts\setup-kali.ps1
```

Kali is rolling-release, so package names drift. Missing ones are listed at the
end rather than aborting the run. Add specific ones with
`.\scripts\setup-kali.ps1 -Packages httpx,nuclei`.

**3. Check it.**

```powershell
.\scripts\doctor.ps1
```

```
Repository
  OK    all 23 required files present

Git safety
  OK    recon/ is ignored, target data cannot be staged
  OK    no target data tracked

Configuration
  WARN  bridge path points at a different machine
              opencode.json has:  /mnt/d/Bug Bounty/scripts/kali-mcp-bridge.sh
        this checkout is:   /mnt/c/you/bugbounty-ai
```

Every line is `OK`, `WARN`, `FAIL` or `SKIP`, and nothing stops the run. A missing
wordlist is information, not a reason to fail your setup. Add `-SkipKali` before
you have WSL, and `-Strict` for CI.

**4. Fix the warning.** `opencode.json` ships pointing at the machine it was
authored on. Edit the `command` array so the bridge path matches your checkout. If
your path has no space in it you can drop the quoting throughout the docs too.

That `recon/ is ignored` line is the one that matters. It means the next
`git add .` cannot stage a real target's `scope.md`, `notes.md` or `findings/`.
Those hold unpublished recon and name the program paying for the finding.

**5. Point your agent at the folder.** Read
[`docs/environment.md`](docs/environment.md) for how the MCP is wired and what to
do when a tool call fails, then open the workspace and start.

## What it will not do

- Nothing runs unattended against a live host. You are in the loop on every scan.
- Scope is never inferred.
- No exploit generation. Proving impact with the smallest sample that shows it is
  the job. Weaponizing it and leaving artifacts behind is not.
- No target data in this repository.

## Which agent am I running?

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

## Day to day

```powershell
# 1. Check the setup. Cheap, run it first every time.
.\scripts\doctor.ps1

# 2. Scaffold a target folder, named after the hostname
.\scripts\new-target.ps1 -Target api.example.com -Program "HackerOne #12345"

# 3. Fill in recon\api.example.com\scope.md BEFORE touching the host

# 4. Recon through the kali MCP, writing only into the target folder.
#    Tool inventory and wordlist paths: docs\environment.md

# 5. Log what you did, including the dead ends, in recon\api.example.com\notes.md
```

On OpenCode the same workflows run by name:

| Command | Does |
| --- | --- |
| `/doctor` | Check the setup and fix what is safe to fix |
| `/scope <url>` | Normalize the target, scaffold the folder, fill the gate, stop for confirmation |
| `/recon <host>` | Resume at active recon, scope already confirmed |
| `/report <host>` | Turn a confirmed bug into a submittable report |
| `/lookup <topic>` | Research protocol: check the index, verify sources, write the note |

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
