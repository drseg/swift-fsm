import Foundation

extension FSMValue where T: Comparable {
    public static func > (lhs: Self, rhs: T) -> Bool {
        guard let value = lhs.wrappedValue else { return false }

        return value > rhs
    }

    public static func < (lhs: Self, rhs: T) -> Bool {
        guard let value = lhs.wrappedValue else { return false }

        return value < rhs
    }

    public static func >= (lhs: Self, rhs: T) -> Bool {
        guard let value = lhs.wrappedValue else { return false }

        return value >= rhs
    }

    public static func <= (lhs: Self, rhs: T) -> Bool {
        guard let value = lhs.wrappedValue else { return false }

        return value <= rhs
    }

    public static func > (lhs: T, rhs: Self) -> Bool {
        guard let value = rhs.wrappedValue else { return false }

        return lhs > value
    }

    public static func < (lhs: T, rhs: Self) -> Bool {
        guard let value = rhs.wrappedValue else { return false }

        return lhs < value
    }

    public static func >= (lhs: T, rhs: Self) -> Bool {
        guard let value = rhs.wrappedValue else { return false }

        return lhs >= value
    }

    public static func <= (lhs: T, rhs: Self) -> Bool {
        guard let value = rhs.wrappedValue else { return false }

        return lhs <= value
    }
}
