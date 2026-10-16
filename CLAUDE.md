# CLAUDE.md

@AGENTS.md

## What this file is

**All workspace rules live in `AGENTS.md`. This file is a pointer, not a
second copy.**

Claude Code only auto-loads `AGENTS.md` when a project has **no** `CLAUDE.md`.
Because this file exists, it must import the real rules explicitly — the `@`
above does that. Keep it that way; a duplicate copy drifts and the two files
contradict each other, which produces unpredictable behavior.

`AGENTS.md` is the tool-agnostic standard and is also read natively by Codex,
GitHub Copilot, opencode, Cursor, Jules, and Amp. **Edit `AGENTS.md`, not this
file.**

## Before starting work

1. Read `AGENTS.md` — it holds the scope gate, the recon layout rules, the
   research protocol, and the environment rules you need to avoid the obvious
   failures.
2. Check `docs/index.md` — the full map of operational docs and research notes.
3. Check `recon/<target>/scope.md` — it defines what is in scope for that host.
   Nothing touches a host before this passes.
4. Check `research/notes/_index.md` — the topic may already be researched.
5. Read `research/notes/_lessons.md` if you're about to run tooling, shell
   commands, or network probes. It records real mistakes that are easy to
   repeat, including the PowerShell/bash quoting trap and the
   status-code-vs-content probe trap.

## Slash commands

If your harness supports opencode-style project commands, four exist in
`.opencode/commands/` and each enforces the gate its task depends on:

| Command | Does |
| --- | --- |
| `/doctor` | Check the setup with `scripts/doctor.ps1`, offer the safe fixes |
| `/scope <host>` | Scaffold `recon/<host>/` and complete the scope gate |
| `/recon <host>` | Run the playbook, with scope and rate gates enforced |
| `/report <host>` | Turn a confirmed bug into a submittable report |
| `/lookup <topic>` | Research protocol — check the index, verify sources, write the note |

## Two rules that get violated most

- **Look it up, don't recall it.** Bug bounty knowledge goes stale silently.
  Verify against the sources listed in `AGENTS.md` and state whether an answer
  came from a fresh lookup or from memory.
- **Stay in your lane.** If you notice a real problem adjacent to the task,
  report it and ask — don't expand into it. Unrequested deep-dives waste the
  session and can be in an unwanted direction.

## House conventions

- Keep `AGENTS.md` under ~200 lines and make it pointers, not an encyclopedia.
  Detail belongs in `docs/` (how we work here) or `research/notes/` (what we
  learned out there).
- **Never copy a fact into two places.** `AGENTS.md` and `CLAUDE.md` must never
  hold the same rule, and `AGENTS.md` must never restate something
  `docs/environment.md` already documents. Duplicated facts drift apart, and
  then agents get contradictory instructions. Point instead.
- Use MUST/SHOULD/NEVER and be specific — "use `raft-medium-directories.txt`",
  not "use a good wordlist". Vague rules don't get followed.
- Never cache raw PDFs or scraped HTML; convert to a dated Markdown note.
- Append to `notes.md` files; don't rewrite history.