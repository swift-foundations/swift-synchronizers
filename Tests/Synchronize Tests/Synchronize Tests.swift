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

import Synchronization
import Synchronizers_Test_Support
import Testing

// MARK: - Test Suites for Synchronize Witness

@Suite("Synchronize Witness")
struct SynchronizeWitnessTests {}

// MARK: - Type Erasure Tests

extension SynchronizeWitnessTests {
    @Suite("Type Erasure")
    struct TypeErasure {}
}

extension SynchronizeWitnessTests.TypeErasure {
    @Test
    func `wraps Synchronizer.Blocking via default init`() {
        let source = Synchronizer.Blocking<1>()
        let witness = Synchronize(source)
        let result = witness.synchronize { 42 }
        #expect(result == 42)
    }

    @Test
    func `wraps Synchronizer.Blocking<2> via default init`() {
        let source = Synchronizer.Blocking<2>()
        let witness = Synchronize(source)
        let result: Int = witness.synchronize { 7 }
        #expect(result == 7)
    }

    @Test
    func `witness copy shares captured source`() {
        let source = Synchronizer.Blocking<1>()
        let witness = Synchronize(source)
        let copy = witness  // struct copy — closures share the captured reference

        let a = witness.synchronize { 1 }
        let b = copy.synchronize { 2 }
        #expect(a == 1)
        #expect(b == 2)
    }

    @Test
    func `witness preserves return value`() {
        let source = Synchronizer.Blocking<1>()
        let witness = Synchronize(source)
        struct Pair: Equatable { let a: Int; let b: Int }
        let result = witness.synchronize { Pair(a: 7, b: 13) }
        #expect(result == Pair(a: 7, b: 13))
    }

    @Test
    func `witness rethrows typed error`() {
        enum WitnessError: Swift.Error, Equatable { case faulted }

        let source = Synchronizer.Blocking<1>()
        let witness = Synchronize(source)
        do {
            let _ = try witness.synchronize { () throws(WitnessError) -> Int in
                throw .faulted
            }
            Issue.record("expected throw")
        } catch {
            #expect(error == .faulted)
        }
    }

    @Test
    func `witness is Sendable`() {
        let source = Synchronizer.Blocking<1>()
        let witness = Synchronize(source)

        func acceptsSendable<S: Sendable>(_ s: S) -> S { s }
        let _ = acceptsSendable(witness)
    }
}
