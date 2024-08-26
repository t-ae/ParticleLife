import Foundation

enum AttractionPreset: String, OptionConvertible {
    case zero = "Zero fill"
    case identity = "Identity"
    case exclusive = "Exclusive"
    case chain = "Chain"
    case snake = "Snake"
    case area = "Area"
}

extension AttractionPreset {
    func steps(colorCount: Int) -> Matrix<Int> {
        switch self {
        case .zero:
            return .colorMatrix(filledWith: 0)
        case .identity:
            var matrix = Matrix<Int>.colorMatrix(filledWith: 0)
            for i in 0..<matrix.rows {
                matrix[i, i] = 10
            }
            return matrix
        case .exclusive:
            var matrix = Matrix<Int>.colorMatrix(filledWith: -10)
            for i in 0..<matrix.rows {
                matrix[i, i] = 10
            }
            return matrix
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
            return matrix
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
            return matrix
        case .area:
            var matrix = Matrix<Int>.colorMatrix(filledWith: 0)
            for i in 0..<matrix.rows {
                matrix[i, i] = 1
            }
            return matrix
        }
    }
}
