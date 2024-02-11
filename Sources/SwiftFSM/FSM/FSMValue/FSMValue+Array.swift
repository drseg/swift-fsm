import Foundation

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
