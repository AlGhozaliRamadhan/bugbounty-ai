---
name: doctor
description: Verify that a Bug Bounty AI checkout is ready to use. Load when the operator just cloned the repo, asks "is this set up", "does this work", "am I ready to start", asks to check the environment, or reports that a kali MCP tool is failing or that a tool is missing. Runs scripts/doctor.ps1, interprets the OK/WARN/FAIL output, and fixes what it can.
---

# Environment check

Confirms a checkout is ready before any recon runs. Cheap, offline, and worth
running first every time, because a fresh clone is broken in the same two ways and
both are quiet.

## The one thing you must not do

**Never report "all set" when a check printed `FAIL`.** The script distinguishes
`WARN` from `FAIL` on purpose:

- `WARN` means the environment is incomplete but recon can still run. Missing
  wordlists, no WSL yet, a path that needs editing. Report it and move on. Do not
  stop the session, and do not offer to install eleven packages unprompted.
- `FAIL` means something is unsafe or structurally wrong. There is exactly one
  `FAIL` that matters: `recon/` is not gitignored, or target data is already
  tracked. That one stops everything. Tell the operator plainly and do not stage,
  commit, or push until it is resolved.

A `SKIP` line means the check did not apply. Say it was skipped and continue.
Do not report a skipped check as a passing one.

## Step 1 — Run it

```powershell
.\scripts\doctor.ps1
```

Add `-SkipKali` on a machine with no WSL yet. Add `-Strict` only for CI.

Use `execute_command` if the shell is not PowerShell, but the script is
PowerShell, so this is normally a direct `shell` call. Read the exit code: `0` is
ready with at most warnings, `1` means a blocking `FAIL` is present.

## Step 2 — Report

Lead with the verdict, then the things that need action. Do not paste the whole
output back; the operator can see it.

Something like: "Ready. Two warnings: the bridge path in `opencode.json` still
points at the original machine, and WSL isn't installed, so recon won't work
until you add it." That is useful. "All checks completed successfully with the
following results" is not.

Name the specific fix for each warning. The script prints the command, so use it
rather than describing the fix in your own words.

## Step 3 — Fix what is safe

Offer these, don't do them unasked:

| Check | Fix |
| --- | --- |
| `mcp-server` missing | `.\scripts\setup-kali.ps1` |
| WSL distro absent | `wsl --install kali-linux --no-launch` |
| kali API server down | `.\scripts\check-kali.ps1 -Fix` |
| bridge path mismatch | edit the `command` array in `opencode.json` |
| recon/ not ignored | restore `recon/*/*` in `.gitignore`, then re-run |

Editing `opencode.json` is a real config change, so ask first. Restoring a
`.gitignore` rule is a safety fix, so do it and say so.

If the operator declines every fix, that is a legitimate answer. Report the
remaining warnings and stop. An incomplete environment still scaffolds targets
and writes notes.

## What this does not cover

Tool inventory, the MCP round-trip probe, and wordlist paths live in
`.\scripts\check-kali.ps1`, which is slower because it runs 22 commands inside
WSL. `doctor.ps1` deliberately points at it instead of duplicating the list.

If a kali MCP tool call fails during a recon session, that is
`check-kali.ps1`, not this skill. See `docs/environment.md`.
