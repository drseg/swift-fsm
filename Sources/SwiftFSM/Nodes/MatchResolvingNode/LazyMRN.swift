import Foundation

final class LazyMatchResolvingNode: Node {
    var rest: [any Node<Input>]
    
    init(rest: [any Node<Input>] = []) {
        self.rest = rest
    }
    
    func combinedWithRest(_ rest: [SemanticValidationNode.Output]) -> [Transition] {
        rest.reduce(into: []) { result, input in
            func appendTransition(predicates: PredicateSet) {
                result.append(Transition(input.match.condition,
                                         input.state.base,
                                         predicates,
                                         input.event.base,
                                         input.nextState.base,
                                         input.actions))
            }
            
            let anyAndAll = input.match.combineAnyAndAll()
            if anyAndAll.isEmpty {
                appendTransition(predicates: [])
            } else {
                input.match.combineAnyAndAll().forEach {
                    appendTransition(predicates: $0)
                }
            }
        }
    }
}
