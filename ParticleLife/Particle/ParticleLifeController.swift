import Foundation
import Metal
import MetalKit

@MainActor
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
        
        self.startUpdateLoop()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        viewportSize.x = Float(size.width)
        viewportSize.y = Float(size.height)
    }
    
    @Published
    var isPaused = true
    
    private var loopTask: Task<Void, Error>?
    
    func startUpdateLoop() {
        loopTask = Task { [unowned self] in
            var lastUpdate = Date()
            var updateCount = 0
            var lastNotify = Date()
            
            while true {
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
                    try await Task.sleep(milliseconds: 1)
                } else {
                    updateCount += 1
                    await updateParticles(dt: dt)
                }
            }
        }
    }
    
    deinit {
        loopTask?.cancel()
    }
    
    func updateParticles(dt: Float) async {
        assert(!isPaused && !particleHolder.isEmpty)
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            fatalError("makeCommandBuffer failed.")
        }
        
        var dt = dt
        var particleCount = UInt32(particleHolder.particleCount)
        var colorCount = UInt32(Color.allCases.count)
        
        do {
            guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
                fatalError("makeComputeCommandEncoder failed.")
            }
            let state = updateVelocityState
            computeEncoder.label = "updateVelocity"
            computeEncoder.setComputePipelineState(state)
            computeEncoder.setBuffer(particleHolder.buffer, offset: 0, index: 0)
            computeEncoder.setBytes(&particleCount, length: MemoryLayout<UInt32>.size, index: 1)
            computeEncoder.setBytes(&colorCount, length: MemoryLayout<UInt32>.size, index: 2)
            computeEncoder.setBytes(attractionMatrix.elements, length: MemoryLayout<Float>.stride * attractionMatrix.elements.count, index: 3)
            computeEncoder.setBytes(&velocityUpdateSetting, length: MemoryLayout<VelocityUpdateSetting>.size, index: 4)
            computeEncoder.setBytes(&dt, length: MemoryLayout<Float>.size, index: 5)
            computeEncoder.dispatchThreads(
                .init(width: particleHolder.particleCount, height: 1, depth: 1),
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
            computeEncoder.setBuffer(particleHolder.buffer, offset: 0, index: 0)
            computeEncoder.setBytes(&dt, length: MemoryLayout<Float>.size, index: 1)
            computeEncoder.dispatchThreads(
                .init(width: particleHolder.particleCount, height: 1, depth: 1),
                threadsPerThreadgroup: .init(width: state.threadExecutionWidth, height: 1, depth: 1)
            )
            computeEncoder.endEncoding()
        }
        
        await withCheckedContinuation { cont in
            commandBuffer.addCompletedHandler { _ in
                cont.resume()
            }
            
            commandBuffer.commit()
        }
    }
    
    let rgbs = Color.allCases.map { $0.rgb }
    
    func draw(in view: MTKView) {
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            fatalError("makeCommandBuffer failed.")
        }
        
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else {
            fatalError("currentRenderPassDescriptor is nil.")
        }
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            fatalError("makeRenderCommandEncoder failed.")
        }
        
        renderEncoder.label = "renderParticles"
        renderEncoder.setRenderPipelineState(renderPipelineState)
        renderEncoder.setVertexBuffer(particleHolder.buffer, offset: 0, index: 0)
        renderEncoder.setVertexBytes(rgbs, length: MemoryLayout<SIMD3<Float>>.stride * rgbs.count, index: 1)
        renderEncoder.setVertexBytes(&particleSize, length: MemoryLayout<Float>.size, index: 2)
        renderEncoder.setVertexBytes(&transform, length: MemoryLayout<Transform>.size, index: 3)
        renderEncoder.setVertexBytes(&viewportSize, length: MemoryLayout<SIMD2<Float>>.size, index: 5)
        for y: Float in [-2, 0, 2] {
            for x: Float in [-2, 0, 2] {
                var offsets = SIMD2<Float>(x: x, y: y)
                renderEncoder.setVertexBytes(&offsets, length: MemoryLayout<SIMD2<Float>>.size, index: 4)
                renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: particleHolder.particleCount)
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
    @MainActor func particleLifeController(
        _ particleLifeController: ParticleLifeController,
        notifyUpdatePerSecond updatePerSeond: Float
    )
}
