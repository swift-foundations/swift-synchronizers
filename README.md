# swift-synchronizers

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Synchronization primitives for Swift. Bundles of mutual exclusion and signaling — variants discriminated by wait mechanism. Layer 3 (Foundations) of the Swift Institute five-layer architecture.

The package implements the agent-witness-attachable triple: `Synchronizer` namespace + `Synchronizer.Protocol` (canonical `synchronize(_:)`) + `Synchronize` type-erased witness + `Synchronizable` attachable.

---

## Products

| Product | Contents |
|---------|----------|
| `Synchronizer Namespace` | `enum Synchronizer {}` — root namespace |
| `Synchronizer Protocol` | `Synchronizer.Protocol` — canonical `synchronize(_:)` contract |
| `Synchronize` | `Synchronize` — top-level type-erased witness |
| `Synchronizable` | `Synchronizable` — attachable for types with a canonical synchronizer |
| `Synchronizer Blocking` | `Synchronizer.Blocking<N>` — mutex + N kernel condvars (thread-blocking) |
| `Synchronizers` | Umbrella re-exporting all of the above |
| `Synchronizers Test Support` | Test fixtures and shared imports |

---

## Installation

### Package.swift

```swift
.package(path: "../swift-synchronizers")
```

### Target dependency

Consumers should prefer narrow product imports over the umbrella unless they genuinely need the full surface.

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "Synchronizer Blocking", package: "swift-synchronizers"),
    ]
)
```

### Requirements

- Swift 6.3+
- macOS 26.0+ / iOS 26.0+ / tvOS 26.0+ / watchOS 26.0+
- Linux (Ubuntu 22.04+)
- Windows (Swift 6.3+)

---

## Quick Start

```swift
import Synchronizer_Blocking

let sync = Synchronizer.Blocking<1>()

let result = sync.synchronize {
    // critical section
    return 42
}
```

Direct lock + condvar control (when you need it beyond `synchronize`):

```swift
sync.lock()
defer { sync.unlock() }

sync.wait(condition: 0)
sync.signal(condition: 0)
```

Dual-channel coordination (worker / deadline separation):

```swift
let sync = Synchronizer.Blocking<2>()

sync.worker.waitTracked()
sync.deadline.signal()
```

---

## Scope

The package is **substrate-layer coordination primitives** — bundles of mutual exclusion and signaling, parameterized by wait mechanism. Each variant is a self-contained primitive that consumers either use directly or compose into higher-level patterns elsewhere.

| Concern | Belongs in |
|---|---|
| Specific async coordination patterns (semaphore, channel, stream) | swift-async-primitives |
| Thread-level dispatch (pool, actor, worker) | swift-threads |
| Thread-level coordination patterns (barrier, gate, semaphore as thread-blocking convenience) | swift-threads |
| Executor types (Cooperative, Polling) | swift-executors |
| Executor-specific wait primitives | swift-executors (may internally compose a Synchronizer) |
| Lock-free atomics | swift-atomic-primitives + Swift stdlib `Synchronization` module |
| The "mutex" itself (single lock, no condvars) | swift-kernel (`Kernel.Thread.Mutex`) + Swift stdlib `Mutex` |

**Future variants** (under the same namespace, as they materialize):

- `Synchronizer.Async<N>` — task-suspending wait via continuation queues
- `Synchronizer.Spin<N>` — atomic-flag spin-wait, no kernel involvement

---

## Architecture

```
swift-synchronizers       ← this package: substrate (mutex + N wait channels)
     |
swift-kernel              ← Kernel.Thread.Mutex / Kernel.Thread.Condition
     |
swift-kernel-primitives   ← raw syscall atoms
```

---

## License

Apache 2.0 — See [LICENSE](LICENSE.md) for details.
