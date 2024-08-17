import Foundation
import Cocoa

class CustomSlider: NSSlider {
    var transform: (Float)->Float = { $0 }
    
    var transformedValue: Float {
        transform(floatValue)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
