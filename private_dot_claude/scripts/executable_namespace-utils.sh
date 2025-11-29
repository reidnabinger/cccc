#!/usr/bin/env bash
#
# namespace-utils.sh - Shared utilities for task namespace support
#
# Source this file in other scripts to get namespace-aware paths:
#   source "${HOME}/.claude/scripts/namespace-utils.sh"
#
# Provides:
#   get_namespace()        - Returns current namespace (from env or default)
#   get_state_dir()        - Returns namespace-specific state directory
#   get_state_file()       - Returns namespace-specific pipeline-state.json path
#   get_journal_file()     - Returns namespace-specific journal log path
#   ensure_namespace_dir() - Creates namespace directory if needed
#   list_namespaces()      - Lists all available namespaces
#   namespace_exists()     - Checks if a namespace exists
#
# Environment variables:
#   CLAUDE_TASK_NAMESPACE - Current task namespace (default: _default)

# Prevent multiple sourcing
if [[ -n "${_NAMESPACE_UTILS_LOADED:-}" ]]; then
  return 0
fi
readonly _NAMESPACE_UTILS_LOADED=1

# Base directories
readonly NAMESPACE_BASE_DIR="${HOME}/.claude/state/tasks"
readonly DEFAULT_NAMESPACE="_default"

#######################################
# Get current task namespace
# Environment:
#   CLAUDE_TASK_NAMESPACE - Override namespace (optional)
# Outputs:
#   Namespace name to stdout
#######################################
function get_namespace() {
  echo "${CLAUDE_TASK_NAMESPACE:-${DEFAULT_NAMESPACE}}"
}

#######################################
# Get namespace-specific state directory
# Arguments:
#   $1 - Namespace (optional, uses current if not provided)
# Outputs:
#   Directory path to stdout
#######################################
function get_state_dir() {
  local -r namespace="${1:-$(get_namespace)}"
  echo "${NAMESPACE_BASE_DIR}/${namespace}"
}

#######################################
# Get namespace-specific pipeline state file path
# Arguments:
#   $1 - Namespace (optional, uses current if not provided)
# Outputs:
#   File path to stdout
#######################################
function get_state_file() {
  local -r namespace="${1:-$(get_namespace)}"
  echo "$(get_state_dir "${namespace}")/pipeline-state.json"
}

#######################################
# Get namespace-specific journal file path
# Arguments:
#   $1 - Namespace (optional, uses current if not provided)
# Outputs:
#   File path to stdout
#######################################
function get_journal_file() {
  local -r namespace="${1:-$(get_namespace)}"
  echo "$(get_state_dir "${namespace}")/pipeline-journal.log"
}

#######################################
# Get namespace-specific actors file path (for multi-instance tracking)
# Arguments:
#   $1 - Namespace (optional, uses current if not provided)
# Outputs:
#   File path to stdout
#######################################
function get_actors_file() {
  local -r namespace="${1:-$(get_namespace)}"
  echo "$(get_state_dir "${namespace}")/actors.json"
}

#######################################
# Ensure namespace directory exists with initial state
# Arguments:
#   $1 - Namespace (optional, uses current if not provided)
# Returns:
#   0 on success, 1 on failure
#######################################
function ensure_namespace_dir() {
  local -r namespace="${1:-$(get_namespace)}"
  local -r state_dir="$(get_state_dir "${namespace}")"
  local -r state_file="$(get_state_file "${namespace}")"

  # Create directory
  if ! mkdir -p "${state_dir}"; then
    echo "ERROR: Failed to create namespace directory: ${state_dir}" >&2
    return 1
  fi

  # Initialize state file if it doesn't exist
  if [[ ! -f "${state_file}" ]]; then
    local -r timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    cat > "${state_file}" << EOF
{
  "namespace": "${namespace}",
  "state": "IDLE",
  "timestamp": "${timestamp}",
  "pipeline_mode": null,
  "context": {
    "gathered": "",
    "refined": "",
    "orchestration": ""
  },
  "history": [
    {
      "agent": "namespace-init",
      "timestamp": "${timestamp}",
      "state_before": null,
      "state_after": "IDLE",
      "reason": "Namespace created"
    }
  ]
}
EOF
    if [[ $? -ne 0 ]]; then
      echo "ERROR: Failed to initialize state file: ${state_file}" >&2
      return 1
    fi
  fi

  return 0
}

#######################################
# List all available namespaces
# Outputs:
#   One namespace per line to stdout
#######################################
function list_namespaces() {
  if [[ ! -d "${NAMESPACE_BASE_DIR}" ]]; then
    return 0
  fi

  # List directories that contain a pipeline-state.json
  for dir in "${NAMESPACE_BASE_DIR}"/*/; do
    if [[ -d "${dir}" && -f "${dir}pipeline-state.json" ]]; then
      basename "${dir}"
    fi
  done
}

#######################################
# Check if a namespace exists
# Arguments:
#   $1 - Namespace name
# Returns:
#   0 if exists, 1 if not
#######################################
function namespace_exists() {
  local -r namespace="$1"
  local -r state_file="$(get_state_file "${namespace}")"
  [[ -f "${state_file}" ]]
}

#######################################
# Get namespace status summary
# Arguments:
#   $1 - Namespace name
# Outputs:
#   JSON status to stdout
#######################################
function get_namespace_status() {
  local -r namespace="$1"
  local -r state_file="$(get_state_file "${namespace}")"

  if [[ ! -f "${state_file}" ]]; then
    echo '{"error": "Namespace not found"}'
    return 1
  fi

  jq -c '{
    namespace: .namespace,
    state: .state,
    pipeline_mode: .pipeline_mode,
    timestamp: .timestamp,
    active_agents: (.active_agents // [])
  }' "${state_file}" 2>/dev/null || echo '{"error": "Failed to read state"}'
}

#######################################
# Delete a namespace (with safety checks)
# Arguments:
#   $1 - Namespace name
#   $2 - Force flag (optional, "force" to skip confirmation)
# Returns:
#   0 on success, 1 on failure
#######################################
function delete_namespace() {
  local -r namespace="$1"
  local -r force="${2:-}"
  local -r state_dir="$(get_state_dir "${namespace}")"

  # Safety: never delete default namespace
  if [[ "${namespace}" == "${DEFAULT_NAMESPACE}" ]]; then
    echo "ERROR: Cannot delete default namespace" >&2
    return 1
  fi

  # Safety: check namespace exists
  if [[ ! -d "${state_dir}" ]]; then
    echo "ERROR: Namespace does not exist: ${namespace}" >&2
    return 1
  fi

  # Safety: check if namespace is active (has non-IDLE state)
  local state
  state="$(jq -r '.state // "IDLE"' "$(get_state_file "${namespace}")" 2>/dev/null)"
  if [[ "${state}" != "IDLE" && "${state}" != "COMPLETE" && "${force}" != "force" ]]; then
    echo "ERROR: Namespace '${namespace}' is in state '${state}'. Use 'force' to delete anyway." >&2
    return 1
  fi

  # Delete the namespace directory
  if rm -rf "${state_dir}"; then
    echo "Namespace '${namespace}' deleted"
    return 0
  else
    echo "ERROR: Failed to delete namespace directory" >&2
    return 1
  fi
}

#######################################
# Migrate legacy state to namespace structure
# Moves existing ~/.claude/state/pipeline-state.json to _default namespace
# Returns:
#   0 on success (or no migration needed), 1 on failure
#######################################
function migrate_legacy_state() {
  local -r legacy_state="${HOME}/.claude/state/pipeline-state.json"
  local -r legacy_journal="${HOME}/.claude/state/pipeline-journal.log"
  local -r default_state_dir="$(get_state_dir "${DEFAULT_NAMESPACE}")"
  local -r default_state_file="$(get_state_file "${DEFAULT_NAMESPACE}")"
  local -r default_journal_file="$(get_journal_file "${DEFAULT_NAMESPACE}")"

  # Check if migration is needed
  if [[ ! -f "${legacy_state}" ]]; then
    return 0  # No legacy state, nothing to migrate
  fi

  # Check if already migrated
  if [[ -f "${default_state_file}" ]]; then
    return 0  # Already have default namespace
  fi

  # Create default namespace directory
  mkdir -p "${default_state_dir}"

  # Move state file
  if ! mv "${legacy_state}" "${default_state_file}"; then
    echo "ERROR: Failed to migrate legacy state file" >&2
    return 1
  fi

  # Add namespace field if missing
  local updated_state
  if updated_state="$(jq --arg ns "${DEFAULT_NAMESPACE}" '.namespace = $ns' "${default_state_file}")"; then
    echo "${updated_state}" > "${default_state_file}"
  fi

  # Move journal if exists
  if [[ -f "${legacy_journal}" ]]; then
    mv "${legacy_journal}" "${default_journal_file}" 2>/dev/null || true
  fi

  echo "Migrated legacy state to namespace: ${DEFAULT_NAMESPACE}"
  return 0
}

#######################################
# TASK LIFECYCLE FUNCTIONS
#######################################

#######################################
# Mark task as complete and trigger documentation checkpoint
# Arguments:
#   $1 - Namespace (optional, uses current if not provided)
#   $2 - Task description (optional)
# Returns:
#   0 on success, 1 on failure
#######################################
function complete_task() {
  local -r namespace="${1:-$(get_namespace)}"
  local -r task_desc="${2:-Task completed}"
  local -r state_file="$(get_state_file "${namespace}")"
  local -r state_dir="$(get_state_dir "${namespace}")"
  local -r journal_file="$(get_journal_file "${namespace}")"
  local -r timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local -r temp_file="${state_dir}/.pipeline-state.tmp.$$"

  if [[ ! -f "${state_file}" ]]; then
    echo "ERROR: State file not found" >&2
    return 1
  fi

  # Get current state
  local current_state
  current_state="$(jq -r '.state // "IDLE"' "${state_file}" 2>/dev/null)"

  # Only allow completion from EXECUTING, ORCHESTRATING_ACTIVE, or GATHERING states
  case "${current_state}" in
    EXECUTING|ORCHESTRATING_ACTIVE|GATHERING|CLASSIFIED)
      ;;
    COMPLETE)
      echo "Task already complete. Documentation checkpoint may be pending."
      return 0
      ;;
    IDLE)
      echo "ERROR: No task in progress (state is IDLE)" >&2
      return 1
      ;;
    *)
      echo "ERROR: Cannot complete task in state: ${current_state}" >&2
      return 1
      ;;
  esac

  # Extract issues from journal for documentation checkpoint
  local issues_json="[]"
  if [[ -f "${journal_file}" ]]; then
    issues_json="$(grep -E '(ERROR|WARN|BLOCK)' "${journal_file}" 2>/dev/null | \
      tail -50 | \
      jq -R -s 'split("\n") | map(select(length > 0))' 2>/dev/null || echo "[]")"
  fi

  # Get list of modified files from git
  local files_json="[]"
  if command -v git >/dev/null 2>&1 && git rev-parse --git-dir >/dev/null 2>&1; then
    files_json="$(git diff --name-only HEAD~5 2>/dev/null | \
      jq -R -s 'split("\n") | map(select(length > 0))' 2>/dev/null || echo "[]")"
  fi

  # Transition to COMPLETE and create documentation checkpoint
  local new_state_json
  if ! new_state_json="$(jq \
    --arg timestamp "${timestamp}" \
    --arg task_desc "${task_desc}" \
    --arg prev_state "${current_state}" \
    --argjson issues "${issues_json}" \
    --argjson files "${files_json}" \
    '
    .state = "COMPLETE" |
    .timestamp = $timestamp |
    .documentation_pending = true |
    .documentation_checkpoint = {
      "created_at": $timestamp,
      "task_description": $task_desc,
      "issues_encountered": $issues,
      "files_modified": $files,
      "checklist": {
        "dev_notes": {"required": true, "completed": false, "description": "Add DEV-NOTE comments explaining tricky code and decisions"},
        "diagrams": {"required": "if_complex", "completed": false, "description": "Create diagrams for complex component interactions"},
        "architecture_docs": {"required": "if_changed", "completed": false, "description": "Update architecture documentation if structure changed"},
        "decision_log": {"required": true, "completed": false, "description": "Record key decisions and their rationale"}
      }
    } |
    .history += [{
      "agent": "task-complete",
      "timestamp": $timestamp,
      "state_before": $prev_state,
      "state_after": "COMPLETE",
      "trigger": "manual_completion"
    }]
    ' "${state_file}")"; then
    echo "ERROR: Failed to transition to COMPLETE" >&2
    return 1
  fi

  # Write atomically
  if echo "${new_state_json}" > "${temp_file}" && mv "${temp_file}" "${state_file}"; then
    # Write to journal
    printf '%s\t%s\t%s\t%s\n' \
      "${timestamp}" "TASK_COMPLETE" "complete_task" "state=${current_state}→COMPLETE desc=${task_desc}" \
      >> "${journal_file}" 2>/dev/null || true

    echo "Task marked complete. Documentation checkpoint created."
    echo ""
    display_documentation_checklist "${namespace}"
    return 0
  else
    rm -f "${temp_file}"
    echo "ERROR: Failed to write state" >&2
    return 1
  fi
}

#######################################
# DOCUMENTATION CHECKPOINT FUNCTIONS
#######################################

#######################################
# Check if documentation is pending for namespace
# Arguments:
#   $1 - Namespace (optional, uses current if not provided)
# Returns:
#   0 if documentation is pending, 1 if not
#######################################
function is_documentation_pending() {
  local -r namespace="${1:-$(get_namespace)}"
  local -r state_file="$(get_state_file "${namespace}")"

  if [[ ! -f "${state_file}" ]]; then
    return 1
  fi

  local pending
  pending="$(jq -r '.documentation_pending // false' "${state_file}" 2>/dev/null)"
  [[ "${pending}" == "true" ]]
}

#######################################
# Create documentation checkpoint when task completes
# Arguments:
#   $1 - Namespace (optional, uses current if not provided)
#   $2 - Task description (optional)
# Returns:
#   0 on success, 1 on failure
#######################################
function create_documentation_checkpoint() {
  local -r namespace="${1:-$(get_namespace)}"
  local -r task_desc="${2:-Task completed}"
  local -r state_file="$(get_state_file "${namespace}")"
  local -r state_dir="$(get_state_dir "${namespace}")"
  local -r timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local -r temp_file="${state_dir}/.pipeline-state.tmp.$$"

  if [[ ! -f "${state_file}" ]]; then
    echo "ERROR: State file not found" >&2
    return 1
  fi

  # Extract issues from journal (lines with ERROR, WARN, BLOCK)
  local -r journal_file="$(get_journal_file "${namespace}")"
  local issues_json="[]"
  if [[ -f "${journal_file}" ]]; then
    # Get recent issues (last 50 lines with ERROR/WARN/BLOCK)
    issues_json="$(grep -E '(ERROR|WARN|BLOCK)' "${journal_file}" 2>/dev/null | \
      tail -50 | \
      jq -R -s 'split("\n") | map(select(length > 0))' 2>/dev/null || echo "[]")"
  fi

  # Get list of modified files from git (if in a git repo)
  local files_json="[]"
  if command -v git >/dev/null 2>&1 && git rev-parse --git-dir >/dev/null 2>&1; then
    files_json="$(git diff --name-only HEAD~5 2>/dev/null | \
      jq -R -s 'split("\n") | map(select(length > 0))' 2>/dev/null || echo "[]")"
  fi

  # Update state file with documentation checkpoint
  local new_state_json
  if ! new_state_json="$(jq \
    --arg timestamp "${timestamp}" \
    --arg task_desc "${task_desc}" \
    --argjson issues "${issues_json}" \
    --argjson files "${files_json}" \
    '
    .documentation_pending = true |
    .documentation_checkpoint = {
      "created_at": $timestamp,
      "task_description": $task_desc,
      "issues_encountered": $issues,
      "files_modified": $files,
      "checklist": {
        "dev_notes": {"required": true, "completed": false, "description": "Add DEV-NOTE comments explaining tricky code and decisions"},
        "diagrams": {"required": "if_complex", "completed": false, "description": "Create diagrams for complex component interactions"},
        "architecture_docs": {"required": "if_changed", "completed": false, "description": "Update architecture documentation if structure changed"},
        "decision_log": {"required": true, "completed": false, "description": "Record key decisions and their rationale"}
      }
    }
    ' "${state_file}")"; then
    echo "ERROR: Failed to create documentation checkpoint" >&2
    return 1
  fi

  # Write atomically
  if echo "${new_state_json}" > "${temp_file}" && mv "${temp_file}" "${state_file}"; then
    return 0
  else
    rm -f "${temp_file}"
    echo "ERROR: Failed to write documentation checkpoint" >&2
    return 1
  fi
}

#######################################
# Get documentation checkpoint details
# Arguments:
#   $1 - Namespace (optional, uses current if not provided)
# Outputs:
#   Checkpoint JSON to stdout
#######################################
function get_documentation_checkpoint() {
  local -r namespace="${1:-$(get_namespace)}"
  local -r state_file="$(get_state_file "${namespace}")"

  if [[ ! -f "${state_file}" ]]; then
    echo '{"error": "State file not found"}'
    return 1
  fi

  jq '.documentation_checkpoint // {"error": "No checkpoint found"}' "${state_file}" 2>/dev/null
}

#######################################
# Display documentation checkpoint as formatted text
# Arguments:
#   $1 - Namespace (optional, uses current if not provided)
# Outputs:
#   Formatted checklist to stdout
#######################################
function display_documentation_checklist() {
  local -r namespace="${1:-$(get_namespace)}"
  local -r state_file="$(get_state_file "${namespace}")"

  if ! is_documentation_pending "${namespace}"; then
    echo "No documentation checkpoint pending for namespace: ${namespace}"
    return 0
  fi

  local checkpoint
  checkpoint="$(get_documentation_checkpoint "${namespace}")"

  local task_desc created_at
  task_desc="$(echo "${checkpoint}" | jq -r '.task_description // "Unknown task"')"
  created_at="$(echo "${checkpoint}" | jq -r '.created_at // "Unknown"')"

  cat << EOF
╔════════════════════════════════════════════════════════════════════════════╗
║  DOCUMENTATION CHECKPOINT - ${namespace}
╠════════════════════════════════════════════════════════════════════════════╣
║
║  Task: ${task_desc}
║  Completed: ${created_at}
║
║  Before starting new work, document what just happened:
║
║  Required:
║    [ ] DEV-NOTEs: Add comments explaining tricky code/decisions
║        → Look for complex logic, workarounds, non-obvious behavior
║        → Explain WHY, not just WHAT
║
║    [ ] Decision Log: Record key decisions and their rationale
║        → What alternatives were considered?
║        → Why was this approach chosen?
║
║  Conditional:
║    [ ] Diagrams: Create visuals for complex component interactions
║        → State machines, data flows, component relationships
║        → Use Mermaid for version-controllable diagrams
║
║    [ ] Architecture Docs: Update if structure changed
║        → New files/modules, changed interfaces, new patterns
║
EOF

  # Show files modified
  local files_count
  files_count="$(echo "${checkpoint}" | jq '.files_modified | length')"
  if [[ "${files_count}" -gt 0 ]]; then
    echo "║  Files modified (${files_count}):"
    echo "${checkpoint}" | jq -r '.files_modified[]' | while read -r file; do
      echo "║    • ${file}"
    done
  fi

  # Show issues encountered
  local issues_count
  issues_count="$(echo "${checkpoint}" | jq '.issues_encountered | length')"
  if [[ "${issues_count}" -gt 0 ]]; then
    echo "║"
    echo "║  Issues encountered (review for DEV-NOTEs):"
    echo "${checkpoint}" | jq -r '.issues_encountered[:5][]' | while read -r issue; do
      # Truncate long lines
      echo "║    • ${issue:0:70}..."
    done
    if [[ "${issues_count}" -gt 5 ]]; then
      echo "║    ... and $((issues_count - 5)) more"
    fi
  fi

  cat << EOF
║
╠════════════════════════════════════════════════════════════════════════════╣
║  Run '/task docs-complete' when documentation is done.
╚════════════════════════════════════════════════════════════════════════════╝
EOF
}

#######################################
# Clear documentation checkpoint (mark as complete)
# Arguments:
#   $1 - Namespace (optional, uses current if not provided)
#   $2 - Notes about what was documented (optional)
# Returns:
#   0 on success, 1 on failure
#######################################
function clear_documentation_checkpoint() {
  local -r namespace="${1:-$(get_namespace)}"
  local -r notes="${2:-Documentation completed}"
  local -r state_file="$(get_state_file "${namespace}")"
  local -r state_dir="$(get_state_dir "${namespace}")"
  local -r timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local -r temp_file="${state_dir}/.pipeline-state.tmp.$$"

  if [[ ! -f "${state_file}" ]]; then
    echo "ERROR: State file not found" >&2
    return 1
  fi

  if ! is_documentation_pending "${namespace}"; then
    echo "No documentation checkpoint pending"
    return 0
  fi

  # Archive the checkpoint to history and clear pending flag
  local new_state_json
  if ! new_state_json="$(jq \
    --arg timestamp "${timestamp}" \
    --arg notes "${notes}" \
    '
    .documentation_pending = false |
    .documentation_history = ((.documentation_history // []) + [{
      "checkpoint": .documentation_checkpoint,
      "completed_at": $timestamp,
      "notes": $notes
    }]) |
    del(.documentation_checkpoint)
    ' "${state_file}")"; then
    echo "ERROR: Failed to clear documentation checkpoint" >&2
    return 1
  fi

  # Write atomically
  if echo "${new_state_json}" > "${temp_file}" && mv "${temp_file}" "${state_file}"; then
    echo "Documentation checkpoint cleared for namespace: ${namespace}"
    return 0
  else
    rm -f "${temp_file}"
    echo "ERROR: Failed to write state" >&2
    return 1
  fi
}
