import Foundation

struct IntermediateIO: Sendable {
    let state: AnyTraceable,
        match: Match,
        event: AnyTraceable,
        nextState: AnyTraceable,
        actions: [AnyAction],
        groupID: UUID,
        isOverride: Bool

    init(
        _ state: AnyTraceable,
        _ match: Match,
        _ event: AnyTraceable,
        _ nextState: AnyTraceable,
        _ actions: [AnyAction],
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

class ActionsResolvingNodeBase: Node {
    var rest: [any Node<DefineNode.Output>]

    required init(rest: [any Node<Input>] = []) {
        self.rest = rest
    }

    func combinedWithRest(_ rest: [DefineNode.Output]) -> [IntermediateIO] {
        var onEntry = [AnyTraceable: [AnyAction]]()
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
