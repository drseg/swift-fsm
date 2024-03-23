import Foundation

final class LazyMatchResolvingNode: MRNBase, MatchResolvingNode {
    func combinedWithRest(_ rest: [SemanticValidationNode.Output]) -> [Transition] {
        do {
            return try rest.reduce(into: []) { result, input in
                func appendTransition(predicates: PredicateSet) throws {
                    let t = Transition(io: input, predicates: predicates)
                    guard !result.containsClash(t) else { throw "" }
                    result.append(t)
                }

                let anyAndAll = input.match.combineAnyAndAll()

                if anyAndAll.isEmpty {
                    try appendTransition(predicates: [])
                } else {
                    try anyAndAll.forEach(appendTransition)
                }
            }
        } catch {
            errors = EagerMatchResolvingNode(rest: self.rest).finalised().errors
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
        predicateTypes.isDisjoint(with: t.predicateTypes)
    }
}

extension [Transition] {
    func containsClash(_ t: Transition) -> Bool {
        filter {
            t.clashes(with: $0) &&
            t.predicates.count == $0.predicates.count
        }
        .contains {
            t.predicateTypesOverlap(with: $0)
        }
    }
}
