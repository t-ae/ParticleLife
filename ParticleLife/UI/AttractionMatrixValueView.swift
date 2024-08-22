import Foundation
import Cocoa

class AttractionMatrixValueView: AttractionMatrixChildView {
    var delegate: AttractionMatrixValueViewDelegate?
    
    private(set) var step: Int = 0 {
        didSet {
            label.stringValue = valueFormatter(step)
            needsLayout = true
            if step != oldValue {
                delegate?.attractionMatrixValueViewOnUpdateValue()
            }
        }
    }
    
    var attractionValue: Float {
        Float(step) / Float(maxStep)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    var label: NSTextField = .label(title: "0.0", textColor: .white)
    
    func setup() {
        addSubview(label)
        
        self.step = 0
        self.allowsExpansionToolTips = true
    }
    
    override func layout() {
        if step > 0 {
            layer?.backgroundColor = .init(red: 0, green: sqrt(CGFloat(step)/CGFloat(maxStep)), blue: 0, alpha: 1)
        } else {
            layer?.backgroundColor = .init(red: sqrt(CGFloat(-step)/CGFloat(maxStep)), green: 0, blue: 0, alpha: 1)
        }
        label.frame = .init(x: 0, y: bounds.midY - label.bounds.midY, width: bounds.width, height: label.frame.height)
    }
    
    func increment() -> Bool {
        if step >= maxStep { return false }
        step += 1
        return true
    }
    
    func decrement() -> Bool {
        if step <= -maxStep { return false }
        step -= 1
        return true
    }
    
    func setStep(_ step: Int) {
        assert(-maxStep <= step && step <= maxStep)
        self.step = step
    }
    
    override func mouseDown(with event: NSEvent) {
        if event.modifierFlags.contains(.shift) {
            setStep(maxStep)
        } else {
            startMouseHold(increment)
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        endMouseHold()
    }
    
    override func rightMouseDown(with event: NSEvent) {
        if event.modifierFlags.contains(.shift) {
            setStep(-maxStep)
        } else {
            startMouseHold(decrement)
        }
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
