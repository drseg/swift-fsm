import Foundation

public enum FSMValue<T: FSMHashable>: FSMHashable {
    case some(T), any

    public var wrappedValue: T? {
        try? throwingWrappedValue()
    }

    var unsafeWrappedValue: T {
        try! throwingWrappedValue()
    }

    func throwingWrappedValue() throws -> T {
        if case let .some(value) = self {
            return value
        } else {
            throw 
"""
\(String(describing: Self.self)).\(String(describing: self)) has no value - performing operations on it as if it did is forbidden.
"""
        }
    }

    var isSome: Bool {
        return if case .some = self {
            true
        } else {
            false
        }
    }
}

public protocol EventWithValues: FSMHashable { }
public extension EventWithValues {
    func hash(into hasher: inout Hasher) {
        hasher.combine(String.caseName(self))
    }
}

extension String {
    static func caseName(_ enumInstance: Any) -> String {
        String(String(describing: enumInstance).split(separator: "(").first!)
    }
}
