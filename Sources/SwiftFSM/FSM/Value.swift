import Foundation

public enum Value<T: Hashable>: Hashable {
    case some(T), any

    public static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.isSome, rhs.isSome else { return true }

        if case let .some(lhsValue) = lhs, case let .some(rhsValue) = rhs {
            return lhsValue == rhsValue
        }

        return false
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

    private var isAny: Bool {
        return if case .any = self {
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
