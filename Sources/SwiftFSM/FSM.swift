//
//  FSM.swift
//  
//  Created by Daniel Segall on 03/03/2023.
//

import Foundation
import ReflectiveEquality

class FSM<State: Hashable, Event: Hashable> {
    @resultBuilder
    struct TableBuilder: ResultBuilder {
        typealias T = Syntax.Define<State>
    }
    
    var state: AnyHashable
    
    init(initialState: State) {
        state = initialState
    }
    
    func buildTable(@TableBuilder _ table: () -> ([Syntax.Define<State>])) throws {
        let finalised = table().map(\.node).map { $0.finalised() }
        let errors = finalised.map(\.errors).flattened
        if !errors.isEmpty { throw CompoundError(errors: errors) }
    }
}
