import Foundation

public struct SuperState {
    var nodes: [any Node<DefaultIO>]
    var onEntry: [Action]
    var onExit: [Action]

    public init(
        adopts superStates: SuperState,
        _ rest: SuperState...,
        onEntry: [Action] = [],
        onExit: [Action] = []
    ) {
        self.init(superStates: [superStates] + rest, onEntry: onEntry, onExit: onExit)
    }
    
    public init(
        adopts superStates: SuperState...,
        onEntry: [Action] = [],
        onExit: [Action] = [],
        @Internal.MWTABuilder _ block: () -> [MWTA]
    ) {
        self.init(nodes: block().nodes,
                  superStates: superStates,
                  onEntry: onEntry,
                  onExit: onExit)
    }
    
    private init(
        nodes: [any Node<DefaultIO>] = [],
        superStates: [SuperState],
        onEntry: [Action],
        onExit: [Action]
    ) {
        self.nodes = nodes + superStates.map(\.nodes).flattened
        self.onEntry = onEntry + superStates.map(\.onEntry).flattened
        self.onExit = onExit + superStates.map(\.onExit).flattened
    }
}
