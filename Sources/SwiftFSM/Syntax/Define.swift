import Foundation

public extension Syntax {
    struct Define<State: Hashable, Event: Hashable> {
        let node: DefineNode

        init(
            state: State,
            adopts superStates: [SuperState],
            onEntry: [AnyAction],
            onExit: [AnyAction],
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

        init(
            _ state: State,
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
