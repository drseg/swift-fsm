import Foundation

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
        default: throw "\(self) has no value - the operation \(f) is invalid."
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

public protocol EventWithValues: FSMHashable { }
extension EventWithValues {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(caseName)
    }

    var caseName: some StringProtocol {
        String(describing: self)
            .lazy
            .split(separator: "(")
            .first!
    }
}
