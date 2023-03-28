//
//  TableBuilder.swift
//
//  Created by Daniel Segall on 03/03/2023.
//

import Foundation

protocol TableBuilder {
    associatedtype State: Hashable
    associatedtype Event: Hashable
}

extension TableBuilder {
    func define(
        _ s1: State,
        _ rest: State...,
        superState: SuperState,
        onEntry: [() -> ()] = [],
        onExit: [() -> ()] = [],
        file: String = #file,
        line: Int = #line
    ) -> Syntax.Define<State> {
        .init([s1] + rest,
              superState: superState,
              onEntry: onEntry,
              onExit: onExit,
              elements: [],
              file: file,
              line: line)
    }
    
    func define(
        _ s1: State,
        _ rest: State...,
        superState: SuperState? = nil,
        onEntry: [() -> ()] = [],
        onExit: [() -> ()] = [],
        file: String = #file,
        line: Int = #line,
        @Internal.MWTABuilder _ block: () -> ([any MWTA])
    ) -> Syntax.Define<State> {
        .init(states: [s1] + rest,
              superState: superState,
              onEntry: onEntry,
              onExit: onExit,
              file: file,
              line: line,
              block)
    }
    
    func matching(
        _ first: any Predicate,
        or: any Predicate...,
        and: any Predicate...,
        file: String = #file,
        line: Int = #line
    ) -> Syntax.Matching {
        .init(first, or: or, and: and, file: file, line: line)
    }
    
    func matching(
        _ first: any Predicate,
        or: any Predicate...,
        and: any Predicate...,
        file: String = #file,
        line: Int = #line,
        @Internal.MWTABuilder _ block: () -> ([any MWTA])
    ) -> Internal.MWTASentence {
        Syntax.Matching(first, or: or, and: and, file: file, line: line).callAsFunction(block)
    }
    
    func matching(
        _ first: any Predicate,
        or: any Predicate...,
        and: any Predicate...,
        file: String = #file,
        line: Int = #line,
        @Internal.MWABuilder _ block: () -> ([any MWA])
    ) -> Internal.MWASentence {
        Syntax.Matching(first, or: or, and: and, file: file, line: line).callAsFunction(block)
    }
    
    func matching(
        _ first: any Predicate,
        or: any Predicate...,
        and: any Predicate...,
        file: String = #file,
        line: Int = #line,
        @Internal.MTABuilder _ block: () -> ([any MTA])
    ) -> Internal.MTASentence {
        Syntax.Matching(first, or: or, and: and, file: file, line: line).callAsFunction(block)
    }
    
    func when(
        _ first: Event,
        _ rest: Event...,
        file: String = #file,
        line: Int = #line
    ) -> Syntax.When<Event> {
        .init([first] + rest, file: file, line: line)
    }
    
    func when(
        _ first: Event,
        _ rest: Event...,
        file: String = #file,
        line: Int = #line,
        @Internal.MTABuilder _ block: () -> ([any MTA])
    ) -> Internal.MWTASentence {
        Syntax.When.init([first] + rest, file: file, line: line).callAsFunction(block)
    }
    
    func when(
        _ first: Event,
        _ rest: Event...,
        file: String = #file,
        line: Int = #line,
        @Internal.MABuilder _ block: () -> ([any MA])
    ) -> Internal.MWASentence {
        Syntax.When.init([first] + rest, file: file, line: line).callAsFunction(block)
    }
    
    func then(
        _ state: State? = nil,
        file: String = #file,
        line: Int = #line
    ) -> Syntax.Then<State> {
        .init(state, file: file, line: line)
    }
    
    func then(
        _ state: State? = nil,
        file: String = #file,
        line: Int = #line,
        @Internal.MWABuilder _ block: () -> ([any MWA])
    ) -> Internal.MWTASentence {
        Syntax.Then(state, file: file, line: line).callAsFunction(block)
    }
    
    func then(
        _ state: State? = nil,
        file: String = #file,
        line: Int = #line,
        @Internal.MABuilder _ block: () -> ([any MA])
    ) -> Internal.MTASentence {
        Syntax.Then(state, file: file, line: line).callAsFunction(block)
    }
    
    func actions(
        _ a1: @escaping () -> (),
        _ aRest: () -> ()...,
        file: String = #file,
        line: Int = #line,
        @Internal.MWTABuilder _ block: () -> ([any MWTA])
    ) -> Internal.MWTASentence {
        Syntax.Actions([a1] + aRest, file: file, line: line).callAsFunction(block)
    }
    
    func actions(
        _ a1: @escaping () -> (),
        _ aRest: () -> ()...,
        file: String = #file,
        line: Int = #line,
        @Internal.MWABuilder _ block: () -> ([any MWA])
    ) -> Internal.MWASentence {
        Syntax.Actions([a1] + aRest, file: file, line: line).callAsFunction(block)
    }
    
    func actions(
        _ a1: @escaping () -> (),
        _ aRest: () -> ()...,
        file: String = #file,
        line: Int = #line,
        @Internal.MTABuilder _ block: () -> ([any MTA])
    ) -> Internal.MTASentence {
        Syntax.Actions([a1] + aRest, file: file, line: line).callAsFunction(block)
    }
}
