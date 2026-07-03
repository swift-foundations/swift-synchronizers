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

/// A type with a canonical synchronizer.
///
/// Conformers expose a synchronizer that mediates access to their shared
/// state. The canonical synchronizer is the one the type wants its CONSUMERS
/// to use when coordinating multi-thread access — distinct from any internal
/// synchronization the type uses for its own invariants.
///
/// ## Use cases
///
/// Types whose API surface mixes mutable shared state with concurrent access
/// requirements — caches, lazy-init holders, observable stores. The attachable
/// protocol enables generic dispatch:
///
/// ```swift
/// extension SharedCache: Synchronizable {
///     public var synchronizer: Synchronizer.Blocking<1> { ... }
/// }
///
/// func atomicGetOrPut<S: Synchronizable>(
///     _ subject: borrowing S,
///     ...
/// ) -> Value { ... }
/// ```
public protocol Synchronizable: ~Copyable & ~Escapable {
    associatedtype
        Synchronizer: Synchronizer_Namespace.Synchronizer.`Protocol` & ~Copyable & ~Escapable

    var synchronizer: Self.Synchronizer {
        @_lifetime(borrow self)
        borrowing get
    }
}
