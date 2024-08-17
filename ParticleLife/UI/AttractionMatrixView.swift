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
    
    var attraction: Attraction {
        .init(matrix: attractionMatrixCells.map { $0.attractionValue })
    }
    
    func setSteps(_ steps: [Int]) {
        for (cell, step) in zip(attractionMatrixCells, steps) {
            cell.setStep(step)
        }
    }
    
    func updateAttraction(update: AttractionUpdate) {
        let count = Color.allCases.count * Color.allCases.count
        
        switch update {
        case .randomize:
            setSteps((0..<count).map { _ in Int.random(in: -10...10) })
        case .symmetricRandom:
            var matrix = [Int](repeating: 0, count: count)
            for i in 0..<Color.allCases.count {
                for j in i..<Color.allCases.count {
                    let v = Int.random(in: -10...10)
                    matrix[i*Color.allCases.count + j] = v
                    matrix[j*Color.allCases.count + i] = v
                }
            }
            setSteps(matrix)
        case .invert:
            let matrix = attractionMatrixCells.map { -$0.step }
            setSteps(matrix)
        case .zeroToOne:
            let matrix = attractionMatrixCells.map { $0.step == 0 ? 10 : $0.step }
            setSteps(matrix)
        case .zeroToMinusOne:
            let matrix = attractionMatrixCells.map { $0.step == 0 ? -10 : $0.step }
            setSteps(matrix)
        }
    }
    
    func setAttraction(preset: AttractionPreset) {
        let count = Color.allCases.count * Color.allCases.count
        
        switch preset {
        case .zero:
            setSteps(.init(repeating: 0, count: count))
        case .identity:
            var matrix = [Int](repeating: 0, count: count)
            for i in 0..<Color.allCases.count {
                matrix[i*Color.allCases.count + i] = 10
            }
            setSteps(matrix)
        case .exclusive:
            var matrix = [Int](repeating: -10, count: count)
            for i in 0..<Color.allCases.count {
                matrix[i*Color.allCases.count + i] = 10
            }
            setSteps(matrix)
        case .chain:
            var matrix = [Int](repeating: 0, count: count)
            for i in 0..<colorCount {
                let prev = (i - 1 + colorCount) % colorCount
                let next = (i + 1) % colorCount
                for j in 0..<colorCount {
                    matrix[i*Color.allCases.count + j] = i == j ? 10 :
                    j == prev || j == next ? 2 :
                    -10
                }
            }
            setSteps(matrix)
        case .snake:
            var matrix = [Int](repeating: 0, count: count)
            for i in 0..<colorCount {
                let next = (i + 1) % colorCount
                for j in 0..<colorCount {
                    matrix[i*Color.allCases.count + j] = i == j ? 10 :
                    j == next ? 2 :
                    0
                }
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
    func attractionMatrixViewOnChangeAttraction(_ attraction: Attraction)
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
    case invert = "Invert"
    case zeroToOne = "Zero to one"
    case zeroToMinusOne = "Zero to minus one"
}

enum AttractionPreset: String, CaseIterable {
    case zero = "Zero fill"
    case identity = "Identity"
    case exclusive = "Exclusive"
    case chain = "Chain"
    case snake = "Snake"
}
