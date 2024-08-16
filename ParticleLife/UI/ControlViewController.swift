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
    @IBOutlet var rmaxButton: NSPopUpButton!
    @IBOutlet var velocityHalfLifeButton: NSPopUpButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        attractionMatrixView.delegate = self
        
        attractionMatrixSetupButton.menu.removeAllItems()
        for attractionSetup in AttractionSetup.allCases {
            attractionMatrixSetupButton.menu.addItem(.init(title: attractionSetup.rawValue, action: #selector(onClickAttractionPresetItem), keyEquivalent: ""))
        }
    }
    
    override func viewWillDisappear() {
        delegate?.controlViewControllerOnClose()
        super.viewWillDisappear()
    }
    
    @IBAction func onClickPlayButton(_ sender: Any) {
        delegate?.controlViewControllerOnClickPlayButton()
    }
    
    @IBAction func onClickPauseButton(_ sender: Any) {
        delegate?.controlViewControllerOnClickPauseButton()
    }
    
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
        default: return
        }
        
        delegate?.controlViewControllerGenerateParticles(generator: generator)
        attractionMatrixView.colorCount = colorCount
    }
    
    @objc func onClickAttractionPresetItem(_ sender: NSMenuItem) {
        let setup = AttractionSetup(rawValue: sender.title)!
        attractionMatrixView.setupAttraction(setup)
    }
    
    
    @IBAction func updateAccelSetting(_ sender: Any) {
        guard let ff = ForceFunction(rawValue: UInt32(forceFunctionButton.selectedTag())) else {
            return
        }
        
        let velocityHalfLife = Float(velocityHalfLifeButton.selectedTag()) / 1000
        let rmax = Float(rmaxButton.selectedTag()) / 1000
        
        delegate?.controlViewControllerUpdateVelocityUpdateSetting(.init(
            forceFunction: ff,
            velocityHalfLife: velocityHalfLife,
            rmax: rmax
        ))
    }
    
    @IBAction func onChangeParticleSizeSlider(_ sender: NSSlider) {
        delegate?.controlViewControllerOnChangeParticleSize(sender.floatValue)
    }
    
    @IBAction func onForceFuctionClickHelpButton(_ sender: Any) {
        let url = URL(string: "https://github.com/t-ae/ParticleLife/blob/main/readme.md#force-functions")!
        NSWorkspace.shared.open(url)
    }
    
    
}

protocol ControlViewControllerDelegate {
    func controlViewControllerOnClickPauseButton()
    func controlViewControllerOnClickPlayButton()
    func controlViewControllerOnClose()
    
    func controlViewControllerGenerateParticles(generator: ParticleGenerator)
    
    func controlViewControllerOnChangeAttraction(_ attraction: Attraction)
    func controlViewControllerUpdateVelocityUpdateSetting(_ setting: VelocityUpdateSetting)
    
    func controlViewControllerOnChangeParticleSize(_ particleSize: Float)
}

extension ControlViewController: AttractionMatrixViewDelegate {
    func attractionMatrixViewOnChangeAttraction(_ attraction: Attraction) {
        delegate?.controlViewControllerOnChangeAttraction(attraction)
    }
}
