import Foundation

extension VelocityUpdateSetting: CustomDebugStringConvertible {
    init(forceFunction: ForceFunction, distanceFunction: DistanceFunction, velocityHalfLife: Float, rmax: Float) {
        self.init(forceFunction: forceFunction.rawValue, distanceFunction: distanceFunction.rawValue, velocityHalfLife: velocityHalfLife, rmax: rmax)
    }
    
    public var debugDescription: String {
        let ff = ForceFunction(rawValue: forceFunction)!
        let df = DistanceFunction(rawValue: distanceFunction)!
        return "VelocityUpdateSetting(forceFunction: .\(ff), distanceFunction: .\(df), velocityHalfLife: \(velocityHalfLife), rmax: \(rmax))"
    }
}

extension Rect2 {
    init(centerX: Float, centerY: Float, width: Float, height: Float) {
        self.init(x: centerX - width/2, y: centerY - height/2, width: width, height: height)
    }
    
    var center: SIMD2<Float> {
        .init(x + width/2, y + height/2)
    }
}
