import Foundation

struct Attraction {
    private(set) var matrix: [Float]
    
    init(matrix: [Float]) {
        assert(matrix.count == Color.allCases.count*Color.allCases.count)
        self.matrix = matrix
    }
    
    init() {
        self.init(matrix: [
            0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0,
        ])
    }
    
    subscript(for target: Color, to to: Color) -> Float {
        get {
            matrix[Int(target.rawValue) * Color.allCases.count + Int(to.rawValue)]
        }
        set {
            matrix[Int(target.rawValue) * Color.allCases.count + Int(to.rawValue)] = newValue
        }
    }
}

extension Attraction: CustomStringConvertible {
    var description: String {
        var str = ""
        for i in 0..<Color.allCases.count {
            for j in 0..<Color.allCases.count {
                str += String(format: "%2.2f ", matrix[i*Color.allCases.count + j])
            }
            str += "\n"
        }
        return str
    }
}

extension Attraction {
    static var exclusive: Attraction {
        .init(matrix: [
            1, -1, -1, -1, -1, -1,
            -1, 1, -1, -1, -1, -1,
            -1, -1, 1, -1, -1, -1,
            -1, -1, -1, 1, -1, -1,
            -1, -1, -1, -1, 1, -1,
            -1, -1, -1, -1, -1, 1,
        ])
    }
    
    static var snake: Attraction {
        var attraction = Attraction()
        
        for color in Color.allCases {
            attraction[for: color, to: color] = 0.6
            attraction[for: color, to: color.next] = 0.1
        }
        
        return attraction
    }
    
    static var chain: Attraction {
        var attraction = Attraction()
        
        for color in Color.allCases {
            attraction[for: color, to: color.next(0)] = 1
            attraction[for: color, to: color.next(1)] = 0.2
            attraction[for: color, to: color.next(2)] = -1
            attraction[for: color, to: color.next(3)] = -1
            attraction[for: color, to: color.next(4)] = -1
            attraction[for: color, to: color.next(5)] = 0.2
        }
        
        return attraction
    }
    
    static func random() -> Attraction {
        Attraction(matrix: (0..<36).map { _ in Float.random(in: -1..<1) })
    }
}
