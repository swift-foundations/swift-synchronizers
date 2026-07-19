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

// MARK: - Convenience for Dual Sync (N == 2)

extension Synchronizer.Blocking where N == 2 {
    /// Accessor for worker condition (index 0).
    public var worker: Channel {
        Channel(sync: self, index: 0)
    }

    /// Accessor for deadline condition (index 1).
    public var deadline: Channel {
        Channel(sync: self, index: 1)
    }

    /// Accessor for a specific condition variable.
    public struct Channel: Sendable {
        @usableFromInline
        internal let sync: Synchronizer.Blocking<2>

        @usableFromInline
        internal let index: Int

        @inlinable
        package init(sync: Synchronizer.Blocking<2>, index: Int) {
            self.sync = sync
            self.index = index
        }
    }
}

extension Synchronizer.Blocking.Channel {
    /// Wait on this condition.
    ///
    /// Must be called while holding the lock.
    /// The lock is released while waiting and reacquired before returning.
    public func wait() {
        sync.wait(condition: index)
    }

    /// Wait on this condition with Duration timeout.
    ///
    /// Must be called while holding the lock.
    /// The lock is released while waiting and reacquired before returning.
    public func wait(timeout: Duration) -> Bool {
        sync.wait(condition: index, timeout: timeout)
    }

    /// Signal one waiter on this condition.
    ///
    /// Lock-optional: unlike `signalIfWaiters`/`broadcastIfWaiters`, this operation
    /// touches no mutex-protected tracked state (it does not read or write
    /// `waiterCounts`), so it may be called with or without holding the lock.
    public func signal() {
        sync.signal(condition: index)
    }

    /// Broadcast to all waiters on this condition.
    ///
    /// Lock-optional: unlike `signalIfWaiters`/`broadcastIfWaiters`, this operation
    /// touches no mutex-protected tracked state (it does not read or write
    /// `waiterCounts`), so it may be called with or without holding the lock.
    public func broadcast() {
        sync.broadcast(condition: index)
    }

    // MARK: - Waiter Tracking

    /// Current waiter count for this condition.
    ///
    /// Must be called while holding the lock.
    ///
    /// Only valid if all waits use `waitTracked`.
    public var waiters: Int {
        sync.waiters(condition: index)
    }

    /// Wait on this condition while tracking waiter count.
    ///
    /// Must be called while holding the lock.
    /// The lock is released while waiting and reacquired before returning.
    /// Waiter count is incremented before waiting and decremented after.
    public func waitTracked() {
        sync.waitTracked(condition: index)
    }

    /// Wait on this condition with timeout while tracking waiter count.
    ///
    /// Must be called while holding the lock.
    /// The lock is released while waiting and reacquired before returning.
    /// Waiter count is incremented before waiting and decremented after.
    public func waitTracked(timeout: Duration) -> Bool {
        sync.waitTracked(condition: index, timeout: timeout)
    }

    /// Signal one waiter if any exist on this condition.
    ///
    /// Must be called while holding the lock.
    /// Skips the signal syscall if no waiters exist.
    @discardableResult
    public func signalIfWaiters() -> Bool {
        sync.signalIfWaiters(condition: index)
    }

    /// Broadcast if any waiters exist on this condition.
    ///
    /// Must be called while holding the lock.
    /// Skips the broadcast syscall if no waiters exist.
    @discardableResult
    public func broadcastIfWaiters() -> Bool {
        sync.broadcastIfWaiters(condition: index)
    }
}
