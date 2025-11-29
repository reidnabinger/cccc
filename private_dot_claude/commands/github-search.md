---
description: Search GitHub for code examples
---

Search GitHub for code examples using: "$ARGUMENTS"

## Your Task

1. Analyze the user's query and determine the best search strategy
2. Use `gh search code` with appropriate qualifiers
3. Present results clearly with repository names, file paths, and URLs

## Search Strategy

Based on the query, intelligently add qualifiers:
- **Language detection**: If query mentions "python", "rust", "nix", "bash" etc., add `--language LANG`
- **File type**: If query mentions file extensions, use `--extension EXT`
- **Scope**: If query mentions specific repos/orgs, use `--repo` or `--org`

## Available Search Qualifiers

- `--language LANG` - python, rust, nix, bash, c, javascript, etc.
- `--extension EXT` - .py, .rs, .nix, .sh, .c, etc.
- `--repo OWNER/REPO` - Search specific repository
- `--limit N` - Number of results (default: 15)

## Execution

Use the Bash tool to execute searches like:
```bash
gh search code "QUERY" --limit 15
gh search code "QUERY" --language python --limit 15
gh search code "QUERY" --extension nix --limit 10
```

## Presentation Format

For each result, show:
- **Repository**: owner/repo-name (with star count if relevant)
- **File**: path/to/file.ext
- **URL**: https://github.com/owner/repo/blob/...
- **Snippet**: Show relevant code excerpt when helpful

If no results found, suggest:
- Broadening the query
- Trying different keywords
- Removing restrictive qualifiers
