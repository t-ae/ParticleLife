import Cocoa

extension Optional {
    func orThrow(_ message: String) throws -> Wrapped {
        guard let wrapped = self else {
            throw MessageError(message)
        }
        return wrapped
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
