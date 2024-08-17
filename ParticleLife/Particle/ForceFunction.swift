import Foundation

extension ForceFunction: LosslessStringConvertible {
    public var description: String {
        switch self {
        case ForceFunction_force1: "force1"
        case ForceFunction_force2: "force2"
        case ForceFunction_force3: "force3"
        default: fatalError("Invalid case: \(self)")
        }
    }
    
    public init?(_ description: String) {
        guard let ff = ForceFunction.allCases.first(where: { $0.description == description }) else {
            return nil
        }
        self = ff
    }
}

extension ForceFunction: CaseIterable {
    public static var allCases: [ForceFunction] {
        [
            ForceFunction_force1,
            ForceFunction_force2,
            ForceFunction_force3,
        ]
    }
}
