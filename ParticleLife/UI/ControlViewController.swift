import Foundation
import Cocoa

class ControlViewController: NSViewController {
    var delegate: ControlViewControllerDelegate?
    
    @IBOutlet var colorCountButton: NSPopUpButton!
    @IBOutlet var particleCountField: NSTextField!
    @IBOutlet var particleGeneratorTypeButton: NSPopUpButton!
    @IBOutlet var fixSeedsCheck: NSButton!
    
    @IBOutlet var attractionMatrixView: AttractionMatrixView!
    @IBOutlet var attractionMatrixUpdateButton: NSComboButton!
    @IBOutlet var attractionMatrixPresetButton: NSComboButton!
    
    @IBOutlet var forceFunctionButton: NSPopUpButton!
    @IBOutlet var distanceFunctionButton: NSPopUpButton!
    @IBOutlet var rmaxButton: NSPopUpButton!
    @IBOutlet var velocityHalfLifeButton: NSPopUpButton!
    @IBOutlet var forceFactorSlider: NSSlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        attractionMatrixView.delegate = self
        
        colorCountButton.removeAllItems()
        colorCountButton.addItems(withTitles: (1...Color.allCases.count).map(String.init))
        colorCountButton.selectItem(at: Color.allCases.count - 1)
        
        attractionMatrixUpdateButton.menu.removeAllItems()
        for attractionSetup in AttractionUpdate.allCases {
            attractionMatrixUpdateButton.menu.addItem(.init(title: attractionSetup.rawValue, action: #selector(onClickAttractionUpdateItem), keyEquivalent: ""))
        }
        
        attractionMatrixPresetButton.menu.removeAllItems()
        for attractionSetup in AttractionPreset.allCases {
            attractionMatrixPresetButton.menu.addItem(.init(title: attractionSetup.rawValue, action: #selector(onClickAttractionPresetItem), keyEquivalent: ""))
        }
        
        forceFunctionButton.removeAllItems()
        forceFunctionButton.addItems(withTitles: ForceFunction.allCases.map { $0.description })
        forceFunctionButton.selectItem(by: ForceFunction.default.description)
        
        distanceFunctionButton.removeAllItems()
        distanceFunctionButton.addItems(withTitles: DistanceFunction.allCases.map { $0.description })
        distanceFunctionButton.selectItem(by: DistanceFunction.default.description)
    }
    
    // MARK: Particle setting
    @IBAction func onClickGenerateParticlesButton(_ sender: Any) {
        let count = particleCountField.integerValue
        let colorCount = Int(colorCountButton.selectedItem!.title)!
        
        let rng: RandomNumberGenerator = fixSeedsCheck.state == .on ? Xorshift64() : SystemRandomNumberGenerator()
        
        let generator: ParticleGenerator
        switch particleGeneratorTypeButton.titleOfSelectedItem {
        case "uniform":
            generator = UniformParticleGenerator(colorCountToUse: colorCount, particleCount: count, rng: rng)
        case "partition":
            generator = PartitionParticleGenerator(colorCountToUse: colorCount, particleCount: count, rng: rng)
        case "ring":
            generator = RingParticleGenerator(colorCountToUse: colorCount, particleCount: count, rng: rng)
        case "imbalance":
            generator = ImbalanceParticleGenerator(colorCountToUse: colorCount, particleCount: count, rng: rng)
        default: return
        }
        
        delegate?.controlViewControllerGenerateParticles(generator: generator)
        attractionMatrixView.colorCount = colorCount
    }
    
    // MARK: Attracion
    @objc func onClickAttractionUpdateItem(_ sender: NSMenuItem) {
        let update = AttractionUpdate(rawValue: sender.title)!
        attractionMatrixView.updateAttraction(update: update)
    }
    
    @objc func onClickAttractionPresetItem(_ sender: NSMenuItem) {
        let preset = AttractionPreset(rawValue: sender.title)!
        attractionMatrixView.setAttraction(preset: preset)
    }
    
    // MARK: Velocity update rule
    @IBAction func updateVelocityUpdateSetting(_ sender: Any) {
        guard let ff = ForceFunction(forceFunctionButton.selectedItem?.title ?? "") else {
            return
        }
        guard let df = DistanceFunction(distanceFunctionButton.selectedItem?.title ?? "") else {
            return
        }
        
        let velocityHalfLife = Float(velocityHalfLifeButton.selectedTag()) / 1000
        let rmax = Float(rmaxButton.selectedTag()) / 1000
        let forceFactor = forceFactorSlider.floatValue
        
        delegate?.controlViewControllerUpdateVelocityUpdateSetting(.init(
            forceFunction: ff,
            distanceFunction: df,
            velocityHalfLife: velocityHalfLife,
            rmax: rmax,
            forceFactor: forceFactor
        ))
    }
    
    @IBAction func onForceFuctionClickHelpButton(_ sender: Any) {
        let url = URL(string: "https://github.com/t-ae/ParticleLife/blob/main/readme.md#force-functions")!
        NSWorkspace.shared.open(url)
    }
    
    
    // MARK: Other
    @IBAction func onChangePreferredFPS(_ sender: NSPopUpButton) {
        let fps = sender.selectedTag()
        delegate?.controlViewControllerOnChangePreferredFPS(fps)
    }
    @IBAction func onChangeFixedDt(_ sender: NSButton) {
        delegate?.controlViewControllerOnChangeFixedDt(sender.state == .on)
    }
    @IBAction func onChangeParticleSizeSlider(_ sender: NSSlider) {
        delegate?.controlViewControllerOnChangeParticleSize(sender.floatValue)
    }
    
    // MARK: Control
    @IBAction func onClickPlayButton(_ sender: Any) {
        delegate?.controlViewControllerOnClickPlayButton()
    }
    
    @IBAction func onClickPauseButton(_ sender: Any) {
        delegate?.controlViewControllerOnClickPauseButton()
    }
}

protocol ControlViewControllerDelegate {
    func controlViewControllerGenerateParticles(generator: ParticleGenerator)
    func controlViewControllerOnChangeAttraction(_ attraction: Matrix<Float>)
    func controlViewControllerUpdateVelocityUpdateSetting(_ setting: VelocityUpdateSetting)
    
    func controlViewControllerOnChangePreferredFPS(_ preferredFPS: Int)
    func controlViewControllerOnChangeFixedDt(_ fixedDt: Bool)
    func controlViewControllerOnChangeParticleSize(_ particleSize: Float)
    
    func controlViewControllerOnClickPauseButton()
    func controlViewControllerOnClickPlayButton()
}

extension ControlViewController: AttractionMatrixViewDelegate {
    func attractionMatrixViewOnChangeAttraction(_ attraction: Matrix<Float>) {
        delegate?.controlViewControllerOnChangeAttraction(attraction)
    }
}
