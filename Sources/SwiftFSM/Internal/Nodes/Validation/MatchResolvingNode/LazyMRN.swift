import Foundation

extension MatchResolvingNode {
    final class Lazy: Base, Interface { }
}

extension MatchResolvingNode.Lazy {
    func combineWith(_ rest: [SemanticValidationNode.Output]) -> [Transition] {
        if !rest.isEmpty {
            errors = MatchResolvingNode.Eager(rest: self.rest).resolve().errors
            guard errors.isEmpty else { return [] }
        }
        
        return rest.reduce(into: []) { result, dto in
            func appendTransition(predicates: PredicateSet = []) {
                result.append(Transition(dto: dto, predicates: predicates))
            }
            
            let allPredicates = dto.descriptor.resolvedPredicates()
            
            if allPredicates.isEmpty {
                appendTransition()
            } else {
                allPredicates.forEach(appendTransition)
            }
        }
    }
}

extension Transition {
    init(dto: OverrideSyntaxDTO, predicates p: PredicateSet) {
        condition = dto.descriptor.condition
        state = dto.state.base
        predicates = p
        event = dto.event.base
        nextState = dto.nextState.base
        actions = dto.actions
    }
}
