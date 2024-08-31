import Cocoa

class LogScaleSlider: BindableSlider {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        target = self
        action = #selector(onChange)
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        target = self
        action = #selector(onChange)
    }
    
    override var maxValue: Double {
        get {
            pow(2, super.maxValue)
        }
        set {
            super.maxValue = log2(newValue)
        }
    }
    
    override var minValue: Double {
        get {
            pow(2, super.minValue)
        }
        set {
            super.minValue = log2(newValue)
        }
    }
    
    override var floatValue: Float {
        get {
            pow(2, super.floatValue)
        }
        set {
            super.floatValue = log2(newValue)
        }
    }
}
