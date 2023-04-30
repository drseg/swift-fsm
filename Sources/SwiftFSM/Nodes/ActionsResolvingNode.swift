import Foundation

struct IntermediateIO {
    let state: AnyTraceable,
        match: Match,
        event: AnyTraceable,
        nextState: AnyTraceable,
        actions: [Action],
        groupID: UUID,
        isOverride: Bool
    
    init(
        _ state: AnyTraceable,
        _ match: Match,
        _ event: AnyTraceable,
        _ nextState: AnyTraceable,
        _ actions: [Action],
        _ groupID: UUID = UUID(),
        _ isOverride: Bool = false
    ) {
        self.state = state
        self.match = match
        self.event = event
        self.nextState = nextState
        self.actions = actions
        self.groupID = groupID
        self.isOverride = isOverride
    }
}

class ActionsResolvingNodeBase: UnsafeNode {
    var rest: [any UnsafeNode]
    
    required init(rest: [any UnsafeNode] = []) {
        self.rest = rest
    }
    
    func combinedWithRest(_ rest: [DefineNode.Output]) -> [IntermediateIO] {
        var onEntry = [AnyTraceable: [Action]]()
        Set(rest.map(\.state)).forEach { state in
            onEntry[state] = rest.first { $0.state == state }?.onEntry
        }
        
        return rest.reduce(into: []) {
            let actions = shouldAddEntryExitActions($1)
            ? $1.actions + $1.onExit + (onEntry[$1.nextState] ?? [])
            : $1.actions
            
            $0.append(IntermediateIO($1.state,
                                     $1.match,
                                     $1.event,
                                     $1.nextState,
                                     actions,
                                     $1.groupID,
                                     $1.isOverride))
        }
    }
    
    func shouldAddEntryExitActions(_ input: Input) -> Bool {
        input.state != input.nextState
    }
}

final class ConditionalActionsResolvingNode: ActionsResolvingNodeBase { }

final class ActionsResolvingNode: ActionsResolvingNodeBase {
    override func shouldAddEntryExitActions(_ input: Input) -> Bool { true }
}

