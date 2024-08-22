import XCTest
@testable import ParticleLife

final class ParticleLifeTests: XCTestCase {

    func testXorshift() {
        var rng = Xorshift64()
    
        let floats = (0..<10000).map { _ in Float.random(in: 0..<1, using: &rng) }
        
        XCTAssertEqual(floats.reduce(0, +) / Float(floats.count), 0.5, accuracy: 1e-2)
    }
    
    func testWrap() {
        // wrap value into [-max, max) range.
        func wrap(value: Float, max: Float) -> Float {
            value - floor((value+max) / (2*max)) * (2*max);
        }
        
        let pairs1: [(input: Float, output: Float)] = [
            (-5, -1),
            (-4.7, -0.7),
            (-3.5, 0.5),
            (-3, -1),
            (0, 0),
            (0.3, 0.3),
            (1.0, -1.0),
            (1.1, -0.9),
            (1.8, -0.2),
        ]
         
        for (input, output) in pairs1 {
            let wrapped = wrap(value: input, max: 1)
            XCTAssertEqual(wrapped, output, accuracy: 1e-4)
        }
        
        let pairs3: [(input: Float, output: Float)] = [
            (-10, 2),
            (-5, 1),
            (-4.7, 1.3),
            (-3.5, 2.5),
            (-3, -3),
            (0, 0),
            (0.3, 0.3),
            (1.0, 1.0),
            (1.8, 1.8),
            (2.9, 2.9),
            (3.0, -3.0),
            (3.5, -2.5),
            (4.0, -2.0),
        ]
         
        for (input, output) in pairs3 {
            let wrapped = wrap(value: input, max: 3)
            XCTAssertEqual(wrapped, output, accuracy: 1e-4, "for input=\(input)")
        }
    }
}
