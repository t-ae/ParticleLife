import Foundation
import Cocoa
import Combine

class ControlViewController: NSViewController {
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
        let viewModel = self.viewModel
        
        // MARK: Particle setting
        colorCountButton.bind(&viewModel.$colorCountToUse, options: [Int](1...Color.allCases.count))
            .store(in: &cancellables)
        
        particleCountField.bind(&viewModel.$particleCountString)
            .store(in: &cancellables)
        
        particleGeneratorTypeButton.bind(&viewModel.$particleGeneratorType)
            .store(in: &cancellables)
        
        fixSeedsCheck.bind(&viewModel.$fixSeeds)
            .store(in: &cancellables)
        
        generateParticlesButton.bind { [particleCountField] in
            viewModel.particleCountString = particleCountField!.stringValue  // Assign editing value
            viewModel.generateParticles.send()
        }.store(in: &cancellables)
        
        // MARK: Attraction
        attractionMatrixView.setMaxStep(viewModel.attractionMaxStep)
        attractionMatrixView.setValueFormatter(viewModel.attractionValueFormatter)
        attractionMatrixView.delegate = self
        viewModel.$renderingColorCount
            .assign(to: \.colorCount, on: attractionMatrixView)
            .store(in: &cancellables)
        viewModel.$attractionSteps
            .assign(to: \.steps, on: attractionMatrixView)
            .store(in: &cancellables)
        
        attractionAutoUpdateSwitch.bind(&viewModel.$autoUpdateAttractionMatrix)
            .store(in: &cancellables)
        viewModel.$autoUpdateAttractionMatrix.sink {
            self.onChangeAttractionAutoUpdate($0)
        }.store(in: &cancellables)
        
        attractionMatrixUpdateButton.bindMenu(AttractionUpdate.self, onChoose: viewModel.updateAttractionMatrix)
        attractionMatrixPresetButton.bindMenu(AttractionPreset.self, onChoose: viewModel.setAttractionMatrixPreset)
        
        // MARK: Velocity update rule
        forceFunctionButton.bind(&viewModel.$forceFunction)
            .store(in: &cancellables)
        
        forceFunctionHelpButton.bind {
            let url = URL(string: "https://github.com/t-ae/ParticleLife/blob/main/readme.md#force-functions")!
            NSWorkspace.shared.open(url)
        }.store(in: &cancellables)
        
        distanceFunctionButton.bind(&viewModel.$distanceFunction)
            .store(in: &cancellables)
        
        rmaxButton.bind(&viewModel.$rmax)
            .store(in: &cancellables)
        
        velocityHalfLifeButton.bind(&viewModel.$velocityHalfLife)
            .store(in: &cancellables)
        
        forceFactorSlider.bind(&viewModel.$forceFactor, range: viewModel.forceFactorRange)
            .store(in: &cancellables)
        viewModel.$forceFactor
            .map { String(format: "%.2f", $0) }
            .assign(to: \.toolTip, on: forceFactorSlider)
            .store(in: &cancellables)
        
        // MARK: Other
        preferredFPSButton.bind(&viewModel.$preferredFPS)
            .store(in: &cancellables)
        
        fixDtCheck.bind(&viewModel.$fixDt)
            .store(in: &cancellables)
        
        particleSizeSlider.bind(&viewModel.$particleSize, range: viewModel.particleSizeRange)
            .store(in: &cancellables)
        viewModel.$particleSize
            .map { String(format: "%.2f", $0) }
            .assign(to: \.toolTip, on: particleSizeSlider)
            .store(in: &cancellables)
        
        // MARK: Control
        playButton.bind {
            viewModel.isPaused = false
        }.store(in: &cancellables)
        pauseButton.bind {
            viewModel.isPaused = true
        }.store(in: &cancellables)
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
