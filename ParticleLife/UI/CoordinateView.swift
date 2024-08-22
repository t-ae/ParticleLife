import Foundation
import Cocoa

final class CoordinateView: NSView {
    let oLabel = NSTextField.label(title: "O", textColor: .white)
    let xPlusLabel = NSTextField.label(title: "x=+1.0", textColor: .white)
    let xMinusLabel = NSTextField.label(title: "x=-1.0", textColor: .white)
    let yPlusLabel = NSTextField.label(title: "y=+1.0", textColor: .white)
    let yMinusLabel = NSTextField.label(title: "y=-1.0", textColor: .white)
    
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    func setup() {
        addSubview(oLabel)
        addSubview(xPlusLabel)
        addSubview(xMinusLabel)
        addSubview(yPlusLabel)
        addSubview(yMinusLabel)
        
        xPlusLabel.frameRotation = 90
        xMinusLabel.frameCenterRotation = -90
    }
    
    override func layout() {
        super.layout()
        
        oLabel.frame.center = bounds.center
        
        xPlusLabel.frame.origin.x = bounds.width
        xPlusLabel.frame.origin.y = oLabel.frame.center.y - xPlusLabel.frame.width/2
        
        xMinusLabel.frame.origin.x = 0
        xMinusLabel.frame.origin.y = oLabel.frame.center.y + xMinusLabel.frame.width/2
        
        yPlusLabel.frame.center.x = oLabel.frame.center.x
        yPlusLabel.frame.origin.y = bounds.height - yPlusLabel.frame.height
        
        yMinusLabel.frame.center.x = oLabel.frame.center.x
        yMinusLabel.frame.origin.y = 0
    }
}
