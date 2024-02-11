import Foundation

#warning("This should probably have convenience overloads for all the comparative and mathematical operators to make the wrapping transparent")
public enum FSMValue<T: FSMHashable>: FSMHashable {
    case some(T), any

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

extension FSMValue: ExpressibleByArrayLiteral where T: FSMArray {
    public init(arrayLiteral elements: T.Element...) {
        self = .some(elements as! T)
    }
}

extension FSMValue: Sequence where T: RandomAccessCollection {
    public func makeIterator() -> T.Iterator {
        wrappedValue!.makeIterator()
    }
    
    public typealias Iterator = T.Iterator
    public typealias Element = T.Element
}

extension FSMValue: Collection where T: RandomAccessCollection {
    public func index(after i: T.Index) -> T.Index {
        wrappedValue!.index(after: i)
    }

    public subscript(position: T.Index) -> T.Element {
        wrappedValue![position]
    }

    public var startIndex: T.Index {
        wrappedValue!.startIndex
    }
    
    public var endIndex: T.Index {
        wrappedValue!.endIndex
    }
    
    public typealias Index = T.Index
}

extension FSMValue: BidirectionalCollection where T: RandomAccessCollection {
    public func index(before i: T.Index) -> T.Index {
        wrappedValue!.index(before: i)
    }
}

extension FSMValue: RandomAccessCollection where T: RandomAccessCollection { }

public protocol FSMArray: RandomAccessCollection { }
extension Array: FSMArray { }

extension FSMValue: ExpressibleByDictionaryLiteral where T: FSMDictionary {
    public init(dictionaryLiteral elements: (T.Key, T.Value)...) {
        self = .some(Dictionary(uniqueKeysWithValues: Array(elements)) as! T)
    }

    subscript(key: Key) -> Value? {
        wrappedValue![key]
    }
    
    subscript(
        key: Key,
        default defaultValue: @autoclosure () -> Value
    ) -> Value {
        wrappedValue![key, default: defaultValue()]
    }
}

public protocol FSMDictionary: Collection {
    associatedtype Key: Hashable
    associatedtype Value

    subscript(key: Key) -> Value? { get set }
    subscript(
        key: Key,
        default defaultValue: @autoclosure () -> Value
    ) -> Value { get set }
}

extension Dictionary: FSMDictionary { }

extension FSMValue: ExpressibleByBooleanLiteral where T == Bool {
    public init(booleanLiteral value: Bool) {
        self = .some(value)
    }
}

extension FSMValue: ExpressibleByNilLiteral where T: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self = .some(nil)
    }
}

public protocol EventWithValues: FSMHashable { }
public extension EventWithValues {
    func hash(into hasher: inout Hasher) {
        hasher.combine(String.caseName(self))
    }
}

extension String {
    static func caseName(_ enumInstance: Any) -> String {
        String(String(describing: enumInstance).split(separator: "(").first!)
    }
}
