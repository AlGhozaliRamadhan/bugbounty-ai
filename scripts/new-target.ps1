<#
.SYNOPSIS
    Scaffold a recon target folder under recon/, named exactly after the hostname.

.DESCRIPTION
    Creates recon/<host>/ with the standard file set. Refuses names that are not
    plain hostnames, because the folder name IS the indexing scheme for this workspace.

    Note: the parameter is -Target, not -Host. $Host is a read-only PowerShell
    automatic variable and cannot be used as a parameter name.

.EXAMPLE
    .\scripts\new-target.ps1 -Target api.example.com
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [string]$Target,

    # Program name, e.g. "HackerOne #12345" or "Private program - Acme Corp".
    [string]$Program,

    # Optional comma-separated hostnames that are explicitly OUT of scope.
    [string]$OutOfScope,

    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$recon = Join-Path $root 'recon'

# The folder name must be a bare hostname. No scheme, no path, no port, no spaces.
if ($Target -notmatch '^[A-Za-z0-9]([A-Za-z0-9._-]*[A-Za-z0-9])?$') {
    throw "'$Target' is not a bare hostname. Pass just the host, e.g. api.example.com (no scheme, no port, no path)."
}
if ($Target -match '^\d+\.\d+\.\d+\.\d+$') {
    Write-Warning "'$Target' looks like a bare IP. Recon folders here are named after the hostname that resolved to it."
}

$path = Join-Path $recon $Target
if ((Test-Path $path) -and (-not $Force)) {
    Write-Host "Already exists: $path  (use -Force to refresh missing files)" -ForegroundColor Yellow
    exit 0
}

New-Item -ItemType Directory -Force -Path $path | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $path 'screenshots') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $path 'scripts') | Out-Null

if ($OutOfScope) {
    $items = @($OutOfScope -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    $oos = "- " + ($items -join "`n- ")
}
else {
    $oos = '- <explicitly excluded hosts, third-party SaaS, other registrable domains>'
}
$prog = if ($Program) { $Program } else { '<program name and ID>' }

$scopePath = Join-Path $path 'scope.md'
if ((-not (Test-Path $scopePath)) -or $Force) {
    @"
# Scope - $Target

**Program:** $prog
**Created:** $(Get-Date -Format 'yyyy-MM-dd')

Fill this in before running anything active against this host. Recon output is only
meaningful if it was collected inside the agreed boundary.

## In scope

- $Target

## Out of scope

$oos

## Rules of engagement

- Rate limit: <requests/sec or concurrent connections allowed>
- Testing hours: <e.g. 24/7, or business hours only>
- Allowed: <e.g. automated scanners, directory fuzzing>
- Not allowed: <e.g. DoS, social engineering, physical testing>
- Disclosure: <private report / public, safe harbor status>

## Notes

- Host resolves to: <ip, CNAME chain, CDN/WAF in front>
"@ | Set-Content -Path $scopePath -Encoding utf8
}

$notesPath = Join-Path $path 'notes.md'
if (-not (Test-Path $notesPath)) {
    @"
# Notes - $Target

Append-only. Record dead ends too, so they don't get retried.

## $(Get-Date -Format 'yyyy-MM-dd')

- Target scaffolded.
"@ | Set-Content -Path $notesPath -Encoding utf8
}

foreach ($f in 'subdomains.txt', 'urls.txt', 'ports.txt', 'live.txt') {
    $p = Join-Path $path $f
    if (-not (Test-Path $p)) { New-Item -ItemType File -Path $p | Out-Null }
}

Write-Host "Created $path" -ForegroundColor Green
Write-Host "Next: fill in $scopePath before active testing." -ForegroundColor Cyan