# CCCC - Claude Code Agent Pipeline

A sophisticated agent orchestration system for Claude Code that enforces structured workflows through a finite state machine.

## What is CCCC?

CCCC (Chezmoi Configs Claude Code) is a **pipeline enforcement system** that ensures complex development tasks follow a structured workflow:

```
┌──────────┐     ┌─────────────┐     ┌──────────────┐     ┌────────────────────┐     ┌───────────┐
│   IDLE   │ ──► │  GATHERING  │ ──► │   REFINING   │ ──► │ ORCHESTRATING      │ ──► │ EXECUTING │
│          │     │  (context)  │     │ (distilling) │     │ (planning)         │     │           │
└──────────┘     └─────────────┘     └──────────────┘     └────────────────────┘     └───────────┘
```

Without guardrails, AI assistants can jump directly to implementation without understanding context. CCCC **enforces discipline** by making it impossible to skip the context-gathering phases.

## Key Features

- **FSM-Enforced Pipeline** - Hook-based enforcement makes skipping stages impossible
- **Adaptive Routing** - Tasks classified as TRIVIAL/MODERATE/COMPLEX/EXPLORATORY
- **Parallel Context Gathering** - 4 specialized sub-gatherers run concurrently
- **Self-Advancing Chains** - Agents invoke successors automatically
- **Persistent Context Memory** - Context cached across sessions
- **Task Namespaces** - Parallel pipelines for independent work streams
- **50+ Specialized Agents** - Domain experts for Bash, Nix, C, Python, and more

## Quick Start

### Installation

```bash
# Clone the repository
git clone https://github.com/youruser/cccc ~/gh/cccc

# Deploy with chezmoi
chezmoi apply

# Verify installation
~/.claude/scripts/pipeline-gate.sh init
jq '.state' ~/.claude/state/tasks/_default/pipeline-state.json
```

### Your First Pipeline Run

1. Start a Claude Code session
2. Request a complex task:
   ```
   "Help me implement a new feature that adds caching to the API"
   ```
3. The pipeline activates and guides you through:
   - Context gathering
   - Intelligence refining
   - Strategic planning
   - Specialist execution

## Documentation

| Document | Description |
|----------|-------------|
| [docs/INDEX.md](docs/INDEX.md) | **Start here** - Complete documentation index |
| [docs/ONBOARDING.md](docs/ONBOARDING.md) | Comprehensive introduction with diagrams |
| [docs/QUICKREF.md](docs/QUICKREF.md) | Pocket reference card |
| [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | Problem solving guide |
| [docs/HOOKS.md](docs/HOOKS.md) | Hook configuration reference |
| [docs/COMMANDS.md](docs/COMMANDS.md) | Commands and skills reference |
| [docs/EXTENDING.md](docs/EXTENDING.md) | How to extend and customize |
| [CHANGELOG.md](CHANGELOG.md) | Version history |

### Agent Guides

| Domain | Guide |
|--------|-------|
| Bash | [BASH-AGENTS-GUIDE.md](private_dot_claude/agents/BASH-AGENTS-GUIDE.md) |
| Python | [PYTHON-AGENTS-GUIDE.md](private_dot_claude/agents/PYTHON-AGENTS-GUIDE.md) |
| C Security | [C-SECURITY-AGENTS-GUIDE.md](private_dot_claude/agents/C-SECURITY-AGENTS-GUIDE.md) |
| Nix | [agents/README.md](private_dot_claude/agents/README.md) |

## Project Structure

```
~/gh/cccc/                          # Source repository
├── README.md                       # This file
├── CHANGELOG.md                    # Version history
├── docs/                           # User documentation
│   ├── INDEX.md                    # Documentation index
│   ├── ONBOARDING.md               # Getting started guide
│   ├── DIAGRAMS.md                 # Architecture diagrams
│   └── ...
└── private_dot_claude/             # Chezmoi source
    ├── CLAUDE.md                   # Runtime instructions
    ├── settings.json               # Hook configuration
    ├── agents/                     # 50+ agent definitions
    ├── scripts/                    # Pipeline enforcement
    ├── commands/                   # Slash commands
    └── skills/                     # Custom skills

~/.claude/                          # Deployed (after chezmoi apply)
├── CLAUDE.md
├── settings.json
├── agents/
├── scripts/
├── commands/
├── skills/
├── state/                          # Runtime state (auto-created)
│   ├── tasks/
│   │   └── _default/
│   │       └── pipeline-state.json
│   └── pipeline-journal.log
└── memory/                         # Context cache
```

## Common Operations

### Pipeline Management

```bash
# Check current state
jq '.state' ~/.claude/state/tasks/_default/pipeline-state.json

# Reset stuck pipeline
~/.claude/scripts/reset-pipeline-state.sh "Reason"

# View journal
tail -20 ~/.claude/state/pipeline-journal.log
```

### Task Namespaces

```bash
# Create namespace for parallel work
/task create feature-auth

# In terminal, switch to namespace
export CLAUDE_TASK_NAMESPACE='feature-auth'
claude

# List all namespaces
/task list

# Mark task complete
/task complete "Implemented auth feature"
```

### Chezmoi Workflow

```bash
# Apply config to ~/.claude/
chezmoi apply

# See what would change
chezmoi diff

# Edit a file
chezmoi edit ~/.claude/CLAUDE.md

# Add a new file
chezmoi add ~/.claude/agents/new-agent.md
```

## Pipeline States

| State | Allowed Agents | Description |
|-------|----------------|-------------|
| IDLE | context-gatherer, task-classifier | Starting point |
| CLASSIFIED | Based on mode | After classification |
| GATHERING | context-refiner (COMPLEX) or execute (MODERATE) | Collecting context |
| REFINING | strategic-orchestrator | Distilling intel |
| ORCHESTRATING_ACTIVE | Language specialists | Planning |
| EXECUTING | Language specialists | Running specialists |
| COMPLETE | context-gatherer (restart) | Done |

## Specialist Agents

### Core Pipeline
- **task-classifier** (haiku) - Quick complexity assessment
- **context-gatherer** (sonnet) - Collect codebase context
- **context-refiner** (sonnet) - Distill into actionable intel
- **strategic-orchestrator** (opus) - Plan and coordinate

### Domain Specialists
- **Bash**: architect, tester, style-enforcer, security-reviewer, optimizer, error-handler, debugger
- **Nix**: architect, module-writer, package-builder, reviewer, debugger
- **C Security**: architect, coder, memory-safety-auditor, privilege-auditor, race-condition-auditor, static-analyzer, reviewer, tester
- **Python**: architect, security-reviewer, ml-specialist, test-writer, quality-enforcer, async-specialist

## Requirements

- **bash** 4.0+ (for hooks and scripts)
- **jq** (JSON processing)
- **chezmoi** (configuration management)
- **Claude Code** (obviously)

## Architecture Status

Per the [roadmap in CLAUDE.md](private_dot_claude/CLAUDE.md):

- [x] FSM Recovery & Self-Healing
- [x] Persistent Context Memory
- [x] Adaptive Pipeline Routing
- [x] Parallel Intelligence Gathering
- [x] Self-Advancing Agent Chains
- [ ] Domain Expansion (Rust, Go, TypeScript, SQL, Terraform, K8s)
- [ ] Cross-Repository Context

## License

Private configuration - not licensed for public distribution.

---

*For more information, see [docs/INDEX.md](docs/INDEX.md)*
