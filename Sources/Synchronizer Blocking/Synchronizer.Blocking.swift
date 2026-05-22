// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-synchronizers open source project
//
// Copyright (c) 2024-2026 Coen ten Thije Boonkkamp and the swift-synchronizers project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

extension Synchronizer {
    /// Thread-blocking synchronizer: mutex + N condition variables.
    ///
    /// Parameterized by condition count for compile-time safety:
    /// - `Synchronizer.Blocking<1>` — single condition (executor job queue)
    /// - `Synchronizer.Blocking<2>` — dual conditions (worker/deadline separation)
    ///
    /// Uses `InlineArray` for zero-allocation fixed-size storage.
    ///
    /// ## Safety Invariant
    ///
    /// This type is `Sendable` by virtue of internal synchronization: every
    /// access to the mutex-protected condition variables and waiter counts
    /// is serialized by `Kernel.Thread.Mutex`. The caller MUST route every
    /// access to protected state through `lock()` / `unlock()` /
    /// `synchronize(_:)`, and MUST NOT read or mutate `conditions` or
    /// `waiterCounts` outside the lock. The `@unsafe` annotation makes this
    /// assertion explicit at the conformance site — callers inherit the
    /// obligation to respect the lock.
    ///
    /// ## Intended Use
    ///
    /// Coordinating producers and consumers under a single mutex with one
    /// or two associated condition variables. Typical consumers:
    /// - Serial executor job queues (`Synchronizer.Blocking<1>`).
    /// - Worker / deadline separation in the stealing executor
    ///   (`Synchronizer.Blocking<2>`).
    /// - Any small, bounded producer/consumer signalling where atomic-only
    ///   primitives are insufficient and a condition variable wait is needed.
    ///
    /// Cross-isolation transfer is sound because every accessor serializes
    /// through the mutex — moving the reference between threads does not
    /// introduce a race that the mutex does not already mediate.
    ///
    /// ## Non-Goals
    ///
    /// - Not a lock-free primitive. Every operation pays for mutex acquisition.
    ///   For high-contention hot paths where atomic primitives suffice, use
    ///   those instead.
    /// - Not a general "thread-safe object." This conformance does not make
    ///   arbitrary concurrent access safe. Access to the protected condition
    ///   variables and waiter counts MUST go through the documented
    ///   `lock()` / `synchronize(_:)` API; touching the stored state outside
    ///   the lock is undefined behaviour.
    /// - Not a replacement for a proper actor. When the coordination is
    ///   naturally expressible via Swift concurrency, prefer an actor;
    ///   `Synchronizer.Blocking` exists for the thread-level layer underneath.
    ///
    /// ## Usage
    /// ```swift
    /// let sync = Synchronizer.Blocking<2>()
    ///
    /// sync.lock()
    /// defer { sync.unlock() }
    ///
    /// // Wait on condition 0 (worker)
    /// sync.wait(condition: 0)
    ///
    /// // Signal condition 1 (deadline)
    /// sync.signal(condition: 1)
    /// ```
    public final class Blocking<let N: Int>: @unsafe @unchecked Sendable {
        @usableFromInline
        internal let mutex = Kernel.Thread.Mutex()

        @usableFromInline
        internal var conditions: InlineArray<N, Kernel.Thread.Condition>

        @usableFromInline
        internal var waiterCounts: InlineArray<N, Int>

        /// Creates a blocking synchronizer with N condition variables.
        ///
        /// - Precondition: N must be at least 1.
        public init() {
            precondition(N >= 1, "Synchronizer.Blocking requires at least 1 condition variable")
            self.conditions = InlineArray { _ in Kernel.Thread.Condition() }
            self.waiterCounts = InlineArray { _ in 0 }
        }
    }
}

// MARK: - Synchronizer.Protocol conformance

extension Synchronizer.Blocking: Synchronizer.`Protocol` {
    /// Canonical synchronizer operation: lock, run body, unlock.
    @inlinable
    public borrowing func synchronize<R, E: Swift.Error>(
        _ body: () throws(E) -> R
    ) throws(E) -> R {
        mutex.lock()
        defer { mutex.unlock() }
        return try body()
    }
}

// MARK: - Lock Operations

extension Synchronizer.Blocking {
    /// Acquire the lock.
    @inlinable
    public func lock() {
        mutex.lock()
    }

    /// Release the lock.
    @inlinable
    public func unlock() {
        mutex.unlock()
    }
}
