extension Synchronizer.Blocking {

    public func wait(condition index: Int = 0) {
        precondition(index >= 0 && index < N, "Condition index \(index) out of bounds (0..<\(N))")
        conditions[index].wait(mutex: mutex)
    }

    public func wait(condition index: Int = 0, timeout: Duration) -> Bool {
        precondition(index >= 0 && index < N, "Condition index \(index) out of bounds (0..<\(N))")
        return conditions[index].wait(mutex: mutex, timeout: timeout)
    }

    public func signal(condition index: Int = 0) {
        precondition(index >= 0 && index < N, "Condition index \(index) out of bounds (0..<\(N))")
        conditions[index].signal()
    }

    public func broadcast(condition index: Int = 0) {
        precondition(index >= 0 && index < N, "Condition index \(index) out of bounds (0..<\(N))")
        conditions[index].broadcast()
    }

    public func broadcastAll() {
        for i in 0..<N {
            conditions[i].broadcast()
        }
    }
}

extension Synchronizer.Blocking {

    public func waiters(condition: Int = 0) -> Int {
        precondition(
            condition >= 0 && condition < N,
            "Condition index \(condition) out of bounds (0..<\(N))"
        )
        return waiterCounts[condition]
    }

    public func waitTracked(condition index: Int = 0) {
        precondition(index >= 0 && index < N, "Condition index \(index) out of bounds (0..<\(N))")
        waiterCounts[index] += 1
        defer {
            waiterCounts[index] -= 1
            assert(waiterCounts[index] >= 0, "Waiter count underflow")
        }
        conditions[index].wait(mutex: mutex)
    }

    public func waitTracked(condition index: Int = 0, timeout: Duration) -> Bool {
        precondition(index >= 0 && index < N, "Condition index \(index) out of bounds (0..<\(N))")
        waiterCounts[index] += 1
        defer {
            waiterCounts[index] -= 1
            assert(waiterCounts[index] >= 0, "Waiter count underflow")
        }
        return conditions[index].wait(mutex: mutex, timeout: timeout)
    }

    public func signalIfWaiters(condition index: Int = 0) -> Bool {
        precondition(index >= 0 && index < N, "Condition index \(index) out of bounds (0..<\(N))")
        guard waiterCounts[index] > 0 else { return false }
        conditions[index].signal()
        return true
    }

    public func broadcastIfWaiters(condition index: Int = 0) -> Bool {
        precondition(index >= 0 && index < N, "Condition index \(index) out of bounds (0..<\(N))")
        guard waiterCounts[index] > 0 else { return false }
        conditions[index].broadcast()
        return true
    }
}
