import Foundation
import Cocoa

class AttractionMatrixView: NSView {
    var delegate: AttractionMatrixViewDelegate?
    
    var colorCount: Int = Color.allCases.count {
        didSet {
            needsLayout = true
        }
    }
    
    var gap: CGFloat = 4 {
        didSet {
            needsLayout = true
        }
    }
    
    private var views: [AttractionMatrixChildView]!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    func setup() {
        var views: [AttractionMatrixChildView] = []
        // Header
        do {
            let view = AttractionMatrixHeaderView()
            view.fillTarget = .diagonal
            view.delegate = self
            views.append(view)
        }
        for color in Color.allCases {
            let view = AttractionMatrixHeaderView()
            view.fillTarget = .column(color)
            view.delegate = self
            views.append(view)
            
        }
        // Rows
        for row in Color.allCases {
            let view = AttractionMatrixHeaderView()
            view.fillTarget = .row(row)
            view.delegate = self
            views.append(view)
            
            for column in Color.allCases {
                let cell = AttractionMatrixValueView()
                cell.delegate = self
                cell.toolTip = "\(row)→\(column) attraction"
                views.append(cell)
            }
        }
        
        for view in views {
            self.addSubview(view)
        }
        
        self.views = views
    }
    
    func setMaxStep(_ maxStep: Int) {
        views.forEach { $0.maxStep = maxStep }
    }
    
    func setValueFormatter(_ formatter: @escaping (Int)->String) {
        views.forEach { $0.valueFormatter = formatter }
    }
    
    var attractionMatrixCells: [AttractionMatrixValueView] {
        views.compactMap { $0 as? AttractionMatrixValueView }
    }
    
    var steps: Matrix<Int> {
        get {
            .init(rows: Color.allCases.count, cols: Color.allCases.count, elements: attractionMatrixCells.map { $0.step })
        }
        set {
            for (cell, step) in zip(attractionMatrixCells, newValue.elements) {
                cell.setStep(step)
            }
        }
    }
    
    override func layout() {
        let w = (bounds.width - CGFloat(colorCount)*gap) / CGFloat(colorCount+1)
        let h = (bounds.height - CGFloat(colorCount)*gap) / CGFloat(colorCount+1)
        
        let c = Color.allCases.count + 1
        
        for row in 0..<c {
            for column in 0..<c {
                let view = views[row*c + column]
                view.frame = CGRect(
                    x: CGFloat(column)*(w+gap),
                    y: bounds.height - h - CGFloat(row)*(h+gap),
                    width: w,
                    height: h
                )
                view.isHidden = row > colorCount || column > colorCount
                view.needsDisplay = true
            }
        }
        
        layoutSubtreeIfNeeded()
    }
}

protocol AttractionMatrixViewDelegate {
    func attractionMatrixViewOnChangeAttractionSteps(_ steps: Matrix<Int>)
    func attractionMatrixValueViewUpdateLine(_ update: AttractionLineUpdate, step: Int)
}

extension AttractionMatrixView: AttractionMatrixHeaderViewDelegate {
    func attractionMatrixHeaderViewOnClickFillMenu(_ view: AttractionMatrixHeaderView, step: Int) {
        delegate?.attractionMatrixValueViewUpdateLine(view.fillTarget, step: step)
    }
}

extension AttractionMatrixView: AttractionMatrixValueViewDelegate {
    func attractionMatrixValueViewOnUpdateValue() {
        delegate?.attractionMatrixViewOnChangeAttractionSteps(steps)
    }
}

class AttractionMatrixChildView: NSControl {
    var maxStep: Int = 10 {
        didSet {
            needsLayout = true
        }
    }
    
    var valueFormatter: (Int)->String = { "\($0)" }
}
