import Foundation

enum MatchResolvingNode {
    protocol Interface: SyntaxNode {
        var errors: [Error] { get }
        func resolve() -> (output: [Transition], errors: [Error])
    }
    
    class Base {
        var rest: [any SyntaxNode<OverrideSyntaxDTO>]
        var errors: [Error] = []
        
        init(rest: [any SyntaxNode<OverrideSyntaxDTO>]) {
            self.rest = rest
        }
    }
}

extension MatchResolvingNode.Interface {
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
