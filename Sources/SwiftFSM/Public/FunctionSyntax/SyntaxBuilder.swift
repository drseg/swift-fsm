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
        @Syntax.MWTABuilder _ block: () -> [Syntax.MWTA]
    ) -> Syntax.Define<State, Event> {
        .init(state: state,
              adopts: superStates,
              onEntry: onEntry,
              onExit: onExit,
              file: file,
              line: line,
              block)
    }
}

// MARK: - Actions
public extension SyntaxBuilder {
    func actions(
        _ action: @escaping FSMAction,
        file: String = #file,
        line: Int = #line,
        @Syntax.MWTABuilder _ block: () -> [Syntax.MWTA]
    ) -> Syntax.MWTABlock {
        Syntax.Actions<Event>(Array(action), file: file, line: line)
            .callAsFunction(block)
    }

    func actions(
        _ action: @escaping FSMActionWithEvent<Event>,
        file: String = #file,
        line: Int = #line,
        @Syntax.MWTABuilder _ block: () -> [Syntax.MWTA]
    ) -> Syntax.MWTABlock {
        Syntax.Actions<Event>(Array(action), file: file, line: line)
            .callAsFunction(block)
    }

    func actions(
        _ actions: [AnyAction],
        file: String = #file,
        line: Int = #line,
        @Syntax.MWTABuilder _ block: () -> [Syntax.MWTA]
    ) -> Syntax.MWTABlock {
        Syntax.Actions<Event>(actions, file: file, line: line)
            .callAsFunction(block)
    }

    func actions(
        _ action: @escaping FSMAction,
        file: String = #file,
        line: Int = #line,
        @Syntax.MWABuilder _ block: () -> [Syntax.MWA]
    ) -> Syntax.MWABlock {
        Syntax.Actions<Event>(Array(action), file: file, line: line)
            .callAsFunction(block)
    }

    func actions(
        _ action: @escaping FSMActionWithEvent<Event>,
        file: String = #file,
        line: Int = #line,
        @Syntax.MWABuilder _ block: () -> [Syntax.MWA]
    ) -> Syntax.MWABlock {
        Syntax.Actions<Event>(Array(action), file: file, line: line)
            .callAsFunction(block)
    }

    func actions(
        _ actions: [AnyAction],
        file: String = #file,
        line: Int = #line,
        @Syntax.MWABuilder _ block: () -> [Syntax.MWA]
    ) -> Syntax.MWABlock {
        Syntax.Actions<Event>(actions, file: file, line: line)
            .callAsFunction(block)
    }

    func actions(
        _ action: @escaping FSMAction,
        file: String = #file,
        line: Int = #line,
        @Syntax.MTABuilder _ block: () -> [Syntax.MTA]
    ) -> Syntax.MTABlock {
        Syntax.Actions<Event>(Array(action), file: file, line: line)
            .callAsFunction(block)
    }

    func actions(
        _ action: @escaping FSMActionWithEvent<Event>,
        file: String = #file,
        line: Int = #line,
        @Syntax.MTABuilder _ block: () -> [Syntax.MTA]
    ) -> Syntax.MTABlock {
        Syntax.Actions<Event>(Array(action), file: file, line: line)
            .callAsFunction(block)
    }

    func actions(
        _ actions: [AnyAction],
        file: String = #file,
        line: Int = #line,
        @Syntax.MTABuilder _ block: () -> [Syntax.MTA]
    ) -> Syntax.MTABlock {
        Syntax.Actions<Event>(actions, file: file, line: line)
            .callAsFunction(block)
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
        @Syntax.MWABuilder _ block: () -> [Syntax.MWA]
    ) -> Syntax.MWTABlock {
        Syntax.Then<State, Event>(state, file: file, line: line)
            .callAsFunction(block)
    }

    func then(
        _ state: State? = nil,
        file: String = #file,
        line: Int = #line,
        @Syntax.MABuilder _ block: () -> [Syntax.MA]
    ) -> Syntax.MTABlock {
        Syntax.Then<State, Event>(state, file: file, line: line)
            .callAsFunction(block)
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
        @Syntax.MTABuilder _ block: () -> [Syntax.MTA]
    ) -> Syntax.MWTABlock {
        Syntax.When<State, Event>([event] + otherEvents, file: file, line: line)
            .callAsFunction(block)
    }

    func when(
        _ event: Event,
        file: String = #file,
        line: Int = #line,
        @Syntax.MTABuilder _ block: () -> [Syntax.MTA]
    ) -> Syntax.MWTABlock {
        Syntax.When<State, Event>([event], file: file, line: line)
            .callAsFunction(block)
    }

    func when(
        _ event: Event,
        or otherEvents: Event...,
        file: String = #file,
        line: Int = #line,
        @Syntax.MABuilder _ block: () -> [Syntax.MA]
    ) -> Syntax.MWABlock {
        Syntax.When<State, Event>([event] + otherEvents, file: file, line: line)
            .callAsFunction(block)
    }

    func when(
        _ event: Event,
        file: String = #file,
        line: Int = #line,
        @Syntax.MABuilder _ block: () -> [Syntax.MA]
    ) -> Syntax.MWABlock {
        Syntax.When<State, Event>([event], file: file, line: line)
            .callAsFunction(block)
    }
}

// MARK: - Overriding
public extension SyntaxBuilder {
    func overriding(
        @Syntax.MWTABuilder _ block: () -> [Syntax.MWTA]
    ) -> [Syntax.MWTA] {
        Syntax.Override().callAsFunction(block)
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
        @Syntax.MWTABuilder _ block: () -> [Syntax.MWTA]
    ) {
        self.init(
            nodes: block().nodes.withOverrideGroupID(),
            superStates: superStates,
            onEntry: onEntry,
            onExit: onExit
        )
    }
}
