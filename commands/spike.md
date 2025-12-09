---
description: Quick prototype mode - bypass full pipeline for exploration
---

# Spike Mode: $ARGUMENTS

You are in **SPIKE MODE** - rapid prototyping to test feasibility.

## What is a Spike?

A spike is a time-boxed exploration to answer a specific question:
- "Can we do X?"
- "How would Y work?"
- "What's the complexity of Z?"

**Spikes produce learning, not production code.**

## Spike Rules

### This IS a spike if:
- [ ] You're testing if something is possible
- [ ] You're exploring an unfamiliar API/library
- [ ] You need a quick proof of concept
- [ ] The code will be thrown away after learning

### This is NOT a spike if:
- [ ] You're implementing a feature for real
- [ ] The code needs to be production quality
- [ ] You're "spiking" to avoid the review process

## Spike Protocol

### 1. Define the Question
What specific question does this spike answer?

**Question**: $ARGUMENTS

### 2. Time Box
Spikes should be SHORT. Set a limit:
- Quick spike: 15-30 minutes
- Medium spike: 1-2 hours
- Large spike: Half day max

**If you can't answer the question in this time, the spike itself is the answer: "This is more complex than expected."**

### 3. Create Spike Branch (Optional but Recommended)

```bash
git checkout -b spike/descriptive-name
```

### 4. Write Throwaway Code

In spike mode, you MAY:
- Skip comprehensive error handling
- Use hardcoded values
- Skip tests
- Write messy code
- Copy-paste examples

You still MUST NOT:
- Introduce security vulnerabilities
- Break existing functionality
- Commit to main

### 5. Document Findings

After the spike, document what you learned:

```markdown
## Spike Results: [Question]

### Question
[What were you trying to learn?]

### Answer
[What did you discover?]

### Feasibility
- [ ] Yes, this is doable
- [ ] Yes, but with caveats: [caveats]
- [ ] No, because: [reasons]
- [ ] Need more investigation: [what's unclear]

### Complexity Assessment
- **Estimated effort**: [Low/Medium/High]
- **Key challenges**: [What's hard about this]
- **Dependencies**: [What would we need]

### Code Location
[Where is the spike code, or "deleted"]

### Next Steps
If proceeding to real implementation:
1. [Step 1]
2. [Step 2]

### Artifacts Worth Keeping
[Any code snippets or patterns worth preserving]
```

### 6. Clean Up

After documenting:

```bash
# Option A: Delete spike branch
git checkout main
git branch -D spike/descriptive-name

# Option B: Keep for reference (if valuable)
git push origin spike/descriptive-name
```

## Pipeline Bypass Notice

**IMPORTANT**: Spike mode is an INTENTIONAL bypass of the normal pipeline.

The hookify rules may still trigger reminders. When they do, acknowledge that:
- You are in spike mode
- This is exploratory, not production code
- You will follow the full pipeline if this becomes a real feature

## Anti-Patterns

- ❌ Using spike mode to avoid reviews
- ❌ Shipping spike code to production
- ❌ Spikes that grow into features without proper process
- ❌ Endless spikes (time-box them!)

## Output

At the end of this spike, provide:
1. The answer to the question
2. Feasibility assessment
3. Complexity estimate
4. Next steps recommendation

**Explore fast. Learn quick. Document findings. Throw away the code.**
