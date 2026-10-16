<#
.SYNOPSIS
    First-run environment check for a fresh clone of the Bug Bounty AI template.

.DESCRIPTION
    Advisory by default. Every check reports OK, WARN, or SKIP and nothing is
    allowed to stop the run, because a missing wordlist on someone's laptop is
    information, not a reason to fail their setup. Pass -Strict to make WARN
    exit non-zero for CI.

    Run this immediately after cloning. A fresh clone is almost always broken in
    the same two ways:

      1. opencode.json still points at the machine it was authored on.
      2. recon/ is not actually ignored, and the first `git add .` publishes
         somebody's target data.

    Check 2 is the one that matters. If recon/ is not ignored, stop and fix it
    before staging anything.

.PARAMETER Strict
    Exit non-zero when any check reports WARN. Off by default.

.PARAMETER SkipKali
    Skip the WSL/Kali checks. Useful on a machine that has not set up WSL yet.

.EXAMPLE
    .\scripts\doctor.ps1
    .\scripts\doctor.ps1 -SkipKali
#>
[CmdletBinding()]
param([switch]$Strict, [switch]$SkipKali)

$ErrorActionPreference = 'Continue'

$script:Warn = 0
$script:Fail = 0

function Write-Status {
    param([string]$Level, [string]$Message, [string]$Hint)
    switch ($Level) {
        'OK'   { Write-Host "  OK    $Message" -ForegroundColor Green }
        'WARN' { $script:Warn++; Write-Host "  WARN  $Message" -ForegroundColor Yellow }
        'FAIL' { $script:Fail++; Write-Host "  FAIL  $Message" -ForegroundColor Red }
        'SKIP' { Write-Host "  --    $Message" -ForegroundColor DarkGray }
    }
    if ($Hint) { Write-Host "        $Hint" -ForegroundColor DarkGray }
}

$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot

Write-Host ''
Write-Host "Bug Bounty AI - environment check" -ForegroundColor Cyan
Write-Host "  $RepoRoot" -ForegroundColor DarkGray
Write-Host ''

# ---------------------------------------------------------------------------
Write-Host 'Repository' -ForegroundColor Cyan

$required = @(
    'AGENTS.md', 'CLAUDE.md', 'README.md', 'opencode.json',
    'docs\environment.md', 'docs\index.md', 'docs\recon-playbook.md',
    'docs\report-writing.md', 'docs\workflow.md', 'docs\toolchain.md',
    'docs\templates\scope.md', 'docs\templates\finding.md',
    'research\notes\_index.md', 'research\notes\_lessons.md',
    'research\notes\sources.md',
    'scripts\check-kali.ps1', 'scripts\new-target.ps1', 'scripts\setup-kali.ps1',
    'scripts\doctor.ps1', 'scripts\scratch.sh', 'recon\README.md',
    '.opencode\skills\doctor\SKILL.md', '.opencode\skills\scope\SKILL.md'
)

$missing = $required | Where-Object { -not (Test-Path $_) }
if ($missing) {
    Write-Status 'WARN' "$($missing.Count) expected file(s) missing" ($missing -join ', ')
} else {
    Write-Status 'OK' "all $($required.Count) required files present"
}

# ---------------------------------------------------------------------------
Write-Host ''
Write-Host 'Git safety' -ForegroundColor Cyan

$insideRepo = $false
git rev-parse --is-inside-work-tree 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) { $insideRepo = $true }

if (-not $insideRepo) {
    Write-Status 'WARN' 'not a git repository, skipping the ignore checks'
}
else {
    # The check that justifies this script. A clone with a weakened .gitignore
    # would stage a real target's scope.md, notes.md and findings/ on the next
    # `git add .`.
    $probe = 'recon/probe.example.com/notes.md'
    git check-ignore -q $probe 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Status 'OK' 'recon/ is ignored, target data cannot be staged'
    }
    else {
        Write-Status 'FAIL' 'recon/ is NOT ignored - do not stage anything' `
            're-add the rule "recon/*/*" to .gitignore'
    }

    # Anything already committed under a *target* folder has to come out of
    # history. recon/README.md is meant to be tracked, so match two levels deep.
    $tracked = git ls-files -- 'recon/*/*' 2>$null
    if ($tracked) {
        Write-Status 'FAIL' 'target data is already tracked in git' `
            "untrack with: git rm -r --cached recon/`n            $($tracked -join ', ')"
    }
    else {
        Write-Status 'OK' 'no target data tracked'
    }

    $pending = git status --porcelain --ignored -- 'recon/' 2>$null |
               Where-Object { $_ -match '^\?\?|^!!' }
    if ($pending) {
        Write-Status 'OK' "$($pending.Count) recon path(s) present locally and ignored"
    }
    else {
        Write-Status 'OK' 'no recon folders yet, nothing to leak'
    }
}

# ---------------------------------------------------------------------------
Write-Host ''
Write-Host 'Configuration' -ForegroundColor Cyan

$cfgPath = Join-Path $RepoRoot 'opencode.json'
if (-not (Test-Path $cfgPath)) {
    Write-Status 'FAIL' 'opencode.json missing, the kali MCP cannot be wired'
}
else {
    try {
        $cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json
    }
    catch {
        $cfg = $null
        Write-Status 'FAIL' 'opencode.json is not valid JSON' $_.Exception.Message
    }

    if ($cfg) {
        $bridge = $cfg.mcp.kali.command
        if (-not $bridge) {
            Write-Status 'FAIL' 'no mcp.kali block in opencode.json'
        }
        else {
            Write-Status 'OK' "mcp.kali wired, timeout $($cfg.mcp.kali.timeout)ms"

            # The bridge path is a WSL path. A fresh clone lives somewhere else,
            # so this is the single most common thing to fix after cloning.
            $wslPath = $bridge | Where-Object { $_ -like '*/scripts/*' } | Select-Object -First 1
            if ($wslPath) {
                $drive = $RepoRoot.Substring(0, 1).ToLower()
                $rest = $RepoRoot.Substring(2) -replace '^\\', '' -replace '\\', '/'
                $expected = "/mnt/$drive/$rest"

                if ($wslPath -eq $expected -or $wslPath.StartsWith("$expected/")) {
                    Write-Status 'OK' "bridge path matches this checkout ($expected)"
                }
                else {
                    Write-Status 'WARN' 'bridge path points at a different machine' @"
        opencode.json has:  $wslPath
        this checkout is:   $expected
        edit the "command" array in opencode.json, replacing the bridge path.
        Docs referencing the old path are cosmetic only.
"@
                }
            }
        }
    }
}

# A space in the path is legal and every reference is quoted, but it is the
# reason the docs are full of quotes, so it is worth knowing about.
if ($RepoRoot -match ' ') {
    Write-Status 'OK' 'checkout path contains a space, references must stay quoted'
}
else {
    Write-Status 'OK' 'checkout path has no spaces'
}

$distro = 'kali-linux'
if ($SkipKali) {
    Write-Status 'SKIP' 'Kali checks skipped (-SkipKali)'
}
else {
    $distros = (wsl --list --quiet 2>$null) -replace "`0", '' |
               ForEach-Object { $_.Trim() } | Where-Object { $_ }
    if ($distros -notcontains $distro) {
        Write-Status 'WARN' "WSL distro '$distro' not installed" `
            "install: wsl --install kali-linux --no-launch"
    }
    else {
        Write-Status 'OK' "WSL distro $distro installed"

        $probe = 'id -u; command -v mcp-server >/dev/null && echo BRIDGE=yes || echo BRIDGE=no'
        [System.IO.File]::WriteAllText("\\wsl$\$distro\tmp\doctor-run.sh", $probe)
        $out = (wsl -d $distro -u root -e bash /tmp/doctor-run.sh 2>&1) -join "`n"
        if ($out -match '^0') {
            Write-Status 'OK' 'Kali reachable as root'
        }
        else {
            Write-Status 'WARN' 'Kali did not answer as root'
        }
        if ($out -match 'BRIDGE=yes') {
            Write-Status 'OK' 'mcp-server bridge installed'
        }
        else {
            Write-Status 'WARN' 'mcp-server missing' 'run: .\scripts\setup-kali.ps1'
        }

        # Full tool inventory, MCP round-trip and wordlist paths live in
        # docs/environment.md. Delegate rather than duplicating the list here.
        Write-Status 'OK' 'for tools, MCP server and wordlists run: .\scripts\check-kali.ps1'
    }
}

# ---------------------------------------------------------------------------
Write-Host ''
if ($script:Fail -gt 0) {
    Write-Host "$($script:Fail) blocking problem(s), $script:Warn warning(s)." -ForegroundColor Red
    if ($script:Fail -gt 0 -and $RepoRoot -like '*Bug Bounty*') {
        Write-Host '' -ForegroundColor Red
        Write-Host 'This looks like the original workspace rather than a fresh' -ForegroundColor Red
        Write-Host 'clone, so the path mismatch above is expected and harmless.' -ForegroundColor Red
    }
    exit 1
}
elseif ($script:Warn -gt 0) {
    Write-Host "Ready, with $script:Warn warning(s) above." -ForegroundColor Yellow
    if ($Strict) { exit 1 }
}
else {
    Write-Host 'All checks passed.' -ForegroundColor Green
}
Write-Host ''
