<#
.SYNOPSIS
    Scaffold a recon target folder under recon/, named exactly after the hostname.

.DESCRIPTION
    Creates recon/<host>/ with the standard file set. Refuses names that are not
    plain hostnames, because the folder name IS the indexing scheme for this workspace.

    scope.md is generated from docs/templates/scope.md, which is the single source
    of truth for its structure. Edit the template, not this script, to change what a
    new target looks like.

    Note: the parameter is -Target, not -Host. $Host is a read-only PowerShell
    automatic variable and cannot be used as a parameter name.

.EXAMPLE
    .\scripts\new-target.ps1 -Target api.example.com
.EXAMPLE
    .\scripts\new-target.ps1 -Target api.example.com -Program "HackerOne #12345" -OutOfScope "cdn.vendor.com"
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

# Windows PowerShell 5.1 is the default here, and it mangles non-ASCII on both
# sides of a Get-Content/Set-Content round-trip: Get-Content -Raw decodes the
# template as ANSI, and Set-Content -Encoding utf8 emits a BOM. The visible
# symptom is em-dashes arriving as "â€”". Use explicit .NET UTF-8 instead.
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

$root = Split-Path -Parent $PSScriptRoot
$recon = Join-Path $root 'recon'
$templatePath = Join-Path $root 'docs\templates\scope.md'

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
New-Item -ItemType Directory -Force -Path (Join-Path $path 'findings') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $path 'poc') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $path 'scripts') | Out-Null

$today = Get-Date -Format 'yyyy-MM-dd'
$prog = if ($Program) { $Program } else { '<program name and ID>' }

# --- scope.md, generated from the canonical template -------------------------
$scopePath = Join-Path $path 'scope.md'

if (-not (Test-Path $templatePath)) {
    Write-Warning "Template not found at $templatePath - falling back to a minimal scope stub."
    Write-Warning "Restore docs\templates\scope.md so generated scopes stay consistent."
    $scopeBody = "# Scope - $Target`n`n**Program:** $prog`n**Created:** $today`n`n## In scope`n`n- $Target`n`n## Out of scope`n`n- <list them>`n`n## Rules of engagement`n`n- Rate limit: <requests/sec>`n- Not allowed: <DoS, social engineering, ...>`n"
}
else {
    # Pull the ```markdown fenced block out of the template doc.
    $template = [System.IO.File]::ReadAllText($templatePath, [System.Text.Encoding]::UTF8)
    $m = [regex]::Match($template, '(?s)```markdown\r?\n(.*?)\r?\n```')
    if (-not $m.Success) {
        throw "Could not find a ```markdown block in $templatePath. The template format changed."
    }
    $scopeBody = $m.Groups[1].Value
}

# Out-of-scope hosts come from the CLI when given; otherwise leave the template's prompt.
if ($OutOfScope) {
    $items = @($OutOfScope -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    $oos = "- " + ($items -join "`n- ")
    $scopeBody = $scopeBody -replace '(?m)^- <explicitly excluded hosts.*$', $oos
}

$scopeBody = $scopeBody -replace '\{\{HOST\}\}', $Target
$scopeBody = $scopeBody -replace '\{\{PROGRAM\}\}', $prog
$scopeBody = $scopeBody -replace '\{\{DATE\}\}', $today

if ((-not (Test-Path $scopePath)) -or $Force) {
    [System.IO.File]::WriteAllText($scopePath, $scopeBody, $utf8NoBom)
}

# --- notes.md, append-only running log --------------------------------------
$notesPath = Join-Path $path 'notes.md'
if (-not (Test-Path $notesPath)) {
    $notes = @"
# Notes - $Target

Append-only. Record dead ends too, so they don't get retried. Never put a live
token in this file - use a gitignored path instead.

## $today

- Target scaffolded.
- Recon not yet run. See docs\recon-playbook.md for the pipeline.
"@
    [System.IO.File]::WriteAllText($notesPath, $notes, $utf8NoBom)
}

# --- findings/README, so the folder isn't an unexplained empty directory ----
$findingsReadme = Join-Path $path 'findings\README.md'
if (-not (Test-Path $findingsReadme)) {
    $findingsDoc = @"
# Findings - $Target

One `.md` per confirmed bug, copied from `docs/templates/finding.md`.

Slug them short and kebab-case: `idor-invoice-endpoint.md`, not `bug1.md`.

Scanner output is a hypothesis, not a finding. Verify manually first.
Show the smallest sample that proves impact - one other user's record, not two
hundred. Redact credentials: `REDACTED`, never a live token.
"@
    [System.IO.File]::WriteAllText($findingsReadme, $findingsDoc, $utf8NoBom)
}

# --- raw output files, pre-created so tools have somewhere to write ---------
foreach ($f in 'subdomains.txt', 'urls.txt', 'ports.txt', 'live.txt') {
    $p = Join-Path $path $f
    if (-not (Test-Path $p)) { New-Item -ItemType File -Path $p | Out-Null }
}

Write-Host "Created $path" -ForegroundColor Green
Write-Host "  scope.md    <- FILL THIS IN BEFORE ANY ACTIVE TESTING" -ForegroundColor Cyan
Write-Host "  notes.md, findings/, poc/, screenshots/, scripts/" -ForegroundColor DarkGray
Write-Host "  subdomains.txt, urls.txt, ports.txt, live.txt" -ForegroundColor DarkGray
Write-Host ''
Write-Host "Next: complete the scope gate in $scopePath, then follow docs\recon-playbook.md" -ForegroundColor Cyan