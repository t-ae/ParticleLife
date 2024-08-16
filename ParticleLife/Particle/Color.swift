import Foundation
import Cocoa

enum Color: UInt32, CaseIterable {
    case red = 0
    case green
    case blue
    case cyan
    case magenta
    case yellow
}

extension Color {
    static let rgb: [SIMD3<Float>] = [
        .init(1, 0, 0),
        .init(0, 1, 0),
        .init(0, 0, 1),
        .init(0, 1, 1),
        .init(1, 0, 1),
        .init(1, 1, 0),
    ]
    
    var rgb: SIMD3<Float> {
        Color.rgb[Int(rawValue)]
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
}
