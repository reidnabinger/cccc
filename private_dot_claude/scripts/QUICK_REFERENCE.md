# Pipeline Scripts Quick Reference

> **Note**: For general user quick reference, see [docs/QUICKREF.md](../../docs/QUICKREF.md).
> This document focuses on script implementation details.

## State Machine Flow

```
┌───────────────────────────────────────────────────────────────────┐
│                   Pipeline State Machine                           │
├──────────────┬──────────────────────────────┬─────────────────────┤
│ Current State│ Allowed Agents               │ Next State          │
├──────────────┼──────────────────────────────┼─────────────────────┤
│ IDLE         │ context-gatherer ONLY        │ → GATHERING         │
│ GATHERING    │ context-refiner + utility    │ → REFINING          │
│ REFINING     │ strategic-orch. + utility    │ → EXECUTING         │
│ EXECUTING    │ bash-*, nix-*, c-* + utility │ → EXECUTING (stays) │
│ COMPLETE     │ context-gatherer             │ → GATHERING         │
└──────────────┴──────────────────────────────┴─────────────────────┘

⚠️  Utility Agents (Explore, Plan, general-purpose):
    BLOCKED in IDLE - must run context-gatherer first!
    Allowed in all other states.
```

## Common Commands

### Check Current State
```bash
jq -r '.state' ~/.claude/state/pipeline-state.json
```

### View Full State
```bash
jq . ~/.claude/state/pipeline-state.json
```

### View History
```bash
jq '.history' ~/.claude/state/pipeline-state.json
```

### View Stored Context
```bash
# Gathered context (from context-gatherer)
jq -r '.context.gathered' ~/.claude/state/pipeline-state.json

# Refined context (from context-refiner)
jq -r '.context.refined' ~/.claude/state/pipeline-state.json

# Orchestration plan (from strategic-orchestrator)
jq -r '.context.orchestration' ~/.claude/state/pipeline-state.json
```

### Reset Pipeline
```bash
~/.claude/scripts/reset-pipeline-state.sh "Reason for reset"
```

### Initialize Fresh State
```bash
~/.claude/scripts/pipeline-gate.sh init
```

## Scripts

| Script                       | Purpose                           |
|------------------------------|-----------------------------------|
| pipeline-gate.sh             | Init state, inject workflow       |
| check-subagent-allowed.sh    | Enforce agent restrictions        |
| update-pipeline-state.sh     | Advance state after agent runs    |
| reset-pipeline-state.sh      | Manual reset to IDLE              |

## Troubleshooting

### Agent Blocked Unexpectedly
1. Check state: `jq -r '.state' ~/.claude/state/pipeline-state.json`
2. Check logs (stderr) for reason
3. Verify agent matches allowed agents for current state
4. If false positive: `reset-pipeline-state.sh "False positive"`

### Pipeline Stuck
```bash
# View current state and last few transitions
jq '{state, last_3: .history[-3:]}' ~/.claude/state/pipeline-state.json

# Reset if needed
~/.claude/scripts/reset-pipeline-state.sh "Pipeline stuck"
```

### State File Corrupted
```bash
# System auto-recovers, but you can manually reinitialize
~/.claude/scripts/pipeline-gate.sh init
```

## State File Location

- State file: `~/.claude/state/pipeline-state.json`
- Backup (after reset): `~/.claude/state/pipeline-state.json.backup`

## Exit Codes

- **0**: Success / Approved
- **1**: Error (missing dependencies, invalid state)
- **2**: Agent blocked (policy violation)

## Hook Integration Points

| Hook               | Handler                                  |
|--------------------|------------------------------------------|
| SessionStart       | `pipeline-gate.sh init`                  |
| UserPromptSubmit   | `pipeline-gate.sh check-prompt`          |
| PreToolUse (Task)  | `check-subagent-allowed.sh < stdin`      |
| SubagentStop       | `AGENT_NAME=... update-pipeline-state.sh`|
