import Foundation

public struct SuperState {
    var nodes: [any Node<DefaultIO>]
    var onEntry: [Action]
    var onExit: [Action]

    public init(
        adopts superState: SuperState,
        _ andSuperStates: SuperState...,
        onEntry: [Action] = [],
        onExit: [Action] = []
    ) {
        self.init(superStates: [superState] + andSuperStates, 
                  onEntry: onEntry,
                  onExit: onExit)
    }

    public init(
        adopts superStates: SuperState...,
        onEntry: [Action] = [],
        onExit: [Action] = [],
        @Internal.MWTABuilder _ block: () -> [MWTA]
    ) {
        self.init(nodes: block().nodes.withGroupID(),
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
        self.nodes = superStates.map(\.nodes).flattened + nodes
        self.onEntry = superStates.map(\.onEntry).flattened + onEntry
        self.onExit = superStates.map(\.onExit).flattened + onExit
    }
}

extension [any Node<DefaultIO>] {
    func withGroupID() -> Self {
        let groupID = UUID()
        (self as? [OverridableNode])?.forEach { $0.groupID = groupID }
        return self
    }
}
