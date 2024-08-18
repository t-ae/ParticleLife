import Cocoa

extension Optional {
    func orThrow(_ message: String) throws -> Wrapped {
        guard let wrapped = self else {
            throw MessageError(message)
        }
        return wrapped
    }
}

extension Task<Never, Never> {
    static func sleep(microseconds: UInt64) async throws {
        try await Task.sleep(nanoseconds: 1000 * microseconds)
    }
    
    static func sleep(milliseconds: UInt64) async throws {
        try await Task.sleep(microseconds: 1000 * milliseconds)
    }
    
    static func sleep(seconds: UInt64) async throws {
        try await Task.sleep(milliseconds: 1000 * seconds)
    }
}

extension NSPopUpButton {
    func selectItem(by title: String) {
        guard let index = itemTitles.firstIndex(of: title) else {
            return
        }
        selectItem(at: index)
    }
}
