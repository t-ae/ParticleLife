import Foundation
import Cocoa

class CommandViewController: NSViewController {
    @IBOutlet private var textView: NSTextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.string = """
        # Comment
        red 0 0 # Center
        green 1 0
        blue 0.5 0.5
        cyan 0 1
        magenta 1 1
        yellow -0.5 -0.5
        """
    }
    
    @IBAction func onClickGenerateButton(_ sender: Any) {
        do {
            let particles = try CommandParticleGenerator().generate(command: textView.string)
            viewModel.setParticlesEvent.send(particles)
        } catch {
            viewModel.errorNotifyEvent.send(error)
        }
    }
}

final class CommandParticleGenerator {
    func generate(command: String) throws -> [Particle] {
        var particles: [Particle] = []
        var errors: [Int: MessageError] = [:]
        
        let lines = command.components(separatedBy: .newlines)
        
        for (i, line) in lines.enumerated() {
            let lineNumber = i + 1
            
            do {
                if let particle = try processLine(line) {
                    particles.append(particle)
                }
            } catch let error as MessageError {
                errors[lineNumber] = error
            }
        }
        
        guard errors.isEmpty else {
            var messages = errors.keys.sorted().map {
                "Line \($0): \(errors[$0]!.message)"
            }
            if messages.count > 5 {
                messages = messages[..<5] + ["(\(messages.count-5) more errors)"]
            }
            
            throw MessageError(messages.joined(separator: "\n"))
        }
        
        return particles
    }
    
    func processLine(_ line: String) throws -> Particle? {
        let command = line.prefix { $0 != "#" }
        let comps = command.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        
        guard !comps.isEmpty else {
            return nil
        }
        
        guard comps.count == 3 else {
            throw MessageError("Invalid command: \(comps)")
        }
        
        let (colorString, xString, yString) = (comps[0], comps[1], comps[2])
        
        guard let color = Color(from: colorString) else {
            throw MessageError("Invalid color: \(colorString)")
        }
        guard let x = Float(xString) else {
            throw MessageError("Invalid x: \(xString)")
        }
        guard let y = Float(yString) else {
            throw MessageError("Invalid y: \(yString)")
        }
        
        return Particle(color: color, position: .init(x: x, y: y))
    }
}
