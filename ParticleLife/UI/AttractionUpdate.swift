import Foundation

enum AttractionUpdate: String, OptionConvertible {
    case randomize = "Randomize"
    case symmetricRandom = "Symmetric random"
    case negate = "Negate"
    case transpose = "Transpose"
    case zeroToOne = "Zero to one"
    case zeroToMinusOne = "Zero to minus one"
}

extension AttractionUpdate {
    func apply(_ steps: inout Matrix<Int>) {
        switch self {
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
    }
}
