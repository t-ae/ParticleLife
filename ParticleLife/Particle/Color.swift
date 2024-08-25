import Foundation
import Cocoa

enum Color: UInt32, CaseIterable, IntRepresentable {
    case red = 0
    case green
    case blue
    case cyan
    case magenta
    case yellow
}

extension Color {
    var rgb: SIMD3<Float> {
        switch self {
        case .red: .init(1, 0, 0)
        case .green: .init(0, 1, 0)
        case .blue: .init(0, 0, 1)
        case .cyan: .init(0, 1, 1)
        case .magenta: .init(1, 0, 1)
        case .yellow: .init(1, 1, 0)
        }
    }
    
    var nsColor: NSColor {
        NSColor(red: CGFloat(rgb.x), green: CGFloat(rgb.y), blue: CGFloat(rgb.z), alpha: 1)
    }
    
    var prev: Color {
        next(Color.allCases.count-1)
    }
    
    var next: Color {
        next(1)
    }
    
    func next(_ i: Int) -> Color {
        .init(rawValue: (rawValue + UInt32(i)) % UInt32(Color.allCases.count))!
    }
    
    init?(from string: String) {
        guard let color = Color.allCases.first(where: { "\($0)" == string }) else {
            return nil
        }
        self = color
    }
}

extension Matrix {
    static func colorMatrix(elements: [Element]) -> Matrix {
        return .init(rows: Color.allCases.count, cols: Color.allCases.count, elements: elements)
    }
    
    static func colorMatrix(filledWith element: Element) -> Matrix {
        return .init(rows: Color.allCases.count, cols: Color.allCases.count, filledWith: element)
    }
}
