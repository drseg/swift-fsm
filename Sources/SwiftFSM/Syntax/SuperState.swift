import Foundation

public struct SuperState {
    var nodes: [any Node<DefaultIO>]
    var onEntry: [AnyAction]
    var onExit: [AnyAction]
    #warning("lost code coverage")
    public init(
        adopts superState: SuperState,
        _ andSuperStates: SuperState...,
        onEntry: [FSMSyncAction] = [],
        onExit: [FSMSyncAction] = []
    ) {
        self.init(superStates: [superState] + andSuperStates, 
                  onEntry: onEntry.map(AnyAction.init),
                  onExit: onExit.map(AnyAction.init))
    }

    public init(
        adopts superState: SuperState,
        _ andSuperStates: SuperState...,
        onEntry: [FSMAsyncAction] = [],
        onExit: [FSMAsyncAction] = []
    ) {
        self.init(superStates: [superState] + andSuperStates,
                  onEntry: onEntry.map(AnyAction.init),
                  onExit: onExit.map(AnyAction.init))
    }

    public init(
        adopts superState: SuperState,
        _ andSuperStates: SuperState...,
        onEntry: [FSMAsyncAction] = [],
        onExit: [FSMSyncAction] = []
    ) {
        self.init(superStates: [superState] + andSuperStates,
                  onEntry: onEntry.map(AnyAction.init),
                  onExit: onExit.map(AnyAction.init))
    }

    public init(
        adopts superState: SuperState,
        _ andSuperStates: SuperState...,
        onEntry: [FSMSyncAction] = [],
        onExit: [FSMAsyncAction] = []
    ) {
        self.init(superStates: [superState] + andSuperStates,
                  onEntry: onEntry.map(AnyAction.init),
                  onExit: onExit.map(AnyAction.init))
    }

    public init(
        adopts superStates: SuperState...,
        onEntry: [FSMSyncAction] = [],
        onExit: [FSMSyncAction] = [],
        @Internal.MWTABuilder _ block: () -> [MWTA]
    ) {
        self.init(nodes: block().nodes.withGroupID(),
                  superStates: superStates,
                  onEntry: onEntry.map(AnyAction.init),
                  onExit: onExit.map(AnyAction.init))
    }

    public init(
        adopts superStates: SuperState...,
        onEntry: [FSMAsyncAction] = [],
        onExit: [FSMAsyncAction] = [],
        @Internal.MWTABuilder _ block: () -> [MWTA]
    ) {
        self.init(nodes: block().nodes.withGroupID(),
                  superStates: superStates,
                  onEntry: onEntry.map(AnyAction.init),
                  onExit: onExit.map(AnyAction.init))
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
    func withGroupID() -> Self {
        let groupID = UUID()
        (self as? [OverridableNode])?.forEach { $0.groupID = groupID }
        return self
    }
}
