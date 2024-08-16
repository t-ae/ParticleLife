import Foundation
import Metal
import MetalKit

final class Renderer: NSObject, MTKViewDelegate {
    static let maxParticleCount = 65536
    
    var delegate: RendererDelegate?
    
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let updateVelocityState: MTLComputePipelineState
    let updatePositionState: MTLComputePipelineState
    let renderPipelineState: MTLRenderPipelineState
    
    var particleCount: Int = 0
    let particleBuffer: MTLBuffer
    
    var attraction: Attraction = .init()
    var velocityUpdateSetting: VelocityUpdateSetting = .init(forceFunction: .force2, velocityHalfLife: 0.1, rmax: 0.05)
    var particleSize: Float = 7
    
    var renderingRect: Rect = .init(x: 0, y: 0, width: 1, height: 1)
    
    init(
        device: MTLDevice,
        pixelFormat: MTLPixelFormat
    ) throws {
        self.device = device
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
            let vertexFunc = try library.makeFunction(name: "vertexFunc")
                .orThrow("makeFunction failed: vertexFunc")
            let fragmentFunc = try library.makeFunction(name: "fragmentFunc")
                .orThrow("makeFunction failed: fragmentFunc")
            
            let renderPipelineStateDescriptor = MTLRenderPipelineDescriptor()
            renderPipelineStateDescriptor.label = "render"
            renderPipelineStateDescriptor.vertexFunction = vertexFunc
            renderPipelineStateDescriptor.fragmentFunction = fragmentFunc
            renderPipelineStateDescriptor.colorAttachments[0].pixelFormat = pixelFormat
            renderPipelineStateDescriptor.colorAttachments[0].isBlendingEnabled = true
            
            renderPipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = .add
            renderPipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
            renderPipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = .destinationAlpha
            
            renderPipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = .add
            renderPipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
            renderPipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .one
            
            self.renderPipelineState = try device.makeRenderPipelineState(descriptor: renderPipelineStateDescriptor)
        }
        
        do {
            let length: Int = MemoryLayout<Particle>.size * Self.maxParticleCount
            let buffer = try device.makeBuffer(length: length, options: .storageModeShared)
                .orThrow("Failed to make buffer")
            buffer.label = "particle_buffer"
            self.particleBuffer = buffer
        }
    }
    
    func generateParticles(_ generator: ParticleGenerator) throws {
        guard generator.particleCount >= 0 else {
            throw MessageError("particleCount must be greater than 0.")
        }
        guard generator.particleCount <= Self.maxParticleCount else {
            throw MessageError("particleCount must be less than \(Self.maxParticleCount).")
        }
        particleCount = generator.particleCount
        let buffer = UnsafeMutableBufferPointer(start: particleBuffer.contents().bindMemory(to: Particle.self, capacity: particleCount), count: particleCount)
        generator.generate(buffer: buffer)
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    private var lastDrawDate = Date()
    private var fpsHistory: [Float] = []
    
    func draw(in view: MTKView) {
        let now = Date()
        let dt = Float(now.timeIntervalSince(lastDrawDate))
        let fps = 1/dt
        fpsHistory.append(fps)
        if fpsHistory.count == 30 {
            delegate?.rendererOnUpdateFPS(fpsHistory.reduce(0, +) / 30)
            fpsHistory = []
        }
        lastDrawDate = now
        
        do { // Update velocity
            guard let commandBuffer = commandQueue.makeCommandBuffer() else {
                fatalError("Failed to make command buffer.")
            }
            updateVelocity(in: view, commandBuffer: commandBuffer, dt: dt)
            commandBuffer.commit()
        }
        do { // Update position
            guard let commandBuffer = commandQueue.makeCommandBuffer() else {
                fatalError("Failed to make command buffer.")
            }
            updatePosition(in: view, commandBuffer: commandBuffer, dt: dt)
            commandBuffer.commit()
        }
        do { // Render
            guard let commandBuffer = commandQueue.makeCommandBuffer() else {
                fatalError("Failed to make command buffer.")
            }
            render(in: view, commandBuffer: commandBuffer)
            commandBuffer.commit()
        }
    }
    
    var isPaused: Bool = false
    
    func updateVelocity(in view: MTKView, commandBuffer: MTLCommandBuffer, dt: Float) {
        guard !isPaused else { return }
        if particleCount == 0 { return }
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            return
        }
        computeEncoder.label = "updateVelocity"

        let dispatchThreads = MTLSize(width: particleCount, height: 1, depth: 1)
        let threadsPerThreadgroup = MTLSize(width: updateVelocityState.threadExecutionWidth, height: 1, depth: 1)

        computeEncoder.setComputePipelineState(updateVelocityState)
        computeEncoder.setBuffer(particleBuffer, offset: 0, index: 0)
        computeEncoder.setBytes(&particleCount, length: MemoryLayout<UInt32>.size, index: 1)
        computeEncoder.setBytes(attraction.matrix, length: MemoryLayout<Float>.size * attraction.matrix.count, index: 2)
        computeEncoder.setBytes(&velocityUpdateSetting, length: MemoryLayout<VelocityUpdateSetting>.size, index: 3)
        var dt = dt
        computeEncoder.setBytes(&dt, length: MemoryLayout<Float>.size, index: 4)
        computeEncoder.setThreadgroupMemoryLength(updatePositionState.threadExecutionWidth * MemoryLayout<Particle>.size, index: 0)
        computeEncoder.dispatchThreads(dispatchThreads, threadsPerThreadgroup: threadsPerThreadgroup)
        computeEncoder.endEncoding()
    }
    
    func updatePosition(in view: MTKView, commandBuffer: MTLCommandBuffer, dt: Float) {
        guard !isPaused else { return }
        if particleCount == 0 { return }
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            return
        }
        computeEncoder.label = "updatePosition"

        let dispatchThreads = MTLSize(width: particleCount, height: 1, depth: 1)
        let threadsPerThreadgroup = MTLSize(width: updatePositionState.threadExecutionWidth, height: 1, depth: 1)

        computeEncoder.setComputePipelineState(updatePositionState)
        computeEncoder.setBuffer(particleBuffer, offset: 0, index: 0)
        computeEncoder.setThreadgroupMemoryLength(updatePositionState.threadExecutionWidth * MemoryLayout<Particle>.size, index: 0)
        var dt = dt
        computeEncoder.setBytes(&dt, length: MemoryLayout<Float>.size, index: 1)
        computeEncoder.dispatchThreads(dispatchThreads, threadsPerThreadgroup: threadsPerThreadgroup)
        computeEncoder.endEncoding()
    }
    
    func render(in view: MTKView, commandBuffer: MTLCommandBuffer) {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = view.currentDrawable?.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = .init(red: 0, green: 0, blue: 0, alpha: 0)
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        renderEncoder.label = "Particle Rendering"
        
        renderEncoder.setRenderPipelineState(renderPipelineState)
        renderEncoder.setVertexBuffer(particleBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBytes(Color.rgb, length: MemoryLayout<vector_float3>.size * Color.rgb.count, index: 1)
        renderEncoder.setVertexBytes(&particleSize, length: MemoryLayout<Float>.size, index: 2)
        renderEncoder.setVertexBytes(&renderingRect, length: MemoryLayout<Rect>.size, index: 3)
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: particleCount)
        renderEncoder.endEncoding()
        
        if let drawable = view.currentDrawable {
            commandBuffer.present(drawable)
        }
    }
}

extension Renderer {
    func particle(_ i: Int) -> Particle {
        let particleBuffer = particleBuffer.contents().bindMemory(to: Particle.self, capacity: particleCount)
        return particleBuffer[i]
    }
}

protocol RendererDelegate {
    func rendererOnUpdateFPS(_ fps: Float)
}
