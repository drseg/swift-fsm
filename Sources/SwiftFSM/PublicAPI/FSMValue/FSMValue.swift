import Foundation

protocol Throwing {
    func `throw`(instance: String, function: String) throws -> Never
}

private struct Thrower: Throwing {
    func `throw`(instance i: String, function f: String) throws -> Never {
        throw "\(i) has no value - the operation \(f) is invalid."
    }
}

nonisolated(unsafe) private var thrower: any Throwing = Thrower()

public enum FSMValue<T: FSMHashable>: FSMHashable {
    case some(T), any

    public var wrappedValue: T? {
        try? throwingWrappedValue()
    }

    func unsafeWrappedValue(_ f: String = #function) -> T {
        try! throwingWrappedValue(f)
    }

    func throwingWrappedValue(_ f: String = #function) throws -> T {
        switch self {
        case let .some(value): value
        default: try thrower.throw(instance: "\(self)", function: f)
        }
    }

    var isSome: Bool {
        if case .some = self {
            true
        } else {
            false
        }
    }
}

#if DEVELOPMENT
extension FSMValue {
    static func setThrower(_ t: some Throwing) {
        thrower = t
    }

    static func resetThrower() {
        thrower = Thrower()
    }
}
#endif

public protocol EventWithValues: FSMHashable { }
extension EventWithValues {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(caseName)
    }

    var caseName: some StringProtocol {
        String(describing: self).lazy.split(separator: "(").first!
    }
}
