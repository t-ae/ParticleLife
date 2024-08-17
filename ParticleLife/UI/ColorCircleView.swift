import Foundation
import Cocoa

class ColorCircleView: NSControl {
    enum FillTarget {
        case row, column
    }
    
    var delegate: ColorCircleViewDelegate?
    
    var color: Color = .red {
        didSet {
            needsLayout = true
        }
    }
    
    var fillTarget: FillTarget = .row {
        didSet {
            toolTip = "Right click to fill this \(fillTarget)"
        }
    }
    
    override func layout() {
        allowsExpansionToolTips = true
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
    
    override func mouseEntered(with event: NSEvent) {
        print(event)
    }
}

protocol ColorCircleViewDelegate {
    func colorCircleViewOnClickFillMenu(_ view: ColorCircleView, value: Int)
}
