extension AsyncStream {
    public func send(_ data: Data, completion: @escaping ((Void) throws -> Void) -> Void = { _ in }) {
        send(data, timingOut: .never, completion: completion)
    }

    public func flush(completion: @escaping ((Void) throws -> Void) -> Void = { _ in }) {
        flush(timingOut: .never, completion: completion)
    }
}
