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
    func apply(_ steps: inout Matrix<Int>, maxStep: Int, colorCount: Int) {
        switch self {
        case .randomize:
            for i in 0..<colorCount {
                for j in 0..<colorCount {
                    steps[i, j] = .random(in: -maxStep...maxStep)
                }
            }
        case .symmetricRandom:
            for i in 0..<colorCount {
                for j in i..<colorCount {
                    let v = Int.random(in: -maxStep...maxStep)
                    steps[i, j] = v
                    steps[j, i] = v
                }
            }
        case .negate:
            steps.modifyElements { _, value in -value }
        case .transpose:
            steps.transpose()
        case .zeroToOne:
            steps.modifyElements { _, value in value == 0 ? maxStep : value }
        case .zeroToMinusOne:
            steps.modifyElements { _, value in value == 0 ? -maxStep : value }
        }
    }
}
