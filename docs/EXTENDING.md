# Extending CCCC

Guide for adding new agents, customizing the pipeline, and contributing to the Claude Code Agent Pipeline.

---

## Table of Contents

1. [Adding New Agents](#adding-new-agents)
2. [Creating Agent Teams](#creating-agent-teams)
3. [Adding Pipeline States](#adding-pipeline-states)
4. [Creating Slash Commands](#creating-slash-commands)
5. [Creating Skills](#creating-skills)
6. [Customizing Hooks](#customizing-hooks)
7. [Contributing Guidelines](#contributing-guidelines)

---

## 1. Adding New Agents

### Agent File Structure

Agents are Markdown files in `~/.claude/agents/` (deployed) or `private_dot_claude/agents/` (source).

```markdown
---
name: agent-name
description: Brief description shown in Task tool
tools: Read, Glob, Grep, Bash, Edit, Write
model: sonnet
---

# Agent Name

Detailed instructions for the agent...
```

### Required Frontmatter

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Unique identifier (kebab-case) |
| `description` | Yes | Shown when using Task tool |
| `tools` | Yes | Comma-separated list of allowed tools |
| `model` | No | haiku, sonnet, or opus (default: inherit) |

### Example: Adding a Rust Security Auditor

**File**: `private_dot_claude/agents/rust-unsafe-auditor.md`

```markdown
---
name: rust-unsafe-auditor
description: Audit Rust code for unsafe block usage, soundness issues, and undefined behavior risks
tools: Read, Glob, Grep, Bash, mcp__context7__resolve-library-id, mcp__context7__get-library-docs
model: sonnet
---

# Rust Unsafe Block Auditor

You are a Rust security specialist focused on auditing unsafe code blocks.

## Core Expertise

- Sound and unsound unsafe code patterns
- Memory safety guarantees and violations
- FFI boundary security
- Raw pointer handling
- Miri for undefined behavior detection

## When Invoked

1. Find all `unsafe` blocks in the codebase
2. For each block, assess:
   - Is the unsafe actually necessary?
   - Are invariants documented?
   - Could safe abstractions replace it?
   - Are there soundness holes?

## Checklist

- [ ] Identify all unsafe blocks
- [ ] Check for undocumented invariants
- [ ] Verify FFI boundaries are sound
- [ ] Look for raw pointer aliasing issues
- [ ] Recommend safe alternatives where possible

## Output Format

For each unsafe block found:

```
File: path/to/file.rs:line
Unsafe Type: [Block/Function/Trait impl/etc.]
Necessity: [Required/Questionable/Unnecessary]
Risk Level: [Low/Medium/High/Critical]
Issues: [List of specific concerns]
Recommendation: [Keep/Refactor/Remove]
```
```

### Registering Agents with the Pipeline

For agents to be used by the pipeline, they must be categorized:

1. **Pipeline agents** (context-gatherer, etc.): Update `check-subagent-allowed.sh`
2. **Language specialists** (bash-*, rust-*, etc.): Add pattern to EXECUTING state
3. **Utility agents**: Add to utility list if needed

**Edit** `~/.claude/scripts/check-subagent-allowed.sh`:

```bash
# In the EXECUTING state section, add your pattern:
if [[ "${agent}" =~ ^(bash-|nix-|c-|python-|rust-) ]]; then
  # Allowed
fi
```

---

## 2. Creating Agent Teams

Agent teams are collections of specialized agents that work together on a domain.

### Team Structure

```
agents/
├── DOMAIN-AGENTS-GUIDE.md    # Usage guide
├── 00-DOMAIN-QUICK-START.md  # Quick reference
├── domain-architect.md       # Design/planning agent
├── domain-implementer.md     # Implementation agent
├── domain-auditor.md         # Review/audit agent
├── domain-tester.md          # Testing agent
└── README.md                 # Update with new team info
```

### Example Team: Terraform/IaC

**1. Create the architect** (`terraform-architect.md`):
```markdown
---
name: terraform-architect
description: Design Terraform module structure and state management strategies
tools: Read, Glob, Grep, mcp__context7__get-library-docs
model: sonnet
---

# Terraform Architect

Design Terraform infrastructure with proper module boundaries...
```

**2. Create the reviewer** (`terraform-reviewer.md`):
```markdown
---
name: terraform-reviewer
description: Review Terraform code for security, best practices, and state safety
tools: Read, Glob, Grep, Bash
model: sonnet
---

# Terraform Security Reviewer

Audit Terraform configurations for security issues...
```

**3. Create the guide** (`TERRAFORM-AGENTS-GUIDE.md`):
```markdown
# Terraform Agent Team

## Workflow

1. terraform-architect - Design module structure
2. (Manual implementation)
3. terraform-reviewer - Security review
```

**4. Update agent registration**:
```bash
# In check-subagent-allowed.sh, add:
if [[ "${agent}" =~ ^(bash-|nix-|c-|python-|terraform-) ]]; then
```

---

## 3. Adding Pipeline States

The FSM can be extended with new states for specialized workflows.

### Current State Machine

```
IDLE → CLASSIFIED → GATHERING → REFINING → ORCHESTRATING_ACTIVE → EXECUTING → COMPLETE
```

### Adding a New State

**Example**: Add TESTING state after EXECUTING

**1. Update state transitions** in `update-pipeline-state.sh`:

```bash
function determine_next_state() {
  local current_state="${1}"
  local agent="${2}"

  case "${current_state}" in
    # ... existing cases ...
    "EXECUTING")
      if [[ "${agent}" =~ ^.*-tester$ ]]; then
        echo "TESTING"
      else
        echo "EXECUTING"
      fi
      ;;
    "TESTING")
      echo "COMPLETE"
      ;;
  esac
}
```

**2. Update allowed agents** in `check-subagent-allowed.sh`:

```bash
"TESTING")
  # Only test runners and review agents
  if [[ "${agent}" =~ ^.*-(tester|reviewer)$ ]]; then
    approve_agent "${agent}"
  else
    block_agent "${agent}" "Testing state only allows tester/reviewer agents"
  fi
  ;;
```

**3. Update documentation**:
- Update ONBOARDING.md state diagram
- Update QUICKREF.md state table
- Update DIAGRAMS.md

---

## 4. Creating Slash Commands

Slash commands are Markdown files in `~/.claude/commands/` (deployed) or `private_dot_claude/commands/` (source).

### Command Structure

```markdown
---
description: Brief description shown in /help
---

Instructions for what the command should do.

Arguments are available as: $ARGUMENTS
```

### Example: /audit-security

**File**: `private_dot_claude/commands/audit-security.md`

```markdown
---
description: Run comprehensive security audit on specified files
---

Run a comprehensive security audit on the specified files or directories.

## Arguments

Target: $ARGUMENTS

If no target specified, audit the entire codebase.

## Execution

1. First, identify the language(s) involved:
   - Check file extensions
   - Identify primary languages

2. For each language found, invoke appropriate security agents:

   **C code**: Launch c-memory-safety-auditor, c-privilege-auditor,
   c-race-condition-auditor in parallel, then c-security-reviewer.

   **Python code**: Use python-security-reviewer.

   **Bash scripts**: Use bash-security-reviewer.

3. Compile findings into a summary report.

## Output

Provide a structured report with:
- Files audited
- Vulnerabilities found (by severity)
- Recommendations
- Priority fixes
```

### Testing Commands

```bash
# Deploy changes
chezmoi apply

# Test command (in Claude Code)
/audit-security src/
```

---

## 5. Creating Skills

Skills are more complex than commands - they're directories with a SKILL.md file.

### Skill Structure

```
skills/
└── my-skill/
    ├── SKILL.md           # Main skill definition (or private_SKILL.md)
    └── (optional files)   # Supporting files
```

### Example: Security Hardening Skill

**Directory**: `private_dot_claude/skills/security-hardening/`

**File**: `private_SKILL.md`

```markdown
---
name: security-hardening
description: Guided security hardening workflow for production deployments
---

# Security Hardening Workflow

This skill guides you through a comprehensive security hardening process.

## Steps

### Step 1: Inventory

First, identify all security-relevant components:

1. List all network-exposed services
2. Identify privilege boundaries
3. Map data flow paths
4. Find credential usage

### Step 2: Analysis

For each component type:

- **C binaries**: Use c-security-reviewer
- **Python services**: Use python-security-reviewer
- **Shell scripts**: Use bash-security-reviewer
- **Configuration**: Manual review

### Step 3: Remediation

For each finding:

1. Assess severity (Critical/High/Medium/Low)
2. Determine fix complexity
3. Implement fixes (high severity first)
4. Verify with re-audit

### Step 4: Documentation

Document:
- Changes made
- Residual risks accepted
- Monitoring recommendations

## Invoke Now

Start by running inventory:

```bash
# Find setuid binaries
find /usr/local/bin -perm -4000 2>/dev/null

# Find world-writable files
find /etc -perm -002 2>/dev/null

# List listening services
ss -tlnp
```
```

---

## 6. Customizing Hooks

### Hook Types

| Hook | When Fired | Purpose |
|------|------------|---------|
| SessionStart | New Claude Code session | Initialize state |
| UserPromptSubmit | User sends message | Inject context |
| PreToolUse | Before any tool | Gate/modify tool use |
| SubagentStop | Agent completes | Update state |

### Adding a Custom Hook

**Example**: Log all tool usage for auditing

**1. Create hook script** (`private_dot_claude/scripts/log-tool-usage.sh`):

```bash
#!/usr/bin/env bash
set -euo pipefail

readonly LOG_FILE="${HOME}/.claude/state/tool-usage.log"
readonly TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Read tool info from stdin
TOOL_INFO="$(cat)"

# Extract tool name
TOOL_NAME="$(echo "${TOOL_INFO}" | jq -r '.tool_name // "unknown"')"

# Log it
echo "[${TIMESTAMP}] Tool: ${TOOL_NAME}" >> "${LOG_FILE}"

# Always approve (this is just logging)
echo '{"decision": "approve"}'
```

**2. Register in settings.json**:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/scripts/log-tool-usage.sh"
          }
        ]
      }
    ]
  }
}
```

**3. Deploy and test**:

```bash
chezmoi apply

# Verify logging works
tail -f ~/.claude/state/tool-usage.log
```

---

## 7. Contributing Guidelines

### Code Style

**Bash Scripts**:
- Follow [Google Bash Style Guide](https://google.github.io/styleguide/shellguide.html)
- Avoid [BashPitfalls](https://mywiki.wooledge.org/BashPitfalls)
- Use shellcheck for linting

**Agent Definitions**:
- Clear, actionable instructions
- Include checklists where appropriate
- Document output formats
- Specify tool requirements

**Documentation**:
- Markdown with Mermaid diagrams where helpful
- Keep examples current and tested
- Update INDEX.md when adding docs

### Testing Changes

Before submitting:

```bash
# Verify chezmoi applies cleanly
chezmoi diff
chezmoi apply

# Test pipeline still works
~/.claude/scripts/pipeline-gate.sh init
echo '{"subagent_type": "context-gatherer"}' | \
  ~/.claude/scripts/check-subagent-allowed.sh

# If you modified agents, test them
# (Invoke in Claude Code and verify behavior)
```

### Commit Guidelines

- Use semantic commit messages
- Test before committing
- Update CHANGELOG.md for user-visible changes

### Pull Request Process

1. Create feature branch
2. Make changes
3. Test thoroughly
4. Update documentation
5. Submit PR with description of changes

---

## Future Expansion Areas

Per the architectural roadmap, these areas are planned:

### Priority 6: Domain Expansion

Needed agent teams:
- **Rust**: rust-architect, rust-unsafe-auditor, rust-lifetime-analyzer
- **Go**: go-architect, go-concurrency-auditor
- **TypeScript**: ts-type-designer, ts-migration-specialist
- **SQL**: sql-security-auditor, sql-optimizer
- **IaC**: terraform-reviewer, k8s-security-auditor

### Priority 7: Cross-Repository Context

Future enhancement to understand dependencies across repositories.

---

*Last updated: November 2025*
