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
        func add<T: Collection>(_ items: [T.Element], _ keyPath: KeyPath<Self, T>) -> [T.Element] {
            superStates.map { $0[keyPath: keyPath] }.flattened + items
        }
        
        self.nodes = add(nodes, \.nodes)
        self.onEntry = add(onEntry, \.onEntry)
        self.onExit = add(onExit, \.onExit)
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
