import Foundation

extension VelocityUpdateSetting: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "VelocityUpdateSetting(forceFunction: .\(forceFunction), distanceFunction: .\(distanceFunction), velocityHalfLife: \(velocityHalfLife), rmax: \(rmax), forceFactor: \(forceFactor))"
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
