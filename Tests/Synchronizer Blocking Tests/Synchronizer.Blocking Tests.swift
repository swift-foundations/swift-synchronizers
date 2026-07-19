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

#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#endif

// MARK: - Test Suites for Synchronizer.Blocking Waiter Tracking

@Suite
struct `Synchronizer.Blocking Tests` {}

// MARK: - Unit Tests

extension `Synchronizer.Blocking Tests` {
    @Suite("Unit")
    struct Unit {}
}

extension `Synchronizer.Blocking Tests`.Unit {
    @Test
    func `waiters starts at zero`() {
        let sync = Synchronizer.Blocking<1>()
        sync.lock()
        #expect(sync.waiters(condition: 0) == 0)
        sync.unlock()
    }

    @Test
    func `signalIfWaiters returns false when no waiters`() {
        let sync = Synchronizer.Blocking<1>()
        sync.lock()
        let result = sync.signalIfWaiters(condition: 0)
        sync.unlock()
        #expect(result == false)
    }

    @Test
    func `broadcastIfWaiters returns false when no waiters`() {
        let sync = Synchronizer.Blocking<1>()
        sync.lock()
        let result = sync.broadcastIfWaiters(condition: 0)
        sync.unlock()
        #expect(result == false)
    }

    @Test
    func `Dual Channel waiters starts at zero`() {
        let sync = Synchronizer.Blocking<2>()
        sync.lock()
        #expect(sync.worker.waiters == 0)
        #expect(sync.deadline.waiters == 0)
        sync.unlock()
    }

    @Test
    func `Dual Channel signalIfWaiters returns false when empty`() {
        let sync = Synchronizer.Blocking<2>()
        sync.lock()
        #expect(sync.worker.signalIfWaiters() == false)
        #expect(sync.deadline.signalIfWaiters() == false)
        sync.unlock()
    }

    @Test
    func `Dual Channel broadcastIfWaiters returns false when empty`() {
        let sync = Synchronizer.Blocking<2>()
        sync.lock()
        #expect(sync.worker.broadcastIfWaiters() == false)
        #expect(sync.deadline.broadcastIfWaiters() == false)
        sync.unlock()
    }
}

// MARK: - Integration Tests

extension `Synchronizer.Blocking Tests` {
    @Suite("Integration")
    struct Integration {}
}

/// Small sleep helper using nanosleep
private func smallSleep(milliseconds: UInt32) {
    #if canImport(Darwin)
        usleep(milliseconds * 1000)
    #elseif canImport(Glibc)
        usleep(milliseconds * 1000)
    #endif
}

extension `Synchronizer.Blocking Tests`.Integration {
    @Test
    func `waitTracked increments waiters`() throws {
        let sync = Synchronizer.Blocking<1>()
        let waiterReady = Atomic<Bool>(false)
        let shouldWake = Atomic<Bool>(false)

        let handle = try Kernel.Thread.spawn {
            sync.lock()
            waiterReady.store(true, ordering: .releasing)
            while !shouldWake.load(ordering: .acquiring) {
                sync.waitTracked(condition: 0)
            }
            sync.unlock()
        }

        while !waiterReady.load(ordering: .acquiring) {
            smallSleep(milliseconds: 1)
        }

        smallSleep(milliseconds: 20)

        sync.lock()
        let count = sync.waiters(condition: 0)
        shouldWake.store(true, ordering: .releasing)
        sync.broadcast(condition: 0)
        sync.unlock()

        handle.join()

        #expect(count == 1)
    }

    @Test
    func `waitTracked decrements waiters after wakeup`() throws {
        let sync = Synchronizer.Blocking<1>()
        let threadDone = Atomic<Bool>(false)

        let handle = try Kernel.Thread.spawn {
            sync.lock()
            _ = sync.waitTracked(condition: 0, timeout: .milliseconds(10))
            sync.unlock()
            threadDone.store(true, ordering: .releasing)
        }

        handle.join()

        sync.lock()
        let count = sync.waiters(condition: 0)
        sync.unlock()

        #expect(count == 0)
        #expect(threadDone.load(ordering: .acquiring) == true)
    }

    @Test
    func `signalIfWaiters returns true and wakes one waiter`() throws {
        let sync = Synchronizer.Blocking<1>()
        let waiterReady = Atomic<Bool>(false)
        let waiterWoken = Atomic<Bool>(false)

        let handle = try Kernel.Thread.spawn {
            sync.lock()
            waiterReady.store(true, ordering: .releasing)
            sync.waitTracked(condition: 0)
            waiterWoken.store(true, ordering: .releasing)
            sync.unlock()
        }

        while !waiterReady.load(ordering: .acquiring) {
            smallSleep(milliseconds: 1)
        }
        smallSleep(milliseconds: 20)

        sync.lock()
        let hadWaiters = sync.signalIfWaiters(condition: 0)
        sync.unlock()

        handle.join()

        #expect(hadWaiters == true)
        #expect(waiterWoken.load(ordering: .acquiring) == true)
    }

    @Test
    func `broadcastIfWaiters returns true and wakes all waiters`() throws {
        let sync = Synchronizer.Blocking<1>()
        let waitersReady = Atomic<Int>(0)
        let waitersWoken = Atomic<Int>(0)
        let numWaiters = 3

        let handle1 = try Kernel.Thread.spawn {
            sync.lock()
            waitersReady.wrappingAdd(1, ordering: .releasing)
            sync.waitTracked(condition: 0)
            waitersWoken.wrappingAdd(1, ordering: .releasing)
            sync.unlock()
        }
        let handle2 = try Kernel.Thread.spawn {
            sync.lock()
            waitersReady.wrappingAdd(1, ordering: .releasing)
            sync.waitTracked(condition: 0)
            waitersWoken.wrappingAdd(1, ordering: .releasing)
            sync.unlock()
        }
        let handle3 = try Kernel.Thread.spawn {
            sync.lock()
            waitersReady.wrappingAdd(1, ordering: .releasing)
            sync.waitTracked(condition: 0)
            waitersWoken.wrappingAdd(1, ordering: .releasing)
            sync.unlock()
        }

        while waitersReady.load(ordering: .acquiring) < numWaiters {
            smallSleep(milliseconds: 1)
        }
        smallSleep(milliseconds: 30)

        sync.lock()
        let count = sync.waiters(condition: 0)
        let hadWaiters = sync.broadcastIfWaiters(condition: 0)
        sync.unlock()

        handle1.join()
        handle2.join()
        handle3.join()

        #expect(count == numWaiters)
        #expect(hadWaiters == true)
        #expect(waitersWoken.load(ordering: .acquiring) == numWaiters)
    }

    @Test
    func `timeout waitTracked still decrements count`() throws {
        let sync = Synchronizer.Blocking<1>()
        let timedOut = Atomic<Bool>(false)

        let handle = try Kernel.Thread.spawn {
            sync.lock()
            let result = sync.waitTracked(condition: 0, timeout: .milliseconds(10))
            timedOut.store(!result, ordering: .releasing)
            sync.unlock()
        }

        handle.join()

        sync.lock()
        let count = sync.waiters(condition: 0)
        sync.unlock()

        #expect(count == 0)
        #expect(timedOut.load(ordering: .acquiring) == true)
    }

    @Test
    func `mixed wait and waitTracked - broadcast still wakes tracked waiters`() throws {
        let sync = Synchronizer.Blocking<1>()
        let trackedReady = Atomic<Bool>(false)
        let trackedWoken = Atomic<Bool>(false)

        let handle = try Kernel.Thread.spawn {
            sync.lock()
            trackedReady.store(true, ordering: .releasing)
            sync.waitTracked(condition: 0)
            trackedWoken.store(true, ordering: .releasing)
            sync.unlock()
        }

        while !trackedReady.load(ordering: .acquiring) {
            smallSleep(milliseconds: 1)
        }
        smallSleep(milliseconds: 20)

        sync.lock()
        sync.broadcast(condition: 0)
        sync.unlock()

        handle.join()

        #expect(trackedWoken.load(ordering: .acquiring) == true)
    }

    @Test
    func `Dual Channel waitTracked works`() throws {
        let sync = Synchronizer.Blocking<2>()
        let waiterReady = Atomic<Bool>(false)
        let waiterWoken = Atomic<Bool>(false)

        let handle = try Kernel.Thread.spawn {
            sync.lock()
            waiterReady.store(true, ordering: .releasing)
            sync.worker.waitTracked()
            waiterWoken.store(true, ordering: .releasing)
            sync.unlock()
        }

        while !waiterReady.load(ordering: .acquiring) {
            smallSleep(milliseconds: 1)
        }
        smallSleep(milliseconds: 20)

        sync.lock()
        let count = sync.worker.waiters
        let hadWaiters = sync.worker.broadcastIfWaiters()
        sync.unlock()

        handle.join()

        #expect(count == 1)
        #expect(hadWaiters == true)
        #expect(waiterWoken.load(ordering: .acquiring) == true)
    }

    // MARK: - Canonical synchronize(_:) tests

    @Test
    func `synchronize executes body under lock`() {
        let sync = Synchronizer.Blocking<1>()
        let result = sync.synchronize { 42 }
        #expect(result == 42)
    }

    @Test
    func `synchronize rethrows typed error`() {
        enum SyncTestError: Swift.Error, Equatable {
            case fault
        }

        let sync = Synchronizer.Blocking<1>()
        do throws(SyncTestError) {
            let _ = try sync.synchronize { () throws(SyncTestError) -> Int in
                throw .fault
            }
            Issue.record("expected throw")
        } catch {
            #expect(error == .fault)
        }
    }
}

// MARK: - Edge Case Tests

extension `Synchronizer.Blocking Tests` {
    @Suite
    struct `Edge Case` {}
}

// F-001 regression coverage: `signalIfWaiters`/`broadcastIfWaiters` read the
// mutex-protected `waiterCounts` array but historically omitted the "must be
// called while holding the lock" doc contract that every other accessor of
// that tracked state (`waiters`, `waitTracked`) states explicitly. Since the
// fix is a doc-comment addition with no runtime reflection surface, this is a
// doc-contract regression test: it reads the actual committed source text of
// `Synchronizer.Blocking.Wait.swift` at test time and asserts the lock
// precondition is documented on both functions. This genuinely fails before
// the doc fix lands (the phrase is absent) and passes after (the phrase is
// present) — a real, mechanically-checkable RED/GREEN, not a reconstruction.
extension `Synchronizer.Blocking Tests`.`Edge Case` {
    /// Reads a source file located relative to this test file's own directory.
    ///
    /// - Note: Explicitly qualified as `Swift.String` throughout — this module
    ///   also sees the ecosystem's `~Copyable` `String_Primitives.String`,
    ///   which shadows the bare `String` identifier and cannot express the
    ///   ordinary value semantics this file-reading helper needs.
    private static func readSiblingSource(_ relativePath: Swift.String, from testFile: Swift.String = #filePath) -> Swift.String {
        let testFileComponents = testFile.split(separator: "/", omittingEmptySubsequences: false)
        let testFileDirectory = testFileComponents.dropLast().joined(separator: "/")
        let fullPath = testFileDirectory + "/" + relativePath

        guard let file = unsafe fopen(fullPath, "r") else { return "" }
        defer { unsafe fclose(file) }

        var bytes: [UInt8] = []
        var buffer = [UInt8](repeating: 0, count: 4096)
        while true {
            let bytesRead = unsafe fread(&buffer, 1, buffer.count, file)
            guard bytesRead > 0 else { break }
            bytes.append(contentsOf: buffer[0..<bytesRead])
        }
        return Swift.String(decoding: bytes, as: Swift.UTF8.self)
    }

    /// Extracts the contiguous `///` doc-comment block immediately preceding
    /// the line declaring `func <name>` in `source`, lowercased for
    /// case-insensitive matching.
    private static func docComment(precedingFunc name: Swift.String, in source: Swift.String) -> Swift.String {
        let lines = source.split(separator: "\n", omittingEmptySubsequences: false)
        guard let declIndex = lines.firstIndex(where: { $0.contains("func \(name)") }) else {
            return ""
        }
        var docLines: [Substring] = []
        var i = declIndex - 1
        while i >= 0 {
            let trimmed = lines[i].drop(while: { $0 == " " || $0 == "\t" })
            guard trimmed.hasPrefix("///") else { break }
            docLines.append(trimmed)
            i -= 1
        }
        return docLines.reversed().joined(separator: "\n").lowercased()
    }

    @Test
    func `signalIfWaiters documents the lock precondition`() {
        let source = Self.readSiblingSource("../../Sources/Synchronizer Blocking/Synchronizer.Blocking.Wait.swift")
        #expect(!source.isEmpty, "expected to read Synchronizer.Blocking.Wait.swift source for doc-contract check")

        let doc = Self.docComment(precedingFunc: "signalIfWaiters", in: source)
        #expect(doc.contains("must be called while holding the lock"))
    }

    @Test
    func `broadcastIfWaiters documents the lock precondition`() {
        let source = Self.readSiblingSource("../../Sources/Synchronizer Blocking/Synchronizer.Blocking.Wait.swift")
        #expect(!source.isEmpty, "expected to read Synchronizer.Blocking.Wait.swift source for doc-contract check")

        let doc = Self.docComment(precedingFunc: "broadcastIfWaiters", in: source)
        #expect(doc.contains("must be called while holding the lock"))
    }
}

// F-001 rev-1 regression coverage: `Synchronizer.Blocking.Channel` (the
// ergonomic worker/deadline accessor for N == 2) re-exposes the entire F-001
// surface — `waiters`, `waitTracked` (x2), `signalIfWaiters`,
// `broadcastIfWaiters`, `wait` (x2) — one level up, and historically carried
// no lock doc contract anywhere on that surface: the same omission class as
// F-001 itself. Same doc-contract test shape as above, extended to the
// Channel source file. Members are located by declaration substring (not bare
// func name) because the surface includes a `var` (`waiters`) and overload
// pairs (`wait()`/`wait(timeout:)`).
extension `Synchronizer.Blocking Tests`.`Edge Case` {
    /// Extracts the contiguous `///` doc-comment block immediately preceding
    /// the first line containing `decl` in `source`, lowercased for
    /// case-insensitive matching. Attribute lines (`@discardableResult`,
    /// `@inlinable`, ...) between the doc block and the declaration are
    /// skipped.
    private static func docComment(precedingDecl decl: Swift.String, in source: Swift.String) -> Swift.String {
        let lines = source.split(separator: "\n", omittingEmptySubsequences: false)
        guard let declIndex = lines.firstIndex(where: { $0.contains(decl) }) else {
            return ""
        }
        var docLines: [Substring] = []
        var i = declIndex - 1
        while i >= 0 {
            let trimmed = lines[i].drop(while: { $0 == " " || $0 == "\t" })
            if trimmed.hasPrefix("///") {
                docLines.append(trimmed)
            } else if trimmed.hasPrefix("@") {
                // attribute between doc block and declaration; keep walking up
            } else {
                break
            }
            i -= 1
        }
        return docLines.reversed().joined(separator: "\n").lowercased()
    }

    @Test
    func `Channel lock-required members document the lock precondition`() {
        let source = Self.readSiblingSource("../../Sources/Synchronizer Blocking/Synchronizer.Blocking.Channel.swift")
        #expect(!source.isEmpty, "expected to read Synchronizer.Blocking.Channel.swift source for doc-contract check")

        let lockRequired: [Swift.String] = [
            "public func wait()",
            "public func wait(timeout",
            "public var waiters",
            "public func waitTracked()",
            "public func waitTracked(timeout",
            "public func signalIfWaiters",
            "public func broadcastIfWaiters",
        ]
        for decl in lockRequired {
            let doc = Self.docComment(precedingDecl: decl, in: source)
            #expect(
                doc.contains("must be called while holding the lock"),
                "`\(decl)` is missing the lock-requirement doc contract"
            )
        }
    }

    @Test
    func `Channel lock-optional members document the lock-optional note`() {
        let source = Self.readSiblingSource("../../Sources/Synchronizer Blocking/Synchronizer.Blocking.Channel.swift")
        #expect(!source.isEmpty, "expected to read Synchronizer.Blocking.Channel.swift source for doc-contract check")

        let lockOptional: [Swift.String] = [
            "public func signal()",
            "public func broadcast()",
        ]
        for decl in lockOptional {
            let doc = Self.docComment(precedingDecl: decl, in: source)
            #expect(
                doc.contains("lock-optional"),
                "`\(decl)` is missing the lock-optional doc note"
            )
        }
    }
}
