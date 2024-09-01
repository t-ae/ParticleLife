import Foundation
import Metal
import MetalKit

final class ParticleLifeController: NSObject, MTKViewDelegate {
    var delegate: ParticleLifeControllerDelegate?
    
    let commandQueue: MTLCommandQueue
    let updateVelocityState: MTLComputePipelineState
    let updatePositionState: MTLComputePipelineState
    let renderPipelineState: MTLRenderPipelineState
    
    let particleHolder: ParticleHolder
    
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
        self.commandQueue = try device.makeCommandQueue().orThrow("makeCommandQueue failed.")
        
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
        
        particleHolder = try ParticleHolder(device: device)
        
        super.init()
        
        self.updateLoop()
    }
    
    nonisolated func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        viewportSize.x = Float(size.width)
        viewportSize.y = Float(size.height)
    }
    
    @Published
    var isPaused = true
    
    func updateLoop() {
        var lastUpdate = Date()
        var updateCount = 0
        var lastNotify = Date()
        
        
        DispatchQueue.global().async { [unowned self] in
            while true {
                let semaphore = particleHolder.semaphore
                semaphore.wait() // Wait until next buffer is available
                
                let now = Date()
                let dt = Float(now.timeIntervalSince(lastUpdate))
                lastUpdate = now
                
                let interval = now.timeIntervalSince(lastNotify)
                if interval > 0.5 {
                    let ups = Float(updateCount) / Float(interval)
                    DispatchQueue.main.async { [unowned self] in
                        delegate?.particleLifeController(self, notifyUpdatePerSecond: ups)
                    }
                    updateCount = 0
                    lastNotify = now
                }
                
                if isPaused || particleHolder.isEmpty {
                    usleep(1000)
                    semaphore.signal()
                } else {
                    updateCount += 1
                    updateParticles(dt: dt)
                    particleHolder.advanceBufferIndex() // After updateParticles is completed
                    semaphore.signal() // Release buffer
                }
            }
        }
    }
    
    /// Update particleHolder.nextBuffer based on particleHolder.currentBuffer.
    func updateParticles(dt: Float) {
        assert(!isPaused && !particleHolder.isEmpty)
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            fatalError("makeCommandBuffer failed.")
        }
        
        let currentBufferIndex = particleHolder.currentBufferIndex
        let nextBufferIndex = particleHolder.nextBufferIndex
        let currentBuffer = particleHolder.buffers[currentBufferIndex]
        let nextBuffer = particleHolder.buffers[nextBufferIndex]
        
        var dt = dt
        var particleCount = UInt32(particleHolder.count)
        var colorCount = UInt32(Color.allCases.count)
        
        do {
            guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
                fatalError("makeComputeCommandEncoder failed.")
            }
            let state = updateVelocityState
            computeEncoder.label = "updateVelocity[\(nextBufferIndex)]"
            computeEncoder.setComputePipelineState(state)
            computeEncoder.setBuffer(currentBuffer, offset: 0, index: 0)
            computeEncoder.setBuffer(nextBuffer, offset: 0, index: 1)
            computeEncoder.setBytes(&particleCount, length: MemoryLayout<UInt32>.size, index: 2)
            computeEncoder.setBytes(&colorCount, length: MemoryLayout<UInt32>.size, index: 3)
            computeEncoder.setBytes(attractionMatrix.elements, length: MemoryLayout<Float>.size * attractionMatrix.elements.count, index: 4)
            computeEncoder.setBytes(&velocityUpdateSetting, length: MemoryLayout<VelocityUpdateSetting>.size, index: 5)
            computeEncoder.setBytes(&dt, length: MemoryLayout<Float>.size, index: 6)
            computeEncoder.setThreadgroupMemoryLength(state.threadExecutionWidth * MemoryLayout<Particle>.size, index: 0)
            computeEncoder.dispatchThreads(
                .init(width: particleHolder.count, height: 1, depth: 1),
                threadsPerThreadgroup: .init(width: state.threadExecutionWidth, height: 1, depth: 1)
            )
            computeEncoder.endEncoding()
        }
        do {
            guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
                fatalError("makeComputeCommandEncoder failed.")
            }
            let state = updatePositionState
            computeEncoder.label = "updatePosition[\(nextBufferIndex)]"
            computeEncoder.setComputePipelineState(state)
            computeEncoder.setBuffer(nextBuffer, offset: 0, index: 0)
            computeEncoder.setThreadgroupMemoryLength(state.threadExecutionWidth * MemoryLayout<Particle>.size, index: 0)
            computeEncoder.setBytes(&dt, length: MemoryLayout<Float>.size, index: 1)
            computeEncoder.dispatchThreads(
                .init(width: particleHolder.count, height: 1, depth: 1),
                threadsPerThreadgroup: .init(width: state.threadExecutionWidth, height: 1, depth: 1)
            )
            computeEncoder.endEncoding()
        }
        
        commandBuffer.commit()
        
        commandBuffer.waitUntilCompleted()
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
        
        let bufferIndex = particleHolder.currentBufferIndex
        let buffer = particleHolder.buffers[bufferIndex]
        
        renderEncoder.label = "renderParticles[\(bufferIndex)]"
        renderEncoder.setRenderPipelineState(renderPipelineState)
        renderEncoder.setVertexBuffer(buffer, offset: 0, index: 0)
        renderEncoder.setVertexBytes(rgbs, length: MemoryLayout<SIMD3<Float>>.size * rgbs.count, index: 1)
        renderEncoder.setVertexBytes(&particleSize, length: MemoryLayout<Float>.size, index: 2)
        renderEncoder.setVertexBytes(&transform, length: MemoryLayout<Transform>.size, index: 3)
        renderEncoder.setVertexBytes(&viewportSize, length: MemoryLayout<SIMD2<Float>>.size, index: 5)
        for y: Float in [-2, 0, 2] {
            for x: Float in [-2, 0, 2] {
                var offsets = SIMD2<Float>(x: x, y: y)
                renderEncoder.setVertexBytes(&offsets, length: MemoryLayout<SIMD2<Float>>.size, index: 4)
                renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: particleHolder.count)
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
}

protocol ParticleLifeControllerDelegate {
    func particleLifeController(_ particleLifeController: ParticleLifeController, notifyUpdatePerSecond updatePerSeond: Float)
}
