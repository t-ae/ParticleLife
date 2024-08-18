import Foundation

extension Particle {
    init(color: Color, position: SIMD2<Float>, velocity: SIMD2<Float> = .zero) {
        self.init(color: color.rawValue, position: position, velocity: velocity, attractorCount: 0)
    }
    
    static func random() -> Particle {
        var g = SystemRandomNumberGenerator()
        return .random(using: &g)
    }
    
    static func random<T: RandomNumberGenerator>(using generator: inout T) -> Particle {
        .init(
            color: Color.allCases.randomElement(using: &generator)!,
            position: .random(in: 0..<1, using: &generator),
            velocity: .zero
        )
    }
    
    var hasNaN: Bool {
        position.hasNaN || velocity.hasNaN
    }
    
    var hasInfinite: Bool {
        position.hasInfinite || velocity.hasInfinite
    }
}

extension SIMD2<Float> {
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
