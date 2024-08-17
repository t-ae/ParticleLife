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

extension DistanceFunction: LosslessStringConvertible {
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
    
    public init?(_ description: String) {
        guard let df = DistanceFunction.allCases.first(where: { $0.description == description }) else {
            return nil
        }
        self = df
    }
}
