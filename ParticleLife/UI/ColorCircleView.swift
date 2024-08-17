import Foundation
import Cocoa

class ColorCircleView: NSView {
    enum Target {
        case row, column
    }
    
    var delegate: ColorCircleViewDelegate?
    
    var color: Color = .red {
        didSet {
            needsLayout = true
        }
    }
    
    var target: Target = .row
    
    override func layout() {
        layer?.backgroundColor = color.nsColor.cgColor
        layer?.cornerRadius = bounds.width / 2
    }
    
    override func menu(for event: NSEvent) -> NSMenu? {
        let menu = NSMenu()
        for i in [0, -1, 1] {
            let item = NSMenuItem(title: "Fill \(i)", action: #selector(menuItemClicked), keyEquivalent: "")
            item.tag = i
            menu.addItem(item)
        }
        return menu
    }
    
    @objc func menuItemClicked(sender: NSMenuItem) {
        delegate?.colorCircleViewOnClickFillMenu(self, value: sender.tag)
    }
}

protocol ColorCircleViewDelegate {
    func colorCircleViewOnClickFillMenu(_ view: ColorCircleView, value: Int)
}
