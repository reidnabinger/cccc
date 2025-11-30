# CCCC Documentation Index

Complete documentation for the Claude Code Agent Pipeline (cccc).

---

## Quick Navigation

| Document | Description | Audience |
|----------|-------------|----------|
| [README](../README.md) | Project overview and chezmoi usage | Everyone |
| [ONBOARDING](ONBOARDING.md) | Comprehensive introduction with diagrams | New users |
| [QUICKREF](QUICKREF.md) | Pocket reference card | Daily use |
| [TROUBLESHOOTING](TROUBLESHOOTING.md) | Problem solving guide | When things break |

---

## Getting Started

### New Users

1. **[ONBOARDING.md](ONBOARDING.md)** - Start here. Comprehensive guide with:
   - Core concepts (FSM, pipeline modes, agents)
   - Architecture overview with Mermaid diagrams
   - Step-by-step first pipeline run
   - Quick reference tables

2. **[QUICKREF.md](QUICKREF.md)** - Keep this handy for:
   - State machine reference
   - Common commands
   - Agent quick reference
   - Troubleshooting shortcuts

### Existing Users

- **[COMMANDS.md](COMMANDS.md)** - Slash commands and skills reference
- **[HOOKS.md](HOOKS.md)** - Hook configuration details
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - When things go wrong

---

## Architecture Documentation

### Diagrams & Visualizations

- **[DIAGRAMS.md](DIAGRAMS.md)** - All architecture diagrams:
  - Complete FSM state diagram
  - Hook execution flow
  - Parallel context gathering
  - Agent hierarchy
  - State file structure
  - Script interaction map
  - Adaptive routing decision tree
  - Error handling flow
  - Context cache architecture
  - Deployment architecture

### Technical Deep-Dives

- **[scripts/ARCHITECTURE.md](../private_dot_claude/scripts/ARCHITECTURE.md)** - Pipeline enforcement internals
- **[scripts/README.md](../private_dot_claude/scripts/README.md)** - Script documentation
- **[scripts/IMPLEMENTATION_SUMMARY.md](../private_dot_claude/scripts/IMPLEMENTATION_SUMMARY.md)** - Implementation details

---

## Agent Guides

### By Domain

| Domain | Guide | Agents Covered |
|--------|-------|----------------|
| **C Security** | [C-SECURITY-AGENTS-GUIDE.md](../private_dot_claude/agents/C-SECURITY-AGENTS-GUIDE.md) | c-security-architect, c-security-coder, c-memory-safety-auditor, c-privilege-auditor, c-race-condition-auditor, c-security-reviewer, c-static-analyzer, c-security-tester |
| **Nix** | [agents/README.md](../private_dot_claude/agents/README.md) | nix-architect, nix-module-writer, nix-package-builder, nix-reviewer, nix-debugger |
| **Bash** | [BASH-AGENTS-GUIDE.md](../private_dot_claude/agents/BASH-AGENTS-GUIDE.md) | bash-architect, bash-tester, bash-style-enforcer, bash-security-reviewer, bash-optimizer, bash-error-handler, bash-debugger |
| **Python** | [PYTHON-AGENTS-GUIDE.md](../private_dot_claude/agents/PYTHON-AGENTS-GUIDE.md) | python-architect, python-security-reviewer, python-ml-specialist, python-test-writer, python-quality-enforcer, python-async-specialist |

### Quick Start

- **[00-QUICK-START.md](../private_dot_claude/agents/00-QUICK-START.md)** - C security agents quick start

### Core Pipeline Agents

| Agent | Purpose | Model |
|-------|---------|-------|
| `task-classifier` | Quick complexity assessment | haiku |
| `context-gatherer` | Collect codebase context | sonnet |
| `context-refiner` | Distill into actionable intel | sonnet |
| `strategic-orchestrator` | Plan and coordinate | opus |

### Sub-Gatherers (Parallel)

| Agent | Focus Area |
|-------|------------|
| `architecture-gatherer` | Structure, modules, entry points |
| `dependency-gatherer` | External/internal dependencies |
| `pattern-gatherer` | Code conventions and patterns |
| `history-gatherer` | Git evolution and history |

---

## Configuration

### Hook System

- **[HOOKS.md](HOOKS.md)** - Complete hook configuration guide:
  - SessionStart, UserPromptSubmit, PreToolUse, SubagentStop
  - Pipeline enforcement hooks
  - Adding custom hooks
  - Debugging hook issues

### Settings

- **settings.json** - Located at `~/.claude/settings.json` after deployment
- See [HOOKS.md](HOOKS.md) for schema and options

---

## Operations

### Commands & Skills

- **[COMMANDS.md](COMMANDS.md)** - Complete command reference:
  - `/pipeline-reset` - Reset stuck pipelines
  - `/task` - Task namespace management
  - `/github-search` - Search GitHub for code
  - `context-pipeline` skill - Start the pipeline

### Troubleshooting

- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Problem solving:
  - "Agent blocked" errors
  - Stuck states
  - Hook failures
  - State corruption
  - Performance issues
  - Debug techniques

---

## Development

### Extending CCCC

- **[EXTENDING.md](EXTENDING.md)** - How to:
  - Add new agents
  - Create domain-specific agent teams
  - Add new pipeline states
  - Customize hook behavior
  - Contribute improvements

### Project History

- **[CHANGELOG.md](../CHANGELOG.md)** - Version history and changes

---

## File Structure

```
~/.claude/                          # Deployed configuration
├── CLAUDE.md                       # Global runtime instructions
├── settings.json                   # Hook configuration
├── agents/                         # Agent definitions
│   ├── context-gatherer.md
│   ├── bash-architect.md
│   └── ...
├── scripts/                        # Pipeline enforcement
│   ├── pipeline-gate.sh            # State initialization
│   ├── check-subagent-allowed.sh   # FSM enforcement
│   ├── update-pipeline-state.sh    # State transitions
│   ├── reset-pipeline-state.sh     # Manual recovery
│   ├── context-cache.sh            # Persistent memory
│   └── namespace-utils.sh          # Task namespaces
├── commands/                       # Slash commands
│   ├── pipeline-reset.md
│   ├── task.md
│   └── github-search.md
├── skills/                         # Custom skills
│   └── context-pipeline/
├── state/                          # Runtime state (auto-created)
│   ├── tasks/                      # Task namespace states
│   │   ├── _default/
│   │   └── <namespace>/
│   └── pipeline-journal.log        # Audit trail
└── memory/                         # Context cache
    ├── index.json
    └── contexts/

~/gh/cccc/                          # Source repository
├── README.md
├── CHANGELOG.md
├── docs/
│   ├── INDEX.md                    # This file
│   ├── ONBOARDING.md
│   ├── DIAGRAMS.md
│   ├── QUICKREF.md
│   ├── TROUBLESHOOTING.md
│   ├── HOOKS.md
│   ├── COMMANDS.md
│   └── EXTENDING.md
└── private_dot_claude/             # Chezmoi source
```

---

## Quick Links

### Most Common Tasks

| Task | Document/Command |
|------|------------------|
| Start a complex task | Use `context-pipeline` skill |
| Reset stuck pipeline | `/pipeline-reset` |
| Check current state | `jq '.state' ~/.claude/state/tasks/_default/pipeline-state.json` |
| View journal | `tail -20 ~/.claude/state/pipeline-journal.log` |
| Create task namespace | `/task create <name>` |
| List namespaces | `/task list` |

### Emergency Recovery

```bash
# Reset pipeline to IDLE
~/.claude/scripts/reset-pipeline-state.sh "Emergency reset"

# Check state file
jq . ~/.claude/state/tasks/_default/pipeline-state.json

# View recent hook activity
tail -50 ~/.claude/state/pipeline-journal.log

# Reinitialize state
~/.claude/scripts/pipeline-gate.sh init
```

---

## Document Conventions

Throughout the documentation:

- `~/.claude/` refers to the deployed configuration directory
- `~/gh/cccc/` refers to the source repository
- Code blocks with `bash` show shell commands
- Code blocks with `json` show configuration or state files
- Mermaid diagrams render in GitHub and compatible viewers
- `[CRITICAL]` markers indicate security-sensitive information
- `DEV-NOTE` comments in code indicate important implementation details

---

*Last updated: November 2025*
*Generated for cccc - Claude Code Agent Pipeline*
