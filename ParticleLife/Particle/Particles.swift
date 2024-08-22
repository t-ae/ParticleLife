import Foundation
import Metal

final class Particles {
    static let maxCount: Int = 65536
    
    private(set) var count: Int = 0
    let buffer: MTLBuffer
    
    var isEmpty: Bool { count == 0 }
    
    init(device: MTLDevice) throws {
        let length: Int = MemoryLayout<Particle>.size * Self.maxCount
        self.buffer = try device.makeBuffer(length: length, options: .storageModeShared)
            .orThrow("Failed to make particle buffer")
        buffer.label = "particle_buffer"
    }
    
    func setCount(_ count: Int) throws {
        guard 0...Self.maxCount ~= count else {
            throw MessageError("Particle count must be in range [0, \(Self.maxCount)].")
        }
        self.count = count
    }
    
    var bufferPointer: UnsafeMutableBufferPointer<Particle> {
        UnsafeMutableRawBufferPointer(start: buffer.contents(), count: MemoryLayout<Particle>.size * count)
            .bindMemory(to: Particle.self)
    }
}
