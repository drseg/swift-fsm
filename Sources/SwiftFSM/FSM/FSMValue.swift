import Foundation

public struct FSMEvent<T: Hashable>: Hashable {
    private let _value: FSMValue<T>
    let name: String

    public static func eventWithValue(_ name: String) -> ((FSMValue<T>) -> FSMEvent<T>) {
        { FSMEvent<T>.init($0, name: name) }
    }

    public static func event(_ name: String) -> () -> FSMEvent<T> {
        { FSMEvent<T>.init(name: name) }
    }

    public var value: T? {
        _value.value
    }

    init(_ value: FSMValue<T>, name: String) {
        self._value = value
        self.name = name
    }

    init(name: String) {
        self._value = FSMValue<T>.any
        self.name = name
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

public enum FSMValue<T: Hashable>: Hashable {
    case some(T), any

    public static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.isSome, rhs.isSome else { return true }

        return lhs.value == rhs.value
    }

    public var value: T? {
        return if case let .some(value) = self {
            value
        } else {
            nil
        }
    }

    private var isSome: Bool {
        return if case .some(_) = self {
            true
        } else {
            false
        }
    }
}

public protocol EventWithValues: Hashable { }
extension EventWithValues {
    func hash(into hasher: inout Hasher) {
        hasher.combine(String.caseName(self))
    }
}

public protocol EventValue: Hashable, CaseIterable {
    static var any: Self { get }
}

extension EventValue {
    static func == (lhs: Self, rhs: Self) -> Bool {
        guard
            lhs.caseName != Self.any.caseName,
            rhs.caseName != Self.any.caseName
        else {
            return true
        }

        return lhs.caseName == rhs.caseName
    }

    var caseName: String {
        String.caseName(self)
    }
}

extension String {
    static func caseName(_ enumInstance: Any) -> String {
        String(String(describing: enumInstance).split(separator: "(").first!)
    }
}
