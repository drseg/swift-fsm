//
//  TransitionBuilder.swift
//
//  Created by Daniel Segall on 03/03/2023.
//

import Foundation

protocol TransitionBuilder {
    associatedtype State: Hashable
    associatedtype Event: Hashable
}

extension TransitionBuilder {
    func define(
        _ s1: State,
        _ rest: State...,
        superState: SuperState,
        entryActions: [() -> ()],
        exitActions: [() -> ()],
        file: String = #file,
        line: Int = #line
    ) -> Syntax.Define<State> {
        .init([s1] + rest,
              superState: superState,
              entryActions: entryActions,
              exitActions: exitActions,
              elements: [],
              file: file,
              line: line)
    }
    
    func define(
        _ s1: State,
        _ rest: State...,
        superState: SuperState? = nil,
        entryActions: [() -> ()],
        exitActions: [() -> ()],
        file: String = #file,
        line: Int = #line,
        @Internal.SentenceBuilder _ block: () -> ([any Sentence])
    ) -> Syntax.Define<State> {
        .init(states: [s1] + rest,
              superState: superState,
              entryActions: entryActions,
              exitActions: exitActions,
              file: file,
              line: line,
              block)
    }
    
    func matching(
        _ p: any Predicate,
        file: String = #file,
        line: Int = #line
    ) -> Syntax.Matching {
        .init(p, file: file, line: line)
    }
    
    func matching(
        any: any Predicate,
        _ any2: any Predicate,
        _ anyRest: any Predicate...,
        file: String = #file,
        line: Int = #line
    ) -> Syntax.Matching {
        .init(any: [any, any2] + anyRest, all: [], file: file, line: line)
    }
    
    func matching(
        all: any Predicate,
        _ all2: any Predicate,
        _ allRest: any Predicate...,
        file: String = #file,
        line: Int = #line
    ) -> Syntax.Matching {
        .init(any: [], all: [all, all2] + allRest, file: file, line: line)
    }
    
    func matching(
        any: any Predicate,
        _ any2: any Predicate,
        _ anyRest: any Predicate...,
        all: any Predicate,
        _ all2: any Predicate,
        _ allRest: any Predicate...,
        file: String = #file,
        line: Int = #line
    ) -> Syntax.Matching {
        .init(any: [any, any2] + anyRest, all: [all, all2] + allRest, file: file, line: line)
    }
    
    func when(
        _ first: Event,
        _ rest: Event...,
        file: String = #file,
        line: Int = #line
    ) -> Syntax.When<Event> {
        .init([first] + rest, file: file, line: line)
    }
    
    func then(
        _ state: State? = nil,
        file: String = #file,
        line: Int = #line
    ) -> Syntax.Then<State> {
        .init(state, file: file, line: line)
    }
    
    func actions(
        _ a1: @escaping () -> (),
        _ aRest: () -> ()...,
        file: String = #file,
        line: Int = #line,
        @Internal.SentenceBuilder _ block: () -> ([any Sentence])
    ) -> Internal.ActionsSentence {
        Syntax.Actions([a1] + aRest, file: file, line: line)(block)
    }
    
    func actions(
        _ a1: @escaping () -> (),
        _ aRest: () -> ()...,
        file: String = #file,
        line: Int = #line,
        @Internal.MWABuilder _ block: () -> ([Internal.MatchingWhenActions])
    ) -> Internal.MWASentence {
        Syntax.Actions([a1] + aRest, file: file, line: line)(block)
    }
    
    func actions(
        _ a1: @escaping () -> (),
        _ aRest: () -> ()...,
        file: String = #file,
        line: Int = #line,
        @Internal.MTABuilder _ block: () -> ([Internal.MatchingThenActions])
    ) -> Internal.MTASentence {
        Syntax.Actions([a1] + aRest, file: file, line: line)(block)
    }
}
