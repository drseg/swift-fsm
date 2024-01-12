import Foundation

public protocol SyntaxBuilder {
    associatedtype State: Hashable
    associatedtype Event: Hashable
}

public extension SyntaxBuilder {
    func define(
        _ state: State,
        adopts superState: SuperState,
        _ andSuperStates: SuperState...,
        onEntry: [Action] = [],
        onExit: [Action] = [],
        file: String = #file,
        line: Int = #line
    ) -> Syntax.Define<State> {
        .init(state,
              adopts: [superState] + andSuperStates,
              onEntry: onEntry,
              onExit: onExit,
              elements: [],
              file: file,
              line: line)
    }

    func define(
        _ state: State,
        adopts superStates: SuperState...,
        onEntry: [Action] = [],
        onExit: [Action] = [],
        file: String = #file,
        line: Int = #line,
        @Internal.MWTABuilder _ block: () -> [MWTA]
    ) -> Syntax.Define<State> {
        .init(state: state,
              adopts: superStates,
              onEntry: onEntry,
              onExit: onExit,
              file: file,
              line: line,
              block)
    }

    func define(
        _ state: State,
        onEntry: [Action] = [],
        onExit: [Action] = [],
        file: String = #file,
        line: Int = #line,
        @Internal.MWTABuilder _ block: () -> [MWTA]
    ) -> Syntax.Define<State> {
        .init(state: state,
              adopts: [],
              onEntry: onEntry,
              onExit: onExit,
              file: file,
              line: line,
              block)
    }

    func when(
        _ event: Event,
        or otherEvents: Event...,
        file: String = #file,
        line: Int = #line
    ) -> Syntax.When<Event> {
        .init([event] + otherEvents, file: file, line: line)
    }

    func when(
        _ event: Event,
        file: String = #file,
        line: Int = #line
    ) -> Syntax.When<Event> {
        .init(event, file: file, line: line)
    }

    func when(
        _ event: Event,
        or otherEvents: Event...,
        file: String = #file,
        line: Int = #line,
        @Internal.MTABuilder _ block: () -> [MTA]
    ) -> Internal.MWTASentence {
        Syntax.When<Event>([event] + otherEvents, file: file, line: line).callAsFunction(block)
    }

    func when(
        _ event: Event,
        file: String = #file,
        line: Int = #line,
        @Internal.MTABuilder _ block: () -> [MTA]
    ) -> Internal.MWTASentence {
        Syntax.When<Event>(event, file: file, line: line).callAsFunction(block)
    }

    func when(
        _ event: Event,
        or otherEvents: Event...,
        file: String = #file,
        line: Int = #line,
        @Internal.MABuilder _ block: () -> [MA]
    ) -> Internal.MWASentence {
        Syntax.When<Event>([event] + otherEvents, file: file, line: line).callAsFunction(block)
    }

    func when(
        _ event: Event,
        file: String = #file,
        line: Int = #line,
        @Internal.MABuilder _ block: () -> [MA]
    ) -> Internal.MWASentence {
        Syntax.When<Event>(event, file: file, line: line).callAsFunction(block)
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
        @Internal.MWABuilder _ block: () -> [MWA]
    ) -> Internal.MWTASentence {
        Syntax.Then<State>(state, file: file, line: line).callAsFunction(block)
    }

    func then(
        _ state: State? = nil,
        file: String = #file,
        line: Int = #line,
        @Internal.MABuilder _ block: () -> [MA]
    ) -> Internal.MTASentence {
        Syntax.Then<State>(state, file: file, line: line).callAsFunction(block)
    }

    func actions(
        _ action: @escaping Action,
        _ otherActions: Action...,
        file: String = #file,
        line: Int = #line,
        @Internal.MWTABuilder _ block: () -> [MWTA]
    ) -> Internal.MWTASentence {
        Syntax.Actions([action] + otherActions, file: file, line: line).callAsFunction(block)
    }

    func actions(
        _ action: @escaping ActionWithEvent<Event>,
        _ otherActions: ActionWithEvent<Event>...,
        file: String = #file,
        line: Int = #line,
        @Internal.MWTABuilder _ block: () -> [MWTA]
    ) -> Internal.MWTASentence {
        Syntax.Actions([action] + otherActions, file: file, line: line).callAsFunction(block)
    }

    func actions(
        _ action: @escaping Action,
        _ otherActions: Action...,
        file: String = #file,
        line: Int = #line,
        @Internal.MWABuilder _ block: () -> [MWA]
    ) -> Internal.MWASentence {
        Syntax.Actions([action] + otherActions, file: file, line: line).callAsFunction(block)
    }

    func actions(
        _ action: @escaping ActionWithEvent<Event>,
        _ otherActions: ActionWithEvent<Event>...,
        file: String = #file,
        line: Int = #line,
        @Internal.MWABuilder _ block: () -> [MWA]
    ) -> Internal.MWASentence {
        Syntax.Actions([action] + otherActions, file: file, line: line).callAsFunction(block)
    }

    func actions(
        _ action: @escaping Action,
        _ otherActions: Action...,
        file: String = #file,
        line: Int = #line,
        @Internal.MTABuilder _ block: () -> [MTA]
    ) -> Internal.MTASentence {
        Syntax.Actions([action] + otherActions, file: file, line: line).callAsFunction(block)
    }

    func actions(
        _ action: @escaping ActionWithEvent<Event>,
        _ otherActions: ActionWithEvent<Event>...,
        file: String = #file,
        line: Int = #line,
        @Internal.MTABuilder _ block: () -> [MTA]
    ) -> Internal.MTASentence {
        Syntax.Actions([action] + otherActions, file: file, line: line).callAsFunction(block)
    }

    func override(
        @Internal.MWTABuilder _ block: () -> [MWTA]
    ) -> [MWTA] {
        Syntax.Override().callAsFunction(block)
    }
}

public protocol ExpandedSyntaxBuilder: SyntaxBuilder { }

public extension ExpandedSyntaxBuilder {
    typealias Matching = Syntax.Expanded.Matching
    typealias Condition = Syntax.Expanded.Condition

    func matching<P: Predicate>(
        _ predicate: P,
        file: String = #file,
        line: Int = #line
    ) -> Matching {
        .init(predicate, file: file, line: line)
    }

    func matching<P: Predicate>(
        _ predicate: P,
        or: P...,
        file: String = #file,
        line: Int = #line
    ) -> Matching {
        .init(predicate, or: or, and: [], file: file, line: line)
    }

    func matching<P: Predicate>(
        _ predicate: P,
        and: P...,
        file: String = #file,
        line: Int = #line
    ) -> Matching {
        .init(predicate, or: [], and: and, file: file, line: line)
    }

    func matching<P: Predicate>(
        _ predicate: P,
        or: P...,
        and: any Predicate...,
        file: String = #file,
        line: Int = #line
    ) -> Matching {
        .init(predicate, or: or, and: and, file: file, line: line)
    }

    func condition(
        _ condition: @escaping () -> Bool,
        file: String = #file,
        line: Int = #line
    ) -> Condition {
        .init(condition, file: file, line: line)
    }

    func matching<P: Predicate>(
        _ predicate: P,
        file: String = #file,
        line: Int = #line,
        @Internal.MWTABuilder _ block: () -> [MWTA]
    ) -> Internal.MWTASentence {
        Matching(predicate, file: file, line: line).callAsFunction(block)
    }

    func matching<P: Predicate>(
        _ predicate: P,
        or: P...,
        file: String = #file,
        line: Int = #line,
        @Internal.MWTABuilder _ block: () -> [MWTA]
    ) -> Internal.MWTASentence {
        Matching(predicate, or: or, and: [], file: file, line: line).callAsFunction(block)
    }

    func matching<P: Predicate>(
        _ predicate: P,
        or: P...,
        and: any Predicate...,
        file: String = #file,
        line: Int = #line,
        @Internal.MWTABuilder _ block: () -> [MWTA]
    ) -> Internal.MWTASentence {
        Matching(predicate, or: or, and: and, file: file, line: line).callAsFunction(block)
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
        _ predicate: P,
        file: String = #file,
        line: Int = #line,
        @Internal.MWABuilder _ block: () -> [MWA]
    ) -> Internal.MWASentence {
        Matching(predicate, file: file, line: line).callAsFunction(block)
    }

    func matching<P: Predicate>(
        _ predicate: P,
        or: P...,
        file: String = #file,
        line: Int = #line,
        @Internal.MWABuilder _ block: () -> [MWA]
    ) -> Internal.MWASentence {
        Matching(predicate, or: or, and: [], file: file, line: line).callAsFunction(block)
    }

    func matching<P: Predicate>(
        _ predicate: P,
        or: P...,
        and: any Predicate...,
        file: String = #file,
        line: Int = #line,
        @Internal.MWABuilder _ block: () -> [MWA]
    ) -> Internal.MWASentence {
        Matching(predicate, or: or, and: and, file: file, line: line).callAsFunction(block)
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
        _ predicate: P,
        file: String = #file,
        line: Int = #line,
        @Internal.MTABuilder _ block: () -> [MTA]
    ) -> Internal.MTASentence {
        Matching(predicate, file: file, line: line).callAsFunction(block)
    }

    func matching<P: Predicate>(
        _ predicate: P,
        or: P...,
        file: String = #file,
        line: Int = #line,
        @Internal.MTABuilder _ block: () -> [MTA]
    ) -> Internal.MTASentence {
        Matching(predicate, or: or, and: [], file: file, line: line).callAsFunction(block)
    }

    func matching<P: Predicate>(
        _ predicate: P,
        or: P...,
        and: any Predicate...,
        file: String = #file,
        line: Int = #line,
        @Internal.MTABuilder _ block: () -> [MTA]
    ) -> Internal.MTASentence {
        Matching(predicate, or: or, and: and, file: file, line: line).callAsFunction(block)
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
