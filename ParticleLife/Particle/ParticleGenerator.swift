import Foundation

protocol ParticleGenerator {
    var colorCount: Int { get }
    var particleCount: Int { get }
    
    func generate(buffer: UnsafeMutableBufferPointer<Particle>)
}

final class UniformParticleGenerator: ParticleGenerator {
    var colorCount: Int
    var particleCount: Int
    var rng: RandomNumberGenerator
    
    init(colorCount: Int, particleCount: Int, rng: RandomNumberGenerator = SystemRandomNumberGenerator()) {
        self.colorCount = colorCount
        self.particleCount = particleCount
        self.rng = rng
    }
    
    func generate(buffer: UnsafeMutableBufferPointer<Particle>) {
        for i in 0..<particleCount {
            let color = Color(intValue: i % colorCount)!
            buffer[i] = Particle(color: color, position: .random(in: 0..<1, using: &rng))
        }
    }
}

final class PartitionParticleGenerator: ParticleGenerator {
    var colorCount: Int
    var particleCount: Int
    var rng: RandomNumberGenerator
    
    init(colorCount: Int, particleCount: Int, rng: RandomNumberGenerator = SystemRandomNumberGenerator()) {
        self.colorCount = colorCount
        self.particleCount = particleCount
        self.rng = rng
    }
    
    func generate(buffer: UnsafeMutableBufferPointer<Particle>) {
        let volume: Float = 1 / Float(colorCount)
        for i in 0..<particleCount {
            let color = Color(intValue: i % colorCount)!
            let xrange = volume*Float(color.rawValue) ..< volume*Float(color.rawValue + 1)
            buffer[i] = Particle(color: color, position: .random(in: xrange, 0..<1, using: &rng))
        }
    }
}

final class RingParticleGenerator: ParticleGenerator {
    var colorCount: Int
    var particleCount: Int
    var rng: RandomNumberGenerator
    
    init(colorCount: Int, particleCount: Int, rng: RandomNumberGenerator = SystemRandomNumberGenerator()) {
        self.colorCount = colorCount
        self.particleCount = particleCount
        self.rng = rng
    }
    
    func generate(buffer: UnsafeMutableBufferPointer<Particle>) {
        let volume: Float = 2 * .pi / Float(colorCount)
        let rRange: Range<Float> = 0.5..<0.7
        for i in 0..<particleCount {
            let color = Color(intValue: i % colorCount)!
            
            let thetaRange = volume*Float(color.rawValue) ..< volume*Float(color.rawValue + 1)
            
            let r = Float.random(in: rRange, using: &rng)
            let theta = Float.random(in: thetaRange, using: &rng)
            
            let position0 = SIMD2<Float>(x: r * cos(theta), y: r * sin(theta))
            buffer[i] = Particle(color: color, position: (position0 + 1) / 2)
        }
    }
}

final class ImbalanceParticleGenerator: ParticleGenerator {
    var colorCount: Int
    var particleCount: Int
    var rng: RandomNumberGenerator
    
    init(colorCount: Int, particleCount: Int, rng: RandomNumberGenerator = SystemRandomNumberGenerator()) {
        self.colorCount = colorCount
        self.particleCount = particleCount
        self.rng = rng
    }
    
    func generate(buffer: UnsafeMutableBufferPointer<Particle>) {
        let replacement = (0..<colorCount).shuffled(using: &rng)
        for i in 0..<particleCount {
            let cc = Int.random(in: 0..<colorCount*colorCount, using: &rng) + 1
            let c = replacement[Int(sqrt(Float(cc)))-1]
            let color = Color(intValue: c)!
            buffer[i] = Particle(color: color, position: .random(in: 0..<1, using: &rng))
        }
    }
}


fileprivate extension SIMD2<Float> {
    static func randomInUnitCircle(using generator: inout RandomNumberGenerator) -> Self {
        let v = SIMD2<Float>.random(in: -1..<1, using: &generator)
        if length(v) > 1 {
            return randomInUnitCircle(using: &generator)
        }
        return v
    }
}
