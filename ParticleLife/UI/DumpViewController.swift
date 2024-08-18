import Foundation
import Cocoa

class DumpViewController: NSViewController {
    var content: String = "" {
        didSet {
            textView?.string = content
        }
    }
    @IBOutlet private var textView: NSTextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.string = content
    }
    
    @IBAction func onClickCloseButton(_ sender: Any) {
        view.window?.close()
    }
}
