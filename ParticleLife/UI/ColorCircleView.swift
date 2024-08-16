import Foundation
import Cocoa

class ColorCircleView: NSView {
    var color: NSColor = .clear
    
    override func layout() {
        layer?.backgroundColor = color.cgColor
        layer?.cornerRadius = bounds.width / 2
    }
}
