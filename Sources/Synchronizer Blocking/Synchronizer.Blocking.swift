extension Synchronizer {

    public final class Blocking<let N: Int>: @unsafe @unchecked Sendable {
        @usableFromInline
        internal let mutex = Kernel.Thread.Mutex()

        @usableFromInline
        internal var conditions: InlineArray<N, Kernel.Thread.Condition>

        @usableFromInline
        internal var waiterCounts: InlineArray<N, Int>

        public init() {
            precondition(N >= 1, "Synchronizer.Blocking requires at least 1 condition variable")
            self.conditions = InlineArray { _ in Kernel.Thread.Condition() }
            self.waiterCounts = InlineArray { _ in 0 }
        }
    }
}

extension Synchronizer.Blocking: Synchronizer.`Protocol` {

    @inlinable
    public borrowing func synchronize<R, E: Swift.Error>(
        _ body: () throws(E) -> R
    ) throws(E) -> R {
        mutex.lock()
        defer { mutex.unlock() }
        return try body()
    }
}

extension Synchronizer.Blocking {

    @inlinable
    public func lock() {
        mutex.lock()
    }

    @inlinable
    public func unlock() {
        mutex.unlock()
    }
}
