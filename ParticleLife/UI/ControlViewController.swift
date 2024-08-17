import Foundation
import Cocoa

class ControlViewController: NSViewController {
    var delegate: ControlViewControllerDelegate?
    
    @IBOutlet var colorCountButton: NSPopUpButton!
    @IBOutlet var particleCountField: NSTextField!
    @IBOutlet var particleGeneratorTypeButton: NSPopUpButton!
    @IBOutlet var fixSeedsCheck: NSButton!
    
    @IBOutlet var attractionMatrixView: AttractionMatrixView!
    @IBOutlet var attractionMatrixSetupButton: NSComboButton!
    @IBOutlet var forceFunctionButton: NSPopUpButton!
    @IBOutlet var distanceFunctionButton: NSPopUpButton!
    @IBOutlet var rmaxButton: NSPopUpButton!
    @IBOutlet var velocityHalfLifeButton: NSPopUpButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        attractionMatrixView.delegate = self
        
        attractionMatrixSetupButton.menu.removeAllItems()
        for attractionSetup in AttractionSetup.allCases {
            attractionMatrixSetupButton.menu.addItem(.init(title: attractionSetup.rawValue, action: #selector(onClickAttractionPresetItem), keyEquivalent: ""))
        }
        
        attractionMatrixSetupButton.allowsExpansionToolTips
    }
    
    // MARK: Particle setting
    @IBAction func onClickGenerateParticlesButton(_ sender: Any) {
        let count = particleCountField.intValue
        let colorCount = colorCountButton.selectedTag()
        
        let rng: RandomNumberGenerator = fixSeedsCheck.state == .on ? Xorshift64() : SystemRandomNumberGenerator()
        
        let generator: ParticleGenerator
        switch particleGeneratorTypeButton.titleOfSelectedItem {
        case "uniform":
            generator = UniformParticleGenerator(colorCount: colorCount, particleCount: Int(count), rng: rng)
        case "partition":
            generator = PartitionParticleGenerator(colorCount: colorCount, particleCount: Int(count), rng: rng)
        case "ring":
            generator = RingParticleGenerator(colorCount: colorCount, particleCount: Int(count), rng: rng)
        case "imbalance":
            generator = ImbalanceParticleGenerator(colorCount: colorCount, particleCount: Int(count), rng: rng)
        default: return
        }
        
        delegate?.controlViewControllerGenerateParticles(generator: generator)
        attractionMatrixView.colorCount = colorCount
    }
    
    // MARK: Attracion
    @objc func onClickAttractionPresetItem(_ sender: NSMenuItem) {
        let setup = AttractionSetup(rawValue: sender.title)!
        attractionMatrixView.setupAttraction(setup)
    }
    
    // MARK: Velocity update rule
    @IBAction func updateVelocityUpdateSetting(_ sender: Any) {
        guard let ff = ForceFunction(intValue: forceFunctionButton.selectedTag()) else {
            return
        }
        guard let df = DistanceFunction(intValue: distanceFunctionButton.selectedTag()) else {
            return
        }
        
        let velocityHalfLife = Float(velocityHalfLifeButton.selectedTag()) / 1000
        let rmax = Float(rmaxButton.selectedTag()) / 1000
        
        delegate?.controlViewControllerUpdateVelocityUpdateSetting(.init(
            forceFunction: ff,
            distanceFunction: df,
            velocityHalfLife: velocityHalfLife,
            rmax: rmax
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
    func controlViewControllerOnChangeAttraction(_ attraction: Attraction)
    func controlViewControllerUpdateVelocityUpdateSetting(_ setting: VelocityUpdateSetting)
    
    func controlViewControllerOnChangePreferredFPS(_ preferredFPS: Int)
    func controlViewControllerOnChangeParticleSize(_ particleSize: Float)
    
    func controlViewControllerOnClickPauseButton()
    func controlViewControllerOnClickPlayButton()
}

extension ControlViewController: AttractionMatrixViewDelegate {
    func attractionMatrixViewOnChangeAttraction(_ attraction: Attraction) {
        delegate?.controlViewControllerOnChangeAttraction(attraction)
    }
}
