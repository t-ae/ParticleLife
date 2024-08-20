import Foundation
import Cocoa

protocol LabelConvertible: RawRepresentable, LosslessStringConvertible, CaseIterable {}

extension LabelConvertible {
    public init?(_ description: String) {
        guard let c = Self.allCases.first(where: { $0.description == description }) else {
            return nil
        }
        self = c
    }
}

extension LabelConvertible where RawValue == String {
    var description: String { rawValue }
}

extension NSPopUpButton {
    func setItems<C: Collection>(_ items: C) where C.Element: LabelConvertible {
        self.removeAllItems()
        self.addItems(withTitles: items.map { $0.description })
    }
    
    func selectItem(_ c: any LabelConvertible) {
        selectItem(by: c.description)
    }
    
    func selectedItem<T: LabelConvertible>() -> T? {
        titleOfSelectedItem.flatMap(T.init)
    }
}

extension NSMenu {
    func setItems<C: Collection>(_ items: C, action: Selector) where C.Element: LabelConvertible {
        removeAllItems()
        for item in items {
            addItem(withTitle: item.description, action: action, keyEquivalent: "")
        }
    }
}
