import Foundation

enum DistanceFunction: Int32, IntRepresentable {
    case l1 = 1
    case l2 = 2
    case linf = -1
    case l05 = -2
    case l02 = -3
    case triangle = -4
}
