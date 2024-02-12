import Foundation

extension FSMValue where T: AdditiveArithmetic {
    public static func + (lhs: Self, rhs: T) -> T {
        lhs.wrappedValue! + rhs
    }

    public static func + (lhs: T, rhs: Self) -> T {
        lhs + rhs.wrappedValue!
    }

    public static func - (lhs: Self, rhs: T) -> T {
        lhs.wrappedValue! - rhs
    }

    public static func - (lhs: T, rhs: Self) -> T {
        lhs - rhs.wrappedValue!
    }
}
