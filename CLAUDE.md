This repository is a mirror of my customized ~/.claude configuration.  The goal
is to be able to package it and share it with other developers who are NOT
on the same team(s) as me, and who do not work on any of the same material.
It will be shared PUBLICLY, and needs to, as such, contain NO SENSITIVE INFORMATION.

## Chezmoi Workflow

This repository is a **chezmoi source directory** that manages `~/.claude`.

### Making Changes

1. **Edit files in this repository** (the chezmoi source)
2. **Apply changes to the live configuration:**
   ```bash
   chezmoi apply
   ```
3. **Commit changes** to preserve them in version control

### Checking Status

- **See what would change:** `chezmoi diff`
- **See reverse diff:** `chezmoi diff --reverse`
- **Check managed files:** `chezmoi status`

Changes made directly to `~/.claude` will be overwritten by `chezmoi apply`.
Always edit the source files in this repository instead.

TODO:

### Priority 7: Cross-Repository Context [ ] TODO

**Problem:** No understanding of dependencies across repositories

**Solution:**
- Parse dependency manifests
- Fetch/clone dependent repos
- Synthesize dependency interface contracts

