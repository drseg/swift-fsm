import Foundation

public extension Syntax {
    struct Define<State: FSMHashable, Event: FSMHashable> {
        let node: DefineNode

        init(
            state: State,
            adopts superStates: [SuperState],
            onEntry: [AnyAction],
            onExit: [AnyAction],
            file: String = #file,
            line: Int = #line,
            @MWTABuilder _ block: () -> [MWTA]
        ) {
            let elements = block()
            
            self.init(
                state,
                adopts: elements.isEmpty ? [] : superStates,
                onEntry: onEntry,
                onExit: onExit,
                elements: elements,
                file: file,
                line: line
            )
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
            let onEntry = superStates.entryActions + onEntry
            let onExit = superStates.exitActions + onExit
            
            let dNode = DefineNode(
                onEntry: onEntry,
                onExit: onExit,
                caller: "define",
                file: file,
                line: line
            )
            
            let isValid = !superStates.isEmpty || !elements.isEmpty

            if isValid {
                dNode.setUp(
                    givenState: state,
                    superStateNodes: superStates.nodes,
                    defineNodes: elements.nodes.withOverrideGroupID(),
                    file: file,
                    line: line
                )
            }

            self.node = dNode
        }
    }
}

private extension DefineNode {
    func setUp<S: FSMHashable>(
        givenState: S,
        superStateNodes: [any Node<DefaultIO>],
        defineNodes: [any Node<DefaultIO>],
        file: String,
        line: Int
    ) {
        let traceableState = AnyTraceable(givenState, file: file, line: line)
        let rest = superStateNodes + defineNodes
        let gNode = GivenNode(states: [traceableState], rest: rest)
        self.rest = [gNode]
    }
}

private extension Array<SuperState> {
    var nodes: [any Node<DefaultIO>] {
        map(\.nodes).flattened
    }
    
    var entryActions: [AnyAction] {
        actions(\.onEntry)
    }
    
    var exitActions: [AnyAction] {
        actions(\.onExit)
    }
    
    func actions(_ transform: (SuperState) -> [AnyAction]) -> [AnyAction] {
        map(transform).flattened
    }
}
