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
        self = switch T.self {
        case is Int8.Type: .some(Int8(value) as! T)
        case is Int16.Type: .some(Int16(value) as! T)
        case is Int32.Type: .some(Int32(value) as! T)
        case is Int64.Type: .some(Int64(value) as! T)
        default: .some(value as! T)
        }
    }
}

extension FSMValue: ExpressibleByFloatLiteral where T: FSMFloat {
    public init(floatLiteral value: Double) {
        self = switch T.self {
        case is Float.Type: .some(Float(value) as! T)
        case is Float80.Type: .some(Float80(value) as! T)
        default: .some(value as! T)
        }
    }
}

extension FSMValue where T: AdditiveArithmetic {
    public static func + (lhs: Self, rhs: T) -> T {
        lhs.unsafeWrappedValue() + rhs
    }

    public static func + (lhs: T, rhs: Self) -> T {
        lhs + rhs.unsafeWrappedValue()
    }

    public static func - (lhs: Self, rhs: T) -> T {
        lhs.unsafeWrappedValue() - rhs
    }

    public static func - (lhs: T, rhs: Self) -> T {
        lhs - rhs.unsafeWrappedValue()
    }
}

extension FSMValue where T: Numeric {
    public static func * (lhs: Self, rhs: T) -> T {
        lhs.unsafeWrappedValue() * rhs
    }

    public static func * (lhs: T, rhs: Self) -> T {
        lhs * rhs.unsafeWrappedValue()
    }
}

extension FSMValue where T: BinaryInteger {
    public static func / (lhs: Self, rhs: T) -> T {
        lhs.unsafeWrappedValue() / rhs
    }

    public static func / (lhs: T, rhs: Self) -> T {
        lhs / rhs.unsafeWrappedValue()
    }

    public static func % (lhs: Self, rhs: T) -> T {
        lhs.unsafeWrappedValue() % rhs
    }

    public static func % (lhs: T, rhs: Self) -> T {
        lhs % rhs.unsafeWrappedValue()
    }
}

extension FSMValue where T: FloatingPoint {
    public static func / (lhs: Self, rhs: T) -> T {
        lhs.unsafeWrappedValue() / rhs
    }

    public static func / (lhs: T, rhs: Self) -> T {
        lhs / rhs.unsafeWrappedValue()
    }
}

