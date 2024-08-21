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
    
    var attraction: Matrix<Float> = .colorMatrix(filledWith: 0)
    var velocityUpdateSetting: VelocityUpdateSetting = .init(
        forceFunction: ForceFunction.default,
        distanceFunction: DistanceFunction.default,
        rmax: 0.05,
        velocityHalfLife: 0.1,
        forceFactor: 1
    )
    var fixedDt: Bool = false
    var particleSize: Float = 5
    var viewportSize: SIMD2<Float> = .zero
    
    let rgbs = Color.allCases.map { $0.rgb }
    var renderingRect: Rect2 = .init(x: 0, y: 0, width: 1, height: 1)
    
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
        
        do {
            let length: Int = MemoryLayout<Particle>.size * Self.maxParticleCount
            let buffer = try device.makeBuffer(length: length, options: .storageModeShared)
                .orThrow("Failed to make buffer")
            buffer.label = "particle_buffer"
            self.particleBuffer = buffer
        }
    }
    
    func generateParticles(_ generator: ParticleGeneratorProtocol) throws {
        guard 0...Self.maxParticleCount ~= generator.particleCount else {
            throw MessageError("particleCount must be in range [0, \(Self.maxParticleCount)].")
        }
        particleCount = generator.particleCount
        let buffer = UnsafeMutableBufferPointer(start: particleBuffer.contents().bindMemory(to: Particle.self, capacity: particleCount), count: particleCount)
        generator.generate(buffer: buffer)
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        viewportSize.x = Float(size.width);
        viewportSize.y = Float(size.height);
    }
    
    private var lastDrawDate = Date()
    private var fpsHistory: RingBuffer = .init(count: 60, initialValue: 0)
    private var dtHistory: RingBuffer = .init(count: 30, initialValue: 0)
    
    func draw(in view: MTKView) {
        let now = Date()
        let realDt = Float(now.timeIntervalSince(lastDrawDate))
        let fps = 1/realDt
        fpsHistory.insert(fps)
        if fpsHistory.head % (view.preferredFramesPerSecond / 2)  == 0 {
            // evenry 0.5sec
            delegate?.rendererOnUpdateFPS(fpsHistory.average())
        }
        lastDrawDate = now
        
        let dt: Float
        let averageDt = dtHistory.average()
        if fixedDt || realDt < averageDt/2 || realDt > averageDt*1.5 { // ignore outlier
            dt =  1 / Float(view.preferredFramesPerSecond)
        } else {
            dt = realDt
        }
        dtHistory.insert(dt)
        
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
            renderParticles(in: view, commandBuffer: commandBuffer)
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
        var colorCount = Color.allCases.count
        computeEncoder.setBytes(&colorCount, length: MemoryLayout<UInt32>.size, index: 2)
        computeEncoder.setBytes(attraction.elements, length: MemoryLayout<Float>.size * attraction.elements.count, index: 3)
        computeEncoder.setBytes(&velocityUpdateSetting, length: MemoryLayout<VelocityUpdateSetting>.size, index: 4)
        var dt = dt
        computeEncoder.setBytes(&dt, length: MemoryLayout<Float>.size, index: 5)
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
    
    func renderParticles(in view: MTKView, commandBuffer: MTLCommandBuffer) {
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
        renderEncoder.setVertexBytes(rgbs, length: MemoryLayout<SIMD3<Float>>.size * rgbs.count, index: 1)
        renderEncoder.setVertexBytes(&particleSize, length: MemoryLayout<Float>.size, index: 2)
        renderEncoder.setVertexBytes(&renderingRect, length: MemoryLayout<Rect2>.size, index: 3)
        renderEncoder.setVertexBytes(&viewportSize, length: MemoryLayout<SIMD2<Float>>.size, index: 5)
        for y: Float in [-1, 0, 1] {
            for x: Float in [-1, 0, 1] {
                var offsets = SIMD2<Float>(x: x, y: y)
                renderEncoder.setVertexBytes(&offsets, length: MemoryLayout<SIMD2<Float>>.size, index: 4)
                renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: particleCount)
            }
        }
        
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
    
    func dumpParameters() -> String {
        """
        particleCount: \(particleCount)
        attraction:
        \(attraction.stringify(elementFormat: "%+.1f"))
        
        velocityUpdateSetting: \(velocityUpdateSetting)
        fixedDt: \(fixedDt)
        particleSize: \(particleSize)
        """
    }
    
    func dumpStatistics() -> String {
        var nanCout = 0
        var infiniteCount = 0
        var colorCounts = [Int](repeating: 0, count: Color.allCases.count)
        var sumOfAttractorCount: UInt32 = 0
        
        let buffer = UnsafeMutableBufferPointer(start: particleBuffer.contents().bindMemory(to: Particle.self, capacity: particleCount), count: particleCount)
        for particle in buffer {
            if particle.hasNaN { nanCout += 1 }
            if particle.hasInfinite { infiniteCount += 1 }
            colorCounts[Int(particle.color)] += 1
            if !particle.hasNaN && !particle.hasInfinite {
                sumOfAttractorCount += particle.attractorCount
            }
        }
        
        var strs = [String]()
        strs.append("particleCount: \(particleCount)")
        for color in Color.allCases {
            strs.append("- \(color): \(colorCounts[color.intValue])")
        }
        
        let validParticleCount = particleCount - nanCout - infiniteCount
        
        let rmax = velocityUpdateSetting.rmax
        let attractionArea = velocityUpdateSetting.distanceFunction.areaOfDistance1 * rmax * rmax
        let expectedAttractorCount = max(Float(validParticleCount-1), 0) * attractionArea
        let averageAttractorCount = Float(sumOfAttractorCount) / max(Float(validParticleCount), 1)
        
        strs.append("""
        
        Expected attractor count: \(expectedAttractorCount)
        Average attractor count: \(averageAttractorCount)
        
        NaN: \(nanCout)
        Infinite: \(infiniteCount)
        """)
        
        return strs.joined(separator: "\n")
    }
    
    func induceInvalid() {
        guard particleCount > 0 else { return }
        let buffer = UnsafeMutableBufferPointer(start: particleBuffer.contents().bindMemory(to: Particle.self, capacity: particleCount), count: particleCount)
        let index = Int.random(in: 0..<particleCount)
        
        let target = ["x", "y", "vx", "vy"].randomElement()!
        let value = [Float.nan, .infinity].randomElement()!
        switch target {
        case "x":
            buffer[index].position.x = value
        case "y":
            buffer[index].position.x = value
        case "vx":
            buffer[index].velocity.x = value
        case "vy":
            buffer[index].velocity.x = value
        default:
            break
        }
        
        print("Induce \(value) for \(target) of particles[\(index)].")
    }
}

protocol RendererDelegate {
    func rendererOnUpdateFPS(_ fps: Float)
}
