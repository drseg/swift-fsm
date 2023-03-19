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
    
    struct Key: Hashable {
        let state: AnyHashable,
            predicates: Set<AnyPredicate>,
            event: AnyHashable
        
        init(state: AnyHashable, predicates: Set<AnyPredicate>, event: AnyHashable ) {
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
        let state: AnyHashable,
            predicates: Set<AnyPredicate>,
            event: AnyHashable,
            nextState: AnyHashable,
            actions: [() -> ()]
    }
    
    var table: [Key: Value] = [:]
    var state: AnyHashable
    
    init(initialState: State) {
        state = initialState
    }
    
    func buildTable(@TableBuilder _ table: () -> ([Syntax.Define<State>])) throws {
        let transitionNode = TransitionNode(rest: table().map(\.node))
        let validationNode = SemanticValidationNode(rest: [transitionNode])
        let tableNode = PreemptiveTableNode(rest: [validationNode])
        let finalised = tableNode.finalised()
        
        try checkForErrors(finalised)
        makeTable(finalised.output)
    }
    
    func checkForErrors(_ finalised: (output: [PreemptiveTableNode.Output], errors: [Error])) throws {
        if !finalised.errors.isEmpty {
            throw CompoundError(errors: finalised.errors)
        }
        
        if finalised.output.isEmpty {
            throw CompoundError(errors: [EmptyTableError()])
        }
        
        if State.self == Event.self {
            throw CompoundError(errors: [TypeClashError()])
        }
        
        let predicates = finalised.output.map(\.predicates).flattened
        if predicates.contains(where: { $0.base.base is State || $0.base.base is Event }) {
            throw CompoundError(errors: [TypeClashError()])
        }
        
        let firstState = finalised.output.first!.state
        let firstEvent = finalised.output.first!.event
        
        if deepDescription((firstState, firstEvent)).contains("NSObject") {
            throw CompoundError(errors: [NSObjectError()])
        }
    }
    
    func makeTable(_ output: [PreemptiveTableNode.Output]) {
        output.forEach {
            let value = Value(state: $0.state.base,
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
                                      event: event)] {
            state = transition.nextState
            transition.actions.forEach { $0() }
        }
    }
}
