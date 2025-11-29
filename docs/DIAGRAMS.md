# CCCC Architecture Diagrams

Visual representations of the cccc agent pipeline system.

---

## 1. Complete FSM State Diagram

```mermaid
stateDiagram-v2
    direction TB

    [*] --> IDLE: SessionStart Hook

    state IDLE {
        note right of IDLE
            Allowed: task-classifier, context-gatherer
            Blocked: All other agents
        end note
    }

    IDLE --> CLASSIFIED: task-classifier completes
    IDLE --> GATHERING: context-gatherer approved<br/>(immediate transition)

    state CLASSIFIED {
        note right of CLASSIFIED
            Routes based on pipeline_mode:
            - TRIVIAL: execution agents
            - MODERATE/COMPLEX: context-gatherer
        end note
    }

    CLASSIFIED --> GATHERING: context-gatherer approved<br/>(MODERATE/COMPLEX/EXPLORATORY)
    CLASSIFIED --> EXECUTING: execution agent<br/>(TRIVIAL only)

    state GATHERING {
        note right of GATHERING
            Parallel sub-gatherers run here:
            - architecture-gatherer
            - dependency-gatherer
            - pattern-gatherer
            - history-gatherer
        end note
    }

    GATHERING --> REFINING: context-refiner approved<br/>(COMPLEX/EXPLORATORY)
    GATHERING --> EXECUTING: execution agent<br/>(MODERATE only)

    state REFINING {
        note right of REFINING
            Context distillation phase
            Allowed: strategic-orchestrator
        end note
    }

    REFINING --> ORCHESTRATING_ACTIVE: strategic-orchestrator approved<br/>(immediate transition)

    state ORCHESTRATING_ACTIVE {
        note right of ORCHESTRATING_ACTIVE
            Orchestrator running
            May deploy specialists
        end note
    }

    ORCHESTRATING_ACTIVE --> EXECUTING: strategic-orchestrator completes

    state EXECUTING {
        note right of EXECUTING
            Specialist agents run:
            bash-*, nix-*, c-*, python-*
            Stays in EXECUTING
        end note
    }

    EXECUTING --> EXECUTING: specialist agents loop

    EXECUTING --> COMPLETE: manual completion

    COMPLETE --> IDLE: reset
```

---

## 2. Hook Execution Flow

```mermaid
sequenceDiagram
    autonumber
    participant User
    participant ClaudeCode as Claude Code
    participant SessionHook as SessionStart Hook
    participant PromptHook as UserPromptSubmit Hook
    participant TaskHook as PreToolUse Hook
    participant StopHook as SubagentStop Hook
    participant State as State File
    participant Agent as Subagent

    User->>ClaudeCode: Start session
    ClaudeCode->>SessionHook: pipeline-gate.sh init
    SessionHook->>State: Create IDLE state
    SessionHook-->>ClaudeCode: Success

    User->>ClaudeCode: "Implement feature X"
    ClaudeCode->>PromptHook: pipeline-gate.sh check-prompt
    PromptHook->>State: Read current state
    State-->>PromptHook: state = IDLE
    PromptHook-->>ClaudeCode: Inject workflow instructions

    ClaudeCode->>TaskHook: check-subagent-allowed.sh<br/>{subagent_type: "context-gatherer"}
    TaskHook->>State: Check if allowed in IDLE
    TaskHook->>State: Transition IDLE → GATHERING
    TaskHook-->>ClaudeCode: {"decision": "approve"}

    ClaudeCode->>Agent: Spawn context-gatherer
    Agent-->>ClaudeCode: Complete with context

    ClaudeCode->>StopHook: update-pipeline-state.sh
    StopHook->>State: Read active_agent
    StopHook->>State: Store gathered context
    StopHook-->>ClaudeCode: Success

    Note over ClaudeCode,State: Pipeline continues through refiner → orchestrator → specialists
```

---

## 3. Parallel Context Gathering

```mermaid
flowchart TB
    subgraph Main["Main Claude"]
        START[User Request]
        CG[context-gatherer<br/>Sonnet model]
        SYNTH[Synthesize Results]
    end

    subgraph Parallel["Parallel Sub-Gatherers (Haiku)"]
        direction LR
        AG[architecture-gatherer<br/>Structure & modules]
        DG[dependency-gatherer<br/>External & internal deps]
        PG[pattern-gatherer<br/>Code conventions]
        HG[history-gatherer<br/>Git evolution]
    end

    subgraph State["State Management"]
        SF[(pipeline-state.json)]
        JF[(journal.log)]
    end

    START --> CG
    CG -->|Spawns 4 in parallel| AG & DG & PG & HG
    AG & DG & PG & HG -->|Results| SYNTH
    SYNTH --> CR[context-refiner]

    CG -.->|Tracks active_agents| SF
    AG & DG & PG & HG -.->|PARALLEL_STOP events| JF
```

---

## 4. Agent Hierarchy

```mermaid
flowchart TB
    subgraph Orchestration["Pipeline Orchestration"]
        TC[task-classifier<br/>Haiku - Quick assessment]
        CG[context-gatherer<br/>Sonnet - Context collection]
        CR[context-refiner<br/>Sonnet - Intelligence distillation]
        SO[strategic-orchestrator<br/>Opus - Master planning]
    end

    subgraph SubGatherers["Sub-Gatherers (Parallel)"]
        AG[architecture-gatherer]
        DG[dependency-gatherer]
        PG[pattern-gatherer]
        HG[history-gatherer]
    end

    subgraph BashAgents["Bash Specialists"]
        BA[bash-architect]
        BT[bash-tester]
        BSE[bash-style-enforcer]
        BSR[bash-security-reviewer]
        BO[bash-optimizer]
        BEH[bash-error-handler]
        BD[bash-debugger]
    end

    subgraph NixAgents["Nix Specialists"]
        NA[nix-architect]
        NMW[nix-module-writer]
        NPB[nix-package-builder]
        NR[nix-reviewer]
        ND[nix-debugger]
    end

    subgraph CAgents["C Security Specialists"]
        CSA[c-security-architect]
        CSC[c-security-coder]
        CMA[c-memory-safety-auditor]
        CPA[c-privilege-auditor]
        CRA[c-race-condition-auditor]
        CSR[c-security-reviewer]
        CST[c-security-tester]
    end

    subgraph PythonAgents["Python Specialists"]
        PA[python-architect]
        PSR[python-security-reviewer]
        PML[python-ml-specialist]
        PTW[python-test-writer]
        PQE[python-quality-enforcer]
    end

    TC -->|Classifies| CG
    CG -->|Orchestrates| SubGatherers
    CG --> CR
    CR --> SO
    SO -->|Deploys| BashAgents & NixAgents & CAgents & PythonAgents
```

---

## 5. State File Structure

```mermaid
classDiagram
    class PipelineState {
        +String version
        +String state
        +String timestamp
        +String session_id
        +String pipeline_mode
        +String active_agent
        +Array~String~ active_agents
        +Context context
        +Array~HistoryEntry~ history
    }

    class Context {
        +String gathered
        +String refined
        +String orchestration
        +String classification
    }

    class HistoryEntry {
        +String agent
        +String timestamp
        +String state_before
        +String state_after
        +String trigger
        +String pipeline_mode
        +String reason
    }

    PipelineState --> Context
    PipelineState --> HistoryEntry

    note for PipelineState "Location: ~/.claude/state/pipeline-state.json"
```

---

## 6. Script Interaction Map

```mermaid
flowchart LR
    subgraph Hooks["Claude Code Hooks"]
        H1[SessionStart]
        H2[UserPromptSubmit]
        H3[PreToolUse]
        H4[SubagentStop]
    end

    subgraph Scripts["Pipeline Scripts"]
        PG[pipeline-gate.sh]
        CSA[check-subagent-allowed.sh]
        UPS[update-pipeline-state.sh]
        RPS[reset-pipeline-state.sh]
        CC[context-cache.sh]
    end

    subgraph Storage["Data Storage"]
        SF[(pipeline-state.json)]
        JF[(pipeline-journal.log)]
        MEM[(memory/)]
    end

    H1 -->|init| PG
    H2 -->|check-prompt| PG
    H3 -->|Task tool| CSA
    H4 --> UPS

    PG -->|read/write| SF
    CSA -->|read/write| SF
    CSA -->|append| JF
    UPS -->|read/write| SF
    UPS -->|append| JF
    UPS -->|store| CC
    RPS -->|write| SF
    RPS -->|append| JF
    CC -->|read/write| MEM

    PG -.->|calls| CC
```

---

## 7. Adaptive Routing Decision Tree

```mermaid
flowchart TB
    START[User Request]
    TC{task-classifier}

    START --> TC

    TC -->|TRIVIAL| TRIVIAL_PATH
    TC -->|MODERATE| MODERATE_PATH
    TC -->|COMPLEX| COMPLEX_PATH
    TC -->|EXPLORATORY| EXPLORATORY_PATH

    subgraph TRIVIAL_PATH["TRIVIAL Path"]
        T1[Skip all gathering]
        T2[Direct to execution agents]
        T1 --> T2
    end

    subgraph MODERATE_PATH["MODERATE Path"]
        M1[context-gatherer]
        M2[Skip refiner/orchestrator]
        M3[Direct to execution agents]
        M1 --> M2 --> M3
    end

    subgraph COMPLEX_PATH["COMPLEX Path"]
        C1[context-gatherer]
        C2[context-refiner]
        C3[strategic-orchestrator]
        C4[Specialist agents]
        C1 --> C2 --> C3 --> C4
    end

    subgraph EXPLORATORY_PATH["EXPLORATORY Path"]
        E1[context-gatherer]
        E2[context-refiner]
        E3[strategic-orchestrator]
        E4[Research specialists]
        E1 --> E2 --> E3 --> E4
    end
```

---

## 8. Error Handling Flow

```mermaid
flowchart TB
    subgraph Validation["Input Validation"]
        V1{jq installed?}
        V2{State file exists?}
        V3{Valid JSON?}
        V4{Agent name present?}
    end

    subgraph Recovery["Error Recovery"]
        R1[Log error]
        R2[Journal write]
        R3[Fail-safe: allow continuation]
        R4[Auto-reset if stale]
    end

    subgraph Success["Success Path"]
        S1[Process normally]
        S2[Transition state]
        S3[Return result]
    end

    START[Hook invoked] --> V1
    V1 -->|No| R1 --> R2 --> FATAL[Exit 1]
    V1 -->|Yes| V2
    V2 -->|No| CREATE[Create IDLE state] --> S1
    V2 -->|Yes| V3
    V3 -->|No| R1 --> R3
    V3 -->|Yes| STALE{State stale?}
    STALE -->|Yes > 10min| R4 --> V4
    STALE -->|No| V4
    V4 -->|No| PARALLEL{In parallel state?}
    PARALLEL -->|Yes| R3
    PARALLEL -->|No| R1 --> R2 --> R3
    V4 -->|Yes| S1 --> S2 --> S3
```

---

## 9. Context Cache Architecture

```mermaid
flowchart TB
    subgraph CacheOps["Cache Operations"]
        FP[fingerprint]
        CHK[check]
        GET[get]
        STORE[store]
        CLEAN[clean]
    end

    subgraph Storage["~/.claude/memory/"]
        IDX[(index.json)]
        CTX[(contexts/)]
    end

    subgraph Fingerprint["Fingerprint Generation"]
        GIT{Git available?}
        GITLS[git ls-files]
        FIND[find command]
        STAT[stat mtimes]
        HASH[SHA256 hash]
    end

    FP --> GIT
    GIT -->|Yes| GITLS --> STAT --> HASH
    GIT -->|No| FIND --> STAT --> HASH

    CHK --> IDX
    GET --> IDX --> CTX
    STORE --> IDX
    STORE --> CTX
    CLEAN --> IDX
    CLEAN --> CTX

    HASH -.->|Cache key| IDX
```

---

## 10. Deployment Architecture

```mermaid
flowchart TB
    subgraph Source["Source Repository"]
        REPO[~/gh/cccc]
        CHEZMOI[chezmoi source files]
        REPO --> CHEZMOI
    end

    subgraph Chezmoi["Chezmoi Processing"]
        APPLY[chezmoi apply]
        TEMPLATE[Template expansion]
        PERM[Permission setting]
    end

    subgraph Target["Deployed Configuration"]
        CLAUDE[~/.claude/]
        SCRIPTS[scripts/]
        AGENTS[agents/]
        SETTINGS[settings.json]
        CLAUDEMD[CLAUDE.md]
    end

    subgraph Runtime["Runtime State"]
        STATE[state/]
        MEMORY[memory/]
        JOURNAL[journal.log]
    end

    CHEZMOI --> APPLY
    APPLY --> TEMPLATE --> PERM
    PERM --> CLAUDE
    CLAUDE --> SCRIPTS & AGENTS & SETTINGS & CLAUDEMD
    CLAUDE -.->|Auto-created| STATE & MEMORY
    STATE --> JOURNAL
```

---

## Legend

| Symbol | Meaning |
|--------|---------|
| `[Rectangle]` | Process/Action |
| `{Diamond}` | Decision |
| `[(Database)]` | Data storage |
| `-->` | Flow direction |
| `-.->` | Indirect/optional flow |
| `&` | Parallel operations |

---

*Generated for the cccc project - Claude Code Agent Pipeline*
