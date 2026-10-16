---
title: Kali / WSL / MCP environment
date: 2026-10-16
type: reference
status: current
verified: 2026-10-16
---

# Environment facts — Kali via WSL

Everything here was probed on this machine on 2026-10-16. Anything marked
"verified" was actually run, not inferred.

## Where things live

| Thing | Path |
| --- | --- |
| Kali distro VHD | `D:\WSL\Kali\ext4.vhdx` |
| Ubuntu distro VHD | `D:\WSL\Ubuntu` |
| Workspace | `D:\Bug Bounty` (note the space) |
| Workspace as Kali sees it | `/mnt/d/Bug Bounty` |
| Kali scratch space | `/tmp/work` |
| MCP API log | `/tmp/kali-mcp.log` inside Kali |

Nothing belongs on `C:`. `C:` is the Windows system drive and has limited free
space.

## The MCP is two processes, not one

This is the single most common failure mode.

1. **`kali-server-mcp`** — an HTTP API server running *inside Kali*, bound to
   `127.0.0.1:5000`. It is what actually executes commands.
2. **`mcp-server`** — the MCP stdio bridge that OpenCode spawns. It is a thin
   client that forwards tool calls to #1 over HTTP.

Both live **inside** the Kali WSL, so `localhost:5000` resolves within the
distro. Do not try to reach that port from Windows, and do not change it.

**If `kali-server-mcp` is not running, every `kali` MCP tool call fails with a
connection error** even though nothing is misconfigured.

Recovery — never hand-roll this:

```powershell
.\scripts\check-kali.ps1          # diagnose only
.\scripts\check-kali.ps1 -Fix     # diagnose and start the API server
```

### Does WSL idle-shutdown kill it?

No — this was tested, because it seemed like the obvious failure mode.

There is no `%USERPROFILE%\.wslconfig`, so `vmIdleTimeout` is at its 60000 ms
default. The obvious worry is that WSL tears the distro down after 60 s idle
and takes `kali-server-mcp` with it. **That does not happen.** The API server
was left running with nothing attached and was still healthy and answering
commands after 3 min 18 s.

The reason is that `vmIdleTimeout` only applies when the distro has **no
running processes**. The backgrounded `kali-server-mcp` counts as a running
process and keeps the distro alive indefinitely.

So the API server does not die on a timer. It dies when it genuinely crashes, or
when someone runs `wsl --shutdown` / kills the VM. Neither is supervised, so
the wrapper and `check-kali.ps1 -Fix` exist to cover it.

## Registration

`opencode.json` in this folder, project-scoped:

```json
"kali": {
  "type": "local",
  "command": ["wsl.exe","-d","kali-linux","-e","mcp-server",
              "--server","http://localhost:5000","--timeout","600"],
  "timeout": 120000
}
```

Two different timeouts, both necessary:

- `timeout: 120000` is OpenCode's **MCP handshake** timeout. The default is
  **5000 ms**, and a WSL cold start reliably exceeds that, so the server fails
  to register. Do not lower it back to the default.
- `--timeout 600` is `mcp-server`'s **per-command** HTTP timeout, in seconds.
  Long scans exceed anything shorter.

The global config at `C:\Users\ozate\.config\opencode\opencode.json` has other
MCP servers and is **not** to be edited from this workspace.

## Kali runs as root, with no default user

Installed with `--no-launch`, so no user was ever created and there is no
`sudo`. Do not prefix commands with `sudo`. Running as root is what makes raw
sockets and OS detection work (see nmap below).

## Installed tooling (verified 2026-10-16)

Present:

```
nmap  httpx  ffuf  nuclei  katana  subfinder  naabu  dnsx  amass
assetfinder  sqlmap  nikto  gobuster  feroxbuster  whatweb  wafw00f
hakrawler  dalfox  gau  waybackurls  gf  jaeles  dirb  wpscan
jq  rg  git  go
```

`gau`, `waybackurls`, `gf`, and `jaeles` were `go install`-ed into
`/root/go/bin`, which is **not** on the default PATH. `/etc/profile.d/gobin.sh`
appends it — that file is the only reason they resolve by name. If a
`go install`-ed binary reports "command not found", that file is the thing to
check. Note that a non-login shell (`bash script.sh`, or the `sh` that
`execute_command` uses) never reads `profile.d` at all, so source it explicitly.

**Not installed** — do not assume these exist: `metasploit`, `hydra`, `john`,
`enum4linux`, `masscan`, `gospider`, `theharvester`, `interactsh-client`,
`uncover`, `dirsearch`, `alterx`, `findomain`, `kxss`.

`uncover` and `interactsh-client` need an API key or an account regardless.
Install extras with `.\scripts\setup-kali.ps1 -Packages <name>`.

Wordlists are installed: `/usr/share/seclists` (1.9 GB) and
`/usr/share/wordlists`.

## Kali inherits the entire Windows PATH

WSL interop injects every Windows PATH entry into the Linux PATH. Inside Kali,
`echo $PATH` ends with a hundred `/mnt/c/...` entries — `Program Files`,
`WindowsApps`, `npm`, `dotnet`, and so on.

Two consequences:

- **Windows binaries are callable from Kali by bare name** (`code`,
  `explorer.exe`, `pwsh`). That's usually convenient and occasionally
  surprising.
- **The Windows entries contain spaces**, which is part of why quoting
  `/mnt/c/...` paths inside Kali is error-prone. Prefer Linux-side paths.

This was checked for collisions on the core tools: `nmap`, `curl`, `git`,
`python3`, `ffuf`, `nuclei`, and `httpx` all resolve to `/usr/bin` first, so
Windows does not shadow them. If a tool ever behaves oddly, check with
`which -a <tool>` before assuming the tool is broken.

## nmap capabilities (verified)

nmap 7.99. `-sT`, `-sS`, and `-O` all work, because Kali runs as root and WSL2
grants `CAP_NET_RAW`.

```bash
# Full TCP, open ports only, into the target folder
nmap -sS -T3 -p- --open -oN "/mnt/d/Bug Bounty/recon/<target>/ports.txt" <host>

# Service/version + OS detection on a known-open set
nmap -sS -sV -O -T3 -p 22,80,443,8080,8443 <host>
```

- `-O` warns "could not find at least 1 open and 1 closed port" unless you scan
  a full port range or include a closed port. The guesses are still usable; it
  just won't print an exact match.
- `-sU` is extremely slow and targets usually rate-limit it. Don't run UDP over
  `-p-`.
- This all depends on being root. A non-root shell loses `-sS` and `-O`.

## Wordlist paths (verified)

`/usr/share/wordlists/seclists` is a symlink to `/usr/share/seclists`. Both
paths work; the latter is the real one.

| Purpose | Path |
| --- | --- |
| Directory brute force (the `gobuster_scan` / `dirb_scan` default) | `/usr/share/wordlists/dirb/common.txt` (35 KB) |
| Directory brute force (bigger) | `/usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt` |
| Larger still | `/usr/share/seclists/Discovery/Web-Content/raft-large-directories.txt` |
| Small / quick first pass | `/usr/share/seclists/Discovery/Web-Content/common.txt` (38 KB) |
| API endpoints | `/usr/share/seclists/Discovery/Web-Content/api/` |
| Password spraying | `/usr/share/wordlists/rockyou.txt.gz` |
| SQLi payloads | `/usr/share/wordlists/sqlmap.txt` |

`/usr/share/wordlists/` also holds `nmap.lst` and a `dirb/` directory with
`big.txt`, `extensions_common.txt`, `indexes.txt` and friends.

One trap: **`rockyou` ships gzipped only.** There is no plain
`/usr/share/wordlists/rockyou.txt`, which is exactly what `john_crack`
defaults to. `gunzip` it into `/tmp/work` first — `ffuf` and most other tools
can't read `.gz` either.

Note for whoever checks next: `dirb/` and `sqlmap.txt` only appeared once the
`wordlists` package finished installing. Probing mid-install produces confident,
wrong answers. Re-verify after any package change.

## `/mnt/d` is slow

It is a cross-filesystem mount. Thousands of small writes across it crawl,
which makes wordlists, `ffuf` response dumps, and nuclei output painful.

Build in `/tmp/work` inside Kali, then copy the finished files into the target
folder:

```bash
mkdir -p /tmp/work && cd /tmp/work
cp /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt ./wf.txt
# ... run the tool against ./ ...
cp -v results.txt "/mnt/d/Bug Bounty/recon/example.com/"
```

The target folder is the durable record; `/tmp/work` is scratch.

## The path has a space in it

`/mnt/d/Bug Bounty/...` — **every reference must be quoted**. An unquoted path
splits at the space and either errors or writes to the wrong place.

## What the MCP actually exposes

Verified with a live `initialize` + `tools/list` handshake on 2026-10-16.
Server reports `kali_mcp` version 1.22.0, 11 tools:

```
nmap_scan  gobuster_scan  dirb_scan  nikto_scan  sqlmap_scan
metasploit_run  hydra_attack  john_crack  wpscan_analyze
enum4linux_scan  server_health  execute_command
```

Two traps in that list:

- **Four named tools depend on software that isn't installed** —
  `metasploit_run`, `hydra_attack`, `john_crack`, and `enum4linux_scan` will
  fail outright. Use `execute_command` with a tool that is actually present
  instead. `nmap_scan`, `gobuster_scan`, `dirb_scan`, `nikto_scan`,
  `sqlmap_scan`, and `wpscan_analyze` all have their dependencies present.
- **`john_crack` defaults to a path that doesn't exist**,
  `/usr/share/wordlists/rockyou.txt`. Only `rockyou.txt.gz` is shipped.
  `gobuster_scan` and `dirb_scan` default to `/usr/share/wordlists/dirb/common.txt`,
  which *is* present and correct.

`server_health` reports a `tools_status` block listing `dirb`, `gobuster`,
`nikto`, `nmap`. That happens to be accurate here, but it only covers those four
and is not a general presence check — use `command -v` for anything else.

## `execute_command` runs under `/bin/sh`, not bash

The API server executes commands through `sh` (dash). Consequences:

- `source file` fails with `source: not found`. Use `. file`, or invoke bash
  explicitly.
- Bashisms that aren't in POSIX `sh` will fail. `&&`, `||`, `$()`, pipes and
  redirection all work fine.
- `/root/go/bin` is not on `sh`'s PATH, so `gau`, `waybackurls`, `gf`, and
  `jaeles` need an explicit `. /etc/profile.d/gobin.sh` first.

Verified working through the live MCP:

```
. /etc/profile.d/gobin.sh; gau --version
```

## Writing bash through PowerShell — always use a script file

`wsl ... bash -lc "..."` runs the string through PowerShell's parser first, so
inline bash breaks in ways that look like bash errors but aren't:

- `&&` and `||` inside the string are parsed by **PowerShell** → `ParserError`
- `$()` subexpressions get expanded by PowerShell, not bash
- `cmd < file` → `The '<' operator is reserved for future use` (PowerShell has
  no input redirection)

When a command needs more than one line, or any of the above appears, write the
script to a file and pipe it in:

```powershell
# no BOM - a UTF-8 BOM makes bash fail with "\ufeff{: command not found"
$script = @'
mkdir -p /tmp/work && cd /tmp/work
nmap --version | head -1
'@
[System.IO.File]::WriteAllText("D:\Bug Bounty\scripts\tmp-probe.sh", $script)
Get-Content "D:\Bug Bounty\scripts\tmp-probe.sh" -Raw | wsl -d kali-linux -u root -e bash -s
```

`bash -s` reads the script from stdin, so `&&` and `$()` are parsed by bash, not
PowerShell. Keep temp scripts on **D:**, and delete them when done.

`Set-Content -Encoding utf8` writes a BOM in Windows PowerShell 5.1 and breaks
the script. Use `[System.IO.File]::WriteAllText` as above, or `-Encoding utf8NoBOM`
on PowerShell 7+.

For a single simple command, skip the shell entirely — this form has no
quoting layer at all:

```powershell
wsl -d kali-linux -u root -e nmap -sS -T3 -p80 scanme.nmap.org
```