import XCTest
@testable import ParticleLife

final class ParticleLifeTests: XCTestCase {

    func testXorshift() {
        var rng = Xorshift64()
    
        let floats = (0..<10000).map { _ in Float.random(in: 0..<1, using: &rng) }
        
        XCTAssertEqual(floats.reduce(0, +) / Float(floats.count), 0.5, accuracy: 1e-2)
    }
}
