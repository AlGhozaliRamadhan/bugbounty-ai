<#
.SYNOPSIS
    Provision the Kali WSL distro used by the `kali` MCP server.

.DESCRIPTION
    Installs the recon/web toolset and the official Kali MCP package (mcp-kali-server),
    then starts kali-server-mcp. Kali is rolling-release, so individual package names
    drift; missing packages are reported at the end rather than aborting the run.

.EXAMPLE
    .\scripts\setup-kali.ps1
    .\scripts\setup-kali.ps1 -Packages httpx,nuclei
    .\scripts\setup-kali.ps1 -Full
#>
[CmdletBinding()]
param(
    [string[]]$Packages,
    [switch]$Full,
    [switch]$SkipMcp
)

$ErrorActionPreference = 'Continue'
$Distro = 'kali-linux'

$distros = (wsl --list --quiet 2>$null) -replace "`0", '' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
if ($distros -notcontains $Distro) {
    throw "WSL distro '$Distro' not found. Install it with: wsl --install kali-linux --location D:\WSL\Kali --no-launch"
}

function Invoke-Kali {
    # Writes tool output to the host stream and returns ONLY the exit code.
    # Letting wsl's stdout flow into the pipeline would make the caller compare an
    # array of log lines against 0, which is always true - and silently reports every
    # package as failed.
    param([string]$Command, [switch]$Quiet)
    $out = wsl -d $Distro -u root -e bash -lc $Command 2>&1
    $code = $LASTEXITCODE
    if (-not $Quiet) { $out | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray } }
    return [int]$code
}

Write-Host '== apt update ==' -ForegroundColor Cyan
if ((Invoke-Kali 'export DEBIAN_FRONTEND=noninteractive; apt-get update -qq' -Quiet) -ne 0) { throw 'apt-get update failed' }

# A previous interrupted run leaves dpkg half-configured, and every later install then
# fails while looking like a missing-package problem.
Write-Host '== repairing dpkg state ==' -ForegroundColor Cyan
Invoke-Kali 'export DEBIAN_FRONTEND=noninteractive; dpkg --configure -a >/dev/null 2>&1; apt-get -f install -y -qq >/dev/null 2>&1; true' -Quiet | Out-Null

if ($Full) {
    Write-Host '== installing kali-linux-full (large, ~25 GB) ==' -ForegroundColor Cyan
    if ((Invoke-Kali 'export DEBIAN_FRONTEND=noninteractive; apt-get install -y -qq kali-linux-full') -ne 0) { throw 'kali-linux-full install failed' }
}
else {
    $default = @(
        # Recon / enumeration
        'nmap', 'dnsutils', 'whois', 'amass', 'subfinder', 'assetfinder', 'findomain',
        'naabu', 'dnsx', 'alterx',
        # Web probing
        'httpx-toolkit', 'katana', 'nuclei', 'ffuf', 'feroxbuster', 'gobuster',
        'nikto', 'sqlmap', 'whatweb', 'wafw00f', 'waybackurls', 'gau', 'hakrawler',
        'jaeles', 'dalfox', 'kxss',
        # Wordlists
        'seclists', 'wordlists',
        # Plumbing
        'jq', 'ripgrep', 'git', 'python3-pip', 'golang-go'
    )
    $list = if ($Packages) { $Packages } else { $default }

    # Sequenced groups keep apt transactions small and failures attributable.
    $groups = @(
        @('nmap', 'dnsutils', 'whois', 'jq', 'ripgrep', 'git', 'python3-pip', 'golang-go'),
        @('httpx-toolkit', 'katana', 'nuclei', 'ffuf', 'naabu', 'dnsx', 'alterx', 'subfinder', 'assetfinder', 'amass', 'findomain'),
        @('feroxbuster', 'gobuster', 'nikto', 'sqlmap', 'whatweb', 'wafw00f', 'waybackurls', 'gau', 'hakrawler', 'jaeles', 'dalfox', 'kxss'),
        @('seclists', 'wordlists')
    )
    if ($Packages) { $groups = @(, $Packages) }

    $failed = @()
    $n = 0
    foreach ($g in $groups) {
        $n++
        Write-Host ("== group {0}/{1}: {2} ==" -f $n, $groups.Count, ($g -join ' ')) -ForegroundColor Cyan
        # Install one at a time so a single renamed package doesn't sink the group.
        foreach ($pkg in $g) {
            $code = Invoke-Kali "export DEBIAN_FRONTEND=noninteractive; apt-get install -y -qq $pkg" -Quiet
            if ($code -ne 0) { $failed += $pkg }
        }
    }
    if ($failed.Count) {
        Write-Host ''
        Write-Host "Failed to install: $($failed -join ', ')" -ForegroundColor Yellow
        Write-Host 'Re-check with: wsl -d kali-linux -e apt-cache search <name>' -ForegroundColor Yellow
    }
    else {
        Write-Host 'All packages installed.' -ForegroundColor Green
    }
}

if (-not $SkipMcp) {
    Write-Host '== installing mcp-kali-server (official Kali package) ==' -ForegroundColor Cyan
    if ((Invoke-Kali 'export DEBIAN_FRONTEND=noninteractive; apt-get install -y -qq mcp-kali-server' -Quiet) -ne 0) {
        throw 'mcp-kali-server install failed - the kali MCP cannot work without it'
    }

    Write-Host '== starting kali-server-mcp ==' -ForegroundColor Cyan
    $r = Invoke-Kali 'pkill -f kali-server-mcp 2>/dev/null; sleep 1; nohup kali-server-mcp >/tmp/kali-mcp.log 2>&1 & sleep 4; pgrep -f kali-server-mcp >/dev/null && echo RUNNING || { echo FAILED; cat /tmp/kali-mcp.log; }' -Quiet
    Write-Host "  $r" -ForegroundColor DarkGray
}

Write-Host ''
Write-Host 'Done. Verify with:' -ForegroundColor Green
Write-Host '  .\scripts\check-kali.ps1'