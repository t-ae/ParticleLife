import Foundation

protocol IntRepresentable: RawRepresentable where RawValue: BinaryInteger {}

extension IntRepresentable {
    var intValue: Int { Int(rawValue) }
    
    init?(intValue: Int) {
        self.init(rawValue: .init(intValue))
    }
}
