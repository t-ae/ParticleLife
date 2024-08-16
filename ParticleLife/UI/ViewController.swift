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
        
        metalView.addGestureRecognizer(NSMagnificationGestureRecognizer(target: self, action: #selector(magnify(_:))))
        let scr = NSPanGestureRecognizer(target: self, action: #selector(pan(_:)))
        metalView.addGestureRecognizer(scr)
        let clickGestureRecognizer = NSClickGestureRecognizer(target: self, action: #selector(doubleClick(_:)))
        clickGestureRecognizer.numberOfClicksRequired = 2
        metalView.addGestureRecognizer(clickGestureRecognizer)
        
        
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
    
    @objc func doubleClick(_ sender: NSClickGestureRecognizer) {
        renderer.renderingRect = .init(x: 0, y: 0, width: 1, height: 1)
    }
    
    @objc func pan(_ sender: NSPanGestureRecognizer) {
        let t = sender.translation(in: view)
        sender.setTranslation(.zero, in: nil)
        renderer.renderingRect.x -= Float(t.x / metalView.bounds.width) * renderer.renderingRect.width
        renderer.renderingRect.y -= Float(t.y / metalView.bounds.height) * renderer.renderingRect.height
    }
    
    @objc func magnify(_ sender: NSMagnificationGestureRecognizer) {
        let factor = Float(sender.magnification / 10) + 1
        var size = renderer.renderingRect.width / factor
        size = min(max(size, 0.2), 1)
        let center = renderer.renderingRect.center
        renderer.renderingRect = .init(centerX: center.x, centerY: center.y, width: size, height: size)
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
