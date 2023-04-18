import Foundation

final class LazyMatchResolvingNode: Node {
    var rest: [any Node<Input>]
    
    init(rest: [any Node<Input>] = []) {
        self.rest = rest
    }
    
    func combinedWithRest(_ rest: [SemanticValidationNode.Output]) -> [Transition] {
        do {
            return try rest.reduce(into: [Transition]()) { result, input in
                func appendTransition(predicates: PredicateSet) throws {
                    func isClash() -> Bool {
                        result
                            .filter   { $0.clashes(with: t) }
                            .contains { $0.predicateTypesOverlap(with: t) }
                    }
                    
                    let t = Transition(io: input, predicates: predicates)
                    guard !isClash() else { throw "" }
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
    init(io: IntermediateIO, predicates p: PredicateSet) {
        condition = io.match.condition
        state = io.state.base
        predicates = p
        event = io.event.base
        nextState = io.nextState.base
        actions = io.actions
    }
    
    var predicateTypes: Set<String> {
        Set(predicates.map(\.type))
    }
    
    func clashes(with t: Transition) -> Bool {
        (state, event) == (t.state, t.event)
    }
    
    func predicateTypesOverlap(with t: Transition) -> Bool {
        predicateTypes
            .intersection(t.predicateTypes)
            .isEmpty
    }
}
