import Foundation

struct RingBuffer {
    private var storage: [Float]
    
    private(set) var head: Int = 0
    
    var count: Int {
        storage.count
    }
    
    init(count: Int, initialValue value: Float = 0) {
        storage = .init(repeating: value, count: count)
    }
    
    mutating func insert(_ value: Float) {
        storage[head] = value
        
        head += 1
        if head == count {
            head = 0
        }
    }
    
    mutating func fill(_ value: Float) {
        storage = .init(repeating: value, count: count)
    }
    
    func sum() -> Float {
        storage.reduce(0, +)
    }
    
    func average() -> Float {
        sum() / Float(count)
    }
}
