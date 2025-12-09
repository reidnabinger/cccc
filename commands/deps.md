---
description: Audit and manage dependencies - outdated, unused, vulnerable
---

# Dependency Audit: $ARGUMENTS

You are auditing project dependencies for issues and update opportunities.

## Phase 1: Detect Package Manager

```bash
# Check what package managers are in use
ls -la package.json package-lock.json yarn.lock pnpm-lock.yaml 2>/dev/null
ls -la requirements.txt pyproject.toml setup.py Pipfile poetry.lock 2>/dev/null
ls -la Cargo.toml Cargo.lock 2>/dev/null
ls -la go.mod go.sum 2>/dev/null
ls -la flake.nix flake.lock 2>/dev/null
```

## Phase 2: Check for Outdated Dependencies

### JavaScript/Node

```bash
npm outdated 2>/dev/null || yarn outdated 2>/dev/null || pnpm outdated 2>/dev/null
```

### Python

```bash
pip list --outdated 2>/dev/null
# Or with poetry
poetry show --outdated 2>/dev/null
```

### Rust

```bash
cargo outdated 2>/dev/null || echo "cargo-outdated not installed"
```

### Go

```bash
go list -u -m all 2>/dev/null | grep '\[' | head -20
```

## Phase 3: Check for Security Vulnerabilities

### JavaScript

```bash
npm audit 2>/dev/null
# Or
yarn audit 2>/dev/null
```

### Python

```bash
pip-audit 2>/dev/null || safety check 2>/dev/null || echo "No Python security scanner found"
```

### Rust

```bash
cargo audit 2>/dev/null || echo "cargo-audit not installed"
```

### General

Use **websearch-agent** to check for recent CVEs affecting major dependencies.

## Phase 4: Check for Unused Dependencies

### JavaScript

```bash
npx depcheck 2>/dev/null || echo "Run: npx depcheck"
```

### Python

```bash
# Check imports vs requirements
pip-extra-reqs . 2>/dev/null || echo "Manual check needed"
```

## Phase 5: Analyze Update Risk

For each outdated dependency, assess:

### Breaking Change Risk

| Version Jump | Risk Level | Action |
|--------------|------------|--------|
| Patch (1.0.0 → 1.0.1) | Low | Usually safe to update |
| Minor (1.0.0 → 1.1.0) | Medium | Check changelog |
| Major (1.0.0 → 2.0.0) | High | Read migration guide |

### Check Changelogs

Use **webfetch-agent** to retrieve changelogs for major updates:
- GitHub releases page
- CHANGELOG.md in repo
- Package registry (npm, PyPI)

## Phase 6: Update Strategy

### Safe Updates (Low Risk)

```bash
# JavaScript - update patch versions
npm update

# Python - update within constraints
pip install --upgrade -r requirements.txt

# Rust
cargo update
```

### Targeted Updates (Medium Risk)

```bash
# JavaScript - specific package
npm install package@latest

# Python
pip install package==new.version

# Rust
cargo update -p package
```

### Major Updates (High Risk)

1. Create a dedicated branch
2. Update one major dep at a time
3. Run full test suite
4. Check for deprecation warnings
5. Fix breaking changes
6. Document migration steps

## Output Format

```markdown
## Dependency Audit Report

### Summary
- Total dependencies: [count]
- Outdated: [count]
- Vulnerable: [count]
- Unused: [count]

### Security Vulnerabilities
| Package | Severity | CVE | Fixed In |
|---------|----------|-----|----------|
| example | High | CVE-2024-1234 | 2.0.1 |

**Action**: Update these IMMEDIATELY

### Outdated Dependencies
| Package | Current | Latest | Risk | Notes |
|---------|---------|--------|------|-------|
| react | 17.0.0 | 18.2.0 | High | Major version |
| lodash | 4.17.0 | 4.17.21 | Low | Patch only |

### Unused Dependencies
| Package | Confidence | Recommendation |
|---------|------------|----------------|
| moment | High | Remove or replace with date-fns |

### Recommended Update Order
1. **Security fixes first**: [list]
2. **Patch updates**: [list]
3. **Minor updates**: [list]
4. **Major updates** (need planning): [list]

### Update Commands
```bash
# Safe updates
[commands]

# Security fixes
[commands]
```
```

## Safety Checklist

- [ ] Vulnerabilities addressed first
- [ ] Changelogs reviewed for breaking changes
- [ ] Test suite passes after updates
- [ ] Lock file committed with updates
- [ ] Major updates done one at a time

**Security first. Test always. Update incrementally.**
