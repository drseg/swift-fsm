//
//  Builders.swift
//  FiniteStateMachine
//
//  Created by Daniel Segall on 05/02/2023.
//

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
        cs.flatten
    }
}

@resultBuilder
struct TableBuilder<S: SP, E: EP>: ResultBuilder {
    typealias T = TableRow<S, E>
}

@resultBuilder
struct WTABuilder<S: SP, E: EP>: ResultBuilder {
    typealias T = WTARow<S, E>
}

@resultBuilder
struct WTBuilder<S: SP, E: EP>: ResultBuilder {
    typealias T = WTRow<S, E>
}
