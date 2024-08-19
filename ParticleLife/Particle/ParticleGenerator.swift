import Foundation

protocol ParticleGenerator {
    static var label: String { get }
    var colorCountToUse: Int { get }
    var particleCount: Int { get }
    var fixed: Bool { get }
    init(colorCountToUse: Int, particleCount: Int, fixed: Bool)
    
    func generate(buffer: UnsafeMutableBufferPointer<Particle>)
}

extension ParticleGenerator {
    func rangomNumberGenerator() -> RandomNumberGenerator {
        if fixed {
            Xorshift64()
        } else {
            SystemRandomNumberGenerator()
        }
    }
    
    fileprivate func colorPalette() -> ColorPalette {
        if fixed {
            ColorPalette(noReplacement: colorCountToUse)
        } else {
            ColorPalette(random: colorCountToUse)
        }
    }
}

enum ParticleGenerators {
    static var allTypes: [ParticleGenerator.Type] {
        [
            UniformParticleGenerator.self,
            PartitionParticleGenerator.self,
            RingParticleGenerator.self,
            GridParticleGenerator.self,
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
    var fixed: Bool
    
    func generate(buffer: UnsafeMutableBufferPointer<Particle>) {
        var rng = rangomNumberGenerator()
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
    var fixed: Bool
    
    func generate(buffer: UnsafeMutableBufferPointer<Particle>) {
        var rng = rangomNumberGenerator()
        let palette = colorPalette()
        
        let volume: Float = 1 / Float(colorCountToUse)
        for i in 0..<particleCount {
            let c = i % colorCountToUse
            let color = palette.get(i)
            let xrange = volume*Float(c) ..< volume*Float(c + 1)
            buffer[i] = Particle(color: color, position: .random(in: xrange, 0..<1, using: &rng))
        }
    }
}

struct RingParticleGenerator: ParticleGenerator {
    static let label: String = "ring"
    var colorCountToUse: Int
    var particleCount: Int
    var fixed: Bool
    
    func generate(buffer: UnsafeMutableBufferPointer<Particle>) {
        var rng = rangomNumberGenerator()
        let palette = colorPalette()
        
        let volume: Float = 2 * .pi / Float(colorCountToUse)
        
        let r0 = fixed ? 0.5 : Float.random(in: 0.2..<0.6)
        let rd = fixed ? 0.2 : Float.random(in: 0.05..<0.3)
        let rRange: Range<Float> = r0..<r0+rd
        
        for i in 0..<particleCount {
            let c = i % colorCountToUse
            let color = palette.get(i)
            
            let thetaRange = volume*Float(c) ..< volume*Float(c + 1)
            
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
    var fixed: Bool
    
    func generate(buffer: UnsafeMutableBufferPointer<Particle>) {
        var rng = rangomNumberGenerator()
        let palette = colorPalette()
        
        let ps = (1 << colorCountToUse) - 1
        
        for i in 0..<particleCount {
            let cc = (1...ps).randomElement()!
            let color = palette.get(Int(log2(Float(cc))))
            buffer[i] = Particle(color: color, position: .random(in: 0..<1, using: &rng))
        }
    }
}

struct GridParticleGenerator: ParticleGenerator {
    static let label: String = "grid"
    var colorCountToUse: Int
    var particleCount: Int
    var fixed: Bool
    
    func generate(buffer: UnsafeMutableBufferPointer<Particle>) {
        let palette = colorPalette()
        
        let rows = Int(ceil(sqrt(Float(particleCount))))
        let gap = 1 / Float(rows)
        
        for i in 0..<particleCount {
            let color = palette.get(i)
            
            let (row, col) = i.quotientAndRemainder(dividingBy: rows)
            let x = Float(col)*gap + gap/2
            let y = Float(rows-row-1)*gap + gap/2
            
            buffer[i] = Particle(color: color, position: .init(x: x, y: y))
        }
    }
}

fileprivate struct ColorPalette {
    private var replacement: [Int]
    
    init(random count: Int) {
        self.replacement = (0..<count).shuffled()
    }
    
    init(noReplacement count: Int) {
        self.replacement = [Int](0..<count)
    }
    
    func get(_ i: Int) -> Color {
        Color(intValue: replacement[i % replacement.count])!
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
