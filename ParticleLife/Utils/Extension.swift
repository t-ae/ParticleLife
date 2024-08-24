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

extension NSTextField {
    static func label(title: String, textColor: NSColor) -> NSTextField {
        let label = NSTextField(string: title)
        label.textColor = textColor
        label.alignment = .center
        label.isBezeled = false
        label.isEditable = false
        label.isSelectable = false
        label.drawsBackground = false
        label.backgroundColor = .clear
        return label
    }
}

extension NSRect {
    var center: CGPoint {
        get {
            .init(x: origin.x + size.width/2, y: origin.y + size.height/2)
        }
        set {
            origin = .init(x: newValue.x - size.width/2 , y: newValue.y - size.height/2)
        }
    }
}

extension SIMD2<Float> {
    // wrap x/y into [-max, max) range.
    func wrapped(max: Int) -> SIMD2<Float> {
        let maxf = Float(max)
        return .init(
            x: x - floor((x+maxf) / (2*maxf)) * (2*maxf),
            y: y - floor((y+maxf) / (2*maxf)) * (2*maxf)
        )
    }
    
    init(_ point: CGPoint) {
        self.init(x: Float(point.x), y: Float(point.y))
    }
}

