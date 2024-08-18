import Foundation

struct Matrix<Element> {
    private(set) var rows: Int
    private(set) var cols: Int
    private(set) var elements: [Element]
    
    init(rows: Int, cols: Int, elements: [Element]) {
        assert(rows*cols == elements.count)
        self.rows = rows
        self.cols = cols
        self.elements = elements
    }
    
    init(rows: Int, cols: Int, filledWith element: Element) {
        self.init(rows: rows, cols: cols, elements: .init(repeating: element, count: rows*cols))
    }
    
    subscript(row: Int, col: Int) -> Element {
        get {
            elements[row*rows + col]
        }
        set {
            elements[row*rows + col] = newValue
        }
    }
    
    func indices() -> [(row: Int, col: Int)] {
        (0..<rows).flatMap { r in
            (0..<cols).map { (r, $0) }
        }
    }
    
    mutating func modifyElements(_ transform: ((Int, Int), Element)->Element) {
        for (r, c) in indices() {
            self[r, c] = transform((r, c), self[r, c])
        }
    }
}

extension Matrix {
    func stringify(elementFormat: String) -> String {
        var strs = [String]()
        for r in 0..<rows {
            var line = ""
            for c in 0..<cols {
                line += String(format: elementFormat, self[r, c] as! CVarArg) + " "
            }
            strs.append(line)
        }
        return strs.joined(separator: "\n")
    }
}
