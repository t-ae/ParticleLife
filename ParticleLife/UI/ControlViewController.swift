import Foundation
import Cocoa
import Combine

class ControlViewController: NSViewController {
    var viewModel: ViewModel!
    private var cancellables = Set<AnyCancellable>()
    
    @IBOutlet var colorCountButton: NSPopUpButton!
    @IBOutlet var particleCountField: NSTextField!
    @IBOutlet var particleGeneratorTypeButton: NSPopUpButton!
    @IBOutlet var fixSeedsCheck: NSButton!
    
    @IBOutlet var attractionMatrixView: AttractionMatrixView!
    @IBOutlet var attractionAutoUpdateSwitch: NSButton!
    @IBOutlet var attractionMatrixUpdateButton: NSComboButton!
    @IBOutlet var attractionMatrixPresetButton: NSComboButton!
    
    @IBOutlet var forceFunctionButton: NSPopUpButton!
    @IBOutlet var distanceFunctionButton: NSPopUpButton!
    @IBOutlet var rmaxButton: NSPopUpButton!
    @IBOutlet var velocityHalfLifeButton: NSPopUpButton!
    @IBOutlet var forceFactorSlider: NSSlider!
    
    @IBOutlet var preferredFPSButton: NSPopUpButton!
    @IBOutlet var fixDtCheck: NSButton!
    @IBOutlet var particleSizeSlider: NSSlider!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
    }
    
    func bindViewModel() {
        // Particle setting
        colorCountButton.removeAllItems()
        colorCountButton.addItems(withTitles: (1...Color.allCases.count).map(String.init))
        viewModel.$colorCountToUse.sink {
            self.colorCountButton.selectItem(by: "\($0)")
        }.store(in: &cancellables)
        
        viewModel.$particleCountString.sink {
            self.particleCountField.stringValue = $0
        }.store(in: &cancellables)
        
        particleGeneratorTypeButton.removeAllItems()
        particleGeneratorTypeButton.addItems(withTitles: ParticleGeneratorType.allCases.map { $0.rawValue })
        viewModel.$particleGenerator.sink {
            self.particleGeneratorTypeButton.selectItem(by: $0.rawValue)
        }.store(in: &cancellables)
        
        viewModel.$fixSeeds.sink {
            self.fixSeedsCheck.state = $0 ? .on : .off
        }.store(in: &cancellables)
        
        // Attraction
        attractionMatrixView.setMaxStep(viewModel.attractionMaxStep)
        attractionMatrixView.setValueFormatter(viewModel.attractionValueFormatter)
        attractionMatrixView.delegate = self
        viewModel.$attractionSteps.sink {
            self.attractionMatrixView.setSteps($0)
        }.store(in: &cancellables)
        
        viewModel.$autoUpdateAttraction.sink {
            self.onChangeAttractionAutoUpdate($0)
        }.store(in: &cancellables)
        
        attractionMatrixUpdateButton.menu.setItems(AttractionUpdate.allCases, action: #selector(onClickAttractionUpdateItem))
        attractionMatrixPresetButton.menu.setItems(AttractionPreset.allCases, action: #selector(onClickAttractionPresetItem))
        
        // Velocity update rule
        forceFunctionButton.setItems(ForceFunction.allCases)
        viewModel.$forceFunction.sink {
            self.forceFunctionButton.selectItem($0)
        }.store(in: &cancellables)
        
        distanceFunctionButton.setItems(DistanceFunction.allCases)
        viewModel.$distanceFunction.sink {
            self.distanceFunctionButton.selectItem($0)
        }.store(in: &cancellables)
        
        rmaxButton.setItems(Rmax.allCases)
        viewModel.$rmax.sink {
            self.rmaxButton.selectItem($0)
        }.store(in: &cancellables)
        
        velocityHalfLifeButton.setItems(VelocityHalfLife.allCases)
        viewModel.$velocityHalfLife.sink {
            self.velocityHalfLifeButton.selectItem($0)
        }.store(in: &cancellables)
        
        forceFactorSlider.minValue = Double(viewModel.forceFactorRange.lowerBound)
        forceFactorSlider.maxValue = Double(viewModel.forceFactorRange.upperBound)
        viewModel.$forceFactor.sink {
            self.forceFactorSlider.floatValue = $0
        }.store(in: &cancellables)
        
        // Other
        preferredFPSButton.removeAllItems()
        preferredFPSButton.addItems(withTitles: FPS.allCases.map { "\($0.rawValue)" })
        viewModel.$preferredFPS.sink {
            self.preferredFPSButton.selectItem(by: "\($0.rawValue)" )
        }.store(in: &cancellables)
        
        viewModel.$fixDt.sink {
            self.fixDtCheck.state = $0 ? .on : .off
        }.store(in: &cancellables)
        
        particleSizeSlider.minValue = Double(viewModel.particleSizeRange.lowerBound)
        particleSizeSlider.maxValue = Double(viewModel.particleSizeRange.upperBound)
        viewModel.$particleSize.sink {
            self.particleSizeSlider.floatValue = $0
        }.store(in: &cancellables)
    }
    
    // MARK: Particle setting
    @IBAction func onChangeColorsToUse(_ sender: NSPopUpButton) {
        guard let title = sender.titleOfSelectedItem, let count = Int(title) else {
            return
        }
        viewModel.colorCountToUse = count
    }
    
    @IBAction func onChangeParticleCount(_ sender: NSTextField) {
        viewModel.particleCountString = sender.stringValue
    }
    
    @IBAction func onChangeParticleGeneratorType(_ sender: NSPopUpButton) {
        guard let title = sender.titleOfSelectedItem, let type = ParticleGeneratorType(rawValue: title) else {
            return
        }
        viewModel.particleGenerator = type
    }
    
    @IBAction func onChangeFixSeeds(_ sender: NSButton) {
        viewModel.fixSeeds = sender.state == .on
    }
    
    @IBAction func onClickGenerateParticlesButton(_ sender: Any) {
        viewModel.particleCountString = particleCountField.stringValue // Assign latest value
        
        attractionMatrixView.colorCount = viewModel.colorCountToUse // Not updated until generate
        viewModel.generateParticles()
    }
    
    // MARK: Attracion
    
    @IBAction func onSwitchAttractionAutoUpdateButton(_ sender: NSButton) {
        viewModel.autoUpdateAttraction = sender.state == .on
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
                    viewModel.updateAttraction(.randomize)
                    try await Task.sleep(seconds: 30)
                }
            }
        } else {
            attractionAutoUpdateTask = nil
        }
    }
    
    
    @objc func onClickAttractionUpdateItem(_ sender: NSMenuItem) {
        viewModel.updateAttraction(sender.option()!)
    }
    
    @objc func onClickAttractionPresetItem(_ sender: NSMenuItem) {
        viewModel.setAttractionPreset(sender.option()!)
    }
    
    // MARK: Velocity update rule
    @IBAction func onChangeForceFunction(_ sender: NSPopUpButton) {
        viewModel.forceFunction = sender.selectedItem()!
    }
    @IBAction func onChangeDistanceFunction(_ sender: NSPopUpButton) {
        viewModel.distanceFunction = sender.selectedItem()!
    }
    @IBAction func onChangeRmax(_ sender: NSPopUpButton) {
        viewModel.rmax = sender.selectedItem()!
    }
    @IBAction func onChangeVelocityHalfLife(_ sender: NSPopUpButton) {
        viewModel.velocityHalfLife = sender.selectedItem()!
    }
    @IBAction func onChangeForceFactor(_ sender: NSSlider) {
        viewModel.forceFactor = sender.floatValue
    }
    
    @IBAction func onForceFuctionClickHelpButton(_ sender: Any) {
        let url = URL(string: "https://github.com/t-ae/ParticleLife/blob/main/readme.md#force-functions")!
        NSWorkspace.shared.open(url)
    }
    
    // MARK: Other
    @IBAction func onChangePreferredFPS(_ sender: NSPopUpButton) {
        viewModel.preferredFPS = sender.selectedItem()!
    }
    @IBAction func onChangeFixedDt(_ sender: NSButton) {
        viewModel.fixDt = sender.state == .on
    }
    @IBAction func onChangeParticleSizeSlider(_ sender: NSSlider) {
        viewModel.particleSize = sender.floatValue
    }
    
    // MARK: Control
    @IBAction func onClickPlayButton(_ sender: Any) {
        viewModel.isPaused = false
    }
    
    @IBAction func onClickPauseButton(_ sender: Any) {
        viewModel.isPaused = true
    }
}

extension ControlViewController: AttractionMatrixViewDelegate {
    func attractionMatrixViewOnChangeAttractionSteps(_ steps: Matrix<Int>) {
        viewModel.attractionSteps = steps
    }
}
