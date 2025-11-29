#!/usr/bin/env bash
#
# context-cache.sh - Persistent context memory for Claude Code pipeline
#
# Provides codebase fingerprinting and context caching to avoid
# re-gathering context for unchanged codebases.
#
# Usage:
#   context-cache.sh fingerprint [path]     - Generate codebase fingerprint
#   context-cache.sh check [path]           - Check if cached context exists
#   context-cache.sh get [path]             - Get cached context (JSON)
#   context-cache.sh store [path]           - Store context from stdin
#   context-cache.sh invalidate [path]      - Invalidate cache for path
#   context-cache.sh info                   - Show cache statistics
#   context-cache.sh clean [days]           - Clean entries older than N days
#
# Environment:
#   CONTEXT_CACHE_DIR - Override cache directory (default: ~/.claude/memory)
#   CONTEXT_CACHE_TTL - Cache TTL in days (default: 7)

set -euo pipefail

readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly CACHE_DIR="${CONTEXT_CACHE_DIR:-${HOME}/.claude/memory}"
readonly CONTEXTS_DIR="${CACHE_DIR}/contexts"
readonly INDEX_FILE="${CACHE_DIR}/index.json"
readonly DEFAULT_TTL_DAYS="${CONTEXT_CACHE_TTL:-7}"

#######################################
# Log message to stderr with timestamp
#######################################
function log_message() {
  local -r message="$1"
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [${SCRIPT_NAME}] ${message}" >&2
}

#######################################
# Ensure cache directories exist
#######################################
function ensure_cache_dirs() {
  mkdir -p "${CONTEXTS_DIR}"

  # Initialize index if missing
  if [[ ! -f "${INDEX_FILE}" ]]; then
    echo '{"version": "1.0", "entries": {}}' > "${INDEX_FILE}"
  fi
}

#######################################
# Generate fingerprint for a codebase
# Uses: git ls-files with mtimes, or find for non-git dirs
# Arguments:
#   $1 - Path to codebase (default: current directory)
# Outputs:
#   SHA256 fingerprint to stdout
#######################################
function generate_fingerprint() {
  local -r target_path="${1:-.}"
  local -r abs_path="$(cd "${target_path}" && pwd)"

  local file_list=""

  if [[ -d "${abs_path}/.git" ]]; then
    # Git repository: use tracked files only
    # Format: path:mtime for each file
    file_list=$(cd "${abs_path}" && git ls-files -z 2>/dev/null | \
      xargs -0 -I{} stat --format='%n:%Y' "{}" 2>/dev/null | sort)
  else
    # Non-git: use find with common excludes
    file_list=$(find "${abs_path}" \
      -type f \
      ! -path '*/node_modules/*' \
      ! -path '*/.git/*' \
      ! -path '*/target/*' \
      ! -path '*/__pycache__/*' \
      ! -path '*/.venv/*' \
      ! -name '*.pyc' \
      -printf '%p:%T@\n' 2>/dev/null | sort)
  fi

  if [[ -z "${file_list}" ]]; then
    log_message "WARN: No files found for fingerprinting in ${abs_path}"
    # Return hash of empty + path as fallback
    echo -n "${abs_path}:empty" | sha256sum | cut -d' ' -f1
    return 0
  fi

  # Include path in fingerprint so different repos don't collide
  echo -n "${abs_path}:${file_list}" | sha256sum | cut -d' ' -f1
}

#######################################
# Get cache path for a fingerprint
# Arguments:
#   $1 - Fingerprint hash
# Outputs:
#   Path to cache directory
#######################################
function get_cache_path() {
  local -r fingerprint="$1"
  # Use first 2 chars as subdirectory for filesystem efficiency
  echo "${CONTEXTS_DIR}/${fingerprint:0:2}/${fingerprint}"
}

#######################################
# Check if valid cached context exists
# Arguments:
#   $1 - Path to codebase (default: current directory)
# Returns:
#   0 if cache hit, 1 if cache miss
# Outputs:
#   Cache status message to stderr
#######################################
function check_cache() {
  local -r target_path="${1:-.}"

  ensure_cache_dirs

  local fingerprint
  fingerprint=$(generate_fingerprint "${target_path}")

  local cache_path
  cache_path=$(get_cache_path "${fingerprint}")

  if [[ -f "${cache_path}/context.json" ]]; then
    # Check TTL
    local cache_mtime
    cache_mtime=$(stat --format='%Y' "${cache_path}/context.json")
    local current_time
    current_time=$(date +%s)
    local age_days=$(( (current_time - cache_mtime) / 86400 ))

    if [[ ${age_days} -lt ${DEFAULT_TTL_DAYS} ]]; then
      log_message "Cache HIT: ${fingerprint:0:12}... (${age_days} days old)"
      echo "hit"
      return 0
    else
      log_message "Cache EXPIRED: ${fingerprint:0:12}... (${age_days} days old, TTL: ${DEFAULT_TTL_DAYS})"
      echo "expired"
      return 1
    fi
  fi

  log_message "Cache MISS: ${fingerprint:0:12}..."
  echo "miss"
  return 1
}

#######################################
# Get cached context
# Arguments:
#   $1 - Path to codebase (default: current directory)
# Outputs:
#   Context JSON to stdout, or empty on miss
# Returns:
#   0 on hit, 1 on miss
#######################################
function get_cache() {
  local -r target_path="${1:-.}"

  ensure_cache_dirs

  local fingerprint
  fingerprint=$(generate_fingerprint "${target_path}")

  local cache_path
  cache_path=$(get_cache_path "${fingerprint}")

  if [[ -f "${cache_path}/context.json" ]]; then
    # Verify TTL
    local cache_mtime
    cache_mtime=$(stat --format='%Y' "${cache_path}/context.json")
    local current_time
    current_time=$(date +%s)
    local age_days=$(( (current_time - cache_mtime) / 86400 ))

    if [[ ${age_days} -lt ${DEFAULT_TTL_DAYS} ]]; then
      cat "${cache_path}/context.json"
      return 0
    fi
  fi

  return 1
}

#######################################
# Store context in cache
# Reads context JSON from stdin
# Arguments:
#   $1 - Path to codebase (default: current directory)
# Returns:
#   0 on success, 1 on failure
#######################################
function store_cache() {
  local -r target_path="${1:-.}"
  local -r abs_path="$(cd "${target_path}" && pwd)"

  ensure_cache_dirs

  # Read context from stdin
  local context
  if ! context=$(cat); then
    log_message "ERROR: Failed to read context from stdin"
    return 1
  fi

  if [[ -z "${context}" ]]; then
    log_message "ERROR: Empty context provided"
    return 1
  fi

  # Validate JSON
  if ! echo "${context}" | jq empty 2>/dev/null; then
    log_message "ERROR: Invalid JSON context"
    return 1
  fi

  local fingerprint
  fingerprint=$(generate_fingerprint "${target_path}")

  local cache_path
  cache_path=$(get_cache_path "${fingerprint}")

  # Create cache directory
  mkdir -p "${cache_path}"

  # Store context atomically
  local -r temp_file="${cache_path}/.context.tmp.$$"

  # Add metadata to context
  local -r timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local stored_context
  stored_context=$(echo "${context}" | jq \
    --arg fingerprint "${fingerprint}" \
    --arg path "${abs_path}" \
    --arg timestamp "${timestamp}" \
    '. + {
      "_cache_metadata": {
        "fingerprint": $fingerprint,
        "path": $path,
        "cached_at": $timestamp
      }
    }')

  if ! echo "${stored_context}" > "${temp_file}"; then
    log_message "ERROR: Failed to write temp file"
    rm -f "${temp_file}"
    return 1
  fi

  if ! mv "${temp_file}" "${cache_path}/context.json"; then
    log_message "ERROR: Failed to move temp file"
    rm -f "${temp_file}"
    return 1
  fi

  # Update index
  update_index "${fingerprint}" "${abs_path}"

  log_message "Cache STORED: ${fingerprint:0:12}... for ${abs_path}"
  return 0
}

#######################################
# Update cache index
# Arguments:
#   $1 - Fingerprint
#   $2 - Path
#######################################
function update_index() {
  local -r fingerprint="$1"
  local -r path="$2"
  local -r timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  local -r temp_file="${CACHE_DIR}/.index.tmp.$$"

  local new_index
  new_index=$(jq \
    --arg fp "${fingerprint}" \
    --arg path "${path}" \
    --arg ts "${timestamp}" \
    '.entries[$fp] = {"path": $path, "cached_at": $ts}' \
    "${INDEX_FILE}")

  if echo "${new_index}" > "${temp_file}" && mv "${temp_file}" "${INDEX_FILE}"; then
    return 0
  else
    rm -f "${temp_file}"
    return 1
  fi
}

#######################################
# Invalidate cache for a path
# Arguments:
#   $1 - Path to codebase
#######################################
function invalidate_cache() {
  local -r target_path="${1:-.}"

  ensure_cache_dirs

  local fingerprint
  fingerprint=$(generate_fingerprint "${target_path}")

  local cache_path
  cache_path=$(get_cache_path "${fingerprint}")

  if [[ -d "${cache_path}" ]]; then
    rm -rf "${cache_path}"
    log_message "Cache INVALIDATED: ${fingerprint:0:12}..."

    # Remove from index
    local new_index
    new_index=$(jq --arg fp "${fingerprint}" 'del(.entries[$fp])' "${INDEX_FILE}")
    echo "${new_index}" > "${INDEX_FILE}"
  else
    log_message "No cache to invalidate for ${target_path}"
  fi
}

#######################################
# Show cache info and statistics
#######################################
function show_info() {
  ensure_cache_dirs

  echo "Context Cache Statistics"
  echo "========================"
  echo "Cache directory: ${CACHE_DIR}"
  echo "TTL: ${DEFAULT_TTL_DAYS} days"
  echo ""

  # Count entries
  local entry_count
  entry_count=$(find "${CONTEXTS_DIR}" -name 'context.json' 2>/dev/null | wc -l)
  echo "Cached contexts: ${entry_count}"

  # Total size
  local total_size
  total_size=$(du -sh "${CACHE_DIR}" 2>/dev/null | cut -f1)
  echo "Total size: ${total_size}"
  echo ""

  # Recent entries
  echo "Recent entries:"
  jq -r '.entries | to_entries | sort_by(.value.cached_at) | reverse | .[0:5] | .[] | "  \(.value.path) (\(.key[0:12])...)"' "${INDEX_FILE}" 2>/dev/null || echo "  (none)"
}

#######################################
# Clean old cache entries
# Arguments:
#   $1 - Days threshold (default: TTL * 2)
#######################################
function clean_cache() {
  local -r days="${1:-$((DEFAULT_TTL_DAYS * 2))}"

  ensure_cache_dirs

  log_message "Cleaning cache entries older than ${days} days..."

  local cleaned=0

  while IFS= read -r -d '' cache_file; do
    local cache_dir
    cache_dir=$(dirname "${cache_file}")

    local cache_mtime
    cache_mtime=$(stat --format='%Y' "${cache_file}")
    local current_time
    current_time=$(date +%s)
    local age_days=$(( (current_time - cache_mtime) / 86400 ))

    if [[ ${age_days} -ge ${days} ]]; then
      rm -rf "${cache_dir}"
      ((cleaned++))
    fi
  done < <(find "${CONTEXTS_DIR}" -name 'context.json' -print0 2>/dev/null)

  log_message "Cleaned ${cleaned} old cache entries"
  echo "Cleaned ${cleaned} entries"
}

#######################################
# Main entry point
#######################################
function main() {
  if ! command -v jq >/dev/null 2>&1; then
    log_message "ERROR: jq is required but not installed"
    return 1
  fi

  local -r command="${1:-help}"
  shift || true

  case "${command}" in
    fingerprint)
      generate_fingerprint "${1:-.}"
      ;;
    check)
      check_cache "${1:-.}"
      ;;
    get)
      get_cache "${1:-.}"
      ;;
    store)
      store_cache "${1:-.}"
      ;;
    invalidate)
      invalidate_cache "${1:-.}"
      ;;
    info)
      show_info
      ;;
    clean)
      clean_cache "${1:-}"
      ;;
    help|--help|-h)
      echo "Usage: ${SCRIPT_NAME} <command> [args]"
      echo ""
      echo "Commands:"
      echo "  fingerprint [path]  - Generate codebase fingerprint"
      echo "  check [path]        - Check if cached context exists"
      echo "  get [path]          - Get cached context (JSON)"
      echo "  store [path]        - Store context from stdin"
      echo "  invalidate [path]   - Invalidate cache for path"
      echo "  info                - Show cache statistics"
      echo "  clean [days]        - Clean entries older than N days"
      ;;
    *)
      log_message "ERROR: Unknown command: ${command}"
      return 1
      ;;
  esac
}

main "$@"
