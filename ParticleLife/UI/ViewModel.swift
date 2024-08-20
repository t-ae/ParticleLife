import Foundation
import Combine

final class ViewModel {
    // MARK: Particle setting
    @Published
    var colorCountToUse: Int = Color.allCases.count
    
    @Published
    var particleCountString: String = "10000"
    
    @Published
    var particleGenerator: ParticleGeneratorType = .uniform
    
    @Published
    var fixSeeds: Bool = false
    
    var generateParticles: (()->Void)!
    
    // MARK: Attraction
    
    let attractionRange: Int = 10
    
    @Published
    var attractionSteps: Matrix<Int> = Matrix(rows: Color.allCases.count, cols: Color.allCases.count, filledWith: 0)
    
    var attraction: any Publisher<Matrix<Float>, Never> {
        $attractionSteps.map {
            Matrix<Float>(rows: $0.rows, cols: $0.cols, elements: $0.elements.map { Float($0) / Float(self.attractionRange) })
        }
    }
    
    @Published
    var autoUpdateAttraction: Bool = false
    
    func updateAttraction(_ update: AttractionUpdate) {
        update.apply(&attractionSteps)
    }
    
    func setAttractionPreset(_ preset: AttractionPreset) {
        attractionSteps = preset.steps(colorCountToUse: colorCountToUse)
    }
    
    // MARK: Velocity update rule
    
    @Published
    var forceFunction: ForceFunction = .default
    
    @Published
    var distanceFunction: DistanceFunction = .default
    
    @Published
    var rmax: Rmax = .r005
    
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
    
    var particleSizeRange: ClosedRange<Float> = 1...15
    
    @Published
    var particleSize: Float = 3
    
    // MARK: Control
    var play: ()->Void = {}
    var pause: ()->Void = {}
}

enum Rmax: Float, OptionConvertible {
    case r001 = 0.01
    case r003 = 0.03
    case r005 = 0.05
    case r010 = 0.10
    case r030 = 0.30
    case r050 = 0.50
    
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
