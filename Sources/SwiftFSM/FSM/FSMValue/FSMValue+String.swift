import Foundation

extension FSMValue: ExpressibleByUnicodeScalarLiteral where T == String {
    public init(unicodeScalarLiteral value: String) {
        self = .some(value)
    }
}

extension FSMValue: ExpressibleByExtendedGraphemeClusterLiteral where T == String {
    public init(extendedGraphemeClusterLiteral value: String) {
        self = .some(value)
    }
}

extension FSMValue: ExpressibleByStringLiteral where T == String {
    public init(stringLiteral value: String) {
        self = .some(value)
    }
}

extension FSMValue where T == String {
    static func + (lhs: Self, rhs: String) -> String {
        lhs.unsafeWrappedValue + rhs
    }

    static func + (lhs: String, rhs: Self) -> String {
        lhs + rhs.unsafeWrappedValue
    }
}
