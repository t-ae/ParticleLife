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
        actionSubject.send(sender)
    }
    let actionSubject = PassthroughSubject<BindableTextField, Never>()
}

extension BindableTextField {
    func bind(_ publisher: inout Published<String>.Publisher) -> Cancellable {
        actionSubject.map {
            $0.stringValue
        }.assign(to: &publisher)
        
        return publisher.assign(to: \.stringValue, on: self)
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
        actionSubject.send(sender)
    }
    let actionSubject = PassthroughSubject<BindablePopUpButton, Never>()
}

extension BindablePopUpButton {
    func bind<T: LosslessStringConvertible>(_ publisher: inout Published<T>.Publisher, options: [T]) -> Cancellable {
        removeAllItems()
        addItems(withTitles: options.map { $0.description })
        
        actionSubject.map {
            T($0.titleOfSelectedItem!)!
        }.assign(to: &publisher)
        
        return publisher.sink {
            self.selectItem(by: $0.description)
        }
    }
    
    func bind<Option: OptionConvertible>(_ publisher: inout Published<Option>.Publisher) -> Cancellable {
        setItems(Option.allCases)
        
        actionSubject.map {
            $0.selectedItem()!
        }.assign(to: &publisher)
        
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
        actionSubject.send(sender)
    }
    let actionSubject = PassthroughSubject<NSSlider, Never>()
}

extension BindableSlider {
    func bind(
        _ publisher: inout Published<Float>.Publisher,
        range: ClosedRange<Float>
    ) -> Cancellable {
        minValue = Double(range.lowerBound)
        maxValue = Double(range.upperBound)
        
        actionSubject.map {
            $0.floatValue
        }.assign(to: &publisher)
        
        return publisher.assign(to: \.floatValue, on: self)
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
        actionSubject.send(sender)
    }
    let actionSubject = PassthroughSubject<NSButton, Never>()
}

extension BindableButton {
    func bind(onClick: @escaping (NSButton)->Void) -> Cancellable {
        return actionSubject.sink {
            onClick($0)
        }
    }
    
    func bind(_ publisher: inout Published<Bool>.Publisher) -> Cancellable {
        actionSubject.map {
            $0.state == .on
        }.assign(to: &publisher)
        
        return publisher.sink {
            self.state = $0 ? .on : .off
        }
    }
}
