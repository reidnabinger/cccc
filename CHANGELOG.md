# Changelog

All notable changes to the CCCC (Chezmoi Configs Claude Code) project.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## [Unreleased]

### Added
- Comprehensive documentation index (`docs/INDEX.md`)
- Bash agents guide (`BASH-AGENTS-GUIDE.md`)
- Python agents guide (`PYTHON-AGENTS-GUIDE.md`)
- Troubleshooting guide (`docs/TROUBLESHOOTING.md`)
- Extension/contribution guide (`docs/EXTENDING.md`)
- Hook configuration reference (`docs/HOOKS.md`)
- Commands and skills reference (`docs/COMMANDS.md`)
- This changelog

---

## [1.5.0] - 2025-11-29

### Added
- **Task namespaces** for parallel pipeline work
  - `/task create <name>` - Create isolated namespace
  - `/task list` - List all namespaces with status
  - `/task join <name>` - Switch to namespace
  - `/task leave` - Return to default namespace
  - `/task destroy <name>` - Delete namespace
  - `CLAUDE_TASK_NAMESPACE` environment variable support
  - Independent FSM state per namespace (`~/.claude/state/tasks/<name>/`)
  - Automatic migration of legacy state to `_default` namespace

- **Documentation checkpoint enforcement**
  - `/task complete [description]` - Mark task complete, trigger checkpoint
  - `/task docs` - Show documentation checklist
  - `/task docs-complete [notes]` - Clear checkpoint after docs written
  - Blocks new pipeline work until documentation addressed
  - Checklist: DEV-NOTEs, diagrams, architecture docs, decision log
  - Checkpoint history archived for audit trail

### Changed
- State files moved from `~/.claude/state/pipeline-state.json` to `~/.claude/state/tasks/_default/pipeline-state.json`

---

## [1.4.0] - 2025-11-29

### Added
- **MCP server configuration**
  - memory-keeper: Persistent memory across sessions
  - sequential-thinking: Structured reasoning for complex decisions
  - context7: Up-to-date library documentation lookup

### Changed
- Project-local MCP server configuration via `.mcp.json`

---

## [1.3.0] - 2025-11-28

### Added
- **Comprehensive onboarding documentation**
  - Full introduction guide (`docs/ONBOARDING.md`)
  - Architecture diagrams with Mermaid (`docs/DIAGRAMS.md`)
  - Quick reference card (`docs/QUICKREF.md`)
  - 10 detailed Mermaid diagrams covering all aspects

### Changed
- Improved documentation structure with dedicated `docs/` folder

---

## [1.2.0] - 2025-11-27

### Added
- **Adaptive pipeline routing**
  - task-classifier agent (haiku model) for quick assessment
  - Four pipeline modes: TRIVIAL, MODERATE, COMPLEX, EXPLORATORY
  - Auto-classification extraction from task-classifier output
  - Mode-based routing:
    - TRIVIAL: Skip gathering → execute directly
    - MODERATE: Gather → execute (skip refiner/orchestrator)
    - COMPLEX: Full pipeline
    - EXPLORATORY: Full pipeline for research

- **CLASSIFIED state** in FSM for post-classification routing

### Changed
- Pipeline now intelligently routes based on task complexity
- Reduced overhead for simple tasks

---

## [1.1.0] - 2025-11-26

### Changed
- **Normalized permissions**: Removed `private_` prefixes from agent files
- Cleaner file naming in chezmoi source

### Fixed
- Permission issues with script execution
- Chezmoi template handling for agent files

---

## [1.0.0] - 2025-11-25

### Added
- **Initial release** of Claude Code Agent Pipeline

- **Pipeline FSM enforcement**
  - States: IDLE, GATHERING, REFINING, ORCHESTRATING_ACTIVE, EXECUTING, COMPLETE
  - Hook-based enforcement via settings.json
  - Automatic state transitions

- **Core pipeline scripts**
  - `pipeline-gate.sh` - State initialization and workflow injection
  - `check-subagent-allowed.sh` - FSM enforcement
  - `update-pipeline-state.sh` - State advancement
  - `reset-pipeline-state.sh` - Manual recovery

- **Context caching**
  - `context-cache.sh` - Persistent context memory
  - Content-addressed storage at `~/.claude/memory/`
  - 7-day TTL with automatic cleanup

- **Core pipeline agents**
  - context-gatherer (sonnet)
  - context-refiner (sonnet)
  - strategic-orchestrator (opus)

- **Parallel sub-gatherers**
  - architecture-gatherer (haiku)
  - dependency-gatherer (haiku)
  - pattern-gatherer (haiku)
  - history-gatherer (haiku)

- **Bash agent team**
  - bash-architect
  - bash-tester
  - bash-style-enforcer
  - bash-security-reviewer
  - bash-optimizer
  - bash-error-handler
  - bash-debugger

- **Nix agent team**
  - nix-architect
  - nix-module-writer
  - nix-package-builder
  - nix-reviewer
  - nix-debugger

- **C security agent team**
  - c-security-architect
  - c-security-coder
  - c-memory-safety-auditor
  - c-privilege-auditor
  - c-race-condition-auditor
  - c-static-analyzer
  - c-security-reviewer
  - c-security-tester

- **Python agent team**
  - python-architect
  - python-security-reviewer
  - python-ml-specialist
  - python-test-writer
  - python-quality-enforcer
  - python-async-specialist

- **Utility agents**
  - critical-code-reviewer
  - docs-reviewer

- **Skills and commands**
  - context-pipeline skill
  - /pipeline-reset command
  - /github-search command

- **Self-advancing agent chains**
  - Agents invoke successors automatically
  - State transitions on approval
  - Main Claude only invokes pipeline start

- **Documentation**
  - CLAUDE.md runtime instructions
  - Agent READMEs and guides
  - Script architecture documentation

---

## Architecture Roadmap Status

### Completed
- [x] Priority 1: FSM Recovery & Self-Healing
- [x] Priority 2: Persistent Context Memory
- [x] Priority 3: Adaptive Pipeline Routing
- [x] Priority 4: Parallel Intelligence Gathering
- [x] Priority 5: Self-Advancing Agent Chains

### In Progress
- [ ] Priority 6: Domain Expansion (Rust, Go, TypeScript, SQL, Terraform, Kubernetes)
- [ ] Priority 7: Cross-Repository Context

---

## Migration Notes

### From pre-1.5.0
State files moved from:
```
~/.claude/state/pipeline-state.json
```
To:
```
~/.claude/state/tasks/_default/pipeline-state.json
```

Legacy state is automatically migrated on first use.

### From pre-1.2.0
New CLASSIFIED state requires updated `check-subagent-allowed.sh`. Run `chezmoi apply` to update.

---

[Unreleased]: https://github.com/user/cccc/compare/v1.5.0...HEAD
[1.5.0]: https://github.com/user/cccc/compare/v1.4.0...v1.5.0
[1.4.0]: https://github.com/user/cccc/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/user/cccc/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/user/cccc/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/user/cccc/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/user/cccc/releases/tag/v1.0.0
