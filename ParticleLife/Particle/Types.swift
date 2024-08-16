import Foundation

extension VelocityUpdateSetting {
    init(forceFunction: ForceFunction, velocityHalfLife: Float, rmax: Float) {
        self.init(forceFunction: forceFunction.rawValue, velocityHalfLife: velocityHalfLife, rmax: rmax)
    }
}

extension Rect {
    init(centerX: Float, centerY: Float, width: Float, height: Float) {
        self.init(x: centerX - width/2, y: centerY - height/2, width: width, height: height)
    }
    
    var center: SIMD2<Float> {
        .init(x + width/2, y + height/2)
    }
}
