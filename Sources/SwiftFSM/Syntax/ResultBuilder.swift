import Foundation

protocol ResultBuilder {
    associatedtype T
}

extension ResultBuilder {
    static func buildExpression( _ row: [T]) -> [T] {
        row
    }
    
    static func buildExpression( _ row: T) -> [T] {
        [row]
    }
    
    static func buildBlock(_ cs: [T]...) -> [T] {
        cs.flattened
    }
}

extension Collection where Element: Collection {
    var flattened: [Element.Element] {
        flatMap { $0 }
    }
}
