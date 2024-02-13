import Foundation

extension FSMValue: ExpressibleByNilLiteral where T: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self = .some(nil)
    }
}
