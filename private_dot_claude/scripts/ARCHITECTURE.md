# Pipeline Enforcement Architecture Document

## Executive Summary

This system implements a finite state machine (FSM) that enforces a mandatory workflow for Claude Code agent execution. The architecture guarantees that complex tasks follow a structured pipeline: **gather context → refine context → orchestrate → execute**. This prevents premature execution without proper context and planning.

## Design Goals

1. **Guarantee workflow compliance** - Make it impossible to skip pipeline stages
2. **Fail-safe defaults** - Errors should not block legitimate operations
3. **Minimal overhead** - Fast JSON operations, no network calls
4. **Auditability** - All decisions logged with timestamps
5. **Easy recovery** - Simple manual reset when needed

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                   Hook-Based Architecture                    │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  SessionStart Hook                                           │
│       │                                                      │
│       ▼                                                      │
│  pipeline-gate.sh init                                       │
│       │                                                      │
│       └──► Creates state file: ~/.claude/state/pipeline-    │
│            state.json with initial IDLE state                │
│                                                              │
│  UserPromptSubmit Hook                                       │
│       │                                                      │
│       ▼                                                      │
│  pipeline-gate.sh check-prompt                               │
│       │                                                      │
│       ├─► If IDLE: inject workflow instructions             │
│       └─► Otherwise: allow without injection                │
│                                                              │
│  PreToolUse Hook (Task tool only)                            │
│       │                                                      │
│       ▼                                                      │
│  check-subagent-allowed.sh < tool_input.json                 │
│       │                                                      │
│       ├─► Read current state                                │
│       ├─► Check if agent allowed in state                   │
│       ├─► Approve (exit 0) or Block (exit 2)                │
│       └─► Log decision to stderr                            │
│                                                              │
│  SubagentStop Hook                                           │
│       │                                                      │
│       ▼                                                      │
│  AGENT_NAME=... update-pipeline-state.sh < output.json       │
│       │                                                      │
│       ├─► Read current state                                │
│       ├─► Determine next state based on agent               │
│       ├─► Extract and store context                         │
│       ├─► Update state file atomically                      │
│       └─► Log transition to stderr                          │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Component Design

### 1. pipeline-gate.sh

**Purpose**: Initialize state and inject workflow instructions when needed.

**Functions**:
- `initialize_state()` - Create IDLE state file
- `check_prompt()` - Inject workflow if IDLE, allow otherwise
- `create_initial_state()` - Generate fresh state JSON
- `write_state_atomic()` - Atomic file write (temp + mv)

**Key Design Decisions**:
- Only injects workflow instructions in IDLE state (avoids spam)
- Uses atomic writes to prevent corruption
- Fail-safe: errors allow continuation without injection

### 2. check-subagent-allowed.sh

**Purpose**: Enforce state machine transitions by blocking unauthorized agents.

**Functions**:
- `read_tool_input()` - Parse agent name from JSON stdin
- `load_current_state()` - Read state file, default to IDLE on error
- `is_agent_allowed()` - Core FSM logic
- `is_utility_agent()` - Check bypass list
- `approve_agent()` / `block_agent()` - Return decision JSON + exit code

**State Machine Logic** (UPDATED 2025-11-25):
```
IDLE:        allow context-gatherer ONLY (utility agents BLOCKED)
GATHERING:   allow context-refiner + utility agents
REFINING:    allow strategic-orchestrator + utility agents
EXECUTING:   allow bash-*, nix-*, c-* + utility agents
COMPLETE:    allow context-gatherer (restart)

Utility agents (Explore, Plan, general-purpose):
  - BLOCKED in IDLE state
  - Allowed in GATHERING, REFINING, EXECUTING states
```

**Key Design Decisions**:
- Utility agents NO LONGER bypass IDLE state (prevents skipping context gathering)
- Utility agents allowed after context-gatherer runs (for narrow follow-up queries)
- Exit code 2 for blocks enables hook enforcement
- Fail-safe: errors approve to avoid blocking legitimate ops

### 3. update-pipeline-state.sh

**Purpose**: Advance state machine after agent completion and store context.

**Functions**:
- `read_agent_output()` - Parse agent output, wrap non-JSON
- `determine_next_state()` - FSM transition logic
- `extract_context_from_agent()` - Parse context fields
- `update_state_file()` - Atomic state update with history

**State Transitions**:
```
context-gatherer:        IDLE → GATHERING
context-refiner:         GATHERING → REFINING
strategic-orchestrator:  REFINING → EXECUTING
language agents:         EXECUTING → EXECUTING (stays)
```

**Key Design Decisions**:
- Extracts context from specific agents (gatherer, refiner, orchestrator)
- History tracks all transitions with timestamps
- Language agents don't auto-transition (manual COMPLETE needed)

### 4. reset-pipeline-state.sh

**Purpose**: Manual reset utility for stuck pipelines.

**Functions**:
- `reset_state()` - Reset to IDLE, preserve history, create backup

**Key Design Decisions**:
- Always creates backup before reset
- Adds reset entry to history with reason
- Useful for manual intervention and debugging

## Data Flow

```
User Prompt
    │
    ▼
[check-prompt] ─────► Inject workflow if IDLE
    │
    │
User invokes Task tool (agent)
    │
    ▼
[check-subagent-allowed] ─────► FSM check ─────┬─► Approve (exit 0)
    │                                           └─► Block (exit 2)
    │
    ▼ (if approved)
Agent executes
    │
    ▼
Agent completes
    │
    ▼
[update-pipeline-state] ─────► Advance FSM ────► Store context
    │
    ▼
State file updated
```

## State File Schema

```json
{
  "version": "1.0",
  "state": "IDLE|GATHERING|REFINING|EXECUTING|COMPLETE",
  "timestamp": "ISO8601",
  "session_id": "",
  "context": {
    "gathered": "...",
    "refined": "...",
    "orchestration": "..."
  },
  "history": [
    {
      "agent": "agent-name",
      "timestamp": "ISO8601",
      "state_before": "...",
      "state_after": "..."
    }
  ]
}
```

## Atomicity Guarantees

All state updates use the following pattern:

```bash
temp_file="${STATE_DIR}/.pipeline-state.tmp.$$"
echo "${new_state}" > "${temp_file}"
mv "${temp_file}" "${STATE_FILE}"  # Atomic on POSIX filesystems
```

This ensures:
- No partial writes (filesystem atomic rename)
- No race conditions between concurrent updates
- Corruption-resistant (interrupted writes don't affect existing state)

## Error Handling Strategy

### Defensive Defaults

**Missing state file**: Create fresh IDLE state
**Invalid JSON**: Default to IDLE, log warning
**jq not found**: Fail with clear error message
**Agent name missing**: Try to extract from input, error if impossible
**Hook errors**: Allow continuation (fail-safe)

### Logging

All scripts log to stderr with format:
```
[2025-11-25T12:05:21Z] [script-name] Message
```

Logs include:
- State transitions
- Approvals/blocks with reasons
- Errors with context
- Warnings for unexpected conditions

## Performance Characteristics

- **State file size**: ~1-10KB typical, grows with history
- **jq parse time**: <10ms for typical state file
- **Hook overhead**: ~50ms per invocation (3 hooks per agent)
- **No network calls**: All operations local
- **No locks needed**: Atomic operations provided by filesystem

## Security Considerations

1. **State file permissions**: User-private (~/.claude/state/)
2. **No code execution**: Only JSON parsing and state updates
3. **Input validation**: All JSON inputs validated before use
4. **Logging**: Audit trail of all decisions
5. **No secrets**: State file contains only workflow data

## Extension Points

### Adding New Agents

To allow a new language-specific agent:

Edit `check-subagent-allowed.sh`, update regex in EXECUTING state:
```bash
if [[ "${agent}" =~ ^(bash-|nix-|c-|rust-) ]]; then
```

### Adding New States

1. Add state to schema
2. Update `determine_next_state()` in update-pipeline-state.sh
3. Update `is_agent_allowed()` in check-subagent-allowed.sh
4. Update documentation

### Custom Context Extraction

Edit `extract_context_from_agent()` in update-pipeline-state.sh to parse agent-specific output formats.

## Testing

Comprehensive test suite at `/tmp/test-pipeline-system.sh` covers:
- State initialization
- Workflow injection
- Agent approvals/blocks in each state
- State transitions
- Utility agent bypass
- Context storage
- History tracking
- Reset functionality

Run tests:
```bash
/tmp/test-pipeline-system.sh
```

## Maintenance

### Backup and Recovery

**Backup creation**: Automatic on reset
**Backup location**: `~/.claude/state/pipeline-state.json.backup`

**Manual backup**:
```bash
cp ~/.claude/state/pipeline-state.json \
   ~/.claude/state/pipeline-state.json.manual-backup
```

**Restore from backup**:
```bash
cp ~/.claude/state/pipeline-state.json.backup \
   ~/.claude/state/pipeline-state.json
```

### Monitoring

**Check state health**:
```bash
jq '{state, timestamp, history_count: (.history | length)}' \
   ~/.claude/state/pipeline-state.json
```

**View recent activity**:
```bash
jq '.history[-10:]' ~/.claude/state/pipeline-state.json
```

## Known Limitations

1. **No session isolation**: Single global state (could add session_id tracking)
2. **No automatic rollback**: Manual reset required if stuck
3. **No state expiration**: Old states persist until reset
4. **No metrics collection**: Could add performance tracking
5. **No distributed state**: Single-machine only

## Future Enhancements

1. **Session tracking**: Isolate parallel workflows with session IDs
2. **State TTL**: Auto-reset stale states after timeout
3. **Metrics dashboard**: Visualize pipeline success rates
4. **Dynamic rules**: Load agent rules from config file
5. **State visualization**: ASCII/HTML diagrams of current position
6. **Checkpoint/restore**: Save/load pipeline state across restarts

## Dependencies

- **bash** 4.0+ (associative arrays, `[[ ]]` conditionals)
- **jq** (JSON parsing and manipulation)
- **coreutils** (date, mv, cat, chmod)

All dependencies checked at runtime with clear error messages.

## License

Internal use only - part of Claude Code automation infrastructure.

## Version History

- **1.0** (2025-11-25): Initial implementation with FSM enforcement
REF_EOF
