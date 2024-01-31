import Foundation

public extension Syntax {
    struct Define<State: Hashable, Event: Hashable> {
        let node: DefineNode

        public init(_ state: State,
                    adopts superState: SuperState,
                    _ andSuperStates: SuperState...,
                    onEntry: [FSMSyncAction],
                    onExit: [FSMSyncAction],
                    file: String = #file,
                    line: Int = #line
        ) {
            self.init(state,
                      adopts: [superState] + andSuperStates,
                      onEntry: onEntry.map(AnyAction.init),
                      onExit: onExit.map(AnyAction.init),
                      elements: [],
                      file: file,
                      line: line)
        }

        public init(_ state: State,
                    adopts superState: SuperState,
                    _ andSuperStates: SuperState...,
                    onEntry: [FSMSyncActionWithEvent<Event>],
                    onExit: [FSMSyncActionWithEvent<Event>],
                    file: String = #file,
                    line: Int = #line
        ) {
            self.init(state,
                      adopts: [superState] + andSuperStates,
                      onEntry: onEntry.map(AnyAction.init),
                      onExit: onExit.map(AnyAction.init),
                      elements: [],
                      file: file,
                      line: line)
        }

        public init(_ state: State,
                    adopts superState: SuperState,
                    _ andSuperStates: SuperState...,
                    onEntry: [FSMSyncActionWithEvent<Event>],
                    onExit: [FSMAsyncActionWithEvent<Event>],
                    file: String = #file,
                    line: Int = #line
        ) {
            self.init(state,
                      adopts: [superState] + andSuperStates,
                      onEntry: onEntry.map(AnyAction.init),
                      onExit: onExit.map(AnyAction.init),
                      elements: [],
                      file: file,
                      line: line)
        }

        public init(_ state: State,
                    adopts superState: SuperState,
                    _ andSuperStates: SuperState...,
                    onEntry: [FSMAsyncActionWithEvent<Event>],
                    onExit: [FSMSyncActionWithEvent<Event>],
                    file: String = #file,
                    line: Int = #line
        ) {
            self.init(state,
                      adopts: [superState] + andSuperStates,
                      onEntry: onEntry.map(AnyAction.init),
                      onExit: onExit.map(AnyAction.init),
                      elements: [],
                      file: file,
                      line: line)
        }

        public init(_ state: State,
                    adopts superState: SuperState,
                    _ andSuperStates: SuperState...,
                    onEntry: [FSMAsyncActionWithEvent<Event>],
                    onExit: [FSMAsyncActionWithEvent<Event>],
                    file: String = #file,
                    line: Int = #line
        ) {
            self.init(state,
                      adopts: [superState] + andSuperStates,
                      onEntry: onEntry.map(AnyAction.init),
                      onExit: onExit.map(AnyAction.init),
                      elements: [],
                      file: file,
                      line: line)
        }

        public init(_ state: State,
                    adopts superState: SuperState,
                    _ andSuperStates: SuperState...,
                    onEntry: [FSMAsyncAction],
                    onExit: [FSMSyncAction],
                    file: String = #file,
                    line: Int = #line
        ) {
            self.init(state,
                      adopts: [superState] + andSuperStates,
                      onEntry: onEntry.map(AnyAction.init),
                      onExit: onExit.map(AnyAction.init),
                      elements: [],
                      file: file,
                      line: line)
        }

        public init(_ state: State,
                    adopts superState: SuperState,
                    _ andSuperStates: SuperState...,
                    onEntry: [FSMSyncAction],
                    onExit: [FSMAsyncAction],
                    file: String = #file,
                    line: Int = #line
        ) {
            self.init(state,
                      adopts: [superState] + andSuperStates,
                      onEntry: onEntry.map(AnyAction.init),
                      onExit: onExit.map(AnyAction.init),
                      elements: [],
                      file: file,
                      line: line)
        }

        public init(_ state: State,
                    adopts superState: SuperState,
                    _ andSuperStates: SuperState...,
                    onEntry: [FSMAsyncAction],
                    onExit: [FSMAsyncAction],
                    file: String = #file,
                    line: Int = #line
        ) {
            self.init(state,
                      adopts: [superState] + andSuperStates,
                      onEntry: onEntry.map(AnyAction.init),
                      onExit: onExit.map(AnyAction.init),
                      elements: [],
                      file: file,
                      line: line)
        }

        public init(_ state: State,
                    adopts superStates: SuperState...,
                    onEntry: [FSMSyncAction] = [],
                    onExit: [FSMSyncAction] = [],
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
                    adopts superStates: SuperState...,
                    onEntry: [FSMSyncActionWithEvent<Event>] = [],
                    onExit: [FSMSyncActionWithEvent<Event>],
                    file: String = #file,
                    line: Int = #line,
                    @Internal.MWTABuilder _ block: () -> [MWTA]
        ) {
            /// Duplication forced by compiler unlike all the others with the same pattern
            let elements = block()

            self.init(state,
                      adopts: elements.isEmpty ? [] : superStates,
                      onEntry: onEntry.map(AnyAction.init),
                      onExit: onExit.map(AnyAction.init),
                      elements: elements,
                      file: file,
                      line: line)
        }

        public init(_ state: State,
                    adopts superStates: SuperState...,
                    onEntry: [FSMAsyncAction] = [],
                    onExit: [FSMSyncAction] = [],
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
                    adopts superStates: SuperState...,
                    onEntry: [FSMSyncActionWithEvent<Event>] = [],
                    onExit: [FSMAsyncActionWithEvent<Event>],
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
                    adopts superStates: SuperState...,
                    onEntry: [FSMAsyncActionWithEvent<Event>] = [],
                    onExit: [FSMSyncActionWithEvent<Event>],
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
                    adopts superStates: SuperState...,
                    onEntry: [FSMAsyncActionWithEvent<Event>] = [],
                    onExit: [FSMAsyncActionWithEvent<Event>],
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
                    adopts superStates: SuperState...,
                    onEntry: [FSMSyncAction] = [],
                    onExit: [FSMAsyncAction] = [],
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
                    adopts superStates: SuperState...,
                    onEntry: [FSMAsyncAction] = [],
                    onExit: [FSMAsyncAction] = [],
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

        public init(state: State,
                    adopts superStates: [SuperState] = [],
                    onEntry: [FSMSyncAction],
                    onExit: [FSMSyncAction],
                    file: String = #file,
                    line: Int = #line,
                    @Internal.MWTABuilder _ block: () -> [MWTA]
        ) {
            let elements = block()

            self.init(state,
                      adopts: elements.isEmpty ? [] : superStates,
                      onEntry: onEntry.map(AnyAction.init),
                      onExit: onExit.map(AnyAction.init),
                      elements: elements,
                      file: file,
                      line: line)
        }

        public init(state: State,
                    adopts superStates: [SuperState] = [],
                    onEntry: [FSMSyncActionWithEvent<Event>],
                    onExit: [FSMSyncActionWithEvent<Event>],
                    file: String = #file,
                    line: Int = #line,
                    @Internal.MWTABuilder _ block: () -> [MWTA]
        ) {
            let elements = block()

            self.init(state,
                      adopts: elements.isEmpty ? [] : superStates,
                      onEntry: onEntry.map(AnyAction.init),
                      onExit: onExit.map(AnyAction.init),
                      elements: elements,
                      file: file,
                      line: line)
        }

        public init(state: State,
                    adopts superStates: [SuperState] = [],
                    onEntry: [FSMSyncActionWithEvent<Event>],
                    onExit: [FSMAsyncActionWithEvent<Event>],
                    file: String = #file,
                    line: Int = #line,
                    @Internal.MWTABuilder _ block: () -> [MWTA]
        ) {
            let elements = block()

            self.init(state,
                      adopts: elements.isEmpty ? [] : superStates,
                      onEntry: onEntry.map(AnyAction.init),
                      onExit: onExit.map(AnyAction.init),
                      elements: elements,
                      file: file,
                      line: line)
        }

        public init(state: State,
                    adopts superStates: [SuperState] = [],
                    onEntry: [FSMAsyncActionWithEvent<Event>],
                    onExit: [FSMSyncActionWithEvent<Event>],
                    file: String = #file,
                    line: Int = #line,
                    @Internal.MWTABuilder _ block: () -> [MWTA]
        ) {
            let elements = block()

            self.init(state,
                      adopts: elements.isEmpty ? [] : superStates,
                      onEntry: onEntry.map(AnyAction.init),
                      onExit: onExit.map(AnyAction.init),
                      elements: elements,
                      file: file,
                      line: line)
        }

        public init(state: State,
                    adopts superStates: [SuperState] = [],
                    onEntry: [FSMAsyncActionWithEvent<Event>],
                    onExit: [FSMAsyncActionWithEvent<Event>],
                    file: String = #file,
                    line: Int = #line,
                    @Internal.MWTABuilder _ block: () -> [MWTA]
        ) {
            let elements = block()

            self.init(state,
                      adopts: elements.isEmpty ? [] : superStates,
                      onEntry: onEntry.map(AnyAction.init),
                      onExit: onExit.map(AnyAction.init),
                      elements: elements,
                      file: file,
                      line: line)
        }

        public init(state: State,
                    adopts superStates: [SuperState] = [],
                    onEntry: [FSMAsyncAction],
                    onExit: [FSMSyncAction],
                    file: String = #file,
                    line: Int = #line,
                    @Internal.MWTABuilder _ block: () -> [MWTA]
        ) {
            let elements = block()

            self.init(state,
                      adopts: elements.isEmpty ? [] : superStates,
                      onEntry: onEntry.map(AnyAction.init),
                      onExit: onExit.map(AnyAction.init),
                      elements: elements,
                      file: file,
                      line: line)
        }

        public init(state: State,
                    adopts superStates: [SuperState] = [],
                    onEntry: [FSMSyncAction],
                    onExit: [FSMAsyncAction],
                    file: String = #file,
                    line: Int = #line,
                    @Internal.MWTABuilder _ block: () -> [MWTA]
        ) {
            let elements = block()

            self.init(state,
                      adopts: elements.isEmpty ? [] : superStates,
                      onEntry: onEntry.map(AnyAction.init),
                      onExit: onExit.map(AnyAction.init),
                      elements: elements,
                      file: file,
                      line: line)
        }

        public init(state: State,
                    adopts superStates: [SuperState] = [],
                    onEntry: [FSMAsyncAction],
                    onExit: [FSMAsyncAction],
                    file: String = #file,
                    line: Int = #line,
                    @Internal.MWTABuilder _ block: () -> [MWTA]
        ) {
            let elements = block()

            self.init(state,
                      adopts: elements.isEmpty ? [] : superStates,
                      onEntry: onEntry.map(AnyAction.init),
                      onExit: onExit.map(AnyAction.init),
                      elements: elements,
                      file: file,
                      line: line)
        }

        internal init(_ state: State,
                      adopts superStates: [SuperState],
                      onEntry: [AnyAction],
                      onExit: [AnyAction],
                      elements: [MWTA],
                      file: String = #file,
                      line: Int = #line
        ) {
            let onEntry = superStates.map(\.onEntry).flattened + onEntry
            let onExit = superStates.map(\.onExit).flattened + onExit

            let dNode = DefineNode(onEntry: onEntry,
                                   onExit: onExit,
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
