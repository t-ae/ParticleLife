extension Optional {
    func orThrow(_ message: String) throws -> Wrapped {
        guard let wrapped = self else {
            throw MessageError(message)
        }
        return wrapped
    }
}

