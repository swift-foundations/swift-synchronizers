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

extension Synchronizer.Blocking where N == 2 {
    /// Accessor for broadcasting all conditions.
    public struct Broadcast: Sendable {
        @usableFromInline
        internal let sync: Synchronizer.Blocking<2>

        @inlinable
        init(sync: Synchronizer.Blocking<2>) {
            self.sync = sync
        }

        /// Broadcast all conditions.
        public func all() {
            sync.broadcastAll()
        }
    }

    /// Broadcast all conditions accessor.
    public var broadcast: Broadcast {
        Broadcast(sync: self)
    }
}
