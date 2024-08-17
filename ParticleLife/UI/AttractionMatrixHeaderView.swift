import Foundation
import Cocoa

class AttractionMatrixHeaderView: NSControl {
    enum FillTarget {
        case row(Color)
        case column(Color)
        case diagonal
    }
    
    var delegate: AttractionMatrixHeaderViewDelegate?
    
    var fillTarget: FillTarget = .diagonal {
        didSet {
            toolTip = switch fillTarget {
            case .row:
                "Right click to fill this row"
            case .column:
                "Right click to fill this column"
            case .diagonal:
                "Right click to fill diagonal values"
            }
        }
    }
    
    let lineLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineWidth = 2
        layer.strokeColor = NSColor.red.cgColor
        
        return layer
    }()
    
    override func makeBackingLayer() -> CALayer {
        let layer = CALayer()
        layer.addSublayer(lineLayer)
        self.clipsToBounds = true
        return layer
    }
    
    override func layout() {
        allowsExpansionToolTips = true
        guard let layer = self.layer else { return }
        
        switch fillTarget {
        case .row(let color), .column(let color):
            layer.backgroundColor = color.nsColor.cgColor
            layer.cornerRadius = bounds.width / 2
            lineLayer.isHidden = true
        case .diagonal:
            layer.backgroundColor = .black
            layer.cornerRadius = bounds.width / 4
            
            let path = NSBezierPath()
            path.move(to: .init(x: bounds.width, y: 0))
            path.line(to: .init(x: 0, y: bounds.height))
            lineLayer.path = path.cgPath
            lineLayer.isHidden = false
        }
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
        delegate?.attractionMatrixHeaderViewOnClickFillMenu(self, value: sender.tag)
    }
}

protocol AttractionMatrixHeaderViewDelegate {
    func attractionMatrixHeaderViewOnClickFillMenu(_ view: AttractionMatrixHeaderView, value: Int)
}
