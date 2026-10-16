<#
.SYNOPSIS
    Health check for the Kali WSL distro and the kali MCP API server.

.DESCRIPTION
    Run this first whenever kali MCP tools fail.

    Health is judged by an actual command round-trip against POST /api/command,
    NOT by looking for a process named "kali-server-mcp" - the running process
    reports itself as "python3 server.py", so pgrep on the script name never
    matches it. The port is the real invariant.

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

function Invoke-Kali {
    param([string]$Script)
    # `bash script.sh` is a non-login shell, so it never reads /etc/profile.d and
    # /root/go/bin (gau, waybackurls, gf, jaeles) would look missing. Source it.
    $full = "source /etc/profile.d/gobin.sh 2>/dev/null || true`n" + $Script
    [System.IO.File]::WriteAllText("\\wsl$\$Distro\tmp\check-kali-run.sh", $full)
    wsl -d $Distro -u root -e bash /tmp/check-kali-run.sh 2>&1
}

# Health = the API accepts a command and returns it. Anything less is "down".
$probe = @'
if ! ss -ltn 2>/dev/null | grep -qw 5000; then echo "STATE=DOWN"; exit 0; fi
r=$(curl -s -m 20 -X POST http://127.0.0.1:5000/api/command \
      -H "Content-Type: application/json" \
      -d '{"command":"echo __probe__"}')
case "$r" in
  *__probe__*) echo "STATE=UP" ;;
  *)           echo "STATE=WEDGED"; echo "RESP=$r" ;;
esac
'@

# Defined before use - PowerShell resolves functions at call time, not parse time.
function Start-ApiServer {
    Write-Host '      starting kali-server-mcp ...' -ForegroundColor Yellow
    $start = @'
nohup kali-server-mcp >/tmp/kali-mcp.log 2>&1 &
for i in $(seq 1 20); do
  ss -ltn 2>/dev/null | grep -qw 5000 && { echo STARTED; exit 0; }
  sleep 0.5
done
echo "FAILED TO START"
echo "--- log ---"
cat /tmp/kali-mcp.log 2>/dev/null | tail -20
'@
    (Invoke-Kali $start) | ForEach-Object { Write-Host "      $_" -ForegroundColor DarkGray }
}

$state = (Invoke-Kali $probe) -join "`n"
switch -Regex ($state) {
    'STATE=UP'      { Write-Host 'OK    kali API server healthy (POST /api/command round-trip)' -ForegroundColor Green }
    'STATE=WEDGED'  {
        Write-Host 'FAIL  port 5000 is open but the API is not answering commands' -ForegroundColor Red
        Write-Host $state -ForegroundColor DarkGray
        if ($Fix) { Start-ApiServer }
        else { Write-Host '      fix with: .\scripts\check-kali.ps1 -Fix' -ForegroundColor Yellow }
    }
    'STATE=DOWN'    {
        Write-Host 'FAIL  kali-server-mcp is not listening on 127.0.0.1:5000' -ForegroundColor Red
        Write-Host '      this makes every kali MCP tool call error' -ForegroundColor Yellow
        if ($Fix) { Start-ApiServer }
        else { Write-Host '      fix with: .\scripts\check-kali.ps1 -Fix' -ForegroundColor Yellow }
    }
    default         { Write-Host "FAIL  unexpected probe result: $state" -ForegroundColor Red }
}

$bridge = Invoke-Kali 'command -v mcp-server >/dev/null && echo OK || echo MISSING'
if (($bridge -join '').Trim() -eq 'OK') { Write-Host 'OK    mcp-server bridge present' -ForegroundColor Green }
else { Write-Host 'FAIL  mcp-server missing - run: .\scripts\setup-kali.ps1' -ForegroundColor Red }

Write-Host ''
Write-Host 'Tool availability:'
$tools = 'nmap', 'httpx', 'ffuf', 'nuclei', 'katana', 'subfinder', 'naabu', 'dnsx',
          'sqlmap', 'nikto', 'gobuster', 'feroxbuster', 'whatweb', 'wafw00f',
          'amass', 'assetfinder', 'hakrawler', 'dalfox', 'gau', 'waybackurls', 'gf', 'jaeles'
foreach ($t in $tools) {
    $r = Invoke-Kali "command -v $t >/dev/null && echo yes || echo no"
    $mark = if (($r -join '').Trim() -eq 'yes') { "OK  $t" } else { "--  $t (missing)" }
    if (($r -join '').Trim() -eq 'yes') { Write-Host "  $mark" -ForegroundColor Green }
    else { Write-Host "  $mark" -ForegroundColor Yellow }
}

Write-Host ''
Write-Host 'Smoke test:'
Write-Host '  wsl -d kali-linux -u root -e nmap -sT -p 80 scanme.nmap.org'