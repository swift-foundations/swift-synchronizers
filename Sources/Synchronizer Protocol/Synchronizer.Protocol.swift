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
    /// The canonical synchronizer contract.
    ///
    /// Conformers expose `synchronize(_:)` — "execute work while holding
    /// exclusive access". This is the universal operation every synchronization
    /// primitive provides, regardless of its backing mechanism (kernel
    /// mutex+condvar, atomic spin, suspending continuation, etc.).
    ///
    /// Variant-specific operations (e.g., `wait(condition:)` / `signal(condition:)`
    /// for condvar-based variants; `tryAcquire()` for spin-based variants)
    /// live on the concrete variant, not on this protocol. The protocol's
    /// purpose is the universal verb; per-variant primitives are accessed
    /// by committing to the concrete type.
    ///
    /// ## Suppressed conformances
    ///
    /// `~Copyable & ~Escapable` is permissive: conformers MAY be classes
    /// (Copyable via reference, Escapable), noncopyable structs, or
    /// nonescapable types. The protocol does not REQUIRE Copyable or
    /// Escapable; it does not FORBID them either. Conformers choose the
    /// shape appropriate to their storage requirements.
    public protocol `Protocol`: ~Copyable & ~Escapable {
        /// Executes the body while holding exclusive access.
        ///
        /// The synchronizer's exclusion guarantee is in force for the duration
        /// of the body call. Implementations MUST ensure that no other caller
        /// executing `synchronize(_:)` on the same instance can be in its body
        /// concurrently.
        ///
        /// - Parameter body: The work to perform under exclusion.
        /// - Returns: The body's return value.
        /// - Throws: Whatever the body throws (re-thrown with typed-throws
        ///   propagation via Swift 6's `Result.init(catching:)`).
        borrowing func synchronize<R, E: Swift.Error>(
            _ body: () throws(E) -> R
        ) throws(E) -> R
    }
}
