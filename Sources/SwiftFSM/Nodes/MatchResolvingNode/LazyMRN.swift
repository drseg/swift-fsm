import Foundation

final class LazyMatchResolvingNode: Node {
    var rest: [any Node<Input>]
    
    init(rest: [any Node<Input>] = []) {
        self.rest = rest
    }
    
    func combinedWithRest(_ rest: [SemanticValidationNode.Output]) -> [Transition] {
        do {
            return try rest.reduce(into: [Transition]()) { result, input in
                func isClash(_ t: Transition) -> Bool {
                    result
                        .filter   { $0.clashes(with: t) }
                        .contains { $0.predicateTypesOverlap(with: t) }
                }
                
                func appendTransition(predicates: PredicateSet) throws {
                    let t = Transition(input.match.condition,
                                       input.state.base,
                                       predicates,
                                       input.event.base,
                                       input.nextState.base,
                                       input.actions)
                    guard !isClash(t) else { throw "" }
                    result.append(t)
                }
                
                let anyAndAll = input.match.combineAnyAndAll()
                if anyAndAll.isEmpty {
                    try appendTransition(predicates: [])
                } else {
                    try anyAndAll.forEach {
                        try appendTransition(predicates: $0)
                    }
                }
            }
        } catch {
            return []
        }
    }
}

extension Transition {
    var predicateTypes: Set<String> {
        Set(predicates.map(\.type))
    }
    
    func clashes(with t: Transition) -> Bool {
        (state, event, nextState) == (t.state, t.event, t.nextState)
    }
    
    func predicateTypesOverlap(with t: Transition) -> Bool {
        predicateTypes
            .intersection(t.predicateTypes)
            .isEmpty
    }
}
