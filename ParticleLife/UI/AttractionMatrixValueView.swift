import Foundation
import Cocoa

class AttractionMatrixValueView: NSControl {
    var delegate: AttractionMatrixValueViewDelegate?
    
    /// [-10, 10] range,
    private(set) var step: Int = 0 {
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
        self.allowsExpansionToolTips = true
    }
    
    override func layout() {
        if step > 0 {
            layer?.backgroundColor = .init(red: 0, green: sqrt(CGFloat(step)/10), blue: 0, alpha: 1)
        } else {
            layer?.backgroundColor = .init(red: sqrt(CGFloat(-step)/10), green: 0, blue: 0, alpha: 1)
        }
        label.frame = .init(x: 0, y: bounds.midY - label.bounds.midY, width: bounds.width, height: label.frame.height)
    }
    
    func increment() -> Bool {
        if step >= 10 { return false }
        step += 1
        return true
    }
    
    func decrement() -> Bool {
        if step <= -10 { return false }
        step -= 1
        return true
    }
    
    func setStep(_ step: Int) {
        assert(-10 <= step && step <= 10)
        self.step = step
    }
    
    override func mouseDown(with event: NSEvent) {
        startMouseHold(increment)
    }
    
    override func mouseUp(with event: NSEvent) {
        endMouseHold()
    }
    
    override func rightMouseDown(with event: NSEvent) {
        startMouseHold(decrement)
    }
    
    override func rightMouseUp(with event: NSEvent) {
        mouseHoldTask?.cancel()
        mouseHoldTask = nil
    }
    
    private var mouseHoldTask: Task<(), Error>? = nil
    
    private func startMouseHold(_ f: @escaping ()->Bool) {
        _ = f() // immediately
        
        mouseHoldTask = Task { @MainActor in
            try await Task.sleep(milliseconds: 500)
            while f() {
                try await Task.sleep(milliseconds: 100)
            }
        }
    }
    
    private func endMouseHold() {
        mouseHoldTask?.cancel()
        mouseHoldTask = nil
    }
}

protocol AttractionMatrixValueViewDelegate {
    func attractionMatrixValueViewOnUpdateValue()
}
