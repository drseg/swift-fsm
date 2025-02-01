import Foundation

public typealias FSMHashable = Hashable & Sendable

@MainActor
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
        @Internal.MWTABuilder _ block: () -> [MWTA]
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
        _ action: @escaping FSMSyncAction,
        file: String = #file,
        line: Int = #line,
        @Internal.MWTABuilder _ block: () -> [MWTA]
    ) -> Internal.MWTASentence {
        Syntax.Actions<Event>(Array(action), file: file, line: line)
            .callAsFunction(block)
    }

    func actions(
        _ action: @escaping FSMAsyncAction,
        file: String = #file,
        line: Int = #line,
        @Internal.MWTABuilder _ block: () -> [MWTA]
    ) -> Internal.MWTASentence {
        Syntax.Actions<Event>(Array(action), file: file, line: line)
            .callAsFunction(block)
    }

    func actions(
        _ action: @escaping FSMSyncActionWithEvent<Event>,
        file: String = #file,
        line: Int = #line,
        @Internal.MWTABuilder _ block: () -> [MWTA]
    ) -> Internal.MWTASentence {
        Syntax.Actions<Event>(Array(action), file: file, line: line)
            .callAsFunction(block)
    }

    func actions(
        _ action: @escaping FSMAsyncActionWithEvent<Event>,
        file: String = #file,
        line: Int = #line,
        @Internal.MWTABuilder _ block: () -> [MWTA]
    ) -> Internal.MWTASentence {
        Syntax.Actions<Event>(Array(action), file: file, line: line)
            .callAsFunction(block)
    }

    func actions(
        _ actions: [AnyAction],
        file: String = #file,
        line: Int = #line,
        @Internal.MWTABuilder _ block: () -> [MWTA]
    ) -> Internal.MWTASentence {
        Syntax.Actions<Event>(actions, file: file, line: line)
            .callAsFunction(block)
    }

    func actions(
        _ action: @escaping FSMSyncAction,
        file: String = #file,
        line: Int = #line,
        @Internal.MWABuilder _ block: () -> [MWA]
    ) -> Internal.MWASentence {
        Syntax.Actions<Event>(Array(action), file: file, line: line)
            .callAsFunction(block)
    }

    func actions(
        _ action: @escaping FSMAsyncAction,
        file: String = #file,
        line: Int = #line,
        @Internal.MWABuilder _ block: () -> [MWA]
    ) -> Internal.MWASentence {
        Syntax.Actions<Event>(Array(action), file: file, line: line)
            .callAsFunction(block)
    }

    func actions(
        _ action: @escaping FSMSyncActionWithEvent<Event>,
        file: String = #file,
        line: Int = #line,
        @Internal.MWABuilder _ block: () -> [MWA]
    ) -> Internal.MWASentence {
        Syntax.Actions<Event>(Array(action), file: file, line: line)
            .callAsFunction(block)
    }

    func actions(
        _ action: @escaping FSMAsyncActionWithEvent<Event>,
        file: String = #file,
        line: Int = #line,
        @Internal.MWABuilder _ block: () -> [MWA]
    ) -> Internal.MWASentence {
        Syntax.Actions<Event>(Array(action), file: file, line: line)
            .callAsFunction(block)
    }

    func actions(
        _ actions: [AnyAction],
        file: String = #file,
        line: Int = #line,
        @Internal.MWABuilder _ block: () -> [MWA]
    ) -> Internal.MWASentence {
        Syntax.Actions<Event>(actions, file: file, line: line)
            .callAsFunction(block)
    }

    func actions(
        _ action: @escaping FSMSyncAction,
        file: String = #file,
        line: Int = #line,
        @Internal.MTABuilder _ block: () -> [MTA]
    ) -> Internal.MTASentence {
        Syntax.Actions<Event>(Array(action), file: file, line: line)
            .callAsFunction(block)
    }

    func actions(
        _ action: @escaping FSMAsyncAction,
        file: String = #file,
        line: Int = #line,
        @Internal.MTABuilder _ block: () -> [MTA]
    ) -> Internal.MTASentence {
        Syntax.Actions<Event>(Array(action), file: file, line: line)
            .callAsFunction(block)
    }

    func actions(
        _ action: @escaping FSMSyncActionWithEvent<Event>,
        file: String = #file,
        line: Int = #line,
        @Internal.MTABuilder _ block: () -> [MTA]
    ) -> Internal.MTASentence {
        Syntax.Actions<Event>(Array(action), file: file, line: line)
            .callAsFunction(block)
    }

    func actions(
        _ action: @escaping FSMAsyncActionWithEvent<Event>,
        file: String = #file,
        line: Int = #line,
        @Internal.MTABuilder _ block: () -> [MTA]
    ) -> Internal.MTASentence {
        Syntax.Actions<Event>(Array(action), file: file, line: line)
            .callAsFunction(block)
    }

    func actions(
        _ actions: [AnyAction],
        file: String = #file,
        line: Int = #line,
        @Internal.MTABuilder _ block: () -> [MTA]
    ) -> Internal.MTASentence {
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
        @Internal.MWABuilder _ block: () -> [MWA]
    ) -> Internal.MWTASentence {
        Syntax.Then<State, Event>(state, file: file, line: line)
            .callAsFunction(block)
    }

    func then(
        _ state: State? = nil,
        file: String = #file,
        line: Int = #line,
        @Internal.MABuilder _ block: () -> [MA]
    ) -> Internal.MTASentence {
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
        @Internal.MTABuilder _ block: () -> [MTA]
    ) -> Internal.MWTASentence {
        Syntax.When<State, Event>([event] + otherEvents, file: file, line: line)
            .callAsFunction(block)
    }

    func when(
        _ event: Event,
        file: String = #file,
        line: Int = #line,
        @Internal.MTABuilder _ block: () -> [MTA]
    ) -> Internal.MWTASentence {
        Syntax.When<State, Event>([event], file: file, line: line)
            .callAsFunction(block)
    }

    func when(
        _ event: Event,
        or otherEvents: Event...,
        file: String = #file,
        line: Int = #line,
        @Internal.MABuilder _ block: () -> [MA]
    ) -> Internal.MWASentence {
        Syntax.When<State, Event>([event] + otherEvents, file: file, line: line)
            .callAsFunction(block)
    }

    func when(
        _ event: Event,
        file: String = #file,
        line: Int = #line,
        @Internal.MABuilder _ block: () -> [MA]
    ) -> Internal.MWASentence {
        Syntax.When<State, Event>([event], file: file, line: line)
            .callAsFunction(block)
    }
}

// MARK: - Overriding
public extension SyntaxBuilder {
    func overriding(
        @Internal.MWTABuilder _ block: () -> [MWTA]
    ) -> [MWTA] {
        Syntax.Override().callAsFunction(block)
    }
}
