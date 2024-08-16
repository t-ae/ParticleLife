import Foundation

struct Xorshift64: RandomNumberGenerator {
    var state: UInt64 = 202408161
    
    mutating func next() -> UInt64 {
        var x: UInt64 = UInt64(state);
        x = x ^ (x << 13)
        x = x ^ (x >> 17)
        x = x ^ (x << 5)
        state = x
        return x
    }
}
