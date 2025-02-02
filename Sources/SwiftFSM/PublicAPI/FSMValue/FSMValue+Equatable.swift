import Foundation

extension FSMValue {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.isSome, rhs.isSome else { return true }

        return lhs.wrappedValue == rhs.wrappedValue
    }

    public static func == (lhs: Self, rhs: T) -> Bool {
        lhs.wrappedValue == rhs
    }

    public static func == (lhs: T, rhs: Self) -> Bool {
        lhs == rhs.wrappedValue
    }

    public static func != (lhs: Self, rhs: T) -> Bool {
        lhs.wrappedValue != rhs
    }

    public static func != (lhs: T, rhs: Self) -> Bool {
        lhs != rhs.wrappedValue
    }
}
