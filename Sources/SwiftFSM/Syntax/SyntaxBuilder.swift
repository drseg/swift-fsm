import Foundation

public protocol SyntaxBuilder {
    associatedtype StateType: Hashable
    associatedtype EventType: Hashable
}

public extension SyntaxBuilder {
    func define(
        _ state: StateType,
        adopts superStates: SuperState,
        _ rest2: SuperState...,
        onEntry: [Action] = [],
        onExit: [Action] = [],
        file: String = #file,
        line: Int = #line
    ) -> Syntax.Define<StateType> {
        .init(state,
              adopts: [superStates] + rest2,
              onEntry: onEntry,
              onExit: onExit,
              elements: [],
              file: file,
              line: line)
    }
    
    func define(
        _ state: StateType,
        adopts superStates: SuperState...,
        onEntry: [Action] = [],
        onExit: [Action] = [],
        file: String = #file,
        line: Int = #line,
        @Internal.MWTABuilder _ block: () -> [MWTA]
    ) -> Syntax.Define<StateType> {
        .init(state: state,
              adopts: superStates,
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
        @Internal.MTABuilder _ block: () -> [MTA]
    ) -> Internal.MWTASentence {
        Syntax.When.init([first] + rest, file: file, line: line).callAsFunction(block)
    }
    
    func when(
        _ first: EventType,
        or rest: EventType...,
        file: String = #file,
        line: Int = #line,
        @Internal.MABuilder _ block: () -> [MA]
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
        @Internal.MWABuilder _ block: () -> [MWA]
    ) -> Internal.MWTASentence {
        Syntax.Then(state, file: file, line: line).callAsFunction(block)
    }
    
    func then(
        _ state: StateType? = nil,
        file: String = #file,
        line: Int = #line,
        @Internal.MABuilder _ block: () -> [MA]
    ) -> Internal.MTASentence {
        Syntax.Then(state, file: file, line: line).callAsFunction(block)
    }
    
    func actions(
        _ a1: @escaping Action,
        _ aRest: Action...,
        file: String = #file,
        line: Int = #line,
        @Internal.MWTABuilder _ block: () -> [MWTA]
    ) -> Internal.MWTASentence {
        Syntax.Actions([a1] + aRest, file: file, line: line).callAsFunction(block)
    }
    
    func actions(
        _ a1: @escaping Action,
        _ aRest: Action...,
        file: String = #file,
        line: Int = #line,
        @Internal.MWABuilder _ block: () -> [MWA]
    ) -> Internal.MWASentence {
        Syntax.Actions([a1] + aRest, file: file, line: line).callAsFunction(block)
    }
    
    func actions(
        _ a1: @escaping Action,
        _ aRest: Action...,
        file: String = #file,
        line: Int = #line,
        @Internal.MTABuilder _ block: () -> [MTA]
    ) -> Internal.MTASentence {
        Syntax.Actions([a1] + aRest, file: file, line: line).callAsFunction(block)
    }
}

public protocol ExpandedSyntaxBuilder: SyntaxBuilder { }

public extension ExpandedSyntaxBuilder {
    typealias Matching = Syntax.Expanded.Matching
    typealias Condition = Syntax.Expanded.Condition
    
    func matching<P: Predicate>(
        _ first: P,
        or: P...,
        and: any Predicate...,
        file: String = #file,
        line: Int = #line
    ) -> Matching {
        .init(first, or: or, and: and, file: file, line: line)
    }
    
    func condition(
        _ condition: @escaping () -> Bool,
        file: String = #file,
        line: Int = #line
    ) -> Condition {
        .init(condition, file: file, line: line)
    }
    
    func matching<P: Predicate>(
        _ first: P,
        or: P...,
        and: any Predicate...,
        file: String = #file,
        line: Int = #line,
        @Internal.MWTABuilder _ block: () -> [MWTA]
    ) -> Internal.MWTASentence {
        Matching(first, or: or, and: and, file: file, line: line).callAsFunction(block)
    }
    
    func condition(
        _ condition: @escaping () -> Bool,
        file: String = #file,
        line: Int = #line,
        @Internal.MWTABuilder _ block: () -> [MWTA]
    ) -> Internal.MWTASentence {
        Condition(condition, file: file, line: line).callAsFunction(block)
    }
    
    func matching<P: Predicate>(
        _ first: P,
        or: P...,
        and: any Predicate...,
        file: String = #file,
        line: Int = #line,
        @Internal.MWABuilder _ block: () -> [MWA]
    ) -> Internal.MWASentence {
        Matching(first, or: or, and: and, file: file, line: line).callAsFunction(block)
    }
    
    func condition(
        _ condition: @escaping () -> Bool,
        file: String = #file,
        line: Int = #line,
        @Internal.MWABuilder _ block: () -> [MWA]
    ) -> Internal.MWASentence {
        Condition(condition, file: file, line: line).callAsFunction(block)
    }
    
    func matching<P: Predicate>(
        _ first: P,
        or: P...,
        and: any Predicate...,
        file: String = #file,
        line: Int = #line,
        @Internal.MTABuilder _ block: () -> [MTA]
    ) -> Internal.MTASentence {
        Matching(first, or: or, and: and, file: file, line: line).callAsFunction(block)
    }
    
    func condition(
        _ condition: @escaping () -> Bool,
        file: String = #file,
        line: Int = #line,
        @Internal.MTABuilder _ block: () -> [MTA]
    ) -> Internal.MTASentence {
        Condition(condition, file: file, line: line).callAsFunction(block)
    }
}
