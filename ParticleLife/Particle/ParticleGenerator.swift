import Foundation

protocol ParticleGenerator {
    static var label: String { get }
    var colorCountToUse: Int { get }
    var particleCount: Int { get }
    var rng: RandomNumberGenerator { get }
    init(colorCountToUse: Int, particleCount: Int, rng: any RandomNumberGenerator)
    
    func generate(buffer: UnsafeMutableBufferPointer<Particle>)
}

enum ParticleGenerators {
    static var allTypes: [ParticleGenerator.Type] {
        [
            UniformParticleGenerator.self,
            PartitionParticleGenerator.self,
            RingParticleGenerator.self,
            ImbalanceParticleGenerator.self,
        ]
    }
    
    static func get(for label: String) -> ParticleGenerator.Type? {
        allTypes.first { $0.label == label }
    }
}

struct UniformParticleGenerator: ParticleGenerator {
    static let label: String = "uniform"
    var colorCountToUse: Int
    var particleCount: Int
    var rng: RandomNumberGenerator
    
    func generate(buffer: UnsafeMutableBufferPointer<Particle>) {
        var rng = rng
        for i in 0..<particleCount {
            let color = Color(intValue: i % colorCountToUse)!
            buffer[i] = Particle(color: color, position: .random(in: 0..<1, using: &rng))
        }
    }
}

struct PartitionParticleGenerator: ParticleGenerator {
    static let label: String = "partition"
    var colorCountToUse: Int
    var particleCount: Int
    var rng: RandomNumberGenerator
    
    func generate(buffer: UnsafeMutableBufferPointer<Particle>) {
        var rng = rng
        let volume: Float = 1 / Float(colorCountToUse)
        for i in 0..<particleCount {
            let color = Color(intValue: i % colorCountToUse)!
            let xrange = volume*Float(color.rawValue) ..< volume*Float(color.rawValue + 1)
            buffer[i] = Particle(color: color, position: .random(in: xrange, 0..<1, using: &rng))
        }
    }
}

struct RingParticleGenerator: ParticleGenerator {
    static let label: String = "ring"
    var colorCountToUse: Int
    var particleCount: Int
    var rng: RandomNumberGenerator
    
    func generate(buffer: UnsafeMutableBufferPointer<Particle>) {
        var rng = rng
        let volume: Float = 2 * .pi / Float(colorCountToUse)
        let rRange: Range<Float> = 0.5..<0.7
        for i in 0..<particleCount {
            let color = Color(intValue: i % colorCountToUse)!
            
            let thetaRange = volume*Float(color.rawValue) ..< volume*Float(color.rawValue + 1)
            
            let r = Float.random(in: rRange, using: &rng)
            let theta = Float.random(in: thetaRange, using: &rng)
            
            let position0 = SIMD2<Float>(x: r * cos(theta), y: r * sin(theta))
            buffer[i] = Particle(color: color, position: (position0 + 1) / 2)
        }
    }
}

struct ImbalanceParticleGenerator: ParticleGenerator {
    static let label: String = "imbalance"
    var colorCountToUse: Int
    var particleCount: Int
    var rng: RandomNumberGenerator
    
    func generate(buffer: UnsafeMutableBufferPointer<Particle>) {
        var rng = rng
        let replacement = (0..<colorCountToUse).shuffled(using: &rng)
        for i in 0..<particleCount {
            let cc = Int.random(in: 0..<colorCountToUse*colorCountToUse, using: &rng) + 1
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
