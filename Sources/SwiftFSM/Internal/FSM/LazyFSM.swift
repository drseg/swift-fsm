import Foundation
import Algorithms

class LazyFSM<State: FSMHashable, Event: FSMHashable>: FSMBase<State, Event> {
    override func makeMatchResolvingNode(
        rest: [any Node<IntermediateIO>]
    ) -> any MatchResolvingNode {
        LazyMatchResolvingNode(rest: rest)
    }

    @discardableResult
    override func handleEvent(
        _ event: Event,
        predicates: [any Predicate],
        isolation: isolated (any Actor)? = #isolation
    ) async -> TransitionStatus {
        for combinations in makeCombinationsSequences(predicates) {
            for combination in combinations {
                let status = await super.handleEvent(
                    event,
                    predicates: combination,
                    isolation: isolation
                )
                
                if transitionWasFound(status) {
                    logTransitionFound(status)
                    return status
                }
            }
        }

        logTransitionNotFound(event, predicates)
        return .notFound(event, predicates)
    }
    
    private func makeCombinationsSequences(
        _ predicates: [any Predicate]
    ) -> [some Sequence<[any Predicate]>] {
        (0..<predicates.count)
            .reversed()
            .reduce(into: [predicates.combinations(ofCount: predicates.count)]) {
                $0.append(predicates.combinations(ofCount: $1))
            }
    }
    
    private func transitionWasFound(_ status: TransitionStatus) -> Bool {
        switch status {
        case .executed, .notExecuted:
            true
        case .notFound:
            false
        }
    }

    private func logTransitionFound(_ status: TransitionStatus) {
        if case let .executed(transition) = status {
            logTransitionExecuted(transition)
        } else if case let .notExecuted(transition) = status {
            logTransitionNotExecuted(transition)
        }
    }
}
