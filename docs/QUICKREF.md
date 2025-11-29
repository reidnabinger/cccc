# CCCC Quick Reference Card

Pocket guide for the Claude Code agent pipeline.

---

## Pipeline States

```
IDLE → GATHERING → REFINING → ORCHESTRATING_ACTIVE → EXECUTING → COMPLETE
```

| State | What's Happening | Allowed Agents |
|-------|------------------|----------------|
| **IDLE** | Waiting to start | `task-classifier`, `context-gatherer` |
| **CLASSIFIED** | Mode determined | Depends on mode |
| **GATHERING** | Collecting context | `context-refiner` (COMPLEX) or exec (MODERATE) |
| **REFINING** | Distilling intel | `strategic-orchestrator` |
| **ORCHESTRATING_ACTIVE** | Planning approach | Language specialists |
| **EXECUTING** | Running specialists | Language specialists |
| **COMPLETE** | Done | `context-gatherer` to restart |

---

## Pipeline Modes

| Mode | When to Use | Path |
|------|-------------|------|
| **TRIVIAL** | Single file, obvious fix | Skip all → Execute |
| **MODERATE** | Focused change, few files | Gather → Execute |
| **COMPLEX** | Multi-component, architecture | Full pipeline |
| **EXPLORATORY** | Research, understanding | Full pipeline |

---

## Essential Commands

```bash
# Check current state
jq '.state' ~/.claude/state/pipeline-state.json

# View full state
jq . ~/.claude/state/pipeline-state.json

# Reset pipeline
~/.claude/scripts/reset-pipeline-state.sh "Reason"

# View journal (last 20 entries)
tail -20 ~/.claude/state/pipeline-journal.log

# Check cache
~/.claude/scripts/context-cache.sh info
```

---

## Starting the Pipeline

**Option A: With Classification**
```
User: "Help me implement X"
Claude: [Invokes task-classifier]
        → Returns TRIVIAL/MODERATE/COMPLEX/EXPLORATORY
        → Routes accordingly
```

**Option B: Full Pipeline**
```
User: "Help me implement X"
Claude: [Invokes context-gatherer]
        → Spawns 4 sub-gatherers
        → Returns comprehensive context
        → Auto-advances to refiner
```

---

## Agent Quick Reference

### Core Pipeline
| Agent | Model | Purpose |
|-------|-------|---------|
| `task-classifier` | haiku | Quick complexity assessment |
| `context-gatherer` | sonnet | Collect codebase context |
| `context-refiner` | sonnet | Distill into actionable intel |
| `strategic-orchestrator` | opus | Plan and coordinate |

### Sub-Gatherers (Parallel)
| Agent | Focus |
|-------|-------|
| `architecture-gatherer` | Structure, modules, entry points |
| `dependency-gatherer` | External/internal deps |
| `pattern-gatherer` | Code conventions |
| `history-gatherer` | Git evolution |

### Specialists
| Domain | Agents |
|--------|--------|
| **Bash** | architect, tester, style-enforcer, security-reviewer, optimizer, error-handler, debugger |
| **Nix** | architect, module-writer, package-builder, reviewer, debugger |
| **C** | security-architect, security-coder, memory-safety-auditor, privilege-auditor, race-condition-auditor, security-reviewer, security-tester |
| **Python** | architect, security-reviewer, ml-specialist, test-writer, quality-enforcer |

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "Agent blocked" | Reset pipeline, start with context-gatherer |
| Stuck state | Wait 10 min (auto-reset) or manual reset |
| "Pipeline mode not set" | `jq '.pipeline_mode = "COMPLEX"' state.json > tmp && mv tmp state.json` |
| Journal errors | Check `~/.claude/state/pipeline-journal.log` |

---

## Key Files

| File | Purpose |
|------|---------|
| `~/.claude/state/pipeline-state.json` | Current FSM state |
| `~/.claude/state/pipeline-journal.log` | Audit trail |
| `~/.claude/CLAUDE.md` | Runtime instructions |
| `~/.claude/settings.json` | Hook config |
| `~/.claude/memory/` | Context cache |

---

## Hook Flow

```
SessionStart     → pipeline-gate.sh init       → Create IDLE state
UserPromptSubmit → pipeline-gate.sh check      → Inject workflow if IDLE
PreToolUse(Task) → check-subagent-allowed.sh   → Approve/block agent
SubagentStop     → update-pipeline-state.sh    → Advance state, store context
```

---

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success / Agent approved |
| 1 | Error |
| 2 | Agent blocked (policy violation) |

---

*Keep this handy while working with cccc!*
