---
description: Scan codebase for technical debt and code quality issues
---

# Technical Debt Audit: $ARGUMENTS

You are scanning for technical debt. Be thorough but prioritize by impact.

## Scope

Target: $ARGUMENTS (if empty, scan the whole codebase or prompt for scope)

## Phase 1: Automated Detection

### TODO/FIXME/HACK Comments

Search for debt markers:

```bash
grep -rn "TODO\|FIXME\|HACK\|XXX\|KLUDGE\|TEMP\|WORKAROUND" --include="*.py" --include="*.js" --include="*.ts" --include="*.go" --include="*.rs" .
```

### Complexity Analysis

If available, run complexity tools:

```bash
# Python
radon cc -a -s . 2>/dev/null || echo "radon not installed"

# JavaScript/TypeScript
npx eslint --rule 'complexity: [warn, 10]' . 2>/dev/null || echo "eslint not available"
```

### Linter Warnings

Run linters and count warnings (don't fix, just inventory):

```bash
# Python
ruff check . --statistics 2>/dev/null | head -20

# JavaScript
npx eslint . --format compact 2>/dev/null | wc -l
```

## Phase 2: Manual Pattern Detection

Use **architecture-analyst** to find:

1. **God files** - Files over 500 lines
2. **God functions** - Functions over 50 lines
3. **Deep nesting** - More than 3-4 levels
4. **Circular dependencies** - Modules that import each other
5. **util/helper graveyards** - Catch-all directories

Use **conventions-analyst** to find:

1. **Inconsistent naming** - Mixed conventions
2. **Dead code** - Unused functions, unreachable branches
3. **Duplicated code** - Copy-paste patterns
4. **Missing abstractions** - Same logic in multiple places

## Phase 3: Dependency Debt

Check for:

```bash
# Outdated dependencies
npm outdated 2>/dev/null || pip list --outdated 2>/dev/null || echo "Check manually"

# Unused dependencies (if tools available)
npx depcheck 2>/dev/null || echo "depcheck not available"
```

## Phase 4: Test Debt

Assess test coverage and quality:

- [ ] What's the coverage percentage?
- [ ] Are there untested critical paths?
- [ ] Are tests actually testing behavior or just lines?
- [ ] Any flaky tests?
- [ ] Missing integration tests?

## Phase 5: Documentation Debt

Check for:

- [ ] Outdated README
- [ ] Missing API documentation
- [ ] Stale comments (describe code that changed)
- [ ] Missing architecture docs

## Phase 6: Categorize and Prioritize

### Debt Categories

| Category | Description | Examples |
|----------|-------------|----------|
| **Cruft** | Dead code, unused deps | Unused imports, dead functions |
| **Complexity** | Hard to understand | God files, deep nesting |
| **Coupling** | Tight dependencies | Circular imports, god objects |
| **Coverage** | Missing tests | Untested critical paths |
| **Consistency** | Mixed patterns | Naming inconsistency |
| **Currency** | Outdated deps | Old library versions |

### Priority Matrix

| Impact | Effort: Low | Effort: High |
|--------|-------------|--------------|
| **High** | DO FIRST | PLAN CAREFULLY |
| **Low** | QUICK WINS | DEFER |

## Output Format

```markdown
## Technical Debt Inventory

### Summary
- **Total items**: [count]
- **Critical**: [count]
- **High**: [count]
- **Medium**: [count]
- **Low**: [count]

### Critical Debt (Blocking/Risky)
1. **[Item]** - [Location]
   - **Category**: [Cruft/Complexity/etc.]
   - **Impact**: [Why this matters]
   - **Effort**: [Low/Medium/High]
   - **Recommendation**: [What to do]

### High Priority
[Same format]

### Medium Priority
[Same format]

### Low Priority / Backlog
[Same format]

### Quick Wins (Low effort, any impact)
1. [Item] - [5 min fix]
2. [Item] - [10 min fix]

### Metrics
- TODO comments: [count]
- FIXME comments: [count]
- Linter warnings: [count]
- Outdated dependencies: [count]
- Files over 500 lines: [count]

### Recommended Sprint
If tackling debt, suggest a focused sprint:
1. [Action 1] - [time estimate]
2. [Action 2] - [time estimate]
```

**Inventory the debt. Prioritize ruthlessly. Fix strategically.**
