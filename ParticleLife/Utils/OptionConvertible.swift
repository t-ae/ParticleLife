import Foundation
import Cocoa

protocol OptionConvertible: RawRepresentable, LosslessStringConvertible, CaseIterable {}

extension OptionConvertible {
    public init?(_ description: String) {
        guard let c = Self.allCases.first(where: { $0.description == description }) else {
            return nil
        }
        self = c
    }
}

extension OptionConvertible where RawValue == String {
    var description: String { rawValue }
}

extension NSPopUpButton {
    func setItems<C: Collection>(_ items: C) where C.Element: OptionConvertible {
        self.removeAllItems()
        self.addItems(withTitles: items.map { $0.description })
    }
    
    func selectItem(_ c: any OptionConvertible) {
        selectItem(by: c.description)
    }
    
    func selectedItem<T: OptionConvertible>() -> T? {
        titleOfSelectedItem.flatMap(T.init)
    }
}

extension NSMenu {
    func setItems<C: Collection>(_ items: C, action: Selector) where C.Element: OptionConvertible {
        removeAllItems()
        for item in items {
            addItem(withTitle: item.description, action: action, keyEquivalent: "")
        }
    }
}
