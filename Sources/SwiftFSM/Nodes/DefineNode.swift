import Foundation

final class DefineNode: NeverEmptyNode {
    struct Output {
        let state: AnyTraceable,
            match: Match,
            event: AnyTraceable,
            nextState: AnyTraceable,
            actions: [AnyAction],
            onEntry: [AnyAction],
            onExit: [AnyAction],
            groupID: UUID,
            isOverride: Bool

        init(_ state: AnyTraceable,
             _ match: Match,
             _ event: AnyTraceable,
             _ nextState: AnyTraceable,
             _ actions: [AnyAction],
             _ onEntry: [AnyAction],
             _ onExit: [AnyAction],
             _ groupID: UUID,
             _ isOverride: Bool
        ) {
            self.state = state
            self.match = match
            self.event = event
            self.nextState = nextState
            self.actions = actions
            self.onEntry = onEntry
            self.onExit = onExit
            self.groupID = groupID
            self.isOverride = isOverride
        }
    }

    let onEntry: [AnyAction]
    let onExit: [AnyAction]
    var rest: [any Node<GivenNode.Output>] = []

    let caller: String
    let file: String
    let line: Int

    private var errors: [Error] = []

    init(
        onEntry: [AnyAction],
        onExit: [AnyAction],
        rest: [any Node<GivenNode.Output>] = [],
        caller: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        self.onEntry = onEntry
        self.onExit = onExit
        self.rest = rest
        self.caller = caller
        self.file = file
        self.line = line
    }

    func combinedWithRest(_ rest: [GivenNode.Output]) -> [Output] {
        let output = rest.reduce(into: [Output]()) {
            if let match = finalise($1.match) {
                $0.append(
                    Output($1.state,
                           match,
                           $1.event,
                           $1.nextState,
                           $1.actions,
                           onEntry,
                           onExit,
                           $1.groupID,
                           $1.isOverride)
                )
            }
        }

        return errors.isEmpty ? output : []
    }

    private func finalise(_ m: Match) -> Match? {
        switch m.finalised() {
        case .failure(let e): errors.append(e); return nil
        case .success(let m): return m
        }
    }

    func validate() -> [Error] {
        makeError(if: rest.isEmpty) + errors
    }
}
