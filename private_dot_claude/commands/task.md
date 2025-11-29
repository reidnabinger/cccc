---
description: Manage task namespaces for parallel pipeline work
---

Manage task namespaces to allow independent pipeline states for parallel work.

## Subcommands

Arguments: "$ARGUMENTS"

Parse the arguments to determine the subcommand:
- `create <name>` - Create new namespace and switch to it
- `list` - List all available namespaces with status
- `join <name>` - Switch to an existing namespace
- `leave` - Return to default namespace
- `status` - Show current namespace status
- `destroy <name>` - Delete a namespace (requires IDLE/COMPLETE state)
- `complete [description]` - Mark current task as complete (triggers documentation checkpoint)
- `docs` - Show documentation checkpoint checklist
- `docs-complete` - Clear documentation checkpoint (after docs are done)

## Execution

First, source the namespace utilities:

```bash
source ~/.claude/scripts/namespace-utils.sh
```

### Parse Arguments

```bash
ARGS="$ARGUMENTS"
SUBCOMMAND="${ARGS%% *}"
NAMESPACE_ARG="${ARGS#* }"
if [[ "${SUBCOMMAND}" == "${NAMESPACE_ARG}" ]]; then
  NAMESPACE_ARG=""
fi
echo "Subcommand: ${SUBCOMMAND}"
echo "Namespace arg: ${NAMESPACE_ARG}"
```

### Execute Subcommand

Based on the parsed subcommand, execute one of the following:

#### create

If subcommand is "create":

1. Validate namespace name (alphanumeric, hyphens, underscores only):
```bash
source ~/.claude/scripts/namespace-utils.sh
NAMESPACE="$NAMESPACE_ARG"
if [[ ! "${NAMESPACE}" =~ ^[a-zA-Z0-9_-]+$ ]]; then
  echo "ERROR: Invalid namespace name. Use only letters, numbers, hyphens, underscores."
  exit 1
fi
if namespace_exists "${NAMESPACE}"; then
  echo "ERROR: Namespace '${NAMESPACE}' already exists. Use 'join' to switch to it."
  exit 1
fi
```

2. Create the namespace:
```bash
source ~/.claude/scripts/namespace-utils.sh
ensure_namespace_dir "${NAMESPACE}"
echo "Created namespace: ${NAMESPACE}"
echo ""
echo "To use this namespace, set the environment variable:"
echo "  export CLAUDE_TASK_NAMESPACE='${NAMESPACE}'"
echo ""
echo "Or start a new Claude Code session with:"
echo "  CLAUDE_TASK_NAMESPACE='${NAMESPACE}' claude"
```

#### list

If subcommand is "list":

```bash
source ~/.claude/scripts/namespace-utils.sh
migrate_legacy_state  # Ensure legacy state is migrated
echo "Available namespaces:"
echo ""
for ns in $(list_namespaces); do
  status=$(get_namespace_status "${ns}")
  state=$(echo "${status}" | jq -r '.state // "UNKNOWN"')
  mode=$(echo "${status}" | jq -r '.pipeline_mode // "none"')
  current=""
  if [[ "${ns}" == "$(get_namespace)" ]]; then
    current=" (current)"
  fi
  printf "  %-20s  state: %-12s  mode: %s%s\n" "${ns}" "${state}" "${mode}" "${current}"
done
```

#### join

If subcommand is "join":

```bash
source ~/.claude/scripts/namespace-utils.sh
NAMESPACE="$NAMESPACE_ARG"
if ! namespace_exists "${NAMESPACE}"; then
  echo "ERROR: Namespace '${NAMESPACE}' does not exist. Use 'create' first."
  exit 1
fi
echo "To join namespace '${NAMESPACE}', set the environment variable:"
echo "  export CLAUDE_TASK_NAMESPACE='${NAMESPACE}'"
echo ""
echo "Or start a new Claude Code session with:"
echo "  CLAUDE_TASK_NAMESPACE='${NAMESPACE}' claude"
echo ""
echo "Current namespace status:"
get_namespace_status "${NAMESPACE}" | jq .
```

#### leave

If subcommand is "leave":

```bash
echo "To return to the default namespace, unset the environment variable:"
echo "  unset CLAUDE_TASK_NAMESPACE"
echo ""
echo "Or start a new Claude Code session without the variable."
```

#### status

If subcommand is "status" or empty:

```bash
source ~/.claude/scripts/namespace-utils.sh
migrate_legacy_state  # Ensure legacy state is migrated
CURRENT_NS=$(get_namespace)
echo "Current namespace: ${CURRENT_NS}"
echo ""
STATE_FILE=$(get_state_file)
if [[ -f "${STATE_FILE}" ]]; then
  echo "Pipeline state:"
  jq '{
    namespace: .namespace,
    state: .state,
    pipeline_mode: .pipeline_mode,
    timestamp: .timestamp,
    active_agents: (.active_agents // [])
  }' "${STATE_FILE}"
else
  echo "No state file found. Run context-gatherer to initialize."
fi
```

#### destroy

If subcommand is "destroy":

```bash
source ~/.claude/scripts/namespace-utils.sh
NAMESPACE="$NAMESPACE_ARG"
if [[ -z "${NAMESPACE}" ]]; then
  echo "ERROR: Must specify namespace to destroy"
  exit 1
fi
delete_namespace "${NAMESPACE}"
```

#### complete

If subcommand is "complete":

Mark the current task as complete. This transitions the pipeline to COMPLETE state
and creates a documentation checkpoint that must be addressed before starting new work.

```bash
source ~/.claude/scripts/namespace-utils.sh
TASK_DESC="${NAMESPACE_ARG:-Task completed}"
complete_task "$(get_namespace)" "${TASK_DESC}"
```

After running this, you MUST complete the documentation checkpoint before starting
new pipeline work. The checkpoint includes:
- Adding DEV-NOTEs to explain tricky code
- Creating diagrams for complex interactions
- Updating architecture docs if structure changed
- Recording key decisions and rationale

#### docs

If subcommand is "docs":

Display the documentation checkpoint checklist for the current namespace.

```bash
source ~/.claude/scripts/namespace-utils.sh
display_documentation_checklist
```

#### docs-complete

If subcommand is "docs-complete":

Clear the documentation checkpoint after documentation is complete.
This allows new pipeline work to proceed.

```bash
source ~/.claude/scripts/namespace-utils.sh
NOTES="${NAMESPACE_ARG:-Documentation completed}"
clear_documentation_checkpoint "$(get_namespace)" "${NOTES}"
```

## Notes

- Each namespace has its own independent FSM state
- Namespaces allow parallel Claude Code instances to work independently
- The `_default` namespace is used when no namespace is specified
- Legacy state files are automatically migrated to the `_default` namespace
- Environment variable `CLAUDE_TASK_NAMESPACE` controls which namespace is active

### Documentation Checkpoint

When you run `/task complete`, a documentation checkpoint is created. This enforces
that documentation is written while context is fresh - before you can start new work.

The checkpoint requires:
1. **DEV-NOTEs**: Comments explaining tricky code, workarounds, non-obvious behavior
2. **Decision Log**: Record key decisions and their rationale
3. **Diagrams** (conditional): Visual representations of complex interactions
4. **Architecture Docs** (conditional): Updates if structure changed

This ensures future maintainers (including future you) can understand what happened.

## Examples

```bash
# Create a new namespace for auth work
/task create auth-refactor

# In terminal 1:
export CLAUDE_TASK_NAMESPACE='auth-refactor'
claude

# In terminal 2 (different task):
export CLAUDE_TASK_NAMESPACE='perf-audit'
claude

# Both can run their pipelines independently
```

### Documentation Workflow

```bash
# After completing work on a task:
/task complete "Implemented task namespace isolation"

# This shows the documentation checklist
# Now add DEV-NOTEs, update docs, create diagrams as needed

# When documentation is complete:
/task docs-complete "Added DEV-NOTEs to namespace-utils.sh, updated ARCHITECTURE.md"

# Now you can start new work
```
