import Foundation

enum AttractionLineUpdate {
    case row(Color)
    case column(Color)
    case diagonal
}

extension AttractionLineUpdate {
    func apply(_ steps: inout Matrix<Int>, step: Int, colorCount: Int) {
        switch self {
        case .row(let color):
            for c in 0..<colorCount {
                steps[color.intValue, c] = step
            }
        case .column(let color):
            for r in 0..<colorCount {
                steps[r, color.intValue] = step
            }
        case .diagonal:
            for i in 0..<colorCount {
                steps[i, i] = step
            }
        }
    }
}
