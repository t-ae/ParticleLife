import Metal

final class ParticleHolder {
    static let maxCount: Int = 65536
    
    @Published
    private(set) var count: Int = 0
    @Published
    private(set) var colorCount: Int = Color.allCases.count
    
    let buffers: [MTLBuffer]
    let semaphores: [DispatchSemaphore]
    
    private var currentBufferIndex = 0
    private var nextBufferIndex = 1
    
    var isEmpty: Bool { count == 0 }
    
    init(device: MTLDevice) throws {
        let length: Int = MemoryLayout<Particle>.size * Self.maxCount
        self.buffers = try (0..<3).map {
            let buffer = try device.makeBuffer(length: length, options: .storageModeShared)
                .orThrow("Failed to make particle buffer")
            buffer.label = "particle_buffer_\($0)"
            return buffer
        }
        self.semaphores = (0..<3).map { _ in DispatchSemaphore(value: 1) }
    }
    
    func currentBuffer() -> MTLBuffer { buffers[currentBufferIndex] }
    func nextBuffer() -> MTLBuffer { buffers[nextBufferIndex] }
    
    func currentSemaphore() -> DispatchSemaphore { semaphores[currentBufferIndex] }
    func nextSemaphore() -> DispatchSemaphore { semaphores[nextBufferIndex] }
    
    func advanceBufferIndex() {
        currentBufferIndex += 1
        if currentBufferIndex >= 3 {
            currentBufferIndex = 0
        }
        nextBufferIndex += 1
        if nextBufferIndex >= 3 {
            nextBufferIndex = 0
        }
    }
    
    func setCount(count: Int, colorCount: Int) throws {
        guard 0...Self.maxCount ~= count else {
            throw MessageError("Particle count must be in range [0, \(Self.maxCount)].")
        }
        guard 1...Color.allCases.count ~= colorCount else {
            throw MessageError("Color count must be in range [1, \(Color.allCases.count)].")
        }
        self.count = count
        self.colorCount = colorCount
    }
    
    private func update(_ f: (UnsafeMutableBufferPointer<Particle>)->Void) {
        semaphores.forEach { $0.wait() }
        
        let bufferPointer = UnsafeMutableRawBufferPointer(start: currentBuffer().contents(), count: MemoryLayout<Particle>.size * Self.maxCount)
            .bindMemory(to: Particle.self)
        f(bufferPointer)
        
        semaphores.forEach { $0.signal() }
    }
    
    func setParticles(_ particles: [Particle], colorCount: Int) throws {
        guard particles.count <= Self.maxCount else {
            throw MessageError("Particle count must be less than or equal to \(Self.maxCount)")
        }
        
        update { bufferPointer in
            self.count = particles.count
            self.colorCount = colorCount
            
            for i in 0..<particles.count {
                bufferPointer[i] = particles[i]
            }
        }
    }
    
    func addParticle(_ particle: Particle) {
        guard count < Self.maxCount-1 else {
            return
        }
        
        update { bufferPointer in
            bufferPointer[count] = particle
            count += 1
        }
    }
    
    func removeNaarestParticle(around center: SIMD2<Float>, in radius: Float) {
        update { bufferPointer in 
            var minimumIndex = -1
            var minimumDistance = Float.infinity
            for i in bufferPointer.indices {
                let v = bufferPointer[i].position - center
                let distance = length(v.wrapped(max: 1))
                
                if distance < radius && distance < minimumDistance {
                    
                }
                if length(v.wrapped(max: 1)) < radius {
                    minimumIndex = i
                    minimumDistance = distance
                }
            }
            if minimumIndex >= 0 {
                if minimumIndex != count-1 {
                    swap(&bufferPointer[minimumIndex], &bufferPointer[count-1])
                }
                count -= 1
            }
        }
    }
    
    func dumpStatistics() -> String {
        var nanCout = 0
        var infiniteCount = 0
        var colorCounts = [Int](repeating: 0, count: Color.allCases.count)
        
        let semaphore = currentSemaphore()
        semaphore.wait()
        defer { semaphore.signal() }
        
        let buffer = UnsafeMutableRawBufferPointer(start: currentBuffer().contents(), count: MemoryLayout<Particle>.size * count)
            .bindMemory(to: Particle.self)
        for particle in buffer {
            if particle.hasNaN { nanCout += 1 }
            if particle.hasInfinite { infiniteCount += 1 }
            colorCounts[Int(particle.color)] += 1
        }
        
        var strs = [String]()
        strs.append("particleCount: \(count)")
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
