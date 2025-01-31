import Foundation

protocol MatchResolvingNode: Node {
    func resolved() -> (output: [Transition], errors: [Error])
}

class MRNBase {
    var rest: [any Node<IntermediateIO>]
    var errors: [Error] = []

    required init(rest: [any Node<IntermediateIO>] = []) {
        self.rest = rest
    }

    func validate() -> [Error] {
        errors
    }
}

struct Transition: @unchecked Sendable {
    let condition: ConditionProvider?,
        state: AnyHashable,
        predicates: PredicateSet,
        event: AnyHashable,
        nextState: AnyHashable,
        actions: [AnyAction]

    init(
        _ condition: ConditionProvider?,
        _ state: AnyHashable,
        _ predicates: PredicateSet,
        _ event: AnyHashable,
        _ nextState: AnyHashable,
        _ actions: [AnyAction]
    ) {
        self.condition = condition
        self.state = state
        self.predicates = predicates
        self.event = event
        self.nextState = nextState
        self.actions = actions
    }
}
