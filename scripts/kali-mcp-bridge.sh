#!/usr/bin/env bash
# Self-healing wrapper around the Kali MCP stdio bridge.
#
# OpenCode spawns this as the `kali` MCP server. It guarantees the HTTP API
# (kali-server-mcp on 127.0.0.1:5000) is listening before handing stdio over to
# the real bridge, so a dead API server no longer means dead MCP tools.
#
# Health is judged by the listening port. Do NOT use `pgrep -f kali-server-mcp`:
# the running process reports itself as "python3 server.py", so that pattern
# never matches.

set -uo pipefail

# go-installed tools live here and it is not on the default PATH
source /etc/profile.d/gobin.sh 2>/dev/null || true

if ! ss -ltn 2>/dev/null | grep -qw 5000; then
  nohup kali-server-mcp >/tmp/kali-mcp.log 2>&1 &
  for _ in $(seq 1 30); do
    ss -ltn 2>/dev/null | grep -qw 5000 && break
    sleep 0.5
  done
fi

exec mcp-server "$@"