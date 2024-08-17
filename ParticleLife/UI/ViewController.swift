import Cocoa
import MetalKit

class ViewController: NSViewController {
    @IBOutlet var metalView: MTKView!
    private var renderer: Renderer!

    override func viewWillAppear() {
        super.viewWillAppear()
        doWithErrorTerminate {
            try setupMetalView()
        }
        openControlWindow()
        
        metalView.isPaused = false
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        // Enable keyboard shortcuts
        view.window?.makeFirstResponder(self)
    }
    
    override func viewWillDisappear() {
        metalView.isPaused = true
        controlWindow?.close()
        super.viewWillDisappear()
    }
    
    func setupMetalView() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw MessageError("MTLCreateSystemDefaultDevice failed.")
        }
        
        metalView.device = device
        metalView.preferredFramesPerSecond = 60
        
        renderer = try Renderer(device: device, pixelFormat: metalView.colorPixelFormat)
        renderer.mtkView(metalView, drawableSizeWillChange: metalView.drawableSize)
        renderer.delegate = self
        
        metalView.delegate = renderer
    }
    
    private var controlWindow: NSWindowController?
    
    func openControlWindow() {
        guard controlWindow == nil else {
            return
        }
        
        let window = (storyboard!.instantiateController(withIdentifier: "ControlWindowController") as! NSWindowController)
        self.controlWindow = window
        let vc = controlWindow?.contentViewController as! ControlViewController
        vc.delegate = self
        window.showWindow(nil)
        window.window?.styleMask.remove(.closable)
    }
    
    override func mouseUp(with event: NSEvent) {
        switch event.clickCount {
        case 2:
            // Reset
            renderer.renderingRect = .init(x: 0, y: 0, width: 1, height: 1)
        default:
            break
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        renderer.renderingRect.x -= Float(event.deltaX / metalView.bounds.width) * renderer.renderingRect.width
        renderer.renderingRect.y += Float(event.deltaY / metalView.bounds.height) * renderer.renderingRect.height
    }
    
    override func magnify(with event: NSEvent) {
        let factor = Float(event.magnification) + 1
        var size = renderer.renderingRect.width / factor
        size = min(max(size, 0.2), 2)
        let center = renderer.renderingRect.center
        renderer.renderingRect = .init(centerX: center.x, centerY: center.y, width: size, height: size)
    }
    
    override func scrollWheel(with event: NSEvent) {
        renderer.renderingRect.x -= Float(event.scrollingDeltaX) / Float(metalView.bounds.width) * renderer.renderingRect.width
        renderer.renderingRect.y += Float(event.scrollingDeltaY) / Float(metalView.bounds.height) * renderer.renderingRect.height
    }
    
    override func keyDown(with event: NSEvent) {
        switch event.characters {
        case "p":
            renderer.dumpParameters()
        case "s":
            renderer.dumpStatistics()
        case "i":
            renderer.induceInvalid()
        default:
            break
        }
    }
}

extension ViewController {
    func doWithErrorNotify(_ f: () throws -> Void) {
        do {
            try f()
        } catch let error as MessageError {
            let alert = NSAlert()
            alert.messageText = error.message
            alert.runModal()
        } catch {
            let alert = NSAlert(error: error)
            alert.runModal()
        }
    }
    
    func doWithErrorTerminate(_ f: () throws -> Void) {
        do {
            try f()
        } catch let error as MessageError {
            let alert = NSAlert()
            alert.messageText = error.message
            alert.runModal()
            NSApplication.shared.terminate(self)
        } catch {
            let alert = NSAlert(error: error)
            alert.runModal()
            NSApplication.shared.terminate(self)
        }
    }
}

extension ViewController: RendererDelegate {
    func rendererOnUpdateFPS(_ fps: Float) {
        self.view.window?.title = String(format: "Particle Life (%.1ffps)", fps)
    }
}

extension ViewController: ControlViewControllerDelegate {
    func controlViewControllerGenerateParticles(generator: any ParticleGenerator) {
        print("generate:", generator)
        doWithErrorNotify {
            try renderer.generateParticles(generator)
        }
    }
    
    func controlViewControllerOnChangeAttraction(_ attraction: Matrix<Float>) {
        renderer.attraction = attraction
    }
    
    func controlViewControllerUpdateVelocityUpdateSetting(_ setting: VelocityUpdateSetting) {
        renderer.velocityUpdateSetting = setting
    }
    
    func controlViewControllerOnChangePreferredFPS(_ preferredFPS: Int) {
        metalView.preferredFramesPerSecond = preferredFPS
    }
    
    func controlViewControllerOnChangeFixedDt(_ fixedDt: Bool) {
        renderer.fixedDt = fixedDt
    }
    
    func controlViewControllerOnChangeParticleSize(_ particleSize: Float) {
        renderer.particleSize = particleSize
    }
    
    func controlViewControllerOnClickPlayButton() {
        renderer.isPaused = false
    }
    
    func controlViewControllerOnClickPauseButton() {
        renderer.isPaused = true
    }
}
