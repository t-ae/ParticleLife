import Metal

final class ParticleHolder {
    static let bufferCount = 3
    static let maxCount: Int = 65536
    
    @Published
    private(set) var particleCount: Int = 0
    @Published
    private(set) var colorCount: Int = Color.allCases.count
    
    let buffers: [MTLBuffer]
    private(set) var currentBufferIndex = 0
    var nextBufferIndex: Int { (currentBufferIndex+1) % Self.bufferCount }
    let semaphore = DispatchSemaphore(value: 1)
    
    var isEmpty: Bool { particleCount == 0 }
    
    init(device: MTLDevice) throws {
        let length: Int = MemoryLayout<Particle>.stride * Self.maxCount
        self.buffers = try (0..<Self.bufferCount).map {
            let buffer = try device.makeBuffer(length: length, options: .storageModeShared)
                .orThrow("Failed to make particle buffer")
            buffer.label = "particle_buffer_\($0)"
            return buffer
        }
    }
    
    func advanceBufferIndex() {
        currentBufferIndex = (currentBufferIndex+1) % Self.bufferCount
    }
    
    private func update(_ f: (UnsafeMutableBufferPointer<Particle>)->Void) {
        semaphore.wait()
        
        let buffer = buffers[currentBufferIndex]
        let bufferPointer = UnsafeMutableRawBufferPointer(start: buffer.contents(), count: MemoryLayout<Particle>.stride * Self.maxCount)
            .bindMemory(to: Particle.self)
        f(bufferPointer)
        
        semaphore.signal()
    }
    
    func setParticles(_ particles: [Particle], colorCount: Int) throws {
        guard particles.count <= Self.maxCount else {
            throw MessageError("Particle count must be less than or equal to \(Self.maxCount)")
        }
        
        update { bufferPointer in
            self.particleCount = particles.count
            self.colorCount = colorCount
            
            for i in 0..<particles.count {
                bufferPointer[i] = particles[i]
            }
        }
    }
    
    func addParticle(_ particle: Particle) {
        guard particleCount < Self.maxCount-1 else {
            return
        }
        
        update { bufferPointer in
            bufferPointer[particleCount] = particle
            particleCount += 1
        }
    }
    
    func removeNaarestParticle(around center: SIMD2<Float>, in radius: Float) {
        update { bufferPointer in 
            var minimumIndex = -1
            var minimumDistance = radius
            for i in 0..<particleCount {
                let v = bufferPointer[i].position - center
                let distance = length(v.wrapped(max: 1))
                
                if length(v.wrapped(max: 1)) < minimumDistance {
                    minimumIndex = i
                    minimumDistance = distance
                }
            }
            if minimumIndex >= 0 {
                if minimumIndex != particleCount-1 {
                    swap(&bufferPointer[minimumIndex], &bufferPointer[particleCount-1])
                }
                particleCount -= 1
            }
        }
    }
    
    func dumpStatistics() -> String {
        var nanCout = 0
        var infiniteCount = 0
        var colorCounts = [Int](repeating: 0, count: Color.allCases.count)
        
        semaphore.wait()
        defer { semaphore.signal() }
        
        let buffer = buffers[currentBufferIndex]
        let bufferPointer = UnsafeMutableRawBufferPointer(start: buffer.contents(), count: MemoryLayout<Particle>.stride * particleCount)
            .bindMemory(to: Particle.self)
        for particle in bufferPointer {
            if particle.hasNaN { nanCout += 1 }
            if particle.hasInfinite { infiniteCount += 1 }
            colorCounts[Int(particle.color)] += 1
        }
        
        var strs = [String]()
        strs.append("particleCount: \(particleCount)")
        for color in Color.allCases {
            strs.append("- \(color): \(colorCounts[color.intValue])")
        }
        
        strs.append("""

        NaN: \(nanCout)
        Infinite: \(infiniteCount)
        """)
        
        return strs.joined(separator: "\n")
    }
}
