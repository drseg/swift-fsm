import Foundation

public struct SuperState {
    var nodes: [any Node<DefaultIO>]
    var onEntry: [AnyAction]
    var onExit: [AnyAction]
    
    public init(
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
    
    public init(
        adopts superStates: SuperState...,
        onEntry: [AnyAction] = [],
        onExit: [AnyAction] = [],
        @Internal.MWTABuilder _ block: () -> [MWTA]
    ) {
        self.init(
            nodes: block().nodes.withOverrideGroupID(),
            superStates: superStates,
            onEntry: onEntry,
            onExit: onExit
        )
    }
    
    private init(
        nodes: [any Node<DefaultIO>] = [],
        superStates: [SuperState],
        onEntry: [AnyAction],
        onExit: [AnyAction]
    ) {
        self.nodes = superStates.map(\.nodes).flattened + nodes
        self.onEntry = superStates.map(\.onEntry).flattened + onEntry
        self.onExit = superStates.map(\.onExit).flattened + onExit
    }
}

extension [any Node<DefaultIO>] {
    func withOverrideGroupID() -> Self {
        let overrideGroupID = UUID()
        overridableNodes?.forEach { $0.overrideGroupID = overrideGroupID }
        return self
    }
    
    private var overridableNodes: [OverridableNode]? {
        self as? [OverridableNode]
    }
}
