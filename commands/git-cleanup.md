---
description: Clean up old branches and stale references
---

# Git Cleanup

You are cleaning up git branches and references.

## Phase 1: Survey the Landscape

```bash
# Fetch latest and prune stale remote-tracking refs
git fetch --all --prune

# List all local branches with last commit date
git for-each-ref --sort=-committerdate refs/heads/ --format='%(committerdate:short) %(refname:short) %(upstream:track)'

# List branches with no remote (potentially orphaned)
git branch -vv | grep ': gone]'

# List merged branches (safe to delete)
git branch --merged main | grep -v "main\|master\|\*"
```

## Phase 2: Identify Cleanup Candidates

### Category 1: Merged Branches (SAFE)
Branches fully merged to main - can delete:

```bash
git branch --merged main | grep -v "main\|master\|\*"
```

### Category 2: Gone Branches (USUALLY SAFE)
Remote deleted but local remains:

```bash
git branch -vv | grep ': gone]' | awk '{print $1}'
```

### Category 3: Stale Branches (REVIEW NEEDED)
Old branches that might be abandoned:

```bash
# Branches not touched in 30+ days
git for-each-ref --sort=committerdate refs/heads/ --format='%(committerdate:relative) %(refname:short)' | grep -E "months? ago|year"
```

## Phase 3: Safe Deletion

### Delete Merged Branches

```bash
# Preview what would be deleted
git branch --merged main | grep -v "main\|master\|\*"

# Delete them
git branch --merged main | grep -v "main\|master\|\*" | xargs -r git branch -d
```

### Delete Gone Branches

```bash
# Preview
git branch -vv | grep ': gone]' | awk '{print $1}'

# Delete them
git branch -vv | grep ': gone]' | awk '{print $1}' | xargs -r git branch -D
```

### Delete Specific Branch

```bash
# Safe delete (only if merged)
git branch -d branch-name

# Force delete (unmerged - be careful!)
git branch -D branch-name
```

## Phase 4: Clean Up Remote References

```bash
# Remove stale remote-tracking branches
git remote prune origin

# Or fetch with prune
git fetch --prune
```

## Phase 5: Garbage Collection

```bash
# Clean up loose objects
git gc --auto

# More aggressive cleanup (if needed)
git gc --aggressive --prune=now
```

## Output Format

```markdown
## Git Cleanup Report

### Branches Deleted
| Branch | Reason | Last Commit |
|--------|--------|-------------|
| feature/old-thing | Merged to main | 2024-01-15 |
| fix/stale-branch | Remote gone | 2024-02-01 |

### Branches Kept (Review Later)
| Branch | Reason Kept | Last Commit |
|--------|-------------|-------------|
| experiment/wip | Unmerged, may have value | 2024-03-01 |

### Cleanup Stats
- Merged branches deleted: [count]
- Gone branches deleted: [count]
- Remote refs pruned: [count]
- Remaining branches: [count]
```

## Safety Rules

1. **Never delete main/master**
2. **Use -d first** (safe), only -D if you understand why
3. **When in doubt, keep** - branches are cheap
4. **Check for unmerged work** before force deleting

**Prune the dead. Keep the living. When in doubt, wait.**
