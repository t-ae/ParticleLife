import Foundation
import Cocoa
import Combine

class ControlViewController: NSViewController {
    var viewModel: ViewModel!
    private var cancellables = Set<AnyCancellable>()
    
    @IBOutlet var colorCountButton: BindablePopUpButton!
    @IBOutlet var particleCountField: BindableTextField!
    @IBOutlet var particleGeneratorTypeButton: BindablePopUpButton!
    @IBOutlet var fixSeedsCheck: BindableButton!
    @IBOutlet var generateParticlesButton: BindableButton!
    
    @IBOutlet var attractionMatrixView: AttractionMatrixView!
    @IBOutlet var attractionAutoUpdateSwitch: BindableButton!
    @IBOutlet var attractionMatrixUpdateButton: BindableComboButton!
    @IBOutlet var attractionMatrixPresetButton: BindableComboButton!
    
    @IBOutlet var forceFunctionButton: BindablePopUpButton!
    @IBOutlet var forceFunctionHelpButton: BindableButton!
    @IBOutlet var distanceFunctionButton: BindablePopUpButton!
    @IBOutlet var rmaxButton: BindablePopUpButton!
    @IBOutlet var velocityHalfLifeButton: BindablePopUpButton!
    @IBOutlet var forceFactorSlider: BindableSlider!
    
    @IBOutlet var preferredFPSButton: BindablePopUpButton!
    @IBOutlet var fixDtCheck: BindableButton!
    @IBOutlet var particleSizeSlider: BindableSlider!
    
    @IBOutlet var playButton: BindableButton!
    @IBOutlet var pauseButton: BindableButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
    }
    
    func bindViewModel() {
        // MARK: Particle setting
        colorCountButton.bind(viewModel.$colorCountToUse, options: [Int](1...Color.allCases.count)) {
            self.viewModel.colorCountToUse = $0
        }.store(in: &cancellables)
        
        viewModel.renderingParticleCountUpdate.map(String.init).assign(to: &viewModel.$particleCountString)
        particleCountField.bind(viewModel.$particleCountString) {
            self.viewModel.particleCountString = $0
        }.store(in: &cancellables)
        
        particleGeneratorTypeButton.bind(viewModel.$particleGeneratorType) {
            self.viewModel.particleGeneratorType = $0
        }.store(in: &cancellables)
        
        fixSeedsCheck.bind(viewModel.$fixSeeds) {
            self.viewModel.fixSeeds = $0
        }.store(in: &cancellables)
        
        generateParticlesButton.bind { _ in
            self.viewModel.particleCountString = self.particleCountField.stringValue  // Assign editing value
            self.viewModel.generateParticles.send(())
        }
        
        // MARK: Attraction
        attractionMatrixView.setMaxStep(viewModel.attractionMaxStep)
        attractionMatrixView.setValueFormatter(viewModel.attractionValueFormatter)
        attractionMatrixView.delegate = self
        viewModel.$renderingColorCount.sink {
            self.attractionMatrixView.colorCount = $0
        }.store(in: &cancellables)
        viewModel.$attractionSteps.sink {
            self.attractionMatrixView.setSteps($0)
        }.store(in: &cancellables)
        
        attractionAutoUpdateSwitch.bind(viewModel.$autoUpdateAttractionMatrix) {
            self.viewModel.autoUpdateAttractionMatrix = $0
        }.store(in: &cancellables)
        viewModel.$autoUpdateAttractionMatrix.sink {
            self.onChangeAttractionAutoUpdate($0)
        }.store(in: &cancellables)
        
        attractionMatrixUpdateButton.bindMenu(AttractionUpdate.self) {
            self.viewModel.updateAttractionMatrix($0)
        }
        attractionMatrixPresetButton.bindMenu(AttractionPreset.self) {
            self.viewModel.setAttractionMatrixPreset($0)
        }
        
        // MARK: Velocity update rule
        forceFunctionButton.bind(viewModel.$forceFunction) {
            self.viewModel.forceFunction = $0
        }.store(in: &cancellables)
        
        forceFunctionHelpButton.bind { _ in
            let url = URL(string: "https://github.com/t-ae/ParticleLife/blob/main/readme.md#force-functions")!
            NSWorkspace.shared.open(url)
        }
        
        distanceFunctionButton.bind(viewModel.$distanceFunction) {
            self.viewModel.distanceFunction = $0
        }.store(in: &cancellables)
        
        rmaxButton.bind(viewModel.$rmax) {
            self.viewModel.rmax = $0
        }.store(in: &cancellables)
        
        velocityHalfLifeButton.bind(viewModel.$velocityHalfLife) {
            self.viewModel.velocityHalfLife = $0
        }.store(in: &cancellables)
        
        forceFactorSlider.bind(viewModel.$forceFactor, range: viewModel.forceFactorRange) {
            self.viewModel.forceFactor = $0
        }.store(in: &cancellables)
        viewModel.$forceFactor.sink {
            self.forceFactorSlider.toolTip = String(format: "%.2f", $0)
        }.store(in: &cancellables)
        
        // MARK: Other
        preferredFPSButton.bind(viewModel.$preferredFPS) {
            self.viewModel.preferredFPS = $0
        }.store(in: &cancellables)
        
        fixDtCheck.bind(viewModel.$fixDt) {
            self.viewModel.fixDt = $0
        }.store(in: &cancellables)
        
        particleSizeSlider.bind(viewModel.$particleSize, range: viewModel.particleSizeRange) {
            self.viewModel.particleSize = $0
        }.store(in: &cancellables)
        viewModel.$particleSize.sink {
            self.particleSizeSlider.toolTip = String(format: "%.2f", $0)
        }.store(in: &cancellables)
        
        // MARK: Control
        playButton.bind { _ in
            self.viewModel.isPaused = false
        }
        pauseButton.bind { _ in
            self.viewModel.isPaused = true
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        becomeFirstResponder()
    }
    
    private var attractionAutoUpdateTask: Task<Void, Error>? = nil
    func onChangeAttractionAutoUpdate(_ on: Bool) {
        print("onSwitchAttractionAutoUpdateButton: \(on)")
        
        attractionAutoUpdateSwitch.state = on ? .on : .off
        
        attractionAutoUpdateTask?.cancel()
        if on {
            attractionAutoUpdateTask = Task {
                while true {
                    print("Auto randomize attraction")
                    viewModel.updateAttractionMatrix(.randomize)
                    try await Task.sleep(seconds: 30)
                }
            }
        } else {
            attractionAutoUpdateTask = nil
        }
    }
}

extension ControlViewController: AttractionMatrixViewDelegate {
    func attractionMatrixViewOnChangeAttractionSteps(_ steps: Matrix<Int>) {
        viewModel.attractionSteps = steps
    }
    
    func attractionMatrixValueViewUpdateLine(_ update: AttractionLineUpdate, step: Int) {
        viewModel.updateAttractionMatrixLine(update, step: step)
    }
}
