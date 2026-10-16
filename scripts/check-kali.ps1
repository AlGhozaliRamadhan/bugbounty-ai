<#
.SYNOPSIS
    Health check for the Kali WSL + kali MCP server.

.DESCRIPTION
    Run this first whenever kali MCP tools fail. The most common cause is that
    kali-server-mcp (the HTTP API on 127.0.0.1:5000 inside Kali) is not running.

.EXAMPLE
    .\scripts\check-kali.ps1
    .\scripts\check-kali.ps1 -Fix
#>
[CmdletBinding()]
param([switch]$Fix)

$ErrorActionPreference = 'Continue'
$Distro = 'kali-linux'

$distros = (wsl --list --quiet 2>$null) -replace "`0", '' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
if ($distros -notcontains $Distro) {
    Write-Host "FAIL  distro '$Distro' not installed" -ForegroundColor Red
    Write-Host "      install: wsl --install kali-linux --location D:\WSL\Kali --no-launch" -ForegroundColor Yellow
    exit 1
}
Write-Host 'OK    distro kali-linux installed' -ForegroundColor Green

function Invoke-Kali { param([string]$Command) wsl -d $Distro -u root -e bash -lc $Command }

$whoami = Invoke-Kali 'id -u'
if ($whoami.Trim() -ne '0') {
    Write-Host "WARN not running as root (uid=$($whoami.Trim())) - sudo may be needed" -ForegroundColor Yellow
}
else { Write-Host 'OK    running as root' -ForegroundColor Green }

$api = Invoke-Kali 'pgrep -f kali-server-mcp >/dev/null && echo UP || echo DOWN'
if ($api.Trim() -eq 'UP') {
    Write-Host 'OK    kali-server-mcp is running (127.0.0.1:5000)' -ForegroundColor Green
}
else {
    Write-Host 'FAIL  kali-server-mcp is NOT running - all kali MCP tools will error' -ForegroundColor Red
    if ($Fix) {
        Write-Host '      starting...' -ForegroundColor Yellow
        Invoke-Kali 'nohup kali-server-mcp >/tmp/kali-mcp.log 2>&1 & sleep 3; pgrep -f kali-server-mcp >/dev/null && echo STARTED || { echo LOG:; cat /tmp/kali-mcp.log; }' |
            ForEach-Object { Write-Host "      $_" -ForegroundColor Yellow }
    }
    else {
        Write-Host '      fix with: .\scripts\check-kali.ps1 -Fix' -ForegroundColor Yellow
    }
}

$bridge = Invoke-Kali 'command -v mcp-server >/dev/null && echo OK || echo MISSING'
if ($bridge.Trim() -eq 'OK') { Write-Host 'OK    mcp-server bridge present' -ForegroundColor Green }
else { Write-Host 'FAIL  mcp-server missing - run: wsl -d kali-linux -u root -e apt-get install -y mcp-kali-server' -ForegroundColor Red }

Write-Host ''
Write-Host 'Tool availability:'
foreach ($t in 'nmap', 'httpx', 'ffuf', 'nuclei', 'katana', 'subfinder', 'naabu', 'dnsx', 'sqlmap', 'nikto') {
    $r = Invoke-Kali "command -v $t >/dev/null && echo yes || echo no"
    if ($r.Trim() -eq 'yes') { Write-Host "  OK    $t" -ForegroundColor Green }
    else { Write-Host "  --    $t (not installed)" -ForegroundColor Yellow }
}

$wl = Invoke-Kali 'ls /usr/share/seclists 2>/dev/null | wc -l'
Write-Host ''
Write-Host "seclists entries: $($wl.Trim())"

Write-Host ''
Write-Host 'Verify nmap works in WSL (connect scan against a known-open local port):'
Write-Host '  wsl -d kali-linux -u root -e nmap -sT -p 22,80,443 scanme.nmap.org'