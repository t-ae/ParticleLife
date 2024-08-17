import Foundation
import Cocoa

class AttractionMatrixValueView: NSView {
    var delegate: AttractionMatrixValueViewDelegate?
    
    /// [-10, 10] range,
    private var step: Int = 0 {
        didSet {
            label.stringValue = String(format: "%.1f", Float(step)/10)
            needsLayout = true
            delegate?.attractionMatrixValueViewOnUpdateValue()
        }
    }
    
    var attractionValue: Float {
        Float(step) / 10
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    var label: NSTextField!
    
    func setup() {
        label = NSTextField(string: "0.0")
        label.textColor = .white
        label.alignment = .center
        label.isBezeled = false
        label.isEditable = false
        label.isSelectable = false
        label.drawsBackground = false
        label.backgroundColor = .clear
        addSubview(label)
        
        self.step = 0
    }
    
    func increment() {
        if step >= 10 { return }
        step += 1
    }
    
    func decrement() {
        if step <= -10 { return }
        step -= 1
    }
    
    func setStep(_ step: Int) {
        assert(-10 <= step && step <= 10)
        self.step = step
    }
    
    override func mouseDown(with event: NSEvent) {
        increment()
    }
    
    override func rightMouseDown(with event: NSEvent) {
        decrement()
    }
    
    override func layout() {
        if step > 0 {
            layer?.backgroundColor = .init(red: 0, green: sqrt(CGFloat(step)/10), blue: 0, alpha: 1)
        } else {
            layer?.backgroundColor = .init(red: sqrt(CGFloat(-step)/10), green: 0, blue: 0, alpha: 1)
        }
        label.frame = .init(x: 0, y: bounds.midY - label.bounds.midY, width: bounds.width, height: label.frame.height)
    }
}

protocol AttractionMatrixValueViewDelegate {
    func attractionMatrixValueViewOnUpdateValue()
}
