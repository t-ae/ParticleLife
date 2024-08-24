import Foundation

protocol ParticleGenerator {
    var fixed: Bool { get }
    
    func generateBody(
        buffer: UnsafeMutableBufferPointer<Particle>,
        palette: ColorPalette,
        rng: inout any RandomNumberGenerator
    )
}

extension Particles {
    func generateParticles(by generator: any ParticleGenerator, particleCount: Int, colorCount: Int) throws {
        try setCount(count: particleCount, colorCount: colorCount)
        generator.generate(particles: self)
    }
}

extension ParticleGenerator {
    fileprivate func generate(particles: Particles) {
        let palette = if fixed {
            ColorPalette(identity: particles.colorCount)
        } else {
            ColorPalette(random: particles.colorCount)
        }
        var rng: RandomNumberGenerator = if fixed {
            Xorshift64()
        } else {
            SystemRandomNumberGenerator()
        }
        generateBody(buffer: particles.bufferPointer, palette: palette, rng: &rng)
    }
}

enum ParticleGeneratorType: String, OptionConvertible {
    case uniform = "Uniform"
    case circle = "Circle"
    case unitCircle = "Unit circle"
    case partition = "Partition"
    case ring = "Ring"
    case rainbowRing = "Rainbow ring"
    case grid = "Grid"
    case line = "Line"
    case imbalance = "Imbalance"
}

extension ParticleGeneratorType {
    func generator(fixed: Bool) -> any ParticleGenerator {
        switch self {
        case .uniform: 
            UniformParticleGenerator(fixed: fixed)
        case .circle:
            CircleParticleGenerator(fixed: fixed)
        case .unitCircle:
            CircleParticleGenerator(fixed: fixed, r: 1)
        case .partition:
            PartitionParticleGenerator(fixed: fixed)
        case .ring:
            RingParticleGenerator(fixed: fixed, rainbow: false)
        case .rainbowRing:
            RingParticleGenerator(fixed: fixed, rainbow: true)
        case .grid:
            GridParticleGenerator(fixed: fixed)
        case .line:
            LineParticleGenerator(fixed: fixed)
        case .imbalance:
            ImbalanceParticleGenerator(fixed: fixed)
        }
    }
}

struct UniformParticleGenerator: ParticleGenerator {
    var fixed: Bool
    
    func generateBody(buffer: UnsafeMutableBufferPointer<Particle>, palette: ColorPalette, rng: inout any RandomNumberGenerator) {
        for i in buffer.indices {
            let color = Color(intValue: i % palette.colorCount)!
            buffer[i] = Particle(color: color, position: .random(in: -1..<1, using: &rng))
        }
    }
}

struct PartitionParticleGenerator: ParticleGenerator {
    var fixed: Bool
    
    func generateBody(buffer: UnsafeMutableBufferPointer<Particle>, palette: ColorPalette, rng: inout any RandomNumberGenerator) {
        let volume: Float = 2 / Float(palette.colorCount)
        for i in buffer.indices {
            let c = i % palette.colorCount
            let color = palette.get(i)
            let xrange = volume*Float(c) ..< volume*Float(c + 1)
            buffer[i] = Particle(color: color, position: .random(in: xrange, 0..<2, using: &rng) - .init(1, 0))
        }
    }
}

struct CircleParticleGenerator: ParticleGenerator {
    var fixed: Bool
    
    var r: Float? = nil
    
    func generateBody(buffer: UnsafeMutableBufferPointer<Particle>, palette: ColorPalette, rng: inout any RandomNumberGenerator) {
        let r = self.r ?? Float.random(in: 0.1 ..< 0.8, using: &rng)
        for i in buffer.indices {
            let color = Color(intValue: i % palette.colorCount)!
            
            var (x, y): (Float, Float)
            repeat {
                x = Float.random(in: -r ... r, using: &rng)
                y = Float.random(in: -r ... r, using: &rng)
            } while x*x + y*y > r*r
            
            buffer[i] = Particle(color: color, position: .init(x: x, y: y))
        }
    }
}

struct RingParticleGenerator: ParticleGenerator {
    var fixed: Bool
    
    var rainbow: Bool
    
    func generateBody(buffer: UnsafeMutableBufferPointer<Particle>, palette: ColorPalette, rng: inout any RandomNumberGenerator) {
        let volume: Float = 2 * .pi / Float(palette.colorCount)
        
        let r0 = fixed ? 0.5 : Float.random(in: 0.2..<0.6)
        let rd = fixed ? 0.2 : Float.random(in: 0.05..<0.3)
        let rRange: Range<Float> = r0..<r0+rd
        
        for i in buffer.indices {
            let c = i % palette.colorCount
            let color = palette.get(c)
            
            let thetaRange = if rainbow {
                volume*Float(c) ..< volume*Float(c + 1)
            } else {
                0..<2*Float.pi
            }
            
            let r = Float.random(in: rRange, using: &rng)
            let theta = Float.random(in: thetaRange, using: &rng)
            
            let position = SIMD2<Float>(x: r * cos(theta), y: r * sin(theta))
            buffer[i] = Particle(color: color, position: position)
        }
    }
}

struct LineParticleGenerator: ParticleGenerator {
    var fixed: Bool
    
    func generateBody(buffer: UnsafeMutableBufferPointer<Particle>, palette: ColorPalette, rng: inout any RandomNumberGenerator) {
        let gap = 2 / Float(buffer.count)
        for i in buffer.indices {
            let color = if fixed {
                palette.get(i)
            } else {
                palette.random(using: &rng)
            }
            
            let x = gap * Float(i) + gap/2
            buffer[i] = Particle(color: color, position: .init(x: x, y: 0))
        }
    }
}

struct ImbalanceParticleGenerator: ParticleGenerator {
    var fixed: Bool
    
    func generateBody(buffer: UnsafeMutableBufferPointer<Particle>, palette: ColorPalette, rng: inout any RandomNumberGenerator) {
        let ps = (1 << palette.colorCount) - 1
        
        for i in buffer.indices {
            let c = i%ps + 1
            let color = palette.get(Int(log2(Float(c))))
            buffer[i] = Particle(color: color, position: .random(in: -1..<1, using: &rng))
        }
    }
}

struct GridParticleGenerator: ParticleGenerator {
    var fixed: Bool
    
    func generateBody(buffer: UnsafeMutableBufferPointer<Particle>, palette: ColorPalette, rng: inout any RandomNumberGenerator) {
        let rows = Int(ceil(sqrt(Float(buffer.count))))
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

struct ColorPalette {
    private var replacement: [Int]
    
    var colorCount: Int {
        replacement.count
    }
    
    init(random count: Int) {
        self.replacement = (0..<count).shuffled()
    }
    
    init(identity count: Int) {
        self.replacement = [Int](0..<count)
    }
    
    func get(_ i: Int) -> Color {
        Color(intValue: replacement[i % replacement.count])!
    }
    
    func random(using generator: inout any RandomNumberGenerator) -> Color {
        get(replacement.indices.randomElement(using: &generator)!)
    }
}
