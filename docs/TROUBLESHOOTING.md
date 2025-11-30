# CCCC Troubleshooting Guide

Comprehensive guide for diagnosing and fixing issues with the Claude Code Agent Pipeline.

---

## Quick Diagnosis Flowchart

```
Problem encountered
       │
       ▼
Is the agent being blocked?
       │
   ┌───┴───┐
  YES      NO
   │        │
   ▼        ▼
See "Agent    Is state stuck?
Blocked"          │
section      ┌────┴────┐
            YES       NO
             │         │
             ▼         ▼
        See "Stuck   See "Other
        State"       Issues"
        section      section
```

---

## 1. Agent Blocked Errors

### Symptom: "Must start pipeline with context-gatherer"

**Cause**: You're trying to use a specialist agent before gathering context.

**Solution**:
```bash
# Check current state
jq '.state' ~/.claude/state/tasks/_default/pipeline-state.json

# If IDLE, you must start with context-gatherer or task-classifier
# Option A: Start with classification
"Use task-classifier to assess this task: [your request]"

# Option B: Start with full context gathering
"Use context-gatherer for: [your request]"
```

### Symptom: "Agent [name] not allowed in state [STATE]"

**Cause**: FSM prevents out-of-order agent execution.

**Reference Table**:

| State | Allowed Agents |
|-------|----------------|
| IDLE | context-gatherer, task-classifier |
| CLASSIFIED | Depends on pipeline_mode |
| GATHERING | context-refiner (COMPLEX) or execution agents (MODERATE) |
| REFINING | strategic-orchestrator |
| ORCHESTRATING_ACTIVE | Language specialists |
| EXECUTING | Language specialists |

**Solution**:
```bash
# Check what state you're in and what's allowed
jq '{state, pipeline_mode, active_agent}' ~/.claude/state/tasks/_default/pipeline-state.json

# Either:
# 1. Use an agent appropriate for current state
# 2. Reset the pipeline if state is incorrect
~/.claude/scripts/reset-pipeline-state.sh "Need to restart"
```

### Symptom: "Utility agents blocked in IDLE"

**Cause**: Explore, Plan, and general-purpose agents are now blocked in IDLE state to prevent skipping context gathering.

**Solution**:
```
# Run context-gatherer first, then utility agents are allowed
"Use context-gatherer for: [your task]"

# After that completes, utility agents work
"Use Explore to find..."
```

---

## 2. Stuck State Issues

### Symptom: Pipeline stuck in GATHERING/REFINING/etc.

**Diagnosis**:
```bash
# Check how long state has been the same
jq '{state, timestamp}' ~/.claude/state/tasks/_default/pipeline-state.json

# Check active agents
jq '.active_agents' ~/.claude/state/tasks/_default/pipeline-state.json

# View recent journal activity
tail -30 ~/.claude/state/pipeline-journal.log
```

**Automatic Recovery**:
The system auto-resets stale states after 10 minutes. If you can't wait:

**Manual Recovery**:
```bash
# Reset with reason
~/.claude/scripts/reset-pipeline-state.sh "Pipeline stuck in GATHERING"

# Verify reset
jq '.state' ~/.claude/state/tasks/_default/pipeline-state.json
# Should show: "IDLE"
```

### Symptom: "Pipeline mode not set" after classification

**Cause**: task-classifier completed but mode wasn't extracted properly.

**Solution**:
```bash
# Manually set the mode
STATE_FILE=~/.claude/state/tasks/_default/pipeline-state.json
jq '.pipeline_mode = "COMPLEX"' "$STATE_FILE" > /tmp/state.json
mv /tmp/state.json "$STATE_FILE"

# Or reset and re-classify
~/.claude/scripts/reset-pipeline-state.sh "Mode not set"
```

### Symptom: State file shows wrong active_agent

**Cause**: SubagentStop hook may have failed or agent name was incorrect.

**Solution**:
```bash
# View what's recorded
jq '{active_agent, active_agents, history: .history[-3:]}' \
   ~/.claude/state/tasks/_default/pipeline-state.json

# Clear active agent and reset if needed
jq '.active_agent = null | .active_agents = []' \
   ~/.claude/state/tasks/_default/pipeline-state.json > /tmp/state.json
mv /tmp/state.json ~/.claude/state/tasks/_default/pipeline-state.json
```

---

## 3. Hook Issues

### Symptom: Hooks not firing

**Diagnosis**:
```bash
# Check if hooks are configured
jq '.hooks' ~/.claude/settings.json

# Manually test a hook
~/.claude/scripts/pipeline-gate.sh init
echo $?  # Should be 0

# Test with verbose output
bash -x ~/.claude/scripts/pipeline-gate.sh init 2>&1
```

**Common Causes**:
1. settings.json not deployed (run `chezmoi apply`)
2. Script permissions wrong (need execute)
3. Script path incorrect

**Fix**:
```bash
# Redeploy configuration
chezmoi apply

# Check permissions
ls -la ~/.claude/scripts/*.sh

# Fix if needed
chmod +x ~/.claude/scripts/*.sh
```

### Symptom: Hook blocks legitimate operation

**Diagnosis**:
```bash
# Check what hook says
echo '{"subagent_type": "context-gatherer"}' | \
  ~/.claude/scripts/check-subagent-allowed.sh
```

**If It's a False Positive**:
```bash
# Reset state
~/.claude/scripts/reset-pipeline-state.sh "False positive block"

# Continue with operation
```

### Symptom: "jq: command not found" in hook errors

**Cause**: jq not installed or not in PATH.

**Solution**:
```bash
# Install jq
# Arch/Manjaro:
sudo pacman -S jq

# Ubuntu/Debian:
sudo apt install jq

# macOS:
brew install jq

# NixOS:
nix-env -iA nixpkgs.jq
```

---

## 4. State File Issues

### Symptom: State file missing

**Cause**: First run or state directory deleted.

**Solution**:
```bash
# The system auto-creates it, but you can force:
~/.claude/scripts/pipeline-gate.sh init

# Or create directory structure
mkdir -p ~/.claude/state/tasks/_default
```

### Symptom: State file corrupted / invalid JSON

**Diagnosis**:
```bash
# Try to parse it
jq . ~/.claude/state/tasks/_default/pipeline-state.json

# If it fails, view raw
cat ~/.claude/state/tasks/_default/pipeline-state.json
```

**Solution**:
```bash
# Reset to fresh state
~/.claude/scripts/reset-pipeline-state.sh "Corrupted state"

# Or manually create valid state
cat > ~/.claude/state/tasks/_default/pipeline-state.json << 'EOF'
{
  "version": "1.0",
  "state": "IDLE",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "pipeline_mode": null,
  "active_agent": null,
  "active_agents": [],
  "context": {},
  "history": []
}
EOF
```

### Symptom: Permission denied on state file

**Cause**: File owned by different user or wrong permissions.

**Solution**:
```bash
# Check ownership
ls -la ~/.claude/state/

# Fix if needed
sudo chown -R $USER:$USER ~/.claude/state/
chmod 644 ~/.claude/state/tasks/_default/pipeline-state.json
chmod 755 ~/.claude/state/tasks/ ~/.claude/state/tasks/_default/
```

---

## 5. Context Cache Issues

### Symptom: Context not being cached

**Diagnosis**:
```bash
# Check cache status
~/.claude/scripts/context-cache.sh info

# Check cache directory exists
ls -la ~/.claude/memory/
```

**Solution**:
```bash
# Create cache directory
mkdir -p ~/.claude/memory/contexts

# Test caching manually
echo "test context" | ~/.claude/scripts/context-cache.sh store .
~/.claude/scripts/context-cache.sh check .
```

### Symptom: Cache returning stale context

**Cause**: Codebase changed but fingerprint matches.

**Solution**:
```bash
# Force fresh fingerprint
~/.claude/scripts/context-cache.sh fingerprint .

# Clean old entries
~/.claude/scripts/context-cache.sh clean 0
```

---

## 6. Task Namespace Issues

### Symptom: Wrong namespace active

**Diagnosis**:
```bash
# Check current namespace
echo $CLAUDE_TASK_NAMESPACE

# List available namespaces
source ~/.claude/scripts/namespace-utils.sh
list_namespaces
```

**Solution**:
```bash
# Switch to correct namespace
export CLAUDE_TASK_NAMESPACE='correct-name'

# Or return to default
unset CLAUDE_TASK_NAMESPACE
```

### Symptom: Namespace state file missing

**Diagnosis**:
```bash
# Check if namespace directory exists
ls -la ~/.claude/state/tasks/
```

**Solution**:
```bash
# Recreate namespace
source ~/.claude/scripts/namespace-utils.sh
ensure_namespace_dir "namespace-name"
```

---

## 7. chezmoi Deployment Issues

### Symptom: Changes not appearing after chezmoi apply

**Diagnosis**:
```bash
# Check what chezmoi would change
chezmoi diff

# Check status
chezmoi status
```

**Solution**:
```bash
# Force apply
chezmoi apply --force

# If templates failing, check data
chezmoi data
```

### Symptom: Files deployed with wrong permissions

**Diagnosis**:
```bash
ls -la ~/.claude/scripts/*.sh
```

**Solution**:
```bash
# Add executable attribute in chezmoi
# In source file, use: executable_scriptname.sh
# Or fix manually and re-add:
chmod +x ~/.claude/scripts/*.sh
chezmoi re-add ~/.claude/scripts/*.sh
```

---

## 8. Performance Issues

### Symptom: Hooks adding noticeable latency

**Diagnosis**:
```bash
# Time a hook
time ~/.claude/scripts/check-subagent-allowed.sh <<< '{"subagent_type":"test"}'
```

**Expected**: <100ms per hook

**If Slow**:
1. Check disk I/O (state file operations)
2. Check jq version (older versions slower)
3. Reduce history size in state file

**Solution**:
```bash
# Trim history if very large
jq '.history = .history[-100:]' ~/.claude/state/tasks/_default/pipeline-state.json \
   > /tmp/state.json
mv /tmp/state.json ~/.claude/state/tasks/_default/pipeline-state.json
```

### Symptom: Journal file growing too large

**Solution**:
```bash
# Rotate journal
mv ~/.claude/state/pipeline-journal.log \
   ~/.claude/state/pipeline-journal.log.old
touch ~/.claude/state/pipeline-journal.log

# Or truncate
tail -1000 ~/.claude/state/pipeline-journal.log > /tmp/journal
mv /tmp/journal ~/.claude/state/pipeline-journal.log
```

---

## 9. Debug Techniques

### Enable Verbose Hook Output

```bash
# Add to hook scripts temporarily:
set -x  # At top of script
PS4='+ ${BASH_SOURCE}:${LINENO}: '  # Better trace output
```

### View Real-Time Journal

```bash
# Watch journal in real-time
tail -f ~/.claude/state/pipeline-journal.log
```

### Trace State Changes

```bash
# Before operation
jq . ~/.claude/state/tasks/_default/pipeline-state.json > /tmp/before.json

# Do operation...

# After operation
jq . ~/.claude/state/tasks/_default/pipeline-state.json > /tmp/after.json

# Compare
diff /tmp/before.json /tmp/after.json
```

### Test Agent Approval Logic

```bash
# Test various agents
for agent in context-gatherer context-refiner bash-architect Explore; do
  echo "Testing $agent:"
  echo "{\"subagent_type\": \"$agent\"}" | \
    ~/.claude/scripts/check-subagent-allowed.sh 2>/dev/null
  echo "Exit code: $?"
  echo "---"
done
```

---

## 10. Emergency Recovery

### Complete Reset

```bash
# Nuclear option: Reset everything
rm -rf ~/.claude/state/
rm -rf ~/.claude/memory/
chezmoi apply

# Reinitialize
~/.claude/scripts/pipeline-gate.sh init
```

### Restore from Backup

```bash
# If backup exists
cp ~/.claude/state/tasks/_default/pipeline-state.json.backup \
   ~/.claude/state/tasks/_default/pipeline-state.json
```

### Bypass Pipeline (Not Recommended)

If absolutely necessary to bypass the pipeline:
1. Manually edit state to EXECUTING
2. Run your agent
3. Reset when done

```bash
# DANGER: Only use in emergencies
jq '.state = "EXECUTING"' ~/.claude/state/tasks/_default/pipeline-state.json \
   > /tmp/state.json
mv /tmp/state.json ~/.claude/state/tasks/_default/pipeline-state.json

# Do what you need...

# Reset when done
~/.claude/scripts/reset-pipeline-state.sh "Bypassed for emergency"
```

---

## Getting Help

### Collect Diagnostic Information

Before asking for help, gather:

```bash
# System info
echo "=== System ==="
uname -a
bash --version | head -1
jq --version

# State info
echo "=== Pipeline State ==="
jq . ~/.claude/state/tasks/_default/pipeline-state.json 2>/dev/null || echo "No state file"

# Recent journal
echo "=== Recent Journal ==="
tail -50 ~/.claude/state/pipeline-journal.log 2>/dev/null || echo "No journal"

# Hook test
echo "=== Hook Test ==="
echo '{"subagent_type": "context-gatherer"}' | \
  ~/.claude/scripts/check-subagent-allowed.sh 2>&1

# Configuration
echo "=== Hooks Configured ==="
jq '.hooks | keys' ~/.claude/settings.json 2>/dev/null || echo "No settings"
```

### Common Questions

**Q: Can I disable the pipeline temporarily?**
A: Remove hooks from settings.json, but you lose enforcement benefits.

**Q: How do I add a new agent to allowed list?**
A: Edit check-subagent-allowed.sh and update the regex patterns.

**Q: Why is context-gatherer mandatory?**
A: It ensures agents have full codebase understanding before making changes.

---

*Last updated: November 2025*
