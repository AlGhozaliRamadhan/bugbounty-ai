# Docs index — task to document

`AGENTS.md` has the short routing table. This is the long one, including the
research notes. Check here before concluding a topic hasn't been researched.

## Skills and commands

### Skills (`.opencode/skills/`)

| Skill | Load it when |
| --- | --- |
| [scope](../.opencode/skills/scope/SKILL.md) | A target URL or hostname is named. Normalizes the input, scaffolds `recon/<host>/`, runs passive enumeration, then **stops at the scope gate** before anything touches the host. |

The `scope` skill is the canonical scope-and-recon workflow. It orchestrates
these docs rather than restating them — if a command or flag is missing from it,
fix the doc it points at, not the skill.

### Commands (`.opencode/commands/`)

| Command | Does |
| --- | --- |
| `/scope <url>` | Loads the `scope` skill, full flow from scratch |
| `/recon <host>` | Loads the `scope` skill, resuming at active recon |
| `/report <host>` | Confirmed bug → submittable report |
| `/lookup <topic>` | Research protocol — check the index, verify sources, write the note |

`/scope` and `/recon` are deliberate delegates. The workflow lives in the skill
so there is exactly one copy of it. See the no-duplication rule in
[`../CLAUDE.md`](../CLAUDE.md).

## Operational docs — `docs/`

| Doc | Read it when |
| --- | --- |
| [environment.md](environment.md) | Kali/WSL/MCP facts: the two-process model, recovery commands, verified tool inventory, wordlist paths, nmap caveats, the PowerShell→bash escaping trap. |
| [workflow.md](workflow.md) | The engagement shape: scope → recon → hunt → prove → report → retest, and where each gate stops you. |
| [recon-playbook.md](recon-playbook.md) | Runnable per-phase recon pipeline with exact commands and rate flags. |
| [toolchain.md](toolchain.md) | Which tool for which job, which rate flag to set, which wordlist to pick. |
| [report-writing.md](report-writing.md) | Severity rubric, structure, minimal-impact proof rules. |
| [templates/scope.md](templates/scope.md) | Canonical `scope.md` template. `new-target.ps1` copies this. |
| [templates/finding.md](templates/finding.md) | Canonical finding template. |

There is deliberately **no `powershell-bash.md`**. The escaping trap is short
enough that splitting it out only created a second place to forget it — it lives
in `docs/environment.md` under "Writing bash through PowerShell".

Deliberate overlap between docs: `environment.md` owns *what is installed and
where things live*; `toolchain.md` owns *which tool to pick and what flags to
set*. Neither restates the other. If you find yourself updating the same fact in
two files, one of them is in the wrong place.

## Research notes — `research/notes/`

Check [`_index.md`](../research/notes/_index.md) first — it lists every note with
its status and coverage. Direct links:

| Note | Covers |
| --- | --- |
| [_lessons.md](../research/notes/_lessons.md) | Real mistakes. **Read before running any tooling.** |
| [sources.md](../research/notes/sources.md) | Verified access routes for all research sources, and the traps that waste a lookup. |
| [tbhm-methodology.md](../research/notes/tbhm-methodology.md) | The 74-item Fast Testing Checklist. Auth/session flaw list. |
| [portswigger-techniques.md](../research/notes/portswigger-techniques.md) | 2024–2026 technique landscape: SAML bypass, desync, URL validation, CSS exfil. |
| [orange-tsai-chains.md](../research/notes/orange-tsai-chains.md) | Multi-step chain structure. Argument injection, filter chains. |
| [assetnote-searchlight.md](../research/notes/assetnote-searchlight.md) | Product-family hunting, parser targets, impact framing. |
| [cve-driven-testing.md](../research/notes/cve-driven-testing.md) | CVE playbook and verified OSV/NVD/cvelistV5 endpoints. |

## Where new knowledge goes

| You learned | Put it in |
| --- | --- |
| A technique, tool flag, or wordlist choice | `docs/recon-playbook.md` or `docs/toolchain.md` |
| A source URL, feed path, or access trap | `research/notes/sources.md` |
| A vulnerability class or bug pattern | `research/notes/<topic>.md`, dated and sourced |
| A mistake you actually made | `research/notes/_lessons.md`, numbered and appended |
| Something about a specific host | `recon/<host>/notes.md`, append-only |
| A confirmed vulnerability | `recon/<host>/findings/` |

## Conventions for docs

- Frontmatter: `title`, `date`, `type`, `status`, `verified`, `sources`.
- `date` is when it was written. `verified` is when it was last re-checked
  against a live source. They are different fields — never put prose in a date.
- `status` is `current`, `stale` (>6 months, re-verify), or `not researched`.
- Pointers, not encyclopedias. Detail belongs one hop away, linked.