# Bash Agent Team - Complete Guide

A specialized team of 7 agents for developing robust, maintainable bash scripts following Google's style guide and avoiding common pitfalls.

## Quick Start

**New bash script workflow:**
```
1. "Use bash-architect to design a deployment script for the monitoring service"
2. "Use bash-error-handler to add proper error handling"
3. "Use bash-style-enforcer to review for style compliance"
4. "Use bash-security-reviewer to check for security issues"
5. "Use bash-tester to write bats tests"
```

**Review existing script:**
```
1. "Use bash-style-enforcer to review scripts/deploy.sh"
2. "Use bash-security-reviewer to audit scripts/deploy.sh for vulnerabilities"
```

---

## Agent Team Overview

### Tier 1: Architecture (Before Coding)

#### bash-architect
**When**: Before writing any significant bash script
**Purpose**: Design script structure, function decomposition, data flow
**Model**: Opus (complex architectural decisions)

**Example Usage:**
```
"Use bash-architect to design a pipeline management script that handles
state initialization, agent approval/blocking, and state transitions"
```

**What It Produces:**
- Recommendation on whether bash is appropriate
- High-level architecture overview
- Function breakdown with purposes
- Key architectural decisions
- Risks and considerations
- Implementation order

**Key Patterns:**
- Simple linear scripts
- Pipeline processing
- Command dispatcher (subcommands)
- Configuration-driven scripts

---

### Tier 2: Implementation Specialists

#### bash-error-handler
**When**: Adding error handling to scripts or reviewing existing handling
**Purpose**: Ensure robust, fail-safe error handling
**Focus**: `set -euo pipefail`, trap handlers, exit codes, graceful failures

**Example Usage:**
```
"Use bash-error-handler to add proper error handling to scripts/deploy.sh"
```

**What It Does:**
- Adds `set -euo pipefail` with understanding of implications
- Implements trap handlers for cleanup on exit/error
- Defines meaningful exit codes
- Handles edge cases (missing files, empty input, etc.)
- Adds defensive checks before dangerous operations

#### bash-optimizer
**When**: Scripts are slow or handle large datasets
**Purpose**: Performance optimization
**Focus**: Bottlenecks, unnecessary subshells, efficient patterns

**Example Usage:**
```
"Use bash-optimizer to improve performance of scripts/process-logs.sh"
```

**What It Does:**
- Identifies performance bottlenecks
- Reduces unnecessary subshells and forks
- Uses built-in string operations over external commands
- Implements efficient loop patterns
- Optimizes file operations

#### bash-debugger
**When**: Scripts fail unexpectedly or behave incorrectly
**Purpose**: Root cause analysis and debugging
**Focus**: Systematic debugging, error reproduction, fix verification

**Example Usage:**
```
"Use bash-debugger to fix the permission error in scripts/backup.sh"
```

**What It Does:**
- Adds debug output (`set -x`, `PS4`)
- Traces execution flow
- Identifies root cause systematically
- Suggests fixes with explanations
- Verifies fixes don't introduce regressions

---

### Tier 3: Quality Assurance

#### bash-style-enforcer
**When**: After writing or modifying bash scripts
**Purpose**: Enforce Google Bash Style Guide compliance
**References**:
- https://google.github.io/styleguide/shellguide.html
- https://mywiki.wooledge.org/BashPitfalls

**Example Usage:**
```
"Use bash-style-enforcer to review scripts/pipeline-gate.sh"
```

**What It Checks:**
- Function and variable naming conventions
- Proper quoting (`"${variable}"` always)
- `[[ ]]` over `[ ]` for conditionals
- Function documentation format
- `readonly` for constants
- `local` variables in functions
- Proper indentation (2 spaces)
- Line length limits

#### bash-security-reviewer
**When**: Scripts handle user input, run with privileges, or access sensitive data
**Purpose**: Security vulnerability detection
**Focus**: Injection, privilege escalation, race conditions

**Example Usage:**
```
"Use bash-security-reviewer to audit scripts/user-setup.sh"
```

**What It Checks:**
- Command injection vulnerabilities
- Unquoted variables in dangerous contexts
- TOCTOU (time-of-check-time-of-use) races
- Unsafe temporary file creation
- Privilege escalation risks
- Sensitive data exposure
- Path traversal vulnerabilities

#### bash-tester
**When**: Scripts need test coverage
**Purpose**: Write bats (Bash Automated Testing System) tests
**Framework**: bats-core

**Example Usage:**
```
"Use bash-tester to write tests for scripts/check-subagent-allowed.sh"
```

**What It Produces:**
- bats test files with proper structure
- Setup/teardown functions
- Edge case coverage
- Error condition tests
- Mock/stub strategies for external commands

---

## Complete Workflows

### Workflow 1: New Script Development

```
Step 1: Architecture
──────────────────────
User: "Use bash-architect to design a context caching script that stores
       and retrieves codebase context with TTL"

Agent designs:
- Function breakdown
- Data structures (JSON with jq)
- File organization
- Error handling strategy


Step 2: Implement
─────────────────
Write the script following the architecture.
(Main Claude or domain specialists can do this)


Step 3: Error Handling
──────────────────────
User: "Use bash-error-handler to ensure robust error handling"

Agent adds:
- set -euo pipefail
- Trap handlers
- Input validation
- Graceful degradation


Step 4: Style Compliance
────────────────────────
User: "Use bash-style-enforcer to review for style issues"

Agent checks:
- Naming conventions
- Quoting
- Documentation
- Formatting


Step 5: Security Review
───────────────────────
User: "Use bash-security-reviewer to audit for vulnerabilities"

Agent examines:
- Input handling
- File operations
- External command usage
- Privilege requirements


Step 6: Testing
───────────────
User: "Use bash-tester to write comprehensive tests"

Agent creates:
- test_context_cache.bats
- Edge case coverage
- Error condition tests
```

---

### Workflow 2: Script Optimization

```
Step 1: Identify Bottlenecks
────────────────────────────
User: "Use bash-optimizer to analyze scripts/process-logs.sh"

Agent identifies:
- Slow operations
- Unnecessary forks
- Inefficient patterns


Step 2: Apply Optimizations
───────────────────────────
User: "Apply the recommended optimizations"

Agent updates:
- Replace external commands with built-ins
- Reduce subshells
- Optimize loops


Step 3: Verify Performance
──────────────────────────
User: "Use bash-tester to add performance regression tests"
```

---

### Workflow 3: Debugging

```
Step 1: Reproduce Issue
───────────────────────
User: "Use bash-debugger to fix: update-pipeline-state.sh fails
       with 'jq: error: null' on some inputs"

Agent:
- Adds debug output
- Traces execution
- Identifies failing code path


Step 2: Root Cause
──────────────────
Agent identifies: Missing null check when extracting agent output


Step 3: Fix and Verify
──────────────────────
Agent:
- Proposes fix with explanation
- Suggests test case for regression
```

---

## Best Practices

### 1. Always Start with Architecture (for non-trivial scripts)

**DON'T:**
```
"Write a script to manage pipeline state"
```

**DO:**
```
"Use bash-architect to design a pipeline state management script"
(then implement following the design)
```

### 2. Use Style Enforcer Proactively

**DON'T:**
```
Write scripts and only review when problems arise
```

**DO:**
```
"Use bash-style-enforcer to review scripts/new-script.sh"
(immediately after writing)
```

### 3. Security Review is Non-Negotiable

For any script that:
- Handles user input
- Runs with elevated privileges
- Accesses sensitive data
- Creates/modifies files based on external input

**ALWAYS:**
```
"Use bash-security-reviewer to audit the script"
```

### 4. Test Edge Cases

**DON'T:**
```
Only test the happy path
```

**DO:**
```
"Use bash-tester to write tests covering:
- Empty input
- Missing files
- Invalid JSON
- Concurrent access
- Large inputs"
```

---

## Agent Capabilities Summary

| Agent | Can Read | Can Edit | Model | Speed | When to Use |
|-------|----------|----------|-------|-------|-------------|
| bash-architect | ✓ | ✗ | opus | Slow | Before writing |
| bash-error-handler | ✓ | ✓ | sonnet | Medium | During/after implementation |
| bash-optimizer | ✓ | ✓ | sonnet | Medium | Performance issues |
| bash-debugger | ✓ | ✓ | sonnet | Medium | Bugs/failures |
| bash-style-enforcer | ✓ | ✓ | sonnet | Fast | After every change |
| bash-security-reviewer | ✓ | ✗ | sonnet | Medium | Before deployment |
| bash-tester | ✓ | ✓ | sonnet | Medium | After implementation |

---

## Common Scenarios

### Scenario: "I need to create a new pipeline script"

1. Use bash-architect to design
2. Implement following design
3. Use bash-error-handler to add error handling
4. Use bash-style-enforcer to verify style
5. Use bash-security-reviewer to audit
6. Use bash-tester to write tests

### Scenario: "Script is failing randomly"

1. Use bash-debugger to investigate
2. Fix the identified issue
3. Use bash-tester to add regression test

### Scenario: "Script is too slow"

1. Use bash-optimizer to analyze
2. Apply optimizations
3. Use bash-tester to verify correctness

### Scenario: "Script handles user input"

1. Use bash-security-reviewer to audit
2. Fix any identified vulnerabilities
3. Use bash-tester to add security tests

---

## Bash Best Practices (Reference)

### Always Do

```bash
#!/usr/bin/env bash
set -euo pipefail

# Constants
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Functions with documentation
# Description: Does something useful
# Arguments:
#   $1 - First argument
# Returns:
#   0 on success, 1 on error
function do_something() {
  local arg="${1:?'Missing argument'}"
  # Implementation
}

# Quote all variables
echo "${variable}"

# Use [[ ]] for conditionals
if [[ -f "${file}" ]]; then
  ...
fi

# Trap for cleanup
trap 'cleanup' EXIT
```

### Never Do

```bash
# ❌ Unquoted variables
echo $variable

# ❌ [ ] instead of [[ ]]
if [ -f "$file" ]; then

# ❌ Parsing ls output
for file in $(ls); do

# ❌ cd without error check
cd $dir && do_something

# ❌ Unvalidated user input in commands
eval "$user_input"  # DANGEROUS!

# ❌ Temporary files in /tmp without mktemp
echo "data" > /tmp/myfile  # Race condition!
```

---

## Integration with Pipeline

These agents are deployed by **strategic-orchestrator** when:
- Creating new bash scripts for the pipeline
- Modifying existing pipeline scripts
- Debugging pipeline enforcement issues
- Optimizing hook performance

After agents complete, results flow back through the pipeline.

---

## Resources

- [Google Bash Style Guide](https://google.github.io/styleguide/shellguide.html)
- [BashPitfalls](https://mywiki.wooledge.org/BashPitfalls)
- [Bats-core Testing](https://github.com/bats-core/bats-core)
- [ShellCheck](https://www.shellcheck.net/)

---

*Generated for cccc - Claude Code Agent Pipeline*
