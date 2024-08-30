import Foundation
import Metal
import MetalKit

final class ParticleLifeController: NSObject, MTKViewDelegate {
    var delegate: ParticleLifeControllerDelegate?
    
    let commandQueue: MTLCommandQueue
    let updateVelocityState: MTLComputePipelineState
    let updatePositionState: MTLComputePipelineState
    let renderPipelineState: MTLRenderPipelineState
    
    let particles: Particles
    
    @Published
    var attractionMatrix: Matrix<Float> = .colorMatrix(filledWith: 0)
    @Published
    var velocityUpdateSetting: VelocityUpdateSetting = .init()
    @Published
    var particleSize: Float = 5
    @Published
    var viewportSize: SIMD2<Float> = .zero
    @Published
    var transform = Transform(center: .zero, zoom: 1)
    
    init(device: MTLDevice, pixelFormat: MTLPixelFormat) throws {
        guard let commandQueue = device.makeCommandQueue() else {
            throw MessageError("makeCommandQueue failed.")
        }
        self.commandQueue = commandQueue
        
        guard let library = device.makeDefaultLibrary() else {
            throw MessageError("makeDefaultLibrary failed.")
        }
        
        do {
            let updateVelocityFunc = try library.makeFunction(name: "updateVelocity")
                .orThrow("makeFunction failed: updateVelocity")
            self.updateVelocityState = try device.makeComputePipelineState(function: updateVelocityFunc)
        }
        do {
            let updatePositionFunc = try library.makeFunction(name: "updatePosition")
                .orThrow("makeFunction failed: updatePosition")
            self.updatePositionState = try device.makeComputePipelineState(function: updatePositionFunc)
        }
        
        do {
            let vertexFunc = try library.makeFunction(name: "particleVertex")
                .orThrow("makeFunction failed: particleVertex")
            let fragmentFunc = try library.makeFunction(name: "particleFragment")
                .orThrow("makeFunction failed: particleFragment")
            
            let renderPipelineStateDescriptor = MTLRenderPipelineDescriptor()
            renderPipelineStateDescriptor.label = "renderParticles"
            renderPipelineStateDescriptor.vertexFunction = vertexFunc
            renderPipelineStateDescriptor.fragmentFunction = fragmentFunc
            renderPipelineStateDescriptor.colorAttachments[0].pixelFormat = pixelFormat
            renderPipelineStateDescriptor.colorAttachments[0].isBlendingEnabled = true
            
            renderPipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = .add
            renderPipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
            renderPipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = .one
            
            renderPipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = .add
            renderPipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
            renderPipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .one
            
            self.renderPipelineState = try device.makeRenderPipelineState(descriptor: renderPipelineStateDescriptor)
        }
        
        particles = try Particles(device: device)
    }
    
    nonisolated func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        viewportSize.x = Float(size.width)
        viewportSize.y = Float(size.height)
    }
    
    func startUpdate() {
        guard isPaused else { return }
        lastUpdate = Date()
        isPaused = false
        
        if !updateLoopStarted {
            updateLoopStarted = true
            Task {
                await updateParticles()
            }
        }
    }
    
    func stopUpdate() {
        guard !isPaused else { return }
        isPaused = true
    }
    
    private var updateLoopStarted = false
    private var lastUpdate = Date()
    private var isPaused = true
    private var updateCount = 0
    private var lastNotify = Date()
    
    @MainActor
    func updateParticles() {
        let now = Date()
        var dt = Float(now.timeIntervalSince(lastUpdate))
        lastUpdate = now
        
        let interval = now.timeIntervalSince(lastNotify)
        if interval > 0.5 {
            let ups = Float(updateCount) / Float(interval)
            delegate?.particleLifeController(self, notifyUpdatePerSecond: ups)
            updateCount = 0
            lastNotify = now
        }
        
        let shouldSkip = isPaused || particles.isEmpty
        if shouldSkip {
            Task {
                try await Task.sleep(milliseconds: 1)
                updateParticles()
            }
            return
        }
        
        updateCount += 1
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            fatalError("makeCommandBuffer failed.")
        }
        
        do {
            guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
                fatalError("makeComputeCommandEncoder failed.")
            }
            let state = updateVelocityState
            computeEncoder.label = "updateVelocity"
            computeEncoder.setComputePipelineState(state)
            computeEncoder.setBuffer(particles.buffer, offset: 0, index: 0)
            var particleCount = UInt32(particles.count)
            computeEncoder.setBytes(&particleCount, length: MemoryLayout<UInt32>.size, index: 1)
            var colorCount = UInt32(Color.allCases.count)
            computeEncoder.setBytes(&colorCount, length: MemoryLayout<UInt32>.size, index: 2)
            computeEncoder.setBytes(attractionMatrix.elements, length: MemoryLayout<Float>.size * attractionMatrix.elements.count, index: 3)
            computeEncoder.setBytes(&velocityUpdateSetting, length: MemoryLayout<VelocityUpdateSetting>.size, index: 4)
            computeEncoder.setBytes(&dt, length: MemoryLayout<Float>.size, index: 5)
            computeEncoder.setThreadgroupMemoryLength(state.threadExecutionWidth * MemoryLayout<Particle>.size, index: 0)
            computeEncoder.dispatchThreads(
                .init(width: particles.count, height: 1, depth: 1),
                threadsPerThreadgroup: .init(width: state.threadExecutionWidth, height: 1, depth: 1)
            )
            computeEncoder.endEncoding()
        }
        do {
            guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
                fatalError("makeComputeCommandEncoder failed.")
            }
            let state = updatePositionState
            computeEncoder.label = "updatePosition"
            computeEncoder.setComputePipelineState(state)
            computeEncoder.setBuffer(particles.buffer, offset: 0, index: 0)
            computeEncoder.setThreadgroupMemoryLength(state.threadExecutionWidth * MemoryLayout<Particle>.size, index: 0)
            computeEncoder.setBytes(&dt, length: MemoryLayout<Float>.size, index: 1)
            computeEncoder.dispatchThreads(
                .init(width: particles.count, height: 1, depth: 1),
                threadsPerThreadgroup: .init(width: state.threadExecutionWidth, height: 1, depth: 1)
            )
            computeEncoder.endEncoding()
        }
        
        commandBuffer.addCompletedHandler { commandBuffer in
            Task {
                self.updateParticles()
            }
        }
        
        commandBuffer.commit()
    }
    
    let rgbs = Color.allCases.map { $0.rgb }
    
    func draw(in view: MTKView) {
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            fatalError("makeCommandBuffer failed.")
        }
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = view.currentDrawable?.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = .init(red: 0, green: 0, blue: 0, alpha: 0)
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            fatalError("makeRenderCommandEncoder failed.")
        }
        
        renderEncoder.label = "renderParticles"
        renderEncoder.setRenderPipelineState(renderPipelineState)
        renderEncoder.setVertexBuffer(particles.buffer, offset: 0, index: 0)
        renderEncoder.setVertexBytes(rgbs, length: MemoryLayout<SIMD3<Float>>.size * rgbs.count, index: 1)
        renderEncoder.setVertexBytes(&particleSize, length: MemoryLayout<Float>.size, index: 2)
        renderEncoder.setVertexBytes(&transform, length: MemoryLayout<Transform>.size, index: 3)
        renderEncoder.setVertexBytes(&viewportSize, length: MemoryLayout<SIMD2<Float>>.size, index: 5)
        for y: Float in [-2, 0, 2] {
            for x: Float in [-2, 0, 2] {
                var offsets = SIMD2<Float>(x: x, y: y)
                renderEncoder.setVertexBytes(&offsets, length: MemoryLayout<SIMD2<Float>>.size, index: 4)
                renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: particles.count)
            }
        }
        
        renderEncoder.endEncoding()
        
        if let drawable = view.currentDrawable {
            commandBuffer.present(drawable)
        }
        
        commandBuffer.commit()
    }
}

extension ParticleLifeController {
    func dumpParameters() -> String {
        """
        attraction:
        \(attractionMatrix.stringify(elementFormat: "%+.1f"))
        
        velocityUpdateSetting: \(velocityUpdateSetting)
        particleSize: \(particleSize)
        """
    }
    
    func dumpStatistics() -> String {
        var nanCout = 0
        var infiniteCount = 0
        var colorCounts = [Int](repeating: 0, count: Color.allCases.count)
        var sumOfAttractorCount: UInt32 = 0
        
        let buffer = particles.bufferPointer
        for particle in buffer {
            if particle.hasNaN { nanCout += 1 }
            if particle.hasInfinite { infiniteCount += 1 }
            colorCounts[Int(particle.color)] += 1
            if !particle.hasNaN && !particle.hasInfinite {
                sumOfAttractorCount += particle.attractorCount
            }
        }
        
        var strs = [String]()
        strs.append("particleCount: \(particles.count)")
        for color in Color.allCases {
            strs.append("- \(color): \(colorCounts[color.intValue])")
        }
        
        let validParticleCount = particles.count - nanCout - infiniteCount
        
        let rmax = velocityUpdateSetting.rmax
        let fieldSize: Float = 2*2
        let attractionArea = velocityUpdateSetting.distanceFunction.areaOfDistance1 * rmax * rmax
        let expectedAttractorCount = max(Float(validParticleCount-1), 0) / fieldSize * attractionArea
        let averageAttractorCount = Float(sumOfAttractorCount) / max(Float(validParticleCount), 1)
        
        strs.append("""
        
        Expected attractor count: \(expectedAttractorCount)
        Average attractor count: \(averageAttractorCount)
        
        NaN: \(nanCout)
        Infinite: \(infiniteCount)
        """)
        
        return strs.joined(separator: "\n")
    }
}

protocol ParticleLifeControllerDelegate {
    func particleLifeController(_ particleLifeController: ParticleLifeController, notifyUpdatePerSecond updatePerSeond: Float)
}
