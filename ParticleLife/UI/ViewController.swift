import Cocoa
import MetalKit
import Combine

class ViewController: NSViewController {
    @IBOutlet var metalView: MTKView!
    private var renderer: Renderer!

    let viewModel = ViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    var setupError: Error? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            try setupMetalView()
            bindViewModel()
            openControlWindow()
            metalView.isPaused = false
        } catch {
            setupError = error
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        // Enable keyboard shortcuts
        view.window?.makeFirstResponder(self)
        
        if let setupError {
            showErrorAlert(setupError)
            NSApplication.shared.terminate(self)
        }
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
    
    func bindViewModel() {
        viewModel.generateParticles = self.generateParticles
        
        viewModel.attraction.sink {
            self.renderer.attraction = $0
        }.store(in: &cancellables)
        
        viewModel.velocityUpdateSetting.sink {
            self.renderer.velocityUpdateSetting = $0
        }.store(in: &cancellables)
        
        viewModel.$preferredFPS.sink {
            self.metalView.preferredFramesPerSecond = $0.rawValue
        }.store(in: &cancellables)
        
        viewModel.$fixDt.sink {
            self.renderer.fixedDt = $0
        }.store(in: &cancellables)
        
        viewModel.$particleSize.sink {
            self.renderer.particleSize = $0
        }.store(in: &cancellables)
        
        viewModel.$isPaused.sink {
            self.renderer.isPaused = $0
        }.store(in: &cancellables)
    }
    
    private var controlWindow: NSWindowController?
    
    func openControlWindow() {
        guard controlWindow == nil else {
            return
        }
        
        let vc = (storyboard!.instantiateController(withIdentifier: "ControlViewController") as! ControlViewController)
        vc.viewModel = viewModel
        let window = NSWindow(contentViewController: vc)
        window.title = "Particle Life - Control"
        window.styleMask.remove(.closable)
        let wc = NSWindowController(window: window)
        wc.showWindow(self)
        controlWindow = wc
    }
    
    func generateParticles() {
        let particleCount = Int(viewModel.particleCountString) ?? -1
        let generator = viewModel.particleGenerator.generator.init(
            colorCountToUse: viewModel.colorCountToUse,
            particleCount: particleCount,
            fixed: viewModel.fixSeeds
        )
        do {
            try renderer.generateParticles(generator)
            viewModel.renderingColorCount = viewModel.colorCountToUse
        } catch {
            showErrorAlert(error)
        }
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
        case "a":
            viewModel.autoUpdateAttraction.toggle()
        case "r":
            viewModel.updateAttraction(.randomize)
        case "p":
            showDumpModal(title: "Parameters", content: renderer.dumpParameters())
        case "s":
            showDumpModal(title: "Statistics", content: renderer.dumpStatistics())
        case "i":
            renderer.induceInvalid()
        case " ":
            viewModel.isPaused.toggle()
        default:
            break
        }
    }
    
    func showDumpModal(title: String, content: String) {
        let vc = storyboard!.instantiateController(withIdentifier: "DumpViewController") as! DumpViewController
        vc.title = title
        vc.content = content
        presentAsModalWindow(vc)
    }
}

extension ViewController {
    func showErrorAlert(_ error: Error) {
        let alert: NSAlert
        if let error = error as? MessageError {
            alert = NSAlert()
            alert.messageText = error.message
        } else {
            alert = NSAlert(error: error)
        }
        alert.runModal()
    }
}

extension ViewController: RendererDelegate {
    func rendererOnUpdateFPS(_ fps: Float) {
        self.view.window?.title = String(format: "Particle Life (%.1ffps)", fps)
    }
}
