import Foundation

extension DistanceFunction: CaseIterable {
    static let `default` = DistanceFunction_l2
    
    public static let allCases: [DistanceFunction] = [
        DistanceFunction_l1,
        DistanceFunction_l2,
        DistanceFunction_linf,
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
        default: fatalError("description is not defined for: \(self)")
        }
    }
}
