---
name: cell-status
description: Check the cell's network jail. Use when asked whether the firewall works, before relying on network access, or when a request fails in a way that might be the perimeter firewall.
---

Run the diagnostic and report its output:

```bash
bash "${CLAUDE_CONFIG_DIR}/skills/cell-status/cell-status.sh"
```

Each check says what it expects. Report any `LEAK DETECTED!` or `FAILED` line to the Warden
plainly, with the check that produced it.
