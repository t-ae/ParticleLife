import Foundation

extension VelocityUpdateSetting: CustomDebugStringConvertible {
    init(forceFunction: ForceFunction, distanceFunction: DistanceFunction, velocityHalfLife: Float, rmax: Float, forceFactor: Float) {
        self.init(forceFunction: forceFunction, distanceFunction: distanceFunction.rawValue, velocityHalfLife: velocityHalfLife, rmax: rmax, forceFactor: forceFactor)
    }
    
    public var debugDescription: String {
        let df = DistanceFunction(rawValue: distanceFunction)!
        return "VelocityUpdateSetting(forceFunction: .\(forceFunction), distanceFunction: .\(df), velocityHalfLife: \(velocityHalfLife), rmax: \(rmax), forceFactor: \(forceFactor))"
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
