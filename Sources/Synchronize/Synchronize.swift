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

/// Type-erased synchronizer witness.
///
/// Holds any conforming `Synchronizer.Protocol` value behind a uniform
/// interface. Use this when you need a value of "a synchronizer" without
/// committing to a specific concrete type — for instance, when storing heterogeneous
/// synchronizers in a collection or when expressing API boundaries that
/// should accept any synchronizer regardless of variant.
///
/// ## Witness shape — existential-free closure-tunneling
///
/// The canonical protocol method `synchronize<R, E>(_:)` has method-level
/// generics that cannot be stored as a polymorphic closure. The witness
/// avoids existentials by:
///
/// 1. Storing a NON-generic `(() -> Void) -> Void` tunnel closure that runs
///    a Void-returning body under the captured source's `synchronize(_:)`.
/// 2. Tunneling the typed return value and typed error through
///    `Result<R, E>` (Swift 6 typed-throws) captured via inout from inside
///    the Void-returning closure.
///
/// This is structurally analogous to the codec pattern's closure-form witness,
/// adapted for protocols whose canonical method has method-level genericity.
/// See `agent-witness-attachable-pattern.md` for the pattern doc.
public struct Synchronize: Synchronizer.`Protocol`, @unchecked Sendable {
    @usableFromInline
    internal let _runSynced: (() -> Void) -> Void

    /// Wraps any Copyable + Escapable conformer (the common case — classes).
    ///
    /// The source is captured by closure-reference. For class conformers
    /// such as `Synchronizer.Blocking<N>`, this gives correct shared-state
    /// semantics: copies of this witness all drive the same underlying lock.
    @inlinable
    public init(_ source: sending some Synchronizer.`Protocol`) {
        self._runSynced = { body in
            source.synchronize { body() }
        }
    }

    /// Wraps any noncopyable conformer by consuming it into the witness.
    ///
    /// For noncopyable struct conformers, such as a hypothetical
    /// `Synchronizer.Spin<N>` holding an atomic flag), `consuming` moves
    /// the source into the closure's capture context.
    @inlinable
    public init(consuming source: consuming sending some Synchronizer.`Protocol` & ~Copyable) {
        self._runSynced = { body in
            source.synchronize { body() }
        }
    }

    @inlinable
    public borrowing func synchronize<R, E: Swift.Error>(
        _ body: () throws(E) -> R
    ) throws(E) -> R {
        var captured: Result<R, E>!
        _runSynced {
            captured = Result { () throws(E) -> R in try body() }
        }
        return try captured.get()
    }
}
