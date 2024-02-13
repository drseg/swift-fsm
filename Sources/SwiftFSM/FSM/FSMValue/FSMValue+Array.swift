import Foundation

extension FSMValue: ExpressibleByArrayLiteral where T: FSMArray {
    public init(arrayLiteral elements: T.Element...) {
        self = .some(elements as! T)
    }
}

extension FSMValue: Sequence where T: RandomAccessCollection {
    public func makeIterator() -> T.Iterator {
        unsafeWrappedValue().makeIterator()
    }

    public typealias Iterator = T.Iterator
    public typealias Element = T.Element
}

extension FSMValue: Collection where T: RandomAccessCollection {
    public func index(after i: T.Index) -> T.Index {
        unsafeWrappedValue().index(after: i)
    }

    public subscript(position: T.Index) -> T.Element {
        unsafeWrappedValue()[position]
    }

    public var startIndex: T.Index {
        unsafeWrappedValue().startIndex
    }

    public var endIndex: T.Index {
        unsafeWrappedValue().endIndex
    }

    public typealias Index = T.Index
}

extension FSMValue: BidirectionalCollection where T: RandomAccessCollection {
    public func index(before i: T.Index) -> T.Index {
        unsafeWrappedValue().index(before: i)
    }
}

extension FSMValue: RandomAccessCollection where T: RandomAccessCollection { }

public protocol FSMArray: RandomAccessCollection { }
extension Array: FSMArray { }
