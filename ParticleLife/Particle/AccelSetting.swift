import Foundation

extension AccelSetting {
    init(forceFunction: ForceFunction, velocityHalfLife: Float, rmax: Float) {
        self.init(forceFunction: forceFunction.rawValue, velocityHalfLife: velocityHalfLife, rmax: rmax)
    }
}
