import Foundation

struct OverrideSyntaxDTO: Sendable {
    let state: AnyTraceable,
        descriptor: MatchDescriptorChain,
        event: AnyTraceable,
        nextState: AnyTraceable,
        actions: [AnyAction],
        overrideGroupID: UUID,
        isOverride: Bool

    init(
        _ state: AnyTraceable,
        _ match: MatchDescriptorChain,
        _ event: AnyTraceable,
        _ nextState: AnyTraceable,
        _ actions: [AnyAction],
        _ overrideGroupID: UUID = UUID(),
        _ isOverride: Bool = false
    ) {
        self.state = state
        self.descriptor = match
        self.event = event
        self.nextState = nextState
        self.actions = actions
        self.overrideGroupID = overrideGroupID
        self.isOverride = isOverride
    }
}

class ActionsResolvingNode: SyntaxNode {
    var rest: [any SyntaxNode<DefineNode.Output>]

    required init(rest: [any SyntaxNode<Input>] = []) {
        self.rest = rest
    }

    func combinedWith(_ rest: [DefineNode.Output]) -> [OverrideSyntaxDTO] {
        var onEntry = [AnyTraceable: [AnyAction]]()
        Set(rest.map(\.state)).forEach { state in
            onEntry[state] = rest.first { $0.state == state }?.onEntry
        }
        
        return rest.reduce(into: []) {
            let actions = shouldAddEntryExitActions($1)
            ? $1.actions + $1.onExit + (onEntry[$1.nextState] ?? [])
            : $1.actions
            
            $0.append(
                OverrideSyntaxDTO(
                    $1.state,
                    $1.match,
                    $1.event,
                    $1.nextState,
                    actions,
                    $1.overrideGroupID,
                    $1.isOverride
                )
            )
        }
    }

    func shouldAddEntryExitActions(_ input: Input) -> Bool {
        input.state != input.nextState
    }
}

extension ActionsResolvingNode {
    final class OnStateChange: ActionsResolvingNode { }
    
    final class ExecuteAlways: ActionsResolvingNode {
        override func shouldAddEntryExitActions(_ input: Input) -> Bool { true }
    }
}

