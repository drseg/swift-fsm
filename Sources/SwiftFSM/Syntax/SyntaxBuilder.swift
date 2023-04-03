//
//  TableBuilder.swift
//
//  Created by Daniel Segall on 03/03/2023.
//

import Foundation

protocol SyntaxBuilder {
    associatedtype StateType: Hashable
    associatedtype EventType: Hashable
}

extension SyntaxBuilder {
    func define(
        _ state: StateType,
        superStates: SuperState,
        _ rest2: SuperState...,
        onEntry: [Action] = [],
        onExit: [Action] = [],
        file: String = #file,
        line: Int = #line
    ) -> Syntax.Define<StateType> {
        .init(state,
              superStates: [superStates] + rest2,
              onEntry: onEntry,
              onExit: onExit,
              elements: [],
              file: file,
              line: line)
    }
    
    func define(
        _ state: StateType,
        superStates: SuperState...,
        onEntry: [Action] = [],
        onExit: [Action] = [],
        file: String = #file,
        line: Int = #line,
        @Internal.MWTABuilder _ block: () -> [any MWTA]
    ) -> Syntax.Define<StateType> {
        .init(state: state,
              superStates: superStates,
              onEntry: onEntry,
              onExit: onExit,
              file: file,
              line: line,
              block)
    }
    
    func when(
        _ first: EventType,
        or rest: EventType...,
        file: String = #file,
        line: Int = #line
    ) -> Syntax.When<EventType> {
        .init([first] + rest, file: file, line: line)
    }
    
    func when(
        _ first: EventType,
        or rest: EventType...,
        file: String = #file,
        line: Int = #line,
        @Internal.MTABuilder _ block: () -> [any MTA]
    ) -> Internal.MWTASentence {
        Syntax.When.init([first] + rest, file: file, line: line).callAsFunction(block)
    }
    
    func when(
        _ first: EventType,
        or rest: EventType...,
        file: String = #file,
        line: Int = #line,
        @Internal.MABuilder _ block: () -> [any MA]
    ) -> Internal.MWASentence {
        Syntax.When.init([first] + rest, file: file, line: line).callAsFunction(block)
    }
    
    func then(
        _ state: StateType? = nil,
        file: String = #file,
        line: Int = #line
    ) -> Syntax.Then<StateType> {
        .init(state, file: file, line: line)
    }
    
    func then(
        _ state: StateType? = nil,
        file: String = #file,
        line: Int = #line,
        @Internal.MWABuilder _ block: () -> [any MWA]
    ) -> Internal.MWTASentence {
        Syntax.Then(state, file: file, line: line).callAsFunction(block)
    }
    
    func then(
        _ state: StateType? = nil,
        file: String = #file,
        line: Int = #line,
        @Internal.MABuilder _ block: () -> [any MA]
    ) -> Internal.MTASentence {
        Syntax.Then(state, file: file, line: line).callAsFunction(block)
    }
    
    func actions(
        _ a1: @escaping Action,
        _ aRest: Action...,
        file: String = #file,
        line: Int = #line,
        @Internal.MWTABuilder _ block: () -> [any MWTA]
    ) -> Internal.MWTASentence {
        Syntax.Actions([a1] + aRest, file: file, line: line).callAsFunction(block)
    }
    
    func actions(
        _ a1: @escaping Action,
        _ aRest: Action...,
        file: String = #file,
        line: Int = #line,
        @Internal.MWABuilder _ block: () -> [any MWA]
    ) -> Internal.MWASentence {
        Syntax.Actions([a1] + aRest, file: file, line: line).callAsFunction(block)
    }
    
    func actions(
        _ a1: @escaping Action,
        _ aRest: Action...,
        file: String = #file,
        line: Int = #line,
        @Internal.MTABuilder _ block: () -> [any MTA]
    ) -> Internal.MTASentence {
        Syntax.Actions([a1] + aRest, file: file, line: line).callAsFunction(block)
    }
}

protocol ExpandedSyntaxBuilder: SyntaxBuilder { }

extension ExpandedSyntaxBuilder {
    typealias Matching = Syntax.Expanded.Matching
    
    func matching(
        _ first: any Predicate,
        or: any Predicate...,
        and: any Predicate...,
        file: String = #file,
        line: Int = #line
    ) -> Matching {
        .init(first, or: or, and: and, file: file, line: line)
    }
    
    func matching(
        _ first: any Predicate,
        or: any Predicate...,
        and: any Predicate...,
        file: String = #file,
        line: Int = #line,
        @Internal.MWTABuilder _ block: () -> [any MWTA]
    ) -> Internal.MWTASentence {
        Matching(first, or: or, and: and, file: file, line: line).callAsFunction(block)
    }
    
    func matching(
        _ first: any Predicate,
        or: any Predicate...,
        and: any Predicate...,
        file: String = #file,
        line: Int = #line,
        @Internal.MWABuilder _ block: () -> [any MWA]
    ) -> Internal.MWASentence {
        Matching(first, or: or, and: and, file: file, line: line).callAsFunction(block)
    }
    
    func matching(
        _ first: any Predicate,
        or: any Predicate...,
        and: any Predicate...,
        file: String = #file,
        line: Int = #line,
        @Internal.MTABuilder _ block: () -> [any MTA]
    ) -> Internal.MTASentence {
        Matching(first, or: or, and: and, file: file, line: line).callAsFunction(block)
    }
}
