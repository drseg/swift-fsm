import Foundation

public protocol ResultBuilder {
    associatedtype T
}

public extension ResultBuilder {
    static func buildExpression( _ row: [T]) -> [T] {
        row
    }

    static func buildExpression( _ row: T) -> [T] {
        [row]
    }

    static func buildBlock(_ rows: [T]...) -> [T] {
        rows.flattened
    }
}

extension Collection where Element: Collection {
    var flattened: [Element.Element] {
        flatMap(\.self)
    }
}
