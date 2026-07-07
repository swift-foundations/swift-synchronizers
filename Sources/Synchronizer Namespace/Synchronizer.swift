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

/// Namespace for synchronization primitives.
///
/// Houses the canonical agent protocol (`Synchronizer.Protocol`) and concrete
/// variants discriminated by wait mechanism. Today the only variant is
/// `Synchronizer.Blocking<N>` (thread-blocking via kernel mutex + condvars).
/// The namespace is shaped to grow additional variants as their consumers
/// materialize, such as `Synchronizer.Async<N>` (task-suspending) or
/// `Synchronizer.Spin<N>` (atomic-flag spin-wait).
public enum Synchronizer {}
