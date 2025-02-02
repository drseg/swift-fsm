import Foundation

extension FSMValue: ExpressibleByDictionaryLiteral where T: FSMDictionary {
    public init(dictionaryLiteral elements: (T.Key, T.Value)...) {
        self = .some(Dictionary(uniqueKeysWithValues: Array(elements)) as! T)
    }

    public subscript(key: Key) -> Value? {
        unsafeWrappedValue()[key]
    }

    public subscript(
        key: Key,
        default defaultValue: @autoclosure () -> Value
    ) -> Value {
        unsafeWrappedValue()[key, default: defaultValue()]
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
