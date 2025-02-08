import Foundation

public typealias FSMHashable = Hashable & Sendable

public protocol SyntaxBuilder {
    associatedtype State: FSMHashable
    associatedtype Event: FSMHashable
}

// MARK: - Define
public extension SyntaxBuilder {
    func define(
        _ state: State,
        adopts superState: SuperState,
        _ andSuperStates: SuperState...,
        onEntry: [AnyAction] = [],
        onExit: [AnyAction] = [],
        file: String = #file,
        line: Int = #line
    ) -> Syntax.Define<State, Event> {
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
        onEntry: [AnyAction] = [],
        onExit: [AnyAction] = [],
        file: String = #file,
        line: Int = #line,
        @Syntax.MWTABuilder _ group: () -> [Syntax.MatchingWhenThenActions]
    ) -> Syntax.Define<State, Event> {
        .init(state: state,
              adopts: superStates,
              onEntry: onEntry,
              onExit: onExit,
              file: file,
              line: line,
              group)
    }
}

// MARK: - Actions
public extension SyntaxBuilder {
    func actions(
        _ action: @escaping FSMAction,
        file: String = #file,
        line: Int = #line,
        @Syntax.MWTABuilder _ group: () -> [Syntax.MatchingWhenThenActions]
    ) -> Syntax.MWTA_Group {
        Syntax.Actions<Event>(Array(action), file: file, line: line)
            .callAsFunction(group)
    }

    func actions(
        _ action: @escaping FSMActionWithEvent<Event>,
        file: String = #file,
        line: Int = #line,
        @Syntax.MWTABuilder _ group: () -> [Syntax.MatchingWhenThenActions]
    ) -> Syntax.MWTA_Group {
        Syntax.Actions<Event>(Array(action), file: file, line: line)
            .callAsFunction(group)
    }

    func actions(
        _ actions: [AnyAction],
        file: String = #file,
        line: Int = #line,
        @Syntax.MWTABuilder _ group: () -> [Syntax.MatchingWhenThenActions]
    ) -> Syntax.MWTA_Group {
        Syntax.Actions<Event>(actions, file: file, line: line)
            .callAsFunction(group)
    }

    func actions(
        _ action: @escaping FSMAction,
        file: String = #file,
        line: Int = #line,
        @Syntax.MWABuilder _ group: () -> [Syntax.MatchingWhenActions]
    ) -> Syntax.MWA_Group {
        Syntax.Actions<Event>(Array(action), file: file, line: line)
            .callAsFunction(group)
    }

    func actions(
        _ action: @escaping FSMActionWithEvent<Event>,
        file: String = #file,
        line: Int = #line,
        @Syntax.MWABuilder _ group: () -> [Syntax.MatchingWhenActions]
    ) -> Syntax.MWA_Group {
        Syntax.Actions<Event>(Array(action), file: file, line: line)
            .callAsFunction(group)
    }

    func actions(
        _ actions: [AnyAction],
        file: String = #file,
        line: Int = #line,
        @Syntax.MWABuilder _ group: () -> [Syntax.MatchingWhenActions]
    ) -> Syntax.MWA_Group {
        Syntax.Actions<Event>(actions, file: file, line: line)
            .callAsFunction(group)
    }

    func actions(
        _ action: @escaping FSMAction,
        file: String = #file,
        line: Int = #line,
        @Syntax.MTABuilder _ group: () -> [Syntax.MatchingThenActions]
    ) -> Syntax.MTA_Group {
        Syntax.Actions<Event>(Array(action), file: file, line: line)
            .callAsFunction(group)
    }

    func actions(
        _ action: @escaping FSMActionWithEvent<Event>,
        file: String = #file,
        line: Int = #line,
        @Syntax.MTABuilder _ group: () -> [Syntax.MatchingThenActions]
    ) -> Syntax.MTA_Group {
        Syntax.Actions<Event>(Array(action), file: file, line: line)
            .callAsFunction(group)
    }

    func actions(
        _ actions: [AnyAction],
        file: String = #file,
        line: Int = #line,
        @Syntax.MTABuilder _ group: () -> [Syntax.MatchingThenActions]
    ) -> Syntax.MTA_Group {
        Syntax.Actions<Event>(actions, file: file, line: line)
            .callAsFunction(group)
    }
}

// MARK: - Then
public extension SyntaxBuilder {
    func then(
        _ state: State? = nil,
        file: String = #file,
        line: Int = #line
    ) -> Syntax.Then<State, Event> {
        .init(state, file: file, line: line)
    }

    func then(
        _ state: State? = nil,
        file: String = #file,
        line: Int = #line,
        @Syntax.MWABuilder _ group: () -> [Syntax.MatchingWhenActions]
    ) -> Syntax.MWTA_Group {
        Syntax.Then<State, Event>(state, file: file, line: line)
            .callAsFunction(group)
    }

    func then(
        _ state: State? = nil,
        file: String = #file,
        line: Int = #line,
        @Syntax.MABuilder _ group: () -> [Syntax.MatchingActions]
    ) -> Syntax.MTA_Group {
        Syntax.Then<State, Event>(state, file: file, line: line)
            .callAsFunction(group)
    }
}

// MARK: - When
public extension SyntaxBuilder {
    func when(
        _ event: Event,
        or otherEvents: Event...,
        file: String = #file,
        line: Int = #line
    ) -> Syntax.When<State, Event> {
        .init([event] + otherEvents, file: file, line: line)
    }

    func when(
        _ event: Event,
        file: String = #file,
        line: Int = #line
    ) -> Syntax.When<State, Event> {
        .init([event], file: file, line: line)
    }

    func when(
        _ event: Event,
        or otherEvents: Event...,
        file: String = #file,
        line: Int = #line,
        @Syntax.MTABuilder _ group: () -> [Syntax.MatchingThenActions]
    ) -> Syntax.MWTA_Group {
        Syntax.When<State, Event>([event] + otherEvents, file: file, line: line)
            .callAsFunction(group)
    }

    func when(
        _ event: Event,
        file: String = #file,
        line: Int = #line,
        @Syntax.MTABuilder _ group: () -> [Syntax.MatchingThenActions]
    ) -> Syntax.MWTA_Group {
        Syntax.When<State, Event>([event], file: file, line: line)
            .callAsFunction(group)
    }

    func when(
        _ event: Event,
        or otherEvents: Event...,
        file: String = #file,
        line: Int = #line,
        @Syntax.MABuilder _ group: () -> [Syntax.MatchingActions]
    ) -> Syntax.MWA_Group {
        Syntax.When<State, Event>([event] + otherEvents, file: file, line: line)
            .callAsFunction(group)
    }

    func when(
        _ event: Event,
        file: String = #file,
        line: Int = #line,
        @Syntax.MABuilder _ group: () -> [Syntax.MatchingActions]
    ) -> Syntax.MWA_Group {
        Syntax.When<State, Event>([event], file: file, line: line)
            .callAsFunction(group)
    }
}

// MARK: - Overriding
public extension SyntaxBuilder {
    func overriding(
        @Syntax.MWTABuilder _ group: () -> [Syntax.MatchingWhenThenActions]
    ) -> [Syntax.MatchingWhenThenActions] {
        Syntax.Override().callAsFunction(group)
    }
}

// MARK: - SuperState
public extension SuperState {
    init(
        adopts superState: SuperState,
        _ andSuperStates: SuperState...,
        onEntry: [AnyAction] = [],
        onExit: [AnyAction] = []
    ) {
        self.init(
            superStates: [superState] + andSuperStates,
            onEntry: onEntry,
            onExit: onExit
        )
    }
    
    init(
        adopts superStates: SuperState...,
        onEntry: [AnyAction] = [],
        onExit: [AnyAction] = [],
        @Syntax.MWTABuilder _ group: () -> [Syntax.MatchingWhenThenActions]
    ) {
        self.init(
            nodes: group().nodes.withOverrideGroupID(),
            superStates: superStates,
            onEntry: onEntry,
            onExit: onExit
        )
    }
}
