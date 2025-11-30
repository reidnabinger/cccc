# Python Agent Team - Complete Guide

A specialized team of 6 agents for developing type-safe, secure Python systems with focus on ML pipelines, multiprocessing, and strict quality enforcement.

## Quick Start

**New Python subsystem workflow:**
```
1. "Use python-architect to design the video processing pipeline"
2. "Use python-async-specialist to implement the multiprocessing architecture"
3. "Use python-quality-enforcer to validate type annotations and style"
4. "Use python-security-reviewer to audit for vulnerabilities"
5. "Use python-test-writer to create comprehensive tests"
```

**ML-specific workflow:**
```
1. "Use python-architect to design the detection inference pipeline"
2. "Use python-ml-specialist to implement PyTorch/ONNX inference"
3. "Use python-quality-enforcer to ensure mypy --strict passes"
4. "Use python-test-writer to write pytest tests with fixtures"
```

---

## Agent Team Overview

### Tier 1: Architecture (Before Coding)

#### python-architect
**When**: Before implementing new Python subsystems
**Purpose**: Design type hierarchies, Protocol classes, process architecture
**Model**: Opus (complex architectural decisions)
**Tools**: Task, mcp__sequential-thinking__sequentialthinking

**Example Usage:**
```
"Use python-architect to design a producer-consumer pipeline for
camera capture and ML detection with typed Queue messages"
```

**What It Produces:**
- Process topology diagrams
- Protocol class definitions
- TypedDict message schemas
- Lifecycle specifications
- Error handling strategies
- Implementation guidance for downstream agents

**Key Patterns:**
- Protocol classes (PEP 544 structural subtyping)
- Generic types for containers
- TypedDict for queue messages
- Multiprocessing with poison pills for shutdown

---

### Tier 2: Implementation Specialists

#### python-async-specialist
**When**: Implementing multiprocessing architectures
**Purpose**: Producer/consumer patterns, Queue/Pipe communication, graceful shutdown
**Focus**: `multiprocessing` module (NOT asyncio for CPU-bound work)

**Example Usage:**
```
"Use python-async-specialist to implement the camera capture process
following the architecture spec from python-architect"
```

**What It Does:**
- Implements Process-based parallelism
- Sets up Queue and Pipe communication
- Handles graceful shutdown with poison pills
- Manages shared state with proper synchronization
- Prevents deadlocks and race conditions

**Key Patterns:**
```python
# DEV-NOTE: Always use poison pills for graceful shutdown
class ShutdownMessage(TypedDict):
    msg_type: Literal['shutdown']
    reason: str

def consumer_main(queue: Queue[QueueMessage], shutdown_event: Event) -> None:
    while not shutdown_event.is_set():
        try:
            msg = queue.get(timeout=1.0)
            if msg['msg_type'] == 'shutdown':
                break
            process_message(msg)
        except Empty:
            continue
```

#### python-ml-specialist
**When**: Implementing ML inference pipelines
**Purpose**: PyTorch, ONNX, TensorRT optimization, OpenCV video processing
**Focus**: GPU memory management, inference optimization, batching

**Example Usage:**
```
"Use python-ml-specialist to implement ONNX inference with TensorRT
for the object detection model"
```

**What It Does:**
- Optimizes model loading and inference
- Manages CUDA memory efficiently
- Implements batching strategies
- Handles OpenCV frame preprocessing
- Integrates with multiprocessing queues

**Key Patterns:**
```python
# DEV-NOTE: Pre-allocate tensors to avoid GPU memory fragmentation
class DetectorInference:
    def __init__(self, model_path: str, device: str = "cuda"):
        self.session = ort.InferenceSession(model_path)
        # Pre-allocate input buffer
        self._input_buffer = np.zeros((1, 3, 640, 640), dtype=np.float32)
```

---

### Tier 3: Quality Assurance

#### python-quality-enforcer
**When**: After implementation, before commit
**Purpose**: Enforce mypy --strict, black formatting, ruff linting
**Focus**: Type safety with disallow_untyped_defs=true

**Example Usage:**
```
"Use python-quality-enforcer to validate src/detection/ passes mypy --strict"
```

**What It Checks:**
- Full mypy --strict compliance
- Black formatting (no changes needed)
- Ruff linting rules
- Type annotation completeness
- Protocol implementation correctness

**What It Fixes:**
- Missing type annotations
- Type errors and mismatches
- Formatting violations
- Linting issues

#### python-security-reviewer
**When**: Before deployment, for security-sensitive code
**Purpose**: Security review for ML systems
**Focus**: RTSP credentials, model loading, network code, IPC security

**Example Usage:**
```
"Use python-security-reviewer to audit the camera connection module
for credential handling vulnerabilities"
```

**What It Checks:**
- RTSP credential exposure
- **CRITICAL**: Unsafe model loading (torch.load without weights_only=True)
- **CRITICAL**: Deserialization vulnerabilities in model files
- Network code security
- IPC security (shared memory, pipes)
- Input validation for ML inputs
- Denial of service vectors

**Security Note on Model Loading:**
```python
# ❌ DANGEROUS: Can execute arbitrary code from model file
model = torch.load("model.pt")

# ✅ SAFE: Only loads weights, not arbitrary code
model = torch.load("model.pt", weights_only=True)

# ✅ PREFERRED: Use safe formats like safetensors or ONNX
model = ort.InferenceSession("model.onnx")
```

#### python-test-writer
**When**: After implementation
**Purpose**: Write pytest tests with fixtures and mocking
**Focus**: ML-specific testing, multiprocessing tests

**Example Usage:**
```
"Use python-test-writer to create tests for the detection pipeline
including mocked model inference"
```

**What It Produces:**
- pytest test files with proper structure
- Fixtures for complex setup/teardown
- Parametrized tests for edge cases
- Mocked external dependencies
- Multiprocessing test patterns

---

## Complete Workflows

### Workflow 1: New ML Subsystem

```
Step 1: Architecture Design
───────────────────────────
User: "Use python-architect to design a real-time object detection
       pipeline with camera input and WebSocket output"

Agent produces:
- Process topology (Camera → Detector → Aggregator → WebSocket)
- Protocol classes for each component
- Queue message TypedDicts
- Shutdown coordination strategy


Step 2: Core Implementation
───────────────────────────
User: "Use python-async-specialist to implement the process management
       and queue communication following the architecture"

Agent implements:
- ProcessManager class
- Queue setup and message routing
- Shutdown coordination with poison pills


Step 3: ML Implementation
─────────────────────────
User: "Use python-ml-specialist to implement the detection inference
       with ONNX runtime and TensorRT optimization"

Agent implements:
- Model loading and optimization
- Frame preprocessing with OpenCV
- Batched inference
- Result post-processing


Step 4: Quality Enforcement
───────────────────────────
User: "Use python-quality-enforcer to ensure mypy --strict passes"

Agent:
- Fixes type annotation issues
- Ensures all functions are typed
- Validates Protocol implementations


Step 5: Security Review
───────────────────────
User: "Use python-security-reviewer to audit for vulnerabilities"

Agent checks:
- Credential handling
- Model loading safety
- Network security
- IPC security


Step 6: Testing
───────────────
User: "Use python-test-writer to create comprehensive tests"

Agent creates:
- Unit tests for each component
- Integration tests for pipeline
- Mocked inference tests
- Multiprocessing tests
```

---

### Workflow 2: Adding New Process Type

```
Step 1: Design
──────────────
User: "Use python-architect to design a new alert aggregator process
       that collects detections and triggers notifications"

Agent designs:
- Process interface (Protocol class)
- Input/output queue message types
- State machine for alert conditions


Step 2: Implement
─────────────────
User: "Use python-async-specialist to implement the aggregator"


Step 3: Validate
────────────────
User: "Use python-quality-enforcer to validate types"


Step 4: Test
────────────
User: "Use python-test-writer to write tests for alert logic"
```

---

### Workflow 3: Security-Critical Changes

```
Step 1: Review First
────────────────────
User: "Use python-security-reviewer to audit the credential management
       module before I make changes"

Agent identifies current vulnerabilities


Step 2: Implement Fixes
───────────────────────
Fix identified issues following security recommendations


Step 3: Re-Review
─────────────────
User: "Use python-security-reviewer to verify the fixes"
```

---

## Best Practices

### 1. Always Start with Architecture

**DON'T:**
```
"Write a camera capture module with multiprocessing"
```

**DO:**
```
"Use python-architect to design the camera capture subsystem"
(then implement following the design)
```

### 2. Use Protocols Over Inheritance

**DON'T:**
```python
class BaseProcessor:
    def process(self, frame: Frame) -> Result:
        raise NotImplementedError
```

**DO:**
```python
class Processor(Protocol):
    def process(self, frame: Frame) -> Result: ...
```

### 3. Type Your Queue Messages

**DON'T:**
```python
queue.put({'type': 'frame', 'data': frame_bytes})
```

**DO:**
```python
class FrameMessage(TypedDict):
    msg_type: Literal['frame']
    timestamp: float
    data: bytes
    shape: tuple[int, int, int]

queue.put(FrameMessage(msg_type='frame', timestamp=time.time(), ...))
```

### 4. Quality Enforcement is Mandatory

For all Python code:
```
"Use python-quality-enforcer to validate"
```

Must pass:
- `mypy --strict`
- `black --check`
- `ruff check`

---

## Agent Capabilities Summary

| Agent | Can Read | Can Edit | Model | Speed | When to Use |
|-------|----------|----------|-------|-------|-------------|
| python-architect | ✓ | ✗ | opus | Slow | Before implementation |
| python-async-specialist | ✓ | ✓ | sonnet | Medium | Multiprocessing work |
| python-ml-specialist | ✓ | ✓ | sonnet | Medium | ML/inference code |
| python-quality-enforcer | ✓ | ✓ | sonnet | Fast | After every change |
| python-security-reviewer | ✓ | ✗ | sonnet | Medium | Security-sensitive code |
| python-test-writer | ✓ | ✓ | sonnet | Medium | After implementation |

---

## Common Scenarios

### Scenario: "I need to add a new ML model"

1. Use python-architect to design the integration
2. Use python-ml-specialist to implement inference
3. Use python-quality-enforcer to validate types
4. Use python-security-reviewer to audit model loading
5. Use python-test-writer to write inference tests

### Scenario: "Adding a new process to the pipeline"

1. Use python-architect to design the process
2. Use python-async-specialist to implement
3. Use python-quality-enforcer to validate
4. Use python-test-writer to test

### Scenario: "Performance optimization needed"

1. Use python-ml-specialist for ML-specific optimization
2. Use python-async-specialist for process-level optimization
3. Use python-test-writer to add performance regression tests

### Scenario: "Security audit requested"

1. Use python-security-reviewer for comprehensive audit
2. Fix identified issues
3. Re-audit to verify

---

## Type System Reference

### Protocol Classes (Structural Subtyping)

```python
from typing import Protocol, TypeVar, Generic

# DEV-NOTE: Protocols enable duck typing with static type checking
class Processor(Protocol):
    def process(self, frame: Frame) -> list[Detection]: ...
    def shutdown(self) -> None: ...

# Any class with matching methods satisfies the Protocol
# No explicit inheritance needed
```

### Generic Types

```python
T = TypeVar('T', bound='BaseMessage')

class MessageQueue(Generic[T]):
    def put(self, item: T) -> None: ...
    def get(self, timeout: float | None = None) -> T: ...
```

### TypedDict for Messages

```python
from typing import TypedDict, Literal

class FrameMessage(TypedDict):
    msg_type: Literal['frame']
    timestamp: float
    camera_id: str
    frame_data: bytes

class ShutdownMessage(TypedDict):
    msg_type: Literal['shutdown']
    reason: str

# Union for queue typing
QueueMessage = FrameMessage | ShutdownMessage
```

---

## Multiprocessing Patterns

### Poison Pill Shutdown

```python
# DEV-NOTE: Never rely on process.terminate() for normal operation
def producer_main(queue: Queue[QueueMessage], shutdown_event: Event) -> None:
    while not shutdown_event.is_set():
        frame = capture_frame()
        queue.put(FrameMessage(...))

    # Send poison pill to signal consumers
    queue.put(ShutdownMessage(msg_type='shutdown', reason='producer_exit'))
```

### Timeout-Based Gets

```python
# DEV-NOTE: Always use timeout to allow shutdown checks
def consumer_main(queue: Queue[QueueMessage], shutdown_event: Event) -> None:
    while not shutdown_event.is_set():
        try:
            msg = queue.get(timeout=1.0)
        except Empty:
            continue

        if msg['msg_type'] == 'shutdown':
            break

        process_message(msg)
```

---

## Anti-Patterns to Avoid

### 1. Untyped Queue Communication

```python
# ❌ BAD: No type safety
queue.put({'data': frame, 'ts': time.time()})

# ✅ GOOD: TypedDict with explicit schema
queue.put(FrameMessage(msg_type='frame', timestamp=time.time(), ...))
```

### 2. Blocking Without Timeout

```python
# ❌ BAD: Blocks forever if producer dies
data = queue.get()

# ✅ GOOD: Timeout allows shutdown checks
try:
    data = queue.get(timeout=1.0)
except Empty:
    continue
```

### 3. Using asyncio for CPU-Bound Work

```python
# ❌ BAD: asyncio doesn't help CPU-bound tasks
async def detect(frame):
    return model.infer(frame)  # Still blocks event loop

# ✅ GOOD: Use multiprocessing for CPU-bound work
def detector_process(queue: Queue) -> None:
    while True:
        frame = queue.get()
        result = model.infer(frame)
```

### 4. Deep Inheritance Hierarchies

```python
# ❌ BAD: Fragile base class problem
class BaseProcessor:
    def process(self): ...

class FrameProcessor(BaseProcessor):
    def process(self): ...

class DetectionProcessor(FrameProcessor):
    def process(self): ...

# ✅ GOOD: Flat Protocols with composition
class Processor(Protocol):
    def process(self) -> ProcessResult: ...
```

---

## Integration with Pipeline

These agents are deployed by **strategic-orchestrator** when:
- Creating new Python subsystems
- Implementing ML inference code
- Adding multiprocessing components
- Validating type safety

The typical invocation chain:
```
strategic-orchestrator
    → python-architect (design)
    → python-async-specialist (multiprocessing)
    → python-ml-specialist (ML code)
    → python-quality-enforcer (validation)
    → python-security-reviewer (audit)
    → python-test-writer (tests)
```

---

## Resources

- [PEP 544 - Protocols](https://peps.python.org/pep-0544/)
- [mypy Documentation](https://mypy.readthedocs.io/)
- [Python multiprocessing](https://docs.python.org/3/library/multiprocessing.html)
- [pytest Documentation](https://docs.pytest.org/)
- [ONNX Runtime](https://onnxruntime.ai/)

---

*Generated for cccc - Claude Code Agent Pipeline*
