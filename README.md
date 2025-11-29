# cccc - Chezmoi Configs Claude Code

Agent orchestration pipeline configuration for Claude Code, managed with chezmoi.

## Structure

```
private_dot_claude/
├── CLAUDE.md                 # Global instructions
├── settings.json             # Hooks, permissions, settings
├── private_agents/           # Agent definitions (.md)
├── scripts/                  # Pipeline enforcement scripts
│   ├── pipeline-gate.sh      # FSM state management
│   ├── check-subagent-allowed.sh  # Pre-tool-use hook
│   └── *.md                  # Architecture docs
├── commands/                 # Custom slash commands
└── skills/                   # Custom skills
    └── context-pipeline/     # Main orchestration skill
```

## Pipeline FSM

```
IDLE → context-gatherer → context-refiner → strategic-orchestrator → [language agents]
                                                         │
                         ┌───────────────────────────────┼───────────────────┐
                         ▼                               ▼                   ▼
                    Nix Agents                      Bash Agents          C Agents
```

## Usage

```bash
# Apply config to ~/.claude/
chezmoi apply

# Edit a file (opens in editor, applies on save)
chezmoi edit ~/.claude/CLAUDE.md

# See what would change
chezmoi diff

# Add a new file to management
chezmoi add ~/.claude/agents/new-agent.md

# Update source from target (if you edited ~/.claude/ directly)
chezmoi re-add ~/.claude/CLAUDE.md
```

## Experimenting Safely

```bash
# Create a branch for experiments
cd ~/gh/cccc && git checkout -b experiment/triage-state

# Make changes to source files
vim private_dot_claude/scripts/pipeline-gate.sh

# Test the changes
chezmoi apply

# If it breaks, rollback
chezmoi apply --source-path <(git show main:private_dot_claude/)
# Or simply:
git checkout main && chezmoi apply
```

## Files NOT Managed (runtime state)

See `.chezmoiignore` - these are explicitly excluded:
- `history.jsonl` - Session history
- `todos/`, `state/` - Ephemeral state
- `.credentials.json` - Secrets
- `debug/`, `session-env/` - Runtime data
