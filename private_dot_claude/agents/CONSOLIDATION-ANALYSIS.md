# Agent Consolidation Analysis

**Generated:** 2025-11-30
**Total Agents Found:** 224 (92 local + 132 plugin)

---

## Summary of Findings

| Category | Count | Action |
|----------|-------|--------|
| Clear Duplicates | 3 | MERGE |
| Overlapping Purpose | 4 | EVALUATE |
| Valid Specialization | 210+ | KEEP |

---

## 1. CLEAR DUPLICATES (Immediate Action Required)

### 1.1 Explore vs Plan Agents

**Problem:** Identical descriptions in system prompt
```
Both have: "Fast agent specialized for exploring codebases. Use this when you need to
quickly find files by patterns..."
```

**Files:** Built-in (not in local files - check if this is a Claude Code bug or misconfiguration)

**Action:** These appear to be built-in agents. If you defined custom versions, consolidate into ONE exploration agent with clear purpose.

---

### 1.2 Code Reviewer Agents (3-WAY DUPLICATE)

**Problem:** Three separate code-reviewer agents with overlapping purposes

| Agent | Location | Model | Purpose |
|-------|----------|-------|---------|
| `feature-dev:code-reviewer` | plugin | sonnet | Confidence-scored review |
| `pr-review-toolkit:code-reviewer` | plugin | opus | Nearly identical to above |
| `critical-code-reviewer` | local | opus | Existential + dependency analysis |

**System Prompt Comparison:**
- `feature-dev:code-reviewer` and `pr-review-toolkit:code-reviewer` share **~95% identical content**
- Only differences: model (sonnet vs opus), color (red vs green)

**Recommendation:**
1. **DELETE** `feature-dev:code-reviewer` (redundant)
2. **KEEP** `pr-review-toolkit:code-reviewer` as the standard code reviewer
3. **KEEP** `critical-code-reviewer` as a deep-analysis reviewer (distinct purpose)

**Files to modify:**
- DELETE: `~/.claude/plugins/marketplaces/claude-code-plugins/plugins/feature-dev/agents/code-reviewer.md`

---

### 1.3 Code Simplification Agents (2-WAY OVERLAP)

| Agent | Location | Model | Purpose |
|-------|----------|-------|---------|
| `pr-review-toolkit:code-simplifier` | plugin | opus | Actively simplifies code |
| `code-simplicity-reviewer` | compounding-eng | - | Reviews, recommends only |

**Verdict:** These have distinct purposes (modify vs review-only). **KEEP BOTH** but rename for clarity:
- `code-simplifier` → keeps code modification role
- `code-simplicity-reviewer` → keeps read-only analysis role

---

## 2. VALID SPECIALIZATIONS (Keep Separate)

These appear duplicative but serve intentionally different purposes:

### 2.1 Gatherers vs Analyzers (Pipeline Architecture)

| Gatherer (haiku, quick) | Analyzer (sonnet/opus, deep) |
|-------------------------|------------------------------|
| `history-gatherer` | `git-history-analyzer` |
| `pattern-gatherer` | `pattern-recognition-specialist` |
| `architecture-gatherer` | `architecture-strategist` |
| `dependency-gatherer` | (no equivalent) |

**Rationale:** Gatherers are lightweight haiku sub-agents for the pipeline. Analyzers are full-fledged agents for standalone deep analysis. **This is good architecture.**

### 2.2 Language-Specific Security Reviewers

| Agent | Focus |
|-------|-------|
| `security-sentinel` | General application security (OWASP) |
| `python-security-reviewer` | Python ML-specific (model loading, RTSP) |
| `bash-security-reviewer` | Bash-specific (command injection, privilege) |
| `c-*-auditor` family | C-specific security (memory, race conditions) |

**Rationale:** Each handles language-specific vulnerability patterns. **Keep all.**

### 2.3 Language-Specific Code Reviewers

| Agent | Focus |
|-------|-------|
| `kieran-python-reviewer` | Python with Kieran's style preferences |
| `kieran-rails-reviewer` | Rails with Kieran's style preferences |
| `kieran-typescript-reviewer` | TypeScript with Kieran's style preferences |
| `dhh-rails-reviewer` | Rails with DHH's 37signals philosophy |

**Rationale:** Different style philosophies for different teams/projects. **Keep all if actively used.**

---

## 3. QUESTIONABLE AGENTS (Evaluate Usefulness)

These agents may not justify their existence:

### 3.1 Over-Specialized Agents

| Agent | Question |
|-------|----------|
| `mikrotik-routeros-specialist` | Do you work with MikroTik often? |
| `fpga-specialist` | Do you do FPGA development? |
| `zerotier-specialist` | How often do you use ZeroTier? |
| `rocm-specialist` | Do you have AMD GPUs? |

**Action:** Review usage. Delete agents for technologies you don't use.

### 3.2 Duplicate Plugin Agents (From Multiple Marketplaces)

Multiple marketplaces may provide similar agents. Check for:
- `claude-code-plugins` vs `every-marketplace` vs `claude-code-marketplace`

---

## 4. PROPOSED ACTIONS

### Immediate (Low Risk)

1. [ ] Delete `feature-dev:code-reviewer` (exact duplicate)
2. [ ] Document distinction between `Explore` and `Plan` (or consolidate)
3. [ ] Add clearer descriptions to distinguish `code-simplifier` vs `code-simplicity-reviewer`

### Evaluate (Medium Risk)

4. [ ] Review kieran-* reviewers - are all three actively used?
5. [ ] Review infrastructure specialists - prune unused technologies
6. [ ] Audit compounding-engineering agents for personal relevance

### Long-Term (Maintenance)

7. [ ] Establish agent naming convention to prevent future duplicates
8. [ ] Create agent index/registry for quick lookup
9. [ ] Set up agent deprecation process

---

## 5. AGENT COUNT BY CATEGORY

### Local Agents (~/.claude/agents/)

| Category | Count |
|----------|-------|
| Bash specialists | 7 |
| C security | 9 |
| Nix specialists | 5 |
| Python specialists | 6 |
| Infrastructure/DevOps | 25+ |
| Pipeline agents | 6 |
| Code review/analysis | 5 |
| Other | 34 |

### Plugin Agents

| Plugin | Agent Count |
|--------|-------------|
| compounding-engineering | 24 |
| pr-review-toolkit | 6 |
| feature-dev | 3 |
| plugin-dev | 3 |
| agent-sdk-dev | 2 |
| hookify | 1 |
| Other plugins | 93+ |

---

## 6. RECOMMENDATIONS SUMMARY

1. **MERGE NOW:** Delete `feature-dev:code-reviewer` - exact duplicate
2. **CLARIFY:** Add better descriptions to distinguish similar agents
3. **PRUNE:** Remove infrastructure agents for technologies you don't use
4. **DOCUMENT:** Create clearer agent selection guide
5. **PREVENT:** Establish naming conventions and review process
