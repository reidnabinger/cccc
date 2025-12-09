---
description: Safely sync branch with upstream (rebase or merge)
---

# Git Sync: $ARGUMENTS

You are syncing a branch with its upstream. This is a careful operation.

## Phase 1: Assess Current State

```bash
# Check current branch and status
git branch --show-current
git status

# Check upstream
git fetch origin
git log --oneline HEAD..origin/main | head -10

# Check for uncommitted changes
git diff --stat
git diff --staged --stat
```

## Phase 2: Stash If Needed

If there are uncommitted changes:

```bash
git stash push -m "WIP before sync $(date +%Y%m%d-%H%M)"
```

## Phase 3: Choose Strategy

### Option A: Rebase (Clean History)

Best when:
- Your branch has clean, logical commits
- You want linear history
- The branch is NOT shared with others

```bash
git rebase origin/main
```

### Option B: Merge (Preserve History)

Best when:
- Branch is shared with others
- You want to preserve merge points
- Rebase would be complex

```bash
git merge origin/main
```

## Phase 4: Handle Conflicts

If conflicts occur:

1. **List conflicting files**:
   ```bash
   git diff --name-only --diff-filter=U
   ```

2. **For each conflict**:
   - Read the file to understand both sides
   - Decide which changes to keep
   - Edit to resolve
   - `git add <file>`

3. **Continue**:
   ```bash
   git rebase --continue  # if rebasing
   git commit             # if merging
   ```

4. **If stuck, abort safely**:
   ```bash
   git rebase --abort  # if rebasing
   git merge --abort   # if merging
   ```

## Phase 5: Verify

After sync:

```bash
# Check history looks right
git log --oneline -10

# Run tests
npm test || pytest || cargo test || go test ./...

# Check nothing broke
git diff origin/main --stat
```

## Phase 6: Restore Stashed Changes

If you stashed earlier:

```bash
git stash pop
```

## Conflict Resolution Tips

### Understanding Conflict Markers

```
<<<<<<< HEAD
Your changes
=======
Incoming changes
>>>>>>> origin/main
```

### Resolution Strategies

1. **Keep ours**: Your version wins
2. **Keep theirs**: Upstream version wins
3. **Combine**: Manually merge both changes
4. **Rewrite**: Neither is right, write fresh

### When Stuck

- Use `git log -p <file>` to see history
- Use **git-agent** to understand what changed and why
- Ask: "What was the INTENT of each change?"

## Safety Checklist

- [ ] Uncommitted changes stashed
- [ ] Understand what upstream changed
- [ ] Conflicts resolved thoughtfully
- [ ] Tests pass after sync
- [ ] History looks sensible

**Sync carefully. Resolve thoughtfully. Verify thoroughly.**
