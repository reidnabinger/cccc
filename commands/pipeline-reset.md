---
description: Reset the pipeline FSM state to IDLE
---

Reset the pipeline state machine to IDLE state.

## When to Use

Use this command when:
- Pipeline is stuck in an intermediate state (GATHERING, REFINING, etc.)
- An agent failed and state didn't advance properly
- You want to start fresh with context gathering
- The stale state auto-reset didn't trigger (timeout is 10 minutes)

## Arguments

Optional reason: "$ARGUMENTS"

If no reason provided, uses "Manual reset via /pipeline-reset"

## Execution

1. First, check the current pipeline state:

```bash
cat ~/.claude/state/pipeline-state.json | jq '{state, timestamp, active_agent}'
```

2. If state is not IDLE, run the reset script:

```bash
~/.claude/scripts/reset-pipeline-state.sh "Manual reset via /pipeline-reset: $ARGUMENTS"
```

3. Verify the reset succeeded:

```bash
cat ~/.claude/state/pipeline-state.json | jq '{state, timestamp}'
```

4. Optionally show recent journal entries:

```bash
tail -20 ~/.claude/state/pipeline-journal.log 2>/dev/null || echo "No journal entries yet"
```

## After Reset

After resetting, the pipeline will be in IDLE state. You can then:
- Start fresh with context-gatherer
- Use any agent (utility agents are now allowed after context gathering)

## Troubleshooting

If reset fails:
- Check that `~/.claude/state/` directory exists
- Verify `jq` is installed
- Check file permissions on state file
- Review journal for error patterns
