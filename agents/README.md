# Agents - Role-Reversed Pipeline

This directory contains agents for the role-reversed pipeline model where:
- **Tool-agents** gather intelligence from specialized tools
- **Analysts** provide brutal expert review
- **Main Claude** writes ALL code (sole executor)

## Directory Structure

```
agents/
├── tool-agents/          # Single-tool intelligence gatherers
│   ├── serena-agent.md
│   ├── context7-agent.md
│   ├── websearch-agent.md
│   ├── webfetch-agent.md
│   ├── sequential-thinking-agent.md
│   ├── github-search-agent.md
│   ├── claude-docs-agent.md
│   └── git-agent.md      # MANDATORY for complex tasks
│
├── advisors/             # Brutal senior developers (language experts)
│   ├── bash-advisor.md
│   ├── c-advisor.md
│   ├── nix-advisor.md
│   └── python-advisor.md
│
├── analysts/             # Project-specific brutal analysts
│   ├── architecture-analyst.md
│   └── conventions-analyst.md
│
├── synthesizer/          # Strategic intelligence combination
│   └── strategist.md
│
├── verifiers/            # Post-implementation QA
│   ├── test-interpreter.md
│   └── lint-interpreter.md
│
└── task-classifier.md    # Quick complexity assessment
```

## Agent Categories

### Tool-Agents
Each tool-agent uses ONE tool and returns interpreted intelligence:

| Agent | Tool | Returns |
|-------|------|---------|
| serena-agent | Serena MCP | Code structure, symbols, call graphs |
| context7-agent | Context7 MCP | Library documentation, API patterns |
| websearch-agent | WebSearch | Evaluated sources, synthesized findings |
| webfetch-agent | WebFetch | Extracted URL content |
| sequential-thinking-agent | SequentialThinking MCP | Reasoned conclusions |
| github-search-agent | GitHub search | Real-world code patterns |
| claude-docs-agent | Claude Code guide | Feature documentation |
| git-agent | Git commands | History, blame, diffs, branch context |

### Domain Advisors
Brutal senior developers who review YOUR code:

| Advisor | Expertise |
|---------|-----------|
| bash-advisor | Google style guide, BashPitfalls, security |
| c-advisor | Memory safety, UB, security vulnerabilities |
| nix-advisor | Anti-patterns, evaluation issues, flake problems |
| python-advisor | Type safety, async pitfalls, Pythonic code |

### Analysts
Project-specific brutal reviewers:

| Analyst | Focus |
|---------|-------|
| architecture-analyst | Module boundaries, coupling, layering |
| conventions-analyst | Project patterns, consistency enforcement |

### Synthesizer
| Agent | Purpose |
|-------|---------|
| strategist | Combines multi-source intelligence into recommendations |

### Verifiers
Post-implementation quality gates:

| Verifier | Purpose |
|----------|---------|
| test-interpreter | Runs tests, interprets failures |
| lint-interpreter | Runs linters/type checkers, interprets results |

## Key Principle

**Main Claude is the sole executor.** These agents gather intelligence and provide review, but they do NOT write code. All code changes happen in main Claude's context.

## Workflow

1. **Gather intelligence** (tool-agents in parallel)
2. **Analyze** (architecture/conventions analysts)
3. **Synthesize** (strategist for complex tasks)
4. **Implement** (YOU write code)
5. **Review** (domain advisor)
6. **Verify** (test + lint interpreters)

## Legacy Agents

Some utility agents from the previous architecture remain at the root level:
- `task-classifier.md` - Still used for complexity assessment
- `codepath-culler.md` / `codepath-culler-contrarian.md` - Dead code analysis
- `critical-code-reviewer.md` - General code review
- `docs-reviewer.md` - Documentation review
- `latex.md` - LaTeX document and mathematical notation generation
- `semantic-explorer.md` - MCP-native codebase exploration (alternative to Explore)
