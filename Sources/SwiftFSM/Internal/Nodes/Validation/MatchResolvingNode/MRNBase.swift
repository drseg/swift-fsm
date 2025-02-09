import Foundation

protocol MatchResolvingNode: SyntaxNode {
    var errors: [Error] { get }
    init(rest: [any SyntaxNode<OverrideSyntaxDTO>])
    func resolve() -> (output: [Transition], errors: [Error])
}

extension MatchResolvingNode {
    func findErrors() -> [Error] {
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
