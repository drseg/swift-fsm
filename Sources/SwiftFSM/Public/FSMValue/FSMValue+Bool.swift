import Foundation

extension FSMValue: ExpressibleByBooleanLiteral where T == Bool {
    public init(booleanLiteral value: Bool) {
        self = .some(value)
    }
}
