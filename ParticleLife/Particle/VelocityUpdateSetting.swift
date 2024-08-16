import Foundation

extension VelocityUpdateSetting {
    init(forceFunction: ForceFunction, velocityHalfLife: Float, rmax: Float) {
        self.init(forceFunction: forceFunction.rawValue, velocityHalfLife: velocityHalfLife, rmax: rmax)
    }
}
