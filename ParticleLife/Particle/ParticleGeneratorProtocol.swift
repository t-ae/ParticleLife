import Foundation

protocol ParticleGeneratorProtocol {
    var colorCountToUse: Int { get }
    var particleCount: Int { get }
    var fixed: Bool { get }
    
    func generateBody(buffer: UnsafeMutableBufferPointer<Particle>)
}

extension ParticleGeneratorProtocol {
    func rangomNumberGenerator() -> RandomNumberGenerator {
        if fixed {
            Xorshift64()
        } else {
            SystemRandomNumberGenerator()
        }
    }
    
    fileprivate func colorPalette() -> ColorPalette {
        if fixed {
            ColorPalette(identity: colorCountToUse)
        } else {
            ColorPalette(random: colorCountToUse)
        }
    }
    
    func generate(particles: Particles) throws {
        try particles.setCount(particleCount)
        generateBody(buffer: particles.bufferPointer)
    }
}

enum ParticleGeneratorType: String, OptionConvertible {
    case uniform = "Uniform"
    case circle = "Circle"
    case unitCircle = "Unit circle"
    case partition = "Partition"
    case rainbowRing = "Rainbow ring"
    case grid = "Grid"
    case imbalance = "Imbalance"
}

extension ParticleGeneratorType {
    func generator(colorCountToUse: Int, particleCount: Int, fixed: Bool) -> any ParticleGeneratorProtocol {
        switch self {
        case .uniform: 
            UniformParticleGenerator(colorCountToUse: colorCountToUse, particleCount: particleCount, fixed: fixed)
        case .circle:
            CircleParticleGenerator(colorCountToUse: colorCountToUse, particleCount: particleCount, fixed: fixed)
        case .unitCircle:
            CircleParticleGenerator(colorCountToUse: colorCountToUse, particleCount: particleCount, fixed: fixed, r: 1)
        case .partition:
            PartitionParticleGenerator(colorCountToUse: colorCountToUse, particleCount: particleCount, fixed: fixed)
        case .rainbowRing: 
            RainbowRingParticleGenerator(colorCountToUse: colorCountToUse, particleCount: particleCount, fixed: fixed)
        case .grid: 
            GridParticleGenerator(colorCountToUse: colorCountToUse, particleCount: particleCount, fixed: fixed)
        case .imbalance: 
            ImbalanceParticleGenerator(colorCountToUse: colorCountToUse, particleCount: particleCount, fixed: fixed)
        }
    }
}

struct UniformParticleGenerator: ParticleGeneratorProtocol {
    var colorCountToUse: Int
    var particleCount: Int
    var fixed: Bool
    
    func generateBody(buffer: UnsafeMutableBufferPointer<Particle>) {
        var rng = rangomNumberGenerator()
        for i in buffer.indices {
            let color = Color(intValue: i % colorCountToUse)!
            buffer[i] = Particle(color: color, position: .random(in: -1..<1, using: &rng))
        }
    }
}

struct PartitionParticleGenerator: ParticleGeneratorProtocol {
    var colorCountToUse: Int
    var particleCount: Int
    var fixed: Bool
    
    func generateBody(buffer: UnsafeMutableBufferPointer<Particle>) {
        var rng = rangomNumberGenerator()
        let palette = colorPalette()
        
        let volume: Float = 2 / Float(colorCountToUse)
        for i in buffer.indices {
            let c = i % colorCountToUse
            let color = palette.get(i)
            let xrange = volume*Float(c) ..< volume*Float(c + 1)
            buffer[i] = Particle(color: color, position: .random(in: xrange, 0..<2, using: &rng) - .init(1, 0))
        }
    }
}

struct CircleParticleGenerator: ParticleGeneratorProtocol {
    var colorCountToUse: Int
    var particleCount: Int
    var fixed: Bool
    
    var r: Float? = nil
    
    func generateBody(buffer: UnsafeMutableBufferPointer<Particle>) {
        var rng = rangomNumberGenerator()
        
        let r = self.r ?? Float.random(in: 0.1 ..< 0.8, using: &rng)
        for i in buffer.indices {
            let color = Color(intValue: i % colorCountToUse)!
            
            var (x, y): (Float, Float)
            repeat {
                x = Float.random(in: -r ... r, using: &rng)
                y = Float.random(in: -r ... r, using: &rng)
            } while x*x + y*y > r*r
            
            buffer[i] = Particle(color: color, position: .init(x: x, y: y))
        }
    }
}

struct RainbowRingParticleGenerator: ParticleGeneratorProtocol {
    var colorCountToUse: Int
    var particleCount: Int
    var fixed: Bool
    
    func generateBody(buffer: UnsafeMutableBufferPointer<Particle>) {
        var rng = rangomNumberGenerator()
        let palette = colorPalette()
        
        let volume: Float = 2 * .pi / Float(colorCountToUse)
        
        let r0 = fixed ? 0.5 : Float.random(in: 0.2..<0.6)
        let rd = fixed ? 0.2 : Float.random(in: 0.05..<0.3)
        let rRange: Range<Float> = r0..<r0+rd
        
        for i in buffer.indices {
            let c = i % colorCountToUse
            let color = palette.get(i)
            
            let thetaRange = volume*Float(c) ..< volume*Float(c + 1)
            
            let r = Float.random(in: rRange, using: &rng)
            let theta = Float.random(in: thetaRange, using: &rng)
            
            let position = SIMD2<Float>(x: r * cos(theta), y: r * sin(theta))
            buffer[i] = Particle(color: color, position: position)
        }
    }
}

struct ImbalanceParticleGenerator: ParticleGeneratorProtocol {
    var colorCountToUse: Int
    var particleCount: Int
    var fixed: Bool
    
    func generateBody(buffer: UnsafeMutableBufferPointer<Particle>) {
        var rng = rangomNumberGenerator()
        let palette = colorPalette()
        
        let ps = (1 << colorCountToUse) - 1
        
        for i in buffer.indices {
            let cc = (1...ps).randomElement()!
            let color = palette.get(Int(log2(Float(cc))))
            buffer[i] = Particle(color: color, position: .random(in: -1..<1, using: &rng))
        }
    }
}

struct GridParticleGenerator: ParticleGeneratorProtocol {
    var colorCountToUse: Int
    var particleCount: Int
    var fixed: Bool
    
    func generateBody(buffer: UnsafeMutableBufferPointer<Particle>) {
        let palette = colorPalette()
        
        let rows = Int(ceil(sqrt(Float(particleCount))))
        let gap = 2 / Float(rows)
        
        for i in buffer.indices {
            let color = palette.get(i)
            
            let (row, col) = i.quotientAndRemainder(dividingBy: rows)
            let x = Float(col)*gap + gap/2 - 1
            let y = Float(rows-row-1)*gap + gap/2 - 1
            
            buffer[i] = Particle(color: color, position: .init(x: x, y: y))
        }
    }
}

fileprivate struct ColorPalette {
    private var replacement: [Int]
    
    init(random count: Int) {
        self.replacement = (0..<count).shuffled()
    }
    
    init(identity count: Int) {
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
