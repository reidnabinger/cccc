---
description: Generate or update documentation for code, APIs, or architecture
---

# Documentation: $ARGUMENTS

You are generating or updating documentation.

## Phase 1: Determine Documentation Type

Based on "$ARGUMENTS", identify what to document:

| Type | Trigger Words | Output |
|------|---------------|--------|
| **README** | "readme", "project", "overview" | Project README.md |
| **API** | "api", "endpoint", "routes" | API reference docs |
| **Architecture** | "architecture", "design", "structure" | Architecture doc + diagrams |
| **Module** | "module", "component", file path | Module-level documentation |
| **Onboarding** | "onboard", "getting started", "new dev" | Developer onboarding guide |

## Phase 2: Gather Information

Use appropriate tool-agents:

### For README/Overview
- **architecture-analyst** - Understand structure
- **git-agent** - Project history, key contributors

### For API Documentation
- **serena-agent** - Find all endpoints, routes, handlers
- **context7-agent** - If using a framework, get conventions

### For Architecture
- **architecture-analyst** - Module boundaries, dependencies
- **serena-agent** - Call graphs, symbol maps

### For Onboarding
- Read existing README, CONTRIBUTING.md
- Identify setup steps, common tasks

## Phase 3: Generate Documentation

### README Template

```markdown
# Project Name

Brief description (1-2 sentences).

## Features

- Feature 1
- Feature 2

## Quick Start

\`\`\`bash
# Installation
command here

# Run
command here
\`\`\`

## Documentation

- [API Reference](./docs/api.md)
- [Architecture](./docs/architecture.md)
- [Contributing](./CONTRIBUTING.md)

## Development

### Prerequisites
- Requirement 1
- Requirement 2

### Setup
\`\`\`bash
steps here
\`\`\`

### Testing
\`\`\`bash
test command
\`\`\`

## License

[License type]
```

### API Documentation Template

```markdown
# API Reference

## Authentication
[How to authenticate]

## Endpoints

### Resource Name

#### GET /resource
Description

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| id | string | Yes | Resource ID |

**Response:**
\`\`\`json
{
  "example": "response"
}
\`\`\`

**Errors:**
| Code | Description |
|------|-------------|
| 404 | Not found |
```

### Architecture Documentation Template

```markdown
# Architecture

## Overview
[High-level description]

## Components

### Component 1
- **Purpose**: What it does
- **Location**: Where the code lives
- **Dependencies**: What it depends on

## Data Flow
[Describe how data moves through the system]

## Diagrams

### System Overview
\`\`\`mermaid
graph TD
    A[Client] --> B[API]
    B --> C[Service]
    C --> D[Database]
\`\`\`

## Key Decisions
| Decision | Rationale | Alternatives Considered |
|----------|-----------|------------------------|
| Choice 1 | Why | What else was considered |
```

## Phase 4: Validate Documentation

Use **docs-reviewer** agent to validate:

- [ ] Accuracy - Does it match the actual code?
- [ ] Completeness - Are there gaps?
- [ ] Clarity - Is it understandable?
- [ ] Currency - Is it up to date?

## Phase 5: Place Documentation

### Placement Guidelines

| Doc Type | Location |
|----------|----------|
| README | Project root: `README.md` |
| API Reference | `docs/api.md` or `docs/api/` |
| Architecture | `docs/architecture.md` |
| Module docs | Adjacent to code or `docs/modules/` |
| Onboarding | `docs/onboarding.md` or `CONTRIBUTING.md` |

## Anti-Patterns to Avoid

- ❌ Documenting implementation details that change frequently
- ❌ Duplicating information from code comments
- ❌ Writing docs that require constant updates
- ❌ Burying important info in walls of text
- ❌ Making up examples that don't actually work

## Quality Checklist

- [ ] Examples actually run/work
- [ ] Commands are copy-paste ready
- [ ] Links are valid
- [ ] No outdated information
- [ ] Accessible to target audience
- [ ] Reviewed by docs-reviewer agent

**Document what matters. Verify accuracy. Keep it current.**
