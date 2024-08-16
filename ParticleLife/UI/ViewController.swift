import Cocoa
import MetalKit

class ViewController: NSViewController {
    @IBOutlet var metalView: MTKView!
    private var renderer: Renderer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        doWithErrorNotify {
            try setupMetalView()
        }
    }

    func setupMetalView() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw MessageError("MTLCreateSystemDefaultDevice failed.")
        }
        
        metalView.isPaused = true
        metalView.device = device
        metalView.preferredFramesPerSecond = 60
        
        
        renderer = try Renderer(device: device, pixelFormat: metalView.colorPixelFormat)
        renderer.mtkView(metalView, drawableSizeWillChange: metalView.drawableSize)
        renderer.delegate = self
        
        metalView.delegate = renderer
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        openControlWindow()
        
        metalView.isPaused = false
    }
    
    override func viewWillDisappear() {
        metalView.isPaused = true
        controlWindow?.close()
        super.viewWillDisappear()
    }
    
    var controlWindow: NSWindowController?
    
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
}

extension ViewController: RendererDelegate {
    func rendererOnUpdateFPS(_ fps: Float) {
        self.view.window?.title = String(format: "Particle Life (%.1ffps)", fps)
    }
}

extension ViewController: ControlViewControllerDelegate {
    func controlViewControllerOnClickPlayButton() {
        renderer.isPaused = false
    }
    
    func controlViewControllerOnClickPauseButton() {
        renderer.isPaused = true
    }
    
    func controlViewControllerOnClose() {
        controlWindow = nil
    }
    
    func controlViewControllerGenerateParticles(generator: any ParticleGenerator) {
        doWithErrorNotify {
            try renderer.generateParticles(generator)
        }
    }
    
    func controlViewControllerOnChangeAttraction(_ attraction: Attraction) {
        renderer.attraction = attraction
    }
    
    func controlViewControllerUpdateVelocityUpdateSetting(_ setting: VelocityUpdateSetting) {
        renderer.velocityUpdateSetting = setting
    }
    
    func controlViewControllerOnChangeParticleSize(_ particleSize: Float) {
        renderer.particleSize = particleSize
    }
}
