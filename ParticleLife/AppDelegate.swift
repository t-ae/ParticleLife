import Cocoa
import Combine

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    let viewModel = ViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        bindViewModel()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        cancellables.removeAll()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func bindViewModel() {
        viewModel.errorNotifyEvent.sink { [ unowned self] in
            showErrorAlert($0)
        }.store(in: &cancellables)
    }
    
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
    
    func openDumpModal(title: String, content: String) {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateController(withIdentifier: "DumpViewController") as! DumpViewController
        vc.title = title
        vc.content = content
        
        let window = NSWindow(contentViewController: vc)
        let wc = NSWindowController(window: window)
        wc.showWindow(self)
        window.orderFrontRegardless()
    }
}

extension NSViewController {
    var appDelegate: AppDelegate {
        NSApplication.shared.delegate as! AppDelegate
    }
    
    var viewModel: ViewModel {
        appDelegate.viewModel
    }
}
