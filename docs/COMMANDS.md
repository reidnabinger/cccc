# CCCC Commands and Skills Reference

Complete reference for slash commands and skills in the Claude Code Agent Pipeline.

---

## Table of Contents

1. [Slash Commands](#slash-commands)
2. [Skills](#skills)
3. [Quick Reference](#quick-reference)

---

## Slash Commands

Slash commands are invoked by typing `/command-name [arguments]` in Claude Code.

### /pipeline-reset

**Purpose**: Reset the pipeline state machine to IDLE.

**Usage**:
```
/pipeline-reset [reason]
```

**When to Use**:
- Pipeline is stuck in an intermediate state
- An agent failed and state didn't advance
- You want to start fresh with context gathering
- Stale state auto-reset didn't trigger (10 min timeout)

**What It Does**:
1. Shows current state
2. Resets state to IDLE
3. Creates backup of previous state
4. Verifies reset succeeded
5. Shows recent journal entries

**Examples**:
```
/pipeline-reset Pipeline stuck after failed agent

/pipeline-reset
```

**Location**: `~/.claude/commands/pipeline-reset.md`

---

### /task

**Purpose**: Manage task namespaces for parallel pipeline work.

**Usage**:
```
/task <subcommand> [arguments]
```

**Subcommands**:

| Subcommand | Description |
|------------|-------------|
| `create <name>` | Create new namespace and get instructions |
| `list` | List all namespaces with status |
| `join <name>` | Get instructions to switch to namespace |
| `leave` | Get instructions to return to default |
| `status` | Show current namespace status |
| `destroy <name>` | Delete a namespace |
| `complete [description]` | Mark task complete (triggers doc checkpoint) |
| `docs` | Show documentation checkpoint checklist |
| `docs-complete [notes]` | Clear documentation checkpoint |

**Examples**:

```
# Create a namespace for auth work
/task create auth-refactor

# List all namespaces
/task list

# Check current status
/task status

# Mark task complete
/task complete "Implemented JWT authentication"

# After writing docs
/task docs-complete "Added architecture docs and DEV-NOTEs"

# Clean up
/task destroy auth-refactor
```

**Namespace Workflow**:
```
Terminal 1:
$ export CLAUDE_TASK_NAMESPACE='auth-refactor'
$ claude
# Pipeline state isolated to auth-refactor namespace

Terminal 2:
$ export CLAUDE_TASK_NAMESPACE='perf-audit'
$ claude
# Independent pipeline state
```

**Documentation Checkpoint**:
When you run `/task complete`, a checkpoint is created requiring:
1. DEV-NOTEs for tricky code
2. Decision log entries
3. Diagrams (if needed)
4. Architecture doc updates (if needed)

You must address the checklist before starting new pipeline work.

**Location**: `~/.claude/commands/task.md`

---

### /github-search

**Purpose**: Search GitHub for code examples.

**Usage**:
```
/github-search <query>
```

**Examples**:
```
/github-search bash pipeline state machine

/github-search "context-gatherer" language:markdown
```

**Location**: `~/.claude/commands/github-search.md`

---

## Skills

Skills are invoked using the Skill tool or by referencing them in conversation.

### context-pipeline

**Purpose**: Start the agent pipeline for complex development tasks.

**Usage**:
- Use the `context-pipeline` skill
- Or mention "use the context pipeline"

**What It Does**:
1. Provides instructions for starting the pipeline
2. Offers two approaches:
   - **Option A**: Quick classification with task-classifier first
   - **Option B**: Full pipeline starting with context-gatherer

**Pipeline Flow**:
```
You invoke context-gatherer
        ↓ (auto-advances)
context-refiner runs
        ↓ (auto-advances)
strategic-orchestrator runs
        ↓ (deploys domain specialists)
Specialized agents execute
        ↓
Final result returned
```

**Classification Results**:

| Classification | Action |
|----------------|--------|
| TRIVIAL | Proceed directly with specialists |
| MODERATE | context-gatherer → execute (skip refiner) |
| COMPLEX | Full pipeline |
| EXPLORATORY | Full pipeline for research |

**Available Specialists**:

- **Bash**: bash-architect, bash-error-handler, bash-style-enforcer, bash-security-reviewer, bash-tester, bash-optimizer, bash-debugger
- **Nix**: nix-architect, nix-module-writer, nix-package-builder, nix-reviewer, nix-debugger
- **C**: c-security-architect, c-security-coder, c-memory-safety-auditor, c-privilege-auditor, c-race-condition-auditor, c-static-analyzer, c-security-reviewer, c-security-tester
- **Python**: python-architect, python-security-reviewer, python-ml-specialist, python-test-writer, python-quality-enforcer, python-async-specialist
- **General**: critical-code-reviewer, docs-reviewer

**Location**: `~/.claude/skills/context-pipeline/SKILL.md`

---

## Plugin Commands

These commands come from enabled Claude Code plugins:

### /commit-commands:commit

Create a git commit with conventional format.

### /commit-commands:commit-push-pr

Commit, push, and open a PR in one command.

### /commit-commands:clean_gone

Clean up git branches deleted on remote.

### /pr-review-toolkit:review-pr

Comprehensive PR review using specialized agents.

### /feature-dev:feature-dev

Guided feature development workflow.

### /code-review:code-review

Code review a pull request.

---

## Quick Reference

### Pipeline Management

| Command | Purpose |
|---------|---------|
| `/pipeline-reset` | Reset stuck pipeline to IDLE |
| `/task status` | Show current namespace and state |
| `/task list` | List all namespaces |

### Task Namespaces

| Command | Purpose |
|---------|---------|
| `/task create <name>` | Create new namespace |
| `/task join <name>` | Switch to namespace |
| `/task leave` | Return to default |
| `/task destroy <name>` | Delete namespace |

### Documentation Checkpoints

| Command | Purpose |
|---------|---------|
| `/task complete [desc]` | Mark task complete |
| `/task docs` | Show doc checklist |
| `/task docs-complete [notes]` | Clear checkpoint |

### Common Shell Commands

```bash
# Check pipeline state
jq '.state' ~/.claude/state/tasks/_default/pipeline-state.json

# View journal
tail -20 ~/.claude/state/pipeline-journal.log

# Manual reset
~/.claude/scripts/reset-pipeline-state.sh "Reason"

# Check cache
~/.claude/scripts/context-cache.sh info
```

---

## Creating Custom Commands

Commands are Markdown files in `~/.claude/commands/`.

### Basic Structure

```markdown
---
description: Brief description for /help
---

Instructions for Claude to execute.

Arguments are available as: $ARGUMENTS
```

### Example: /audit-all

**File**: `~/.claude/commands/audit-all.md`

```markdown
---
description: Run all security auditors on specified path
---

Run comprehensive security audit on: $ARGUMENTS

## Execution

1. Identify file types in the target path
2. For each type, invoke appropriate security agents:
   - C: c-security-reviewer
   - Python: python-security-reviewer
   - Bash: bash-security-reviewer
3. Compile findings into report
```

### Testing

```bash
# Deploy
chezmoi apply

# Use in Claude Code
/audit-all src/
```

---

## Creating Custom Skills

Skills are directories in `~/.claude/skills/` with a `SKILL.md` file.

### Structure

```
skills/
└── my-skill/
    └── SKILL.md   # (or private_SKILL.md for private)
```

### Example: Database Migration Skill

**Directory**: `~/.claude/skills/db-migration/`

**File**: `SKILL.md`

```markdown
---
name: db-migration
description: Guided database migration workflow
---

# Database Migration Skill

This skill guides you through safe database migrations.

## Steps

1. **Backup**: Create backup of current schema
2. **Plan**: Review migration changes
3. **Test**: Run migration on test database
4. **Execute**: Apply to production
5. **Verify**: Confirm migration success

## Start Now

What database are you migrating? (PostgreSQL, MySQL, SQLite)
```

---

*Last updated: November 2025*
