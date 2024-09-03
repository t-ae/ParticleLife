import Foundation
import Cocoa

class AttractionMatrixHeaderView: AttractionMatrixChildView {
    var delegate: AttractionMatrixHeaderViewDelegate?
    
    var fillTarget: AttractionLineUpdate = .diagonal {
        didSet {
            toolTip = switch fillTarget {
            case .row:
                "Click to fill this row"
            case .column:
                "Click to fill this column"
            case .diagonal:
                "Click to fill diagonal values"
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
        
        layer.borderColor = .white
        
        switch fillTarget {
        case .row(let color), .column(let color):
            layer.backgroundColor = color.nsColor.cgColor
            lineLayer.isHidden = true
        case .diagonal:
            layer.backgroundColor = .black
            
            let path = NSBezierPath()
            path.move(to: .init(x: bounds.width, y: 0))
            path.line(to: .init(x: 0, y: bounds.height))
            lineLayer.path = path.cgPath
            lineLayer.isHidden = false
        }
    }
    
    override func menu(for event: NSEvent) -> NSMenu? {
        let menu = NSMenu()
        for step in [0, -maxStep, maxStep] {
            let item = NSMenuItem(title: "Fill \(valueFormatter(step))", action: #selector(menuItemClicked), keyEquivalent: "")
            item.tag = step
            menu.addItem(item)
        }
        return menu
    }
    
    @objc func menuItemClicked(sender: NSMenuItem) {
        delegate?.attractionMatrixHeaderViewOnClickFillMenu(self, step: sender.tag)
    }
    
    override func mouseDown(with event: NSEvent) {
        let menu = menu(for: event)!
        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }
    
    override func mouseEntered(with event: NSEvent) {
        layer?.borderWidth = 3
    }
    
    override func mouseExited(with event: NSEvent) {
        layer?.borderWidth = 0
    }
}

protocol AttractionMatrixHeaderViewDelegate {
    func attractionMatrixHeaderViewOnClickFillMenu(_ view: AttractionMatrixHeaderView, step: Int)
}
