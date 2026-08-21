extension Synchronizer.Blocking where N == 2 {

    public var worker: Channel {
        Channel(sync: self, index: 0)
    }

    public var deadline: Channel {
        Channel(sync: self, index: 1)
    }

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

    public func wait() {
        sync.wait(condition: index)
    }

    public func wait(timeout: Duration) -> Bool {
        sync.wait(condition: index, timeout: timeout)
    }

    public func signal() {
        sync.signal(condition: index)
    }

    public func broadcast() {
        sync.broadcast(condition: index)
    }

    public var waiters: Int {
        sync.waiters(condition: index)
    }

    public func waitTracked() {
        sync.waitTracked(condition: index)
    }

    public func waitTracked(timeout: Duration) -> Bool {
        sync.waitTracked(condition: index, timeout: timeout)
    }

    @discardableResult
    public func signalIfWaiters() -> Bool {
        sync.signalIfWaiters(condition: index)
    }

    @discardableResult
    public func broadcastIfWaiters() -> Bool {
        sync.broadcastIfWaiters(condition: index)
    }
}
