---
description: Dead code removal workflow with adversarial review
---

# Dead Code Culling: $ARGUMENTS

You are removing dead code. This is a two-phase adversarial process to prevent accidental removal of code that's actually needed.

## Scope

Target: $ARGUMENTS (if empty, scan the whole codebase or prompt for scope)

## Phase 1: Identify Dead Code

Invoke **codepath-culler** agent to scan for:

1. **Unused imports** - Imported but never referenced
2. **Dead functions** - Defined but never called
3. **Unreachable code** - Code after returns, impossible branches
4. **Commented-out code** - Old code preserved in comments
5. **Deprecated code** - Marked deprecated but never removed
6. **Feature flag cleanup** - Flags that are always true/false

The culler will produce a report categorized by confidence:
- **High confidence**: Safe to remove
- **Medium confidence**: Verify before removing
- **Low confidence**: Investigate further

## Phase 2: Adversarial Review

**MANDATORY**: Before removing ANYTHING, invoke **codepath-culler-contrarian** agent.

The contrarian will challenge every removal recommendation by searching for:
- Dynamic references (reflection, getattr, etc.)
- External consumers (if this is a library)
- Configuration-driven usage
- Plugin/extension patterns
- Framework magic
- Fallback/safety mechanisms

The contrarian will classify items as:
- **BLOCKED**: Do not remove - found hidden usage
- **CAUTION**: Need more investigation
- **APPROVED**: Confirmed safe to remove

## Phase 3: Remove in Stages

Only remove items that passed BOTH the culler AND contrarian review.

### Removal Order

1. **Start with high confidence + APPROVED items**
2. Run tests after each batch
3. Commit in logical chunks
4. Keep items in CAUTION for later review

### For Each Removal

```markdown
## Removing: [item]

### Culler Assessment
- Confidence: [High/Medium/Low]
- Reason: [Why it appears dead]

### Contrarian Assessment
- Status: [APPROVED/CAUTION/BLOCKED]
- Verification: [What was checked]

### Removal
- File: [path]
- Lines: [range]
- Test result: [pass/fail]
```

## Phase 4: Verify

After removals:

1. Run full test suite
2. Run linters
3. Check for import errors
4. Verify build succeeds

```bash
# Typical verification
npm test || pytest || cargo test || go test ./...
npm run build || python -m py_compile *.py || cargo build
```

## Output Format

```markdown
## Dead Code Removal Report

### Summary
- Items identified by culler: [count]
- Items blocked by contrarian: [count]
- Items approved for removal: [count]
- Items removed: [count]
- Lines removed: [count]

### Removed Items
| Item | File | Lines Removed | Confidence |
|------|------|---------------|------------|
| function_name | path/file.py | 45-67 | High |

### Blocked Items (Contrarian Found Usage)
| Item | File | Reason Blocked |
|------|------|----------------|
| helper_func | utils.py | Dynamic lookup in plugin loader |

### Deferred Items (Need Investigation)
| Item | File | Concern |
|------|------|---------|
| old_api | api.py | May have external consumers |

### Verification
- Tests: [PASS/FAIL]
- Linters: [PASS/FAIL]
- Build: [PASS/FAIL]

### Next Steps
1. [Any follow-up needed]
```

## Safety Rules

1. **Never remove without contrarian review**
2. **Never remove BLOCKED items**
3. **Test after each batch of removals**
4. **Commit in reversible chunks**
5. **When in doubt, defer**

## Git Strategy

```bash
# Create a dedicated branch
git checkout -b chore/dead-code-removal

# Commit in logical batches
git add [files]
git commit -m "Remove unused [category]: [details]"

# Keep commits atomic and reversible
```

**Identify aggressively. Review adversarially. Remove cautiously.**
