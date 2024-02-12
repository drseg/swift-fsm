import Foundation

public protocol FSMFloat { }
extension Float: FSMFloat { }
extension Float80: FSMFloat { }
extension Double: FSMFloat { }

public protocol FSMInt { }
extension Int8: FSMInt { }
extension Int: FSMInt { }
extension Int16: FSMInt { }
extension Int32: FSMInt { }
extension Int64: FSMInt { }

extension FSMValue: ExpressibleByIntegerLiteral where T: FSMInt {
    public init(integerLiteral value: Int) {
        if T.self == Int8.self {
            self = .some(Int8(value) as! T)
        } else if T.self == Int16.self {
            self = .some(Int16(value) as! T)
        } else if T.self == Int32.self {
            self = .some(Int32(value) as! T)
        } else if T.self == Int64.self {
            self = .some(Int64(value) as! T)
        } else {
            self = .some(value as! T)
        }
    }
}

extension FSMValue: ExpressibleByFloatLiteral where T: FSMFloat {
    public init(floatLiteral value: Double) {
        if T.self == Float.self {
            self = .some(Float(value) as! T)
        } else if T.self == Float80.self {
            self = .some(Float80(value) as! T)
        } else {
            self = .some(value as! T)
        }
    }
}

extension FSMValue where T: AdditiveArithmetic {
    public static func + (lhs: Self, rhs: T) -> T {
        lhs.unsafeWrappedValue + rhs
    }

    public static func + (lhs: T, rhs: Self) -> T {
        lhs + rhs.unsafeWrappedValue
    }

    public static func - (lhs: Self, rhs: T) -> T {
        lhs.unsafeWrappedValue - rhs
    }

    public static func - (lhs: T, rhs: Self) -> T {
        lhs - rhs.unsafeWrappedValue
    }
}

extension FSMValue where T: Numeric {
    public static func * (lhs: Self, rhs: T) -> T {
        lhs.unsafeWrappedValue * rhs
    }

    public static func * (lhs: T, rhs: Self) -> T {
        lhs * rhs.unsafeWrappedValue
    }
}

extension FSMValue where T: BinaryInteger {
    public static func / (lhs: Self, rhs: T) -> T {
        lhs.unsafeWrappedValue / rhs
    }

    public static func / (lhs: T, rhs: Self) -> T {
        lhs / rhs.unsafeWrappedValue
    }

    public static func % (lhs: Self, rhs: T) -> T {
        lhs.unsafeWrappedValue % rhs
    }

    public static func % (lhs: T, rhs: Self) -> T {
        lhs % rhs.unsafeWrappedValue
    }
}

extension FSMValue where T: FloatingPoint {
    public static func / (lhs: Self, rhs: T) -> T {
        lhs.unsafeWrappedValue / rhs
    }

    public static func / (lhs: T, rhs: Self) -> T {
        lhs / rhs.unsafeWrappedValue
    }
}

