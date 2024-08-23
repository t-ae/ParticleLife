import Cocoa
import MetalKit
import Combine

class ViewController: NSViewController {
    @IBOutlet var metalView: MTKView!
    @IBOutlet var coordinateView: CoordinateView!
    
    private var renderer: Renderer!

    private var cancellables = Set<AnyCancellable>()
    
    private var setupError: Error? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            let renderer = try setupMetal()
            self.renderer = renderer
            bindViewModel(renderer: renderer)
            openControlWindow()
        } catch {
            setupError = error
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        // Enable keyboard shortcuts
        view.window?.makeFirstResponder(self)
        view.window?.delegate = self
        
        if let setupError {
            appDelegate.showErrorAlert(setupError)
            NSApplication.shared.terminate(self)
        }
    }
    
    func setupMetal() throws -> Renderer {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw MessageError("MTLCreateSystemDefaultDevice failed.")
        }
        
        metalView.device = device
        metalView.preferredFramesPerSecond = 60
        
        let renderer = try Renderer(device: device, pixelFormat: metalView.colorPixelFormat)
        renderer.mtkView(metalView, drawableSizeWillChange: metalView.drawableSize)
        renderer.delegate = self
        
        metalView.delegate = renderer
        
        return renderer
    }
    
    func bindViewModel(renderer: Renderer) {
        let viewModel = self.viewModel
        
        renderer.particles.$count
            .subscribe(viewModel.renderingParticleCountUpdate)
            .store(in: &cancellables)
        renderer.particles.$colorCount
            .assign(to: &viewModel.$renderingColorCount)
        
        viewModel.generateEvent.sink { generator, particleCount, colorCount in
            do {
                try renderer.particles.generateParticles(by: generator, particleCount: particleCount, colorCount: colorCount)
            } catch {
                viewModel.errorNotifyEvent.send(error)
            }
        }.store(in: &cancellables)
        
        viewModel.attractionMatrix.assign(to: &renderer.$attractionMatrix)
        viewModel.velocityUpdateSetting.assign(to: &renderer.$velocityUpdateSetting)
         
        viewModel.$preferredFPS
            .map { $0.rawValue }
            .assign(to: \.preferredFramesPerSecond, on: metalView)
            .store(in: &cancellables)
        
        viewModel.$fixDt.assign(to: &renderer.$fixedDt)
        viewModel.$particleSize.assign(to: &renderer.$particleSize)
        viewModel.$isPaused.assign(to: &renderer.$isPaused)
        viewModel.transform.assign(to: &renderer.$transform)
        
        viewModel.hideCoordinateView
            .assign(to: \.isHidden, on: coordinateView)
            .store(in: &cancellables)
    }
    
    func openControlWindow() {
        let vc = (storyboard!.instantiateController(withIdentifier: "ControlViewController") as! ControlViewController)
        let window = NSWindow(contentViewController: vc)
        window.title = "Particle Life - Control"
        window.styleMask.remove(.closable)
        let wc = NSWindowController(window: window)
        wc.showWindow(self)
        window.orderFrontRegardless()
    }
    
    override func mouseUp(with event: NSEvent) {
        switch event.clickCount {
        case 1:
            let location0 = metalView.convert(event.locationInWindow, from: nil)
            let location1 = SIMD2<Float>(
                Float(location0.x / metalView.bounds.width) * 2 - 1,
                Float(location0.y / metalView.bounds.height) * 2 - 1
            )
            print("Clicked point:", location1 / viewModel.zoom + viewModel.center)
        case 2:
            viewModel.resetTransform()
        default:
            break
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        var center = viewModel.center
        center.x -= 2 * Float(event.deltaX / metalView.bounds.width) / viewModel.zoom
        center.y += 2 * Float(event.deltaY / metalView.bounds.height) / viewModel.zoom
        viewModel.center = center
    }
    
    override func magnify(with event: NSEvent) {
        let factor = Float(event.magnification) + 1
        viewModel.zoom(factor: factor)
    }
    
    override func scrollWheel(with event: NSEvent) {
        if event.modifierFlags.contains(.shift) {
            let factor = exp2(-event.scrollingDeltaY / 100)
            viewModel.zoom(factor: Float(factor))
        } else {
            var center = viewModel.center
            center.x -= 2 * Float(event.scrollingDeltaX) / Float(metalView.bounds.width) / viewModel.zoom
            center.y += 2 * Float(event.scrollingDeltaY) / Float(metalView.bounds.height) / viewModel.zoom
            viewModel.center = center
        }
    }
    
    override func keyDown(with event: NSEvent) {
        let command = event.modifierFlags.contains(.command)
        switch (event.characters, command) {
        case (" ", _):
            viewModel.isPaused.toggle()
        case ("a", true):
            viewModel.autoUpdateAttractionMatrix.toggle()
        case ("r", true):
            viewModel.updateAttractionMatrix(.randomize)
        case ("p", true):
            let content = renderer.dumpParameters()
            appDelegate.openDumpModal(title: "Parameters", content: content)
        case ("s", true):
            let content = renderer.dumpStatistics()
            appDelegate.openDumpModal(title: "Statistics", content: content)
        default:
            break
        }
    }
}

extension ViewController: RendererDelegate {
    func renderer(_ renderer: Renderer, onUpdateFPS fps: Float) {
        self.view.window?.title = String(format: "Particle Life (%d particles / %.1ffps)", renderer.particles.count, fps)
    }
}

extension ViewController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        NSApplication.shared.terminate(nil)
    }
}
