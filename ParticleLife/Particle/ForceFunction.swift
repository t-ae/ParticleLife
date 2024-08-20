import Foundation

extension ForceFunction: CaseIterable {
    static let `default` = ForceFunction_force2
    
    public static let allCases: [ForceFunction] = [
        ForceFunction_force1,
        ForceFunction_force2,
        ForceFunction_force3,
    ]
}


extension ForceFunction: LabelConvertible {
    public var description: String {
        switch self {
        case ForceFunction_force1: "force1"
        case ForceFunction_force2: "force2"
        case ForceFunction_force3: "force3"
        default: fatalError("description is not defined for: \(self)")
        }
    }
}

