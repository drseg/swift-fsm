import Foundation

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
