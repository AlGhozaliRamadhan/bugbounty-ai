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

1. Read `AGENTS.md` — it has the scope rules, recon layout, WSL/Kali setup, and
   the research protocol.
2. Check `research/notes/_index.md` — the topic may already be researched.
3. Check `recon/<target>/scope.md` — it defines what is in scope for that host.
4. Read `research/notes/_lessons.md` if you're about to run tooling, shell
   commands, or network probes. It records real mistakes that are easy to
   repeat, including the PowerShell/bash quoting trap and the
   status-code-vs-content probe trap.

## Two rules that get violated most

- **Look it up, don't recall it.** Bug bounty knowledge goes stale silently.
  Verify against the sources listed in `AGENTS.md` and state whether an answer
  came from a fresh lookup or from memory.
- **Stay in your lane.** If you notice a real problem adjacent to the task,
  report it and ask — don't expand into it. Unrequested deep-dives waste the
  session and can be in an unwanted direction.

## House conventions

- Keep `AGENTS.md` under ~200 lines and make it pointers, not an encyclopedia.
  Detail belongs in `research/notes/`.
- Use MUST/SHOULD/NEVER and be specific — "use `raft-medium-directories.txt`",
  not "use a good wordlist". Vague rules don't get followed.
- Never cache raw PDFs or scraped HTML; convert to a dated Markdown note.
- Append to `notes.md` files; don't rewrite history.