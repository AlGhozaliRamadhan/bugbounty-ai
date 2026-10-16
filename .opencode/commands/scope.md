---
description: Scaffold a recon target and fill in its scope gate
---

Load the `scope` skill with the `skill` tool and follow it, using `$1` as the
target URL or hostname.

The full workflow lives in `.opencode/skills/scope/SKILL.md` — normalize the
input, scaffold, run passive enumeration, then stop at the scope gate before
anything touches the host.

Don't summarize the workflow from memory; load it.