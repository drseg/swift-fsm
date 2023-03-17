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
        let tableNode = PreemptiveTableNode(rest: table().map(\.node))
        let finalised = tableNode.finalised()
        
        try checkForErrors(finalised)
    }
    
    func checkForErrors(_ finalised: (output: [TableNodeOutput], errors: [Error])) throws {
        if !finalised.errors.isEmpty {
            throw CompoundError(errors: finalised.errors)
        }
        
        if finalised.output.isEmpty {
            throw CompoundError(errors: [EmptyTableError()])
        }
        
        let firstState = finalised.output.first!.state
        let firstEvent = finalised.output.first!.event
        
        if deepDescription((firstState, firstEvent)).contains("NSObject") {
            throw CompoundError(errors: [NSObjectError()])
        }
    }
}

struct NSObjectError: Error {
    
}
