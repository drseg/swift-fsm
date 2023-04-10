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
        
        init(_ value: Value) {
            state = value.state
            predicates = value.predicates
            event = value.event
        }
    }
    
    struct Value {
        let condition: () -> Bool,
            state: AnyHashable,
            predicates: PredicateSet,
            event: AnyHashable,
            nextState: AnyHashable,
            actions: [Action]
    }
    
    var table: [Key: Value] = [:]
    var state: AnyHashable
    
    init(initialState: State) {
        state = initialState
    }
    
    func buildTable(@Builder _ table: () -> [Syntax.Define<State>]) throws {
        let transitionNode = ActionsResolvingNode(rest: table().map(\.node))
        let validationNode = SemanticValidationNode(rest: [transitionNode])
        let tableNode = MatchResolvingNode(rest: [validationNode])
        let result = tableNode.finalised()
        
        try checkForErrors(result)
        makeTable(result.output)
    }
    
    func checkForErrors(_ result: (output: [MatchResolvingNode.Output], errors: [Error])) throws {
        #warning("also need to check that buildTable hasn't already been called")
        
        if !result.errors.isEmpty {
            throw SwiftFSMError(errors: result.errors)
        }
        
        if result.output.isEmpty {
            throw SwiftFSMError(errors: [EmptyTableError()])
        }
        
        let stateEvent = (result.output[0].state, result.output[0].event)
        if deepDescription(stateEvent).contains("NSObject") {
            throw SwiftFSMError(errors: [NSObjectError()])
        }
    }
    
    func makeTable(_ output: [MatchResolvingNode.Output]) {
        output.forEach {
            let value = Value(condition: $0.condition,
                              state: $0.state.base,
                              predicates: $0.predicates,
                              event: $0.event.base,
                              nextState: $0.nextState.base,
                              actions: $0.actions)
            table[Key(value)] = value
        }
    }
    
    func handleEvent(_ event: Event, predicates: any Predicate...) {
        handleEvent(event, predicates: predicates)
    }
    
    func handleEvent(_ event: Event, predicates: [any Predicate]) {
        if let transition = table[Key(state: state,
                                      predicates: Set(predicates.erased()),
                                      event: event)],
           transition.condition()
        {
            state = transition.nextState
            transition.actions.forEach { $0() }
        }
    }
}
