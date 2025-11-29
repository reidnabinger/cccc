#!/usr/bin/env bash
#
# verify-installation.sh - Verify pipeline enforcement system installation
#
# Usage: verify-installation.sh

set -euo pipefail

readonly SCRIPT_DIR="${HOME}/.claude/scripts"
readonly STATE_DIR="${HOME}/.claude/state"

echo "=== Pipeline Enforcement System - Installation Verification ==="
echo

# Check for required executables
echo "Checking dependencies..."
if command -v jq >/dev/null 2>&1; then
  echo "  ✓ jq found: $(which jq)"
else
  echo "  ✗ jq NOT FOUND (required)"
  exit 1
fi

if command -v bash >/dev/null 2>&1; then
  echo "  ✓ bash found: $(bash --version | head -1)"
else
  echo "  ✗ bash NOT FOUND (required)"
  exit 1
fi
echo

# Check for scripts
echo "Checking scripts..."
for script in pipeline-gate.sh check-subagent-allowed.sh update-pipeline-state.sh reset-pipeline-state.sh; do
  if [[ -x "${SCRIPT_DIR}/${script}" ]]; then
    echo "  ✓ ${script} (executable)"
  else
    echo "  ✗ ${script} (missing or not executable)"
    exit 1
  fi
done
echo

# Check for documentation
echo "Checking documentation..."
for doc in README.md QUICK_REFERENCE.md ARCHITECTURE.md IMPLEMENTATION_SUMMARY.md; do
  if [[ -f "${SCRIPT_DIR}/${doc}" ]]; then
    lines=$(wc -l < "${SCRIPT_DIR}/${doc}")
    echo "  ✓ ${doc} (${lines} lines)"
  else
    echo "  ✗ ${doc} (missing)"
    exit 1
  fi
done
echo

# Check state directory
echo "Checking state directory..."
if [[ -d "${STATE_DIR}" ]]; then
  echo "  ✓ ${STATE_DIR} exists"
  if [[ -f "${STATE_DIR}/pipeline-state.json" ]]; then
    state=$(jq -r '.state' "${STATE_DIR}/pipeline-state.json" 2>/dev/null || echo "INVALID")
    echo "  ✓ pipeline-state.json exists (current state: ${state})"
  else
    echo "  ℹ pipeline-state.json will be created on first run"
  fi
else
  echo "  ✗ ${STATE_DIR} does not exist"
  exit 1
fi
echo

# Test basic functionality
echo "Testing basic functionality..."

# Test 1: Initialize
if output=$("${SCRIPT_DIR}/pipeline-gate.sh" init 2>&1); then
  echo "  ✓ pipeline-gate.sh init"
else
  echo "  ✗ pipeline-gate.sh init failed"
  exit 1
fi

# Test 2: Check-prompt
if output=$("${SCRIPT_DIR}/pipeline-gate.sh" check-prompt 2>/dev/null); then
  if echo "${output}" | jq -e '.continue' >/dev/null 2>&1; then
    echo "  ✓ pipeline-gate.sh check-prompt (returns valid JSON)"
  else
    echo "  ✗ pipeline-gate.sh check-prompt (invalid JSON)"
    exit 1
  fi
else
  echo "  ✗ pipeline-gate.sh check-prompt failed"
  exit 1
fi

# Test 3: Agent check
if output=$(echo '{"subagent_type": "context-gatherer"}' | "${SCRIPT_DIR}/check-subagent-allowed.sh" 2>/dev/null); then
  if echo "${output}" | jq -e '.decision == "approve"' >/dev/null 2>&1; then
    echo "  ✓ check-subagent-allowed.sh (approves context-gatherer in IDLE)"
  else
    echo "  ✗ check-subagent-allowed.sh (unexpected decision)"
    exit 1
  fi
else
  echo "  ✗ check-subagent-allowed.sh failed"
  exit 1
fi

# Test 4: Reset
if output=$("${SCRIPT_DIR}/reset-pipeline-state.sh" "Verification test" 2>/dev/null); then
  echo "  ✓ reset-pipeline-state.sh"
else
  echo "  ✗ reset-pipeline-state.sh failed"
  exit 1
fi

echo

# Summary
echo "=== Installation Verified ==="
echo
echo "All components installed correctly!"
echo
echo "Next steps:"
echo "  1. Read README.md for usage: cat ${SCRIPT_DIR}/README.md"
echo "  2. Configure Claude Code hooks (see README.md)"
echo "  3. Run test suite: /tmp/test-pipeline-system.sh (if available)"
echo
echo "Current state: $(jq -r '.state' "${STATE_DIR}/pipeline-state.json")"
echo "State file: ${STATE_DIR}/pipeline-state.json"
