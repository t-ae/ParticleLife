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

extension SIMD2<Float> {
    init(_ point: CGPoint) {
        self.init(x: Float(point.x), y: Float(point.y))
    }
    
    // wrap x/y into [-max, max) range.
    func wrapped(max: Int) -> SIMD2<Float> {
        let maxf = Float(max)
        return .init(
            x: x - floor((x+maxf) / (2*maxf)) * (2*maxf),
            y: y - floor((y+maxf) / (2*maxf)) * (2*maxf)
        )
    }
    
    static func random(in range: Range<Float>) -> Self {
        var g = SystemRandomNumberGenerator()
        return .random(in: range, using: &g)
    }
    
    static func random<T: RandomNumberGenerator>(in range: Range<Float>, using generator: inout T) -> Self {
        .random(in: range, range, using: &generator)
    }
    
    static func random(in xrange: Range<Float>, _ yrange: Range<Float>) -> Self {
        var g = SystemRandomNumberGenerator()
        return .random(in: xrange, yrange, using: &g)
    }
    
    static func random<T: RandomNumberGenerator>(in xrange: Range<Float>, _ yrange: Range<Float>, using generator: inout T) -> Self {
        .init(.random(in: xrange, using: &generator), .random(in: yrange, using: &generator))
    }
    
    var hasNaN: Bool { x.isNaN || y.isNaN }
    var hasInfinite: Bool { x.isInfinite || y.isInfinite }
}

