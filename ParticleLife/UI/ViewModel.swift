import Foundation
import Combine

final class ViewModel {
    // MARK: Particle setting
    @Published
    var colorCountToUse: Int = Color.allCases.count
    
    @Published
    var renderingColorCount: Int = Color.allCases.count
    
    @Published
    var particleCountString: String = "10000"
    
    @Published
    var particleGeneratorType: ParticleGeneratorType = .uniform
    
    @Published
    var fixSeeds: Bool = false
    
    let setParticlesEvent = PassthroughSubject<([Particle], Int) , Never>()
    
    // MARK: Attraction
    let attractionMaxStep = 10
    var attractionValueFormatter: (Int)->String {
        { [attractionMaxStep] in String(format: "%.1f", Float($0) / Float(attractionMaxStep)) }
    }
    
    @Published
    var attractionSteps: Matrix<Int> = Matrix(rows: Color.allCases.count, cols: Color.allCases.count, filledWith: 0)
    
    var attractionMatrix: any Publisher<Matrix<Float>, Never> {
        $attractionSteps.map {
            Matrix<Float>(rows: $0.rows, cols: $0.cols, elements: $0.elements.map {
                Float($0) / Float(self.attractionMaxStep)
            })
        }
    }
    
    @Published
    var autoUpdateAttractionMatrix: Bool = false
    
    func updateAttractionMatrix(_ update: AttractionUpdate) {
        update.apply(&attractionSteps, maxStep: attractionMaxStep, colorCount: renderingColorCount)
    }
    
    func updateAttractionMatrixLine(_ update: AttractionLineUpdate, step: Int) {
        update.apply(&attractionSteps, step: step, colorCount: renderingColorCount)
    }
    
    func setAttractionMatrixPreset(_ preset: AttractionPreset) {
        attractionSteps = preset.steps(colorCount: renderingColorCount)
    }
    
    // MARK: Velocity update rule
    @Published
    var forceFunction: ForceFunction = .default
    
    @Published
    var distanceFunction: DistanceFunction = .default
    
    @Published
    var rmax: Rmax = .r010
    
    @Published
    var velocityHalfLife: VelocityHalfLife = .l100
    
    let forceFactorRange: ClosedRange<Float> = 0...10
    
    @Published
    var forceFactor: Float = 1
    
    var velocityUpdateSetting: any Publisher<VelocityUpdateSetting, Never> {
        let p0 = $forceFunction.combineLatest($distanceFunction, $rmax).eraseToAnyPublisher()
        let p1 = $velocityHalfLife.combineLatest($forceFactor).eraseToAnyPublisher()
        
        return p0.combineLatest(p1) { a, b in
            VelocityUpdateSetting(
                forceFunction: a.0,
                distanceFunction: a.1,
                rmax: a.2.rawValue,
                velocityHalfLife: b.0.rawValue,
                forceFactor: b.1
            )
        }
    }
    
    
    // MARK: Other
    @Published
    var preferredFPS: FPS = .fps60
    
    @Published
    var fixDt: Bool = false
    
    let particleSizeRange: ClosedRange<Float> = 1...10
    
    @Published
    var particleSize: Float = 5
    
    // MARK: Control
    @Published
    var isPaused: Bool = false
    
    // MARK: Transform
    @Published
    private(set) var zoom: Float = 1
    
    func zoom(factor: Float) {
        zoom = min(max(zoom * factor, 1.0/3), 15)
    }
    
    @Published
    var center: SIMD2<Float> = .zero
    
    var transform: any Publisher<Transform, Never> {
        $zoom.combineLatest($center) { zoom, center in
            Transform(center: center, zoom: zoom)
        }
    }
    
    func resetTransform() {
        zoom = 1
        center = .zero
    }
    
    // MARK: Events
    let errorNotifyEvent = PassthroughSubject<Error, Never>()
}

enum Rmax: Float, OptionConvertible {
    case r001 = 0.01
    case r003 = 0.03
    case r005 = 0.05
    case r010 = 0.10
    case r030 = 0.30
    case r050 = 0.50
    case r100 = 1.00
    
    var description: String { String(format: "%.2f", rawValue) }
}

enum VelocityHalfLife: Float, OptionConvertible {
    case l10 = 0.01
    case l50 = 0.05
    case l100 = 0.1
    case l500 = 0.5
    case l1000 = 1
    
    var description: String { String(format: "%.3fms", rawValue) }
}

enum FPS: Int, OptionConvertible {
    case fps30 = 30
    case fps60 = 60
    case fps120 = 120
    
    var description: String { "\(rawValue)" }
}
