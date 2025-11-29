# Claude Code Pipeline Enforcement System

## Overview

This system implements a hook-based pipeline enforcement mechanism for Claude Code that guarantees agent execution follows a strict workflow:

```
IDLE → context-gatherer → REFINING → context-refiner → ORCHESTRATING → strategic-orchestrator → EXECUTING → language agents
```

## Architecture

The system consists of three cooperating bash scripts that communicate via a shared JSON state file at `~/.claude/state/pipeline-state.json`:

1. **pipeline-gate.sh** - Initializes state and injects workflow instructions
2. **check-subagent-allowed.sh** - Enforces state machine transitions (blocks unauthorized agents)
3. **update-pipeline-state.sh** - Advances state after agent completion

## Files

```
~/.claude/scripts/
├── pipeline-gate.sh              # SessionStart & UserPromptSubmit hook handler
├── check-subagent-allowed.sh     # PreToolUse hook handler (Task tool)
├── update-pipeline-state.sh      # SubagentStop hook handler
├── reset-pipeline-state.sh       # Manual state reset utility
└── README.md                     # This file

~/.claude/state/
└── pipeline-state.json           # Shared state file (created automatically)
```

## State Machine

```
┌──────────────────────────────────────────────────────────────────────────┐
│                         State Transitions                                 │
├─────────────┬─────────────────────────────────────┬──────────────────────┤
│ State       │ Allowed Agents                      │ Next State           │
├─────────────┼─────────────────────────────────────┼──────────────────────┤
│ IDLE        │ context-gatherer ONLY               │ GATHERING            │
│ GATHERING   │ context-refiner, utility agents     │ REFINING             │
│ REFINING    │ strategic-orchestrator, utility     │ EXECUTING            │
│ EXECUTING   │ bash-*, nix-*, c-*, utility         │ EXECUTING (stays)    │
│ COMPLETE    │ context-gatherer                    │ GATHERING (restart)  │
├─────────────┴─────────────────────────────────────┴──────────────────────┤
│ IMPORTANT: Utility agents (Explore, Plan, general-purpose) are BLOCKED   │
│ in IDLE state. They may only be used AFTER context-gatherer has run.     │
│ This ensures comprehensive context is gathered before ad-hoc searches.   │
└──────────────────────────────────────────────────────────────────────────┘
```

## State File Schema

```json
{
  "version": "1.0",
  "state": "IDLE|GATHERING|REFINING|ORCHESTRATING|EXECUTING|COMPLETE",
  "timestamp": "ISO8601 timestamp",
  "session_id": "optional session identifier",
  "context": {
    "gathered": "Raw context from context-gatherer agent",
    "refined": "Refined context from context-refiner agent",
    "orchestration": "Orchestrator decisions and selected agents"
  },
  "history": [
    {
      "agent": "agent-name",
      "timestamp": "ISO8601 timestamp",
      "state_before": "previous state",
      "state_after": "new state"
    }
  ]
}
```

## Usage

### Automatic Operation

Once hooks are configured (see Hook Configuration below), the system operates automatically:

1. **Session Start**: State is initialized to IDLE
2. **User Prompt**: Workflow instructions are injected if in IDLE state
3. **Agent Invocation**: System checks if agent is allowed in current state
4. **Agent Completion**: State is advanced to next stage
5. **Repeat**: Continue until pipeline completes

### Manual State Management

#### Reset to IDLE

```bash
~/.claude/scripts/reset-pipeline-state.sh "Reason for reset"
```

This creates a backup at `~/.claude/state/pipeline-state.json.backup` before resetting.

#### Check Current State

```bash
jq -r '.state' ~/.claude/state/pipeline-state.json
```

#### View State History

```bash
jq '.history' ~/.claude/state/pipeline-state.json
```

#### View Gathered Context

```bash
jq -r '.context.gathered' ~/.claude/state/pipeline-state.json
```

## Hook Configuration

The system requires Claude Code hooks to be configured. The exact hook configuration mechanism depends on your Claude Code version.

**Expected hook invocations:**

1. **SessionStart**: `pipeline-gate.sh init`
   - Creates initial IDLE state
   
2. **UserPromptSubmit**: `pipeline-gate.sh check-prompt`
   - Injects workflow instructions if state is IDLE
   - Returns JSON: `{"continue": true, "additional_context": "..."}`
   
3. **PreToolUse** (Task tool only): `check-subagent-allowed.sh < tool_input.json`
   - Receives tool input via stdin
   - Returns JSON: `{"decision": "approve"}` or `{"decision": "block", "reason": "..."}`
   - Exit code 0 = approve, 2 = block
   
4. **SubagentStop**: `AGENT_NAME=agent-name update-pipeline-state.sh < agent_output.json`
   - Receives agent output via stdin
   - AGENT_NAME can be set via environment or extracted from stdin JSON
   - Updates state and stores context

## Troubleshooting

### Pipeline is stuck

```bash
# Check current state
jq . ~/.claude/state/pipeline-state.json

# Reset to IDLE if needed
~/.claude/scripts/reset-pipeline-state.sh "Pipeline stuck in EXECUTING"
```

### Agent blocked unexpectedly

1. Check current state: `jq -r '.state' ~/.claude/state/pipeline-state.json`
2. Review block reason in script logs (stderr)
3. Verify the agent is appropriate for current state (see State Machine table)
4. If legitimate, reset state: `reset-pipeline-state.sh "False positive block"`

### State file missing or corrupted

The system auto-recovers by creating a fresh IDLE state. If persistent:

```bash
# Manually recreate state
~/.claude/scripts/pipeline-gate.sh init
```

### Logs not appearing

All scripts log to stderr with timestamps. Check your Claude Code configuration for stderr handling.

Example log format:
```
[2025-11-25T12:05:21Z] [pipeline-gate.sh] Pipeline state initialized successfully
```

## Design Decisions

### Atomic Writes

All state updates use atomic writes (write to temp file, then `mv`) to prevent corruption during concurrent access.

### Fail-Safe Defaults

- Missing state file → defaults to IDLE
- Invalid JSON → defaults to IDLE  
- Hook errors → allow continuation (don't block legitimate operations)

### Utility Agent Restrictions (UPDATED 2025-11-25)

**IMPORTANT CHANGE**: Utility agents are NO LONGER exempt from the pipeline.

The following agents are now BLOCKED in IDLE state:
- `Explore` - File system exploration
- `Plan` - Task planning
- `general-purpose` - General utility work

**Why this changed**: These agents were being used as shortcuts to bypass proper context gathering, leading to incomplete understanding and mistakes. They are now only allowed AFTER `context-gatherer` has been run.

**New behavior**:
- IDLE state: Only `context-gatherer` allowed
- GATHERING/REFINING/EXECUTING states: Utility agents allowed alongside primary agents

This ensures the main agent always has comprehensive context before making decisions.

### Context Storage

Context from `context-gatherer`, `context-refiner`, and `strategic-orchestrator` is stored in the state file for downstream agents to reference.

## Testing

### Test Script 1: pipeline-gate.sh

```bash
# Initialize state
~/.claude/scripts/pipeline-gate.sh init

# Verify state file
jq . ~/.claude/state/pipeline-state.json

# Test check-prompt in IDLE (should inject workflow)
~/.claude/scripts/pipeline-gate.sh check-prompt

# Advance state to REFINING
jq '.state = "REFINING"' ~/.claude/state/pipeline-state.json > /tmp/state.json
mv /tmp/state.json ~/.claude/state/pipeline-state.json

# Test check-prompt in non-IDLE (should not inject)
~/.claude/scripts/pipeline-gate.sh check-prompt
```

### Test Script 2: check-subagent-allowed.sh

```bash
# Reset to IDLE
~/.claude/scripts/reset-pipeline-state.sh "Testing"

# Test approved agent in IDLE
echo '{"subagent_type": "context-gatherer"}' | \
  ~/.claude/scripts/check-subagent-allowed.sh
# Expected: {"decision": "approve"}

# Test blocked agent in IDLE
echo '{"subagent_type": "bash-architect"}' | \
  ~/.claude/scripts/check-subagent-allowed.sh
echo "Exit code: $?"
# Expected: {"decision": "block", "reason": "..."} and exit code 2

# Test utility agent in IDLE (NOW BLOCKED)
echo '{"subagent_type": "Explore"}' | \
  ~/.claude/scripts/check-subagent-allowed.sh
echo "Exit code: $?"
# Expected: {"decision": "block", "reason": "..."} and exit code 2
# Utility agents require context-gatherer to run first
```

### Test Script 3: update-pipeline-state.sh

```bash
# Reset to IDLE
~/.claude/scripts/reset-pipeline-state.sh "Testing"

# Simulate context-gatherer completion
export AGENT_NAME="context-gatherer"
echo '{"context": "Test context data"}' | \
  ~/.claude/scripts/update-pipeline-state.sh

# Verify state advanced to REFINING
jq -r '.state' ~/.claude/state/pipeline-state.json
# Expected: REFINING

# Verify context was stored
jq -r '.context.gathered' ~/.claude/state/pipeline-state.json
# Expected: Test context data

# Verify history was updated
jq '.history[-1]' ~/.claude/state/pipeline-state.json
# Expected: Entry with agent="context-gatherer", state_after="REFINING"
```

## Dependencies

- **bash** (version 4.0+)
- **jq** (JSON processing)
- **coreutils** (date, mv, cat, etc.)

All scripts check for `jq` availability and fail gracefully if missing.

## Security Considerations

1. **State file location**: `~/.claude/state/` is user-private (mode 755)
2. **Atomic writes**: Prevents race conditions and corruption
3. **Input validation**: All JSON inputs are validated before processing
4. **Fail-safe defaults**: Errors allow continuation rather than blocking
5. **Logging**: All decisions are logged to stderr for audit trail

## Performance

- **Minimal overhead**: Simple jq queries on small JSON files
- **No network calls**: All operations are local
- **Atomic operations**: No locks needed, filesystem provides atomicity
- **Lazy initialization**: State file created only when needed

## Future Enhancements

Potential improvements (not currently implemented):

1. **Session tracking**: Store session_id to isolate parallel workflows
2. **Context caching**: Avoid re-gathering context if unchanged
3. **State persistence**: Backup state across Claude Code restarts
4. **Metrics collection**: Track pipeline success rates and bottlenecks
5. **Dynamic agent rules**: Configure allowed agents via external config file
6. **State visualization**: Pretty-print state machine and current position

## License

Internal use only - part of Claude Code automation infrastructure.

## Authors

Designed following Google Bash Style Guide and BashPitfalls best practices.

Generated: 2025-11-25
