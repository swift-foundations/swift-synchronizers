extension Synchronizer {

    public protocol `Protocol`: ~Copyable & ~Escapable {

        borrowing func synchronize<R, E: Swift.Error>(
            _ body: () throws(E) -> R
        ) throws(E) -> R
    }
}
