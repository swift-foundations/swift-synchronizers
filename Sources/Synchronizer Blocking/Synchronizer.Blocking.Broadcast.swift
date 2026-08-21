extension Synchronizer.Blocking where N == 2 {

    public struct Broadcast: Sendable {
        @usableFromInline
        internal let sync: Synchronizer.Blocking<2>

        @inlinable
        package init(sync: Synchronizer.Blocking<2>) {
            self.sync = sync
        }
    }

    public var broadcast: Broadcast {
        Broadcast(sync: self)
    }
}

extension Synchronizer.Blocking.Broadcast {

    public func all() {
        sync.broadcastAll()
    }
}
