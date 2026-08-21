public struct Synchronize: Synchronizer.`Protocol`, @unchecked Sendable {
    @usableFromInline
    internal let _runSynced: (() -> Void) -> Void

    @inlinable
    public init(_ source: sending some Synchronizer.`Protocol`) {
        self._runSynced = { body in
            source.synchronize { body() }
        }
    }

    @inlinable
    public init(consuming source: consuming sending some Synchronizer.`Protocol` & ~Copyable) {
        self._runSynced = { body in
            source.synchronize { body() }
        }
    }
}

extension Synchronize {
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
