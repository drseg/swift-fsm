//
//  FSM.swift
//  
//  Created by Daniel Segall on 03/03/2023.
//

import Foundation
import ReflectiveEquality

class FSM<State: Hashable, Event: Hashable> {
    @resultBuilder
    struct Builder: ResultBuilder {
        typealias T = Syntax.Define<State>
    }
    
    struct Key: Hashable {
        let state: AnyHashable,
            predicates: PredicateSet,
            event: AnyHashable
        
        init(state: AnyHashable, predicates: PredicateSet, event: AnyHashable) {
            self.state = state
            self.predicates = predicates
            self.event = event
        }
        
        init(_ value: Transition) {
            state = value.state
            predicates = value.predicates
            event = value.event
        }
    }
    
    var table: [Key: Transition] = [:]
    var state: AnyHashable
    
    init(initialState: State) {
        state = initialState
    }
    
    func buildTable(
        file: String = #file,
        line: Int = #line,
        @Builder _ block: () -> [Syntax.Define<State>]
    ) throws {
        guard table.isEmpty else {
            throw makeError(TableAlreadyBuiltError(file: file, line: line))
        }
        
        let transitionNode = ActionsResolvingNode(rest: block().map(\.node))
        let validationNode = SemanticValidationNode(rest: [transitionNode])
        let tableNode = EagerMatchResolvingNode(rest: [validationNode])
        let result = tableNode.finalised()
        
        try checkForErrors(result)
        makeTable(result.output)
    }
    
    func checkForErrors(_ result: (output: [EagerMatchResolvingNode.Output], errors: [Error])) throws {
        if !result.errors.isEmpty {
            throw makeError(result.errors)
        }
        
        if result.output.isEmpty {
            throw makeError(EmptyTableError())
        }
        
        let stateEvent = (result.output[0].state, result.output[0].event)
        if deepDescription(stateEvent).contains("NSObject") {
            throw makeError(NSObjectError())
        }
    }
    
    func makeError(_ error: Error) -> SwiftFSMError {
        makeError([error])
    }
    
    func makeError(_ errors: [Error]) -> SwiftFSMError {
        SwiftFSMError(errors: errors)
    }
    
    func makeTable(_ output: [Transition]) {
        output.forEach { table[Key($0)] = $0 }
    }
    
    func handleEvent(_ event: Event, predicates: any Predicate...) {
        handleEvent(event, predicates: predicates)
    }
    
    func handleEvent(_ event: Event, predicates: [any Predicate]) {
        if let transition = table[Key(state: state,
                                      predicates: Set(predicates.erased()),
                                      event: event)],
           transition.condition?() ?? true
        {
            state = transition.nextState
            transition.actions.forEach { $0() }
        }
    }
}
