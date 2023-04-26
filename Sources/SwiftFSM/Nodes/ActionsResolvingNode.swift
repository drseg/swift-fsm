import Foundation

struct IntermediateIO {
    let state: AnyTraceable,
        match: Match,
        event: AnyTraceable,
        nextState: AnyTraceable,
        actions: [Action]
    
    init(
        _ state: AnyTraceable,
        _ match: Match,
        _ event: AnyTraceable,
        _ nextState: AnyTraceable,
        _ actions: [Action]
    ) {
        self.state = state
        self.match = match
        self.event = event
        self.nextState = nextState
        self.actions = actions
    }
}

class ActionsResolvingNodeBase: Node {
    var rest: [any Node<Input>]
    
    required init(rest: [any Node<Input>] = []) {
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
            
            $0.append(IntermediateIO($1.state, $1.match, $1.event, $1.nextState, actions))
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

