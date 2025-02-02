import Foundation

extension FSMValue: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .some(value): "\(value)"
        default: "\(Self.self).any"
        }
    }
}
