import Foundation

extension DistanceFunction: CaseIterable {
    static let `default` = DistanceFunction_l2
    
    public static let allCases: [DistanceFunction] = [
        DistanceFunction_l02,
        DistanceFunction_l05,
        DistanceFunction_l1,
        DistanceFunction_l2,
        DistanceFunction_linf,
        DistanceFunction_triangular,
        DistanceFunction_pentagonal,
    ]
}

extension DistanceFunction {
    /// The area inside distance==1 contour.
    var areaOfDistance1: Float {
        switch self {
        case DistanceFunction_l1:
            return 2
        case DistanceFunction_l2:
            return .pi
        case DistanceFunction_linf:
            return 4
        case DistanceFunction_l05:
            // https://www.wolframalpha.com/input?i=area+of+%28%7Cx%7C%5E0.5+%2B+%7Cy%7C%5E0.5%29%5E2+%3D+1
            return 2.0/3.0
        case DistanceFunction_l02:
            // area in the first quadrant = 1/252
            // https://www.wolframalpha.com/input?i=integral+y+%3D+%281-x%5E%281%2F5%29%29%5E5+for+x+in+0...1
            return 4.0/252
        case DistanceFunction_triangular:
            return 3 * sin(2 * .pi / 3) / 2
        case DistanceFunction_pentagonal:
            return 5 * sin(2 * .pi / 5) / 2
        default:
            // Undefined
            return .nan
        }
    }
}

extension DistanceFunction: OptionConvertible {
    public var description: String {
        switch self {
        case DistanceFunction_l1: "L1 norm"
        case DistanceFunction_l2: "L2 norm"
        case DistanceFunction_linf: "L∞ norm"
        case DistanceFunction_l02: "L0.2 norm"
        case DistanceFunction_l05: "L0.5 norm"
        case DistanceFunction_triangular: "Triangular"
        case DistanceFunction_pentagonal: "Pentagonal"
        default: fatalError("description is not defined for: \(self)")
        }
    }
}
