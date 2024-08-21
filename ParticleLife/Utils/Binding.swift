import Foundation
import Combine
import Cocoa

class BindableTextField: NSTextField {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        target = self
        action = #selector(onChange)
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        target = self
        action = #selector(onChange)
    }
    @objc func onChange(sender: BindableTextField) {
        actionClosure?(sender)
    }
    var actionClosure: ((BindableTextField)->Void)?
}

extension BindableTextField {
    func bind(_ publisher: any Publisher<String, Never>, onChange: @escaping (String)->Void) -> Cancellable {
        actionClosure = {
            onChange($0.stringValue)
        }
        return publisher.sink {
            self.stringValue = $0
        }
    }
}

class BindablePopUpButton: NSPopUpButton {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        target = self
        action = #selector(onChange)
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        target = self
        action = #selector(onChange)
    }
    @objc func onChange(sender: BindablePopUpButton) {
        actionClosure?(sender)
    }
    var actionClosure: ((BindablePopUpButton)->Void)?
}

extension BindablePopUpButton {
    func bind<T: LosslessStringConvertible>(_ publisher: any Publisher<T, Never>, options: [T], onChange: @escaping (T)->Void) -> Cancellable {
        removeAllItems()
        addItems(withTitles: options.map { $0.description })
        actionClosure = {
            onChange(.init($0.titleOfSelectedItem!)!)
        }
        return publisher.sink {
            self.selectItem(by: $0.description)
        }
    }
    
    func bind<Option: OptionConvertible>(_ publisher: any Publisher<Option, Never>, onChange: @escaping (Option)->Void) -> Cancellable {
        setItems(Option.allCases)
        actionClosure = {
            onChange($0.selectedItem()!)
        }
        return publisher.sink {
            self.selectItem($0)
        }
    }
}

class BindableSlider: NSSlider {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        target = self
        action = #selector(onChange)
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        target = self
        action = #selector(onChange)
    }
    @objc func onChange(sender: NSSlider) {
        actionClosure?(sender)
    }
    var actionClosure: ((NSSlider)->Void)?
}

extension BindableSlider {
    func bind(
        _ publisher: any Publisher<Float, Never>,
        range: ClosedRange<Float>,
        onChange: @escaping (Float)->Void
    ) -> Cancellable {
        minValue = Double(range.lowerBound)
        maxValue = Double(range.upperBound)
        actionClosure = {
            onChange($0.floatValue)
        }
        return publisher.sink {
            self.floatValue = $0
        }
    }
}

class BindableComboButton: NSComboButton {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    @objc func onChoose(sender: NSMenuItem) {
        actionClosure?(sender)
    }
    var actionClosure: ((NSMenuItem)->Void)?
}

extension BindableComboButton {
    func bindMenu<Option: OptionConvertible>(_ optionType: Option.Type = Option.self, onChoose: @escaping (Option)->Void) {
        menu.setItems(Option.allCases, target: self, action: #selector(self.onChoose))
        actionClosure = {
            onChoose($0.option()!)
        }
    }
}

class BindableButton: NSButton {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        target = self
        action = #selector(onClick)
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        target = self
        action = #selector(onClick)
    }
    @objc func onClick(sender: NSButton) {
        actionClosure?(sender)
    }
    var actionClosure: ((NSButton)->Void)?
}

extension BindableButton {
    func bind(onClick: @escaping (NSButton)->Void) {
        actionClosure = {
            onClick($0)
        }
    }
    
    func bind(_ publisher: any Publisher<Bool, Never>, onChange: @escaping (Bool)->Void) -> Cancellable {
        actionClosure = {
            onChange($0.state == .on)
        }
        return publisher.sink {
            self.state = $0 ? .on : .off
        }
    }
}
