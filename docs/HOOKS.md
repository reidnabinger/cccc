# CCCC Hook Configuration Guide

Complete reference for Claude Code hooks used by the agent pipeline.

---

## Overview

Hooks are shell commands that execute at specific points in the Claude Code lifecycle. CCCC uses hooks to enforce the pipeline state machine.

```
┌─────────────────┐
│  SessionStart   │──► pipeline-gate.sh init
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│UserPromptSubmit │──► pipeline-gate.sh check-prompt
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   PreToolUse    │──► check-subagent-allowed.sh (Task tool)
│                 │──► pipeline-enforce.sh (Read/Write/Edit/etc.)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  SubagentStop   │──► update-pipeline-state.sh
└─────────────────┘
```

---

## settings.json Structure

The hook configuration lives in `~/.claude/settings.json`:

```json
{
  "permissions": {
    "allow": [
      "Bash(export:*)"
    ]
  },
  "hooks": {
    "SessionStart": [...],
    "UserPromptSubmit": [...],
    "PreToolUse": [...],
    "SubagentStop": [...]
  },
  "statusLine": {...},
  "enabledPlugins": {...},
  "alwaysThinkingEnabled": true
}
```

---

## Hook Types

### SessionStart

**Fires**: When a new Claude Code session begins.

**Purpose**: Initialize pipeline state.

**Configuration**:
```json
"SessionStart": [
  {
    "hooks": [
      {
        "type": "command",
        "command": "~/.claude/scripts/pipeline-gate.sh init"
      }
    ]
  }
]
```

**Script Behavior**:
- Creates `~/.claude/state/tasks/_default/pipeline-state.json` if missing
- Sets state to IDLE
- Records session start in journal

**Output**: Success message or error to stderr

---

### UserPromptSubmit

**Fires**: When user submits a message (before Claude processes it).

**Purpose**: Inject workflow instructions when pipeline is IDLE.

**Configuration**:
```json
"UserPromptSubmit": [
  {
    "hooks": [
      {
        "type": "command",
        "command": "~/.claude/scripts/pipeline-gate.sh check-prompt"
      }
    ]
  }
]
```

**Script Behavior**:
- Checks current pipeline state
- If IDLE: Returns JSON with `additional_context` containing workflow instructions
- If not IDLE: Returns empty response (no injection)

**Output Format**:
```json
{
  "continue": true,
  "additional_context": "Pipeline workflow instructions..."
}
```

---

### PreToolUse

**Fires**: Before Claude executes any tool.

**Purpose**: Gate tool usage based on pipeline state.

**Configuration**:
```json
"PreToolUse": [
  {
    "matcher": "Task",
    "hooks": [
      {
        "type": "command",
        "command": "~/.claude/scripts/check-subagent-allowed.sh"
      }
    ]
  },
  {
    "matcher": "Read",
    "hooks": [
      {
        "type": "command",
        "command": "~/.claude/scripts/pipeline-enforce.sh"
      }
    ]
  }
]
```

**Matchers**:
- `"Task"` - Matches Task tool (agent invocations)
- `"Read"`, `"Write"`, `"Edit"` - File operations
- `"Glob"`, `"Grep"` - Search operations
- `"WebSearch"`, `"WebFetch"` - Web operations
- `"*"` - Matches all tools

**Script Behavior** (check-subagent-allowed.sh):
- Reads tool input from stdin (JSON with `subagent_type`)
- Checks if agent is allowed in current state
- Returns approval or block decision

**Output Format**:
```json
// Approval
{"decision": "approve"}

// Block
{"decision": "block", "reason": "Must start with context-gatherer"}
```

**Exit Codes**:
- `0` - Tool approved
- `1` - Error (tool may proceed)
- `2` - Tool blocked (policy violation)

---

### SubagentStop

**Fires**: When a spawned agent completes.

**Purpose**: Advance pipeline state and store context.

**Configuration**:
```json
"SubagentStop": [
  {
    "hooks": [
      {
        "type": "command",
        "command": "~/.claude/scripts/update-pipeline-state.sh"
      }
    ]
  }
]
```

**Script Behavior**:
- Reads agent output from stdin
- Extracts agent name from environment (`AGENT_NAME`) or input
- Determines next state based on current state and agent
- Stores context from pipeline agents
- Updates state file atomically

**State Transitions**:
| Current State | Agent | Next State |
|---------------|-------|------------|
| IDLE | context-gatherer | GATHERING |
| IDLE | task-classifier | CLASSIFIED |
| CLASSIFIED | context-gatherer | GATHERING |
| GATHERING | context-refiner | REFINING |
| REFINING | strategic-orchestrator | ORCHESTRATING_ACTIVE |
| ORCHESTRATING_ACTIVE | * | EXECUTING |
| EXECUTING | * | EXECUTING (stays) |

---

## Complete settings.json Example

```json
{
  "permissions": {
    "allow": [
      "Bash(export:*)",
      "Bash(tree:*)",
      "Bash(chezmoi apply:*)"
    ]
  },
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/scripts/pipeline-gate.sh init"
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/scripts/pipeline-gate.sh check-prompt"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Read",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/scripts/pipeline-enforce.sh"
          }
        ]
      },
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/scripts/pipeline-enforce.sh"
          }
        ]
      },
      {
        "matcher": "Edit",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/scripts/pipeline-enforce.sh"
          }
        ]
      },
      {
        "matcher": "Glob",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/scripts/pipeline-enforce.sh"
          }
        ]
      },
      {
        "matcher": "Grep",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/scripts/pipeline-enforce.sh"
          }
        ]
      },
      {
        "matcher": "WebSearch",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/scripts/pipeline-enforce.sh"
          }
        ]
      },
      {
        "matcher": "WebFetch",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/scripts/pipeline-enforce.sh"
          }
        ]
      },
      {
        "matcher": "Task",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/scripts/check-subagent-allowed.sh"
          }
        ]
      }
    ],
    "SubagentStop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/scripts/update-pipeline-state.sh"
          }
        ]
      }
    ]
  },
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline-command.sh"
  },
  "enabledPlugins": {
    "pr-review-toolkit@claude-code-plugins": true,
    "commit-commands@claude-code-plugins": true,
    "feature-dev@claude-code-plugins": true,
    "security-guidance@claude-code-plugins": true,
    "code-review@claude-code-plugins": true,
    "explanatory-output-style@claude-code-plugins": true
  },
  "alwaysThinkingEnabled": true
}
```

---

## Hook Scripts Reference

### pipeline-gate.sh

**Location**: `~/.claude/scripts/pipeline-gate.sh`

**Commands**:
- `init` - Initialize state file to IDLE
- `check-prompt` - Check if workflow injection needed

**Usage**:
```bash
# Initialize
~/.claude/scripts/pipeline-gate.sh init

# Check prompt (outputs JSON)
~/.claude/scripts/pipeline-gate.sh check-prompt
```

### check-subagent-allowed.sh

**Location**: `~/.claude/scripts/check-subagent-allowed.sh`

**Input**: JSON on stdin with `subagent_type` field

**Output**: JSON decision

**Usage**:
```bash
echo '{"subagent_type": "context-gatherer"}' | \
  ~/.claude/scripts/check-subagent-allowed.sh
```

### update-pipeline-state.sh

**Location**: `~/.claude/scripts/update-pipeline-state.sh`

**Input**: Agent output on stdin (optional)

**Environment**: `AGENT_NAME` should be set

**Usage**:
```bash
AGENT_NAME="context-gatherer" \
  echo '{"context": "..."}' | \
  ~/.claude/scripts/update-pipeline-state.sh
```

### reset-pipeline-state.sh

**Location**: `~/.claude/scripts/reset-pipeline-state.sh`

**Arguments**: Optional reason string

**Usage**:
```bash
~/.claude/scripts/reset-pipeline-state.sh "Manual reset"
```

### pipeline-enforce.sh

**Location**: `~/.claude/scripts/pipeline-enforce.sh`

**Purpose**: Enforce pipeline state for non-Task tools

**Usage**: Called automatically by PreToolUse hooks

---

## Debugging Hooks

### View Hook Output

```bash
# Test a hook manually
~/.claude/scripts/pipeline-gate.sh init 2>&1

# Test with input
echo '{"subagent_type": "bash-architect"}' | \
  ~/.claude/scripts/check-subagent-allowed.sh 2>&1
```

### Enable Verbose Logging

Add to the top of hook scripts:
```bash
set -x  # Print commands as executed
PS4='+ ${BASH_SOURCE}:${LINENO}: '  # Better trace format
```

### View Journal

```bash
# Real-time journal
tail -f ~/.claude/state/pipeline-journal.log

# Recent entries
tail -50 ~/.claude/state/pipeline-journal.log
```

### Check Hook Configuration

```bash
# Verify hooks are configured
jq '.hooks | keys' ~/.claude/settings.json

# See all hooks for a type
jq '.hooks.PreToolUse' ~/.claude/settings.json
```

---

## Common Hook Issues

### Hook Not Firing

**Symptoms**: Pipeline state not changing, no journal entries

**Causes**:
1. settings.json not deployed
2. Hook command path wrong
3. Script not executable

**Fix**:
```bash
chezmoi apply
chmod +x ~/.claude/scripts/*.sh
```

### Hook Blocking Everything

**Symptoms**: All agents blocked

**Causes**:
1. State file corrupted
2. Wrong state recorded

**Fix**:
```bash
~/.claude/scripts/reset-pipeline-state.sh "Reset for debugging"
```

### Hook Errors in stderr

**Symptoms**: Error messages but operation continues

**Causes**:
1. jq not installed
2. State file permissions
3. Script syntax error

**Fix**:
```bash
# Check jq
which jq

# Check permissions
ls -la ~/.claude/state/

# Test script
bash -n ~/.claude/scripts/check-subagent-allowed.sh
```

---

## Adding Custom Hooks

### Example: Logging Hook

**Create script** (`~/.claude/scripts/log-activity.sh`):
```bash
#!/usr/bin/env bash
set -euo pipefail

LOG="${HOME}/.claude/state/activity.log"
TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Read input
INPUT="$(cat)"
TOOL="$(echo "${INPUT}" | jq -r '.tool_name // "unknown"')"

# Log
echo "[${TIMESTAMP}] ${TOOL}" >> "${LOG}"

# Approve
echo '{"decision": "approve"}'
```

**Register in settings.json**:
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/scripts/log-activity.sh"
          }
        ]
      }
    ]
  }
}
```

### Hook Order

Multiple hooks for the same event run in order. The first hook that blocks will prevent the operation.

```json
"PreToolUse": [
  {"matcher": "Task", "hooks": [
    {"command": "first-hook.sh"},   // Runs first
    {"command": "second-hook.sh"}   // Runs if first approves
  ]}
]
```

---

## Security Considerations

### Script Permissions

Hook scripts should be:
- Owned by you
- Not world-writable
- Executable only by owner

```bash
chmod 700 ~/.claude/scripts/*.sh
```

### Input Validation

Hook scripts should validate input:
```bash
# Validate JSON input
if ! INPUT="$(cat)" || ! echo "${INPUT}" | jq -e . >/dev/null 2>&1; then
  echo '{"decision": "approve"}' # Fail-safe
  exit 0
fi
```

### Fail-Safe Defaults

Hooks should fail-safe (allow operation) on errors to avoid blocking legitimate work:
```bash
# If anything goes wrong, approve
trap 'echo "{\"decision\": \"approve\"}"; exit 0' ERR
```

---

*Last updated: November 2025*
