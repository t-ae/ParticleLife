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
    
    private var views: [NSView] = []
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    func setup() {
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
    }
    
    var attractionMatrixCells: [AttractionMatrixValueView] {
        views.compactMap { $0 as? AttractionMatrixValueView }
    }
    
    var attraction: Matrix<Float> {
        .init(rows: Color.allCases.count, cols: Color.allCases.count, elements: attractionMatrixCells.map { $0.attractionValue })
    }
    
    var steps: Matrix<Int> {
        .init(rows: Color.allCases.count, cols: Color.allCases.count, elements: attractionMatrixCells.map { $0.step })
    }
    
    func setSteps(_ steps: Matrix<Int>) {
        for (cell, step) in zip(attractionMatrixCells, steps.elements) {
            cell.setStep(step)
        }
    }
    
    func updateAttraction(update: AttractionUpdate) {
        var steps = steps
        
        switch update {
        case .randomize:
            steps.modifyElements { _, _  in .random(in: -10...10) }
        case .symmetricRandom:
            for i in 0..<Color.allCases.count {
                for j in i..<Color.allCases.count {
                    let v = Int.random(in: -10...10)
                    steps[i, j] = v
                    steps[j, i] = v
                }
            }
        case .negate:
            steps.modifyElements { _, value in -value }
        case .transpose:
            steps.transpose()
        case .zeroToOne:
            steps.modifyElements { _, value in value == 0 ? 10 : value }
        case .zeroToMinusOne:
            steps.modifyElements { _, value in value == 0 ? -10 : value }
        }
        
        setSteps(steps)
    }
    
    func setAttraction(preset: AttractionPreset) {
        switch preset {
        case .zero:
            setSteps(.colorMatrix(filledWith: 0))
        case .identity:
            var matrix = Matrix<Int>.colorMatrix(filledWith: 0)
            for i in 0..<matrix.rows {
                matrix[i, i] = 10
            }
            setSteps(matrix)
        case .exclusive:
            var matrix = Matrix<Int>.colorMatrix(filledWith: -10)
            for i in 0..<matrix.rows {
                matrix[i, i] = 10
            }
            setSteps(matrix)
        case .chain:
            var matrix = Matrix<Int>.colorMatrix(filledWith: 0)
            for i in 0..<colorCount {
                let prev = (i - 1 + colorCount) % colorCount
                let next = (i + 1) % colorCount
                for j in 0..<colorCount {
                    matrix[i, j] = i == j ? 10 :
                    j == prev || j == next ? 2 :
                    -10
                }
            }
            setSteps(matrix)
        case .snake:
            var matrix = Matrix<Int>.colorMatrix(filledWith: 0)
            for i in 0..<colorCount {
                let next = (i + 1) % colorCount
                for j in 0..<colorCount {
                    matrix[i, j] = i == j ? 10 :
                    j == next ? 2 :
                    0
                }
            }
            setSteps(matrix)
        case .region:
            var matrix = Matrix<Int>.colorMatrix(filledWith: 0)
            for i in 0..<matrix.rows {
                matrix[i, i] = 1
            }
            setSteps(matrix)
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
    func attractionMatrixViewOnChangeAttraction(_ attraction: Matrix<Float>)
}

extension AttractionMatrixView: AttractionMatrixHeaderViewDelegate {
    func attractionMatrixHeaderViewOnClickFillMenu(_ view: AttractionMatrixHeaderView, value: Int) {
        let cells = attractionMatrixCells
        switch view.fillTarget {
        case .row(let color):
            for i in 0..<colorCount {
                cells[color.intValue * Color.allCases.count + i].setStep(value*10)
            }
        case .column(let color):
            for i in 0..<colorCount {
                cells[i * Color.allCases.count + color.intValue].setStep(value*10)
            }
        case .diagonal:
            for i in 0..<colorCount {
                cells[i * Color.allCases.count + i].setStep(value*10)
            }
        }
    }
}

extension AttractionMatrixView: AttractionMatrixValueViewDelegate {
    func attractionMatrixValueViewOnUpdateValue() {
        delegate?.attractionMatrixViewOnChangeAttraction(attraction)
    }
}

enum AttractionUpdate: String, CaseIterable {
    case randomize = "Randomize"
    case symmetricRandom = "Symmetric random"
    case negate = "Negate"
    case transpose = "Transpose"
    case zeroToOne = "Zero to one"
    case zeroToMinusOne = "Zero to minus one"
}

enum AttractionPreset: String, CaseIterable {
    case zero = "Zero fill"
    case identity = "Identity"
    case exclusive = "Exclusive"
    case chain = "Chain"
    case snake = "Snake"
    case region = "Region"
}
