import Foundation
import Metal

final class Particles {
    static let maxCount: Int = 65536
    
    @Published
    private(set) var count: Int = 0
    @Published
    private(set) var colorCount: Int = Color.allCases.count
    
    let buffer: MTLBuffer
    
    var isEmpty: Bool { count == 0 }
    
    init(device: MTLDevice) throws {
        let length: Int = MemoryLayout<Particle>.size * Self.maxCount
        self.buffer = try device.makeBuffer(length: length, options: .storageModeShared)
            .orThrow("Failed to make particle buffer")
        buffer.label = "particle_buffer"
    }
    
    func setCount(count: Int, colorCount: Int) throws {
        guard 0...Self.maxCount ~= count else {
            throw MessageError("Particle count must be in range [0, \(Self.maxCount)].")
        }
        guard 1...Color.allCases.count ~= colorCount else {
            throw MessageError("Color count must be in range [0, \(Color.allCases.count)].")
        }
        self.count = count
        self.colorCount = colorCount
    }
    
    var bufferPointer: UnsafeMutableBufferPointer<Particle> {
        UnsafeMutableRawBufferPointer(start: buffer.contents(), count: MemoryLayout<Particle>.size * count)
            .bindMemory(to: Particle.self)
    }
    
    func addParticle(_ particle: Particle) {
        guard count < Self.maxCount-1 else {
            return
        }
        count += 1
        bufferPointer[count-1] = particle
    }
}
