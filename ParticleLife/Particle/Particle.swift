import Foundation

extension Particle {
    init(color: Color, position: SIMD2<Float>, velocity: SIMD2<Float> = .zero) {
        self.init(color: color.rawValue, position: position, velocity: velocity)
    }
    
    var hasNaN: Bool {
        position.hasNaN || velocity.hasNaN
    }
    
    var hasInfinite: Bool {
        position.hasInfinite || velocity.hasInfinite
    }
}
