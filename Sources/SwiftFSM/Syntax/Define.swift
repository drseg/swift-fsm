import Foundation

public extension Syntax {
    struct Define<State: Hashable> {
        let node: DefineNode

        public init(_ state: State,
                    adopts superState: SuperState,
                    _ andSuperStates: SuperState...,
                    onEntry: [FSMAction],
                    onExit: [FSMAction],
                    file: String = #file,
                    line: Int = #line
        ) {
            self.init(state,
                      adopts: [superState] + andSuperStates,
                      onEntry: onEntry,
                      onExit: onExit,
                      elements: [],
                      file: file,
                      line: line)
        }

        public init(_ state: State,
                    adopts superStates: SuperState...,
                    onEntry: [FSMAction] = [],
                    onExit: [FSMAction] = [],
                    file: String = #file,
                    line: Int = #line,
                    @Internal.MWTABuilder _ block: () -> [MWTA]
        ) {
            self.init(state: state,
                      adopts: superStates,
                      onEntry: onEntry,
                      onExit: onExit,
                      file: file,
                      line: line,
                      block)
        }

        public init(_ state: State,
                    onEntry: [FSMAction] = [],
                    onExit: [FSMAction] = [],
                    file: String = #file,
                    line: Int = #line,
                    @Internal.MWTABuilder _ block: () -> [MWTA]
        ) {
            self.init(state: state,
                      adopts: [],
                      onEntry: onEntry,
                      onExit: onExit,
                      file: file,
                      line: line,
                      block)
        }

        public init(state: State,
                    adopts superStates: [SuperState] = [],
                    onEntry: [FSMAction],
                    onExit: [FSMAction],
                    file: String = #file,
                    line: Int = #line,
                    @Internal.MWTABuilder _ block: () -> [MWTA]
        ) {
            let elements = block()

            self.init(state,
                      adopts: elements.isEmpty ? [] : superStates,
                      onEntry: onEntry,
                      onExit: onExit,
                      elements: elements,
                      file: file,
                      line: line)
        }

        internal init(_ state: State,
                      adopts superStates: [SuperState],
                      onEntry: [FSMAction],
                      onExit: [FSMAction],
                      elements: [MWTA],
                      file: String = #file,
                      line: Int = #line
        ) {
            let onEntry = superStates.map(\.onEntry).flattened + onEntry
            let onExit = superStates.map(\.onExit).flattened + onExit

            let dNode = DefineNode(onEntry: onEntry.map(AnyAction.init),
                                   onExit: onExit.map(AnyAction.init),
                                   caller: "define",
                                   file: file,
                                   line: line)

            let isValid = !superStates.isEmpty || !elements.isEmpty

            if isValid {
                let state = AnyTraceable(state, file: file, line: line)
                let rest = superStates.map(\.nodes).flattened + elements.nodes.withGroupID()
                let gNode = GivenNode(states: [state], rest: rest)

                dNode.rest = [gNode]
            }

            self.node = dNode
        }
    }
}
