import Foundation

#warning("This should probably have convenience overloads for all the comparative and mathematical operators to make the wrapping transparent")
public enum FSMValue<T: FSMHashable>: FSMHashable {
    case some(T), any

    public static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.isSome, rhs.isSome else { return true }

        return lhs.wrappedValue == rhs.wrappedValue
    }

    public var wrappedValue: T? {
        return if case let .some(value) = self {
            value
        } else {
            nil
        }
    }

    private var isSome: Bool {
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

public protocol EventValue: FSMHashable, CaseIterable {
    static var any: Self { get }
}

public extension EventValue {
    static func == (lhs: Self, rhs: Self) -> Bool {
        guard
            lhs.caseName != Self.any.caseName,
            rhs.caseName != Self.any.caseName
        else {
            return true
        }

        return lhs.caseName == rhs.caseName
    }

    internal var caseName: String {
        String.caseName(self)
    }
}

extension String {
    static func caseName(_ enumInstance: Any) -> String {
        String(String(describing: enumInstance).split(separator: "(").first!)
    }
}
