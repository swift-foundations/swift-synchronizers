public protocol Synchronizable: ~Copyable & ~Escapable {
    associatedtype
        Synchronizer: Synchronizer_Namespace.Synchronizer.`Protocol` & ~Copyable & ~Escapable

    var synchronizer: Self.Synchronizer {
        @_lifetime(borrow self)
        borrowing get
    }
}
