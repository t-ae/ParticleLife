import Cocoa
import Combine

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    let viewModel = ViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    private var keyEventMonitor: Any?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        bindViewModel()
        
        keyEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown, handler: handleShortcut(event:))
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        if let keyEventMonitor {
            NSEvent.removeMonitor(keyEventMonitor)
        }
        
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
    
    func handleShortcut(event: NSEvent) -> NSEvent? {
        guard event.modifierFlags.contains(.command) else {
            return event
        }
        
        switch event.characters {
        case "a":
            viewModel.autoUpdateAttractionMatrix.toggle()
        case "r":
            viewModel.updateAttractionMatrix(.randomize)
        case "p":
            viewModel.dumpParametersEvent.send()
        case "s":
            viewModel.dumpStatisticsEvent.send()
        default:
            return event
        }
        
        return nil
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
