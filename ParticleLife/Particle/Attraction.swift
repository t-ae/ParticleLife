import Foundation

struct Attraction {
    private(set) var matrix: [Float]
    
    init(matrix: [Float]) {
        assert(matrix.count == Color.allCases.count*Color.allCases.count)
        self.matrix = matrix
    }
    
    init() {
        self.init(matrix: .init(repeating: 0, count: Color.allCases.count*Color.allCases.count))
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
        var strs = [String]()
        for i in 0..<Color.allCases.count {
            var line = ""
            for j in 0..<Color.allCases.count {
                line += String(format: "%2.2f ", matrix[i*Color.allCases.count + j])
            }
            strs.append(line)
        }
        return strs.joined(separator: "\n")
    }
}
