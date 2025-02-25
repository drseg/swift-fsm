import Foundation

public struct SuperState {
    internal var nodes: [any SyntaxNode<RawSyntaxDTO>]
    internal var onEntry: [AnyAction]
    internal var onExit: [AnyAction]
    
    internal init(
        nodes: [any SyntaxNode<RawSyntaxDTO>] = [],
        superStates: [SuperState],
        onEntry: [AnyAction],
        onExit: [AnyAction]
    ) {
        self.nodes = superStates.map(\.nodes).flattened + nodes
        self.onEntry = superStates.map(\.onEntry).flattened + onEntry
        self.onExit = superStates.map(\.onExit).flattened + onExit
    }
}

extension [any SyntaxNode<RawSyntaxDTO>] {
    func withOverrideGroupID() -> Self {
        let overrideGroupID = UUID()
        overridableNodes?.forEach { $0.overrideGroupID = overrideGroupID }
        return self
    }
    
    private var overridableNodes: [OverridableNode]? {
        self as? [OverridableNode]
    }
}
