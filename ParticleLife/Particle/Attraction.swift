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
            matrix[target.intValue * Color.allCases.count + to.intValue]
        }
        set {
            matrix[target.intValue * Color.allCases.count + to.intValue] = newValue
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
