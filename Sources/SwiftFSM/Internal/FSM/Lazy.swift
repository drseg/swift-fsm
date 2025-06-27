import Foundation
import Algorithms

extension FSM {
    class Lazy: Base {
        override func makeMatchResolvingNode(
            rest: [any SyntaxNode<OverrideSyntaxDTO>]
        ) -> any MatchResolvingNode.Interface {
            MatchResolvingNode.Lazy(rest: rest)
        }
        
        @discardableResult
        override func handleEvent(
            _ event: Event,
            predicates: [any Predicate],
            isolation: isolated (any Actor)? = #isolation
        ) async -> TransitionStatus {
            for combination in allCombinations(predicates) {
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
            
            logTransitionNotFound(event, predicates)
            return .notFound(event, predicates)
        }
        
        private func allCombinations(
            _ predicates: [any Predicate]
        ) -> [[any Predicate]] {
            (0..<predicates.count)
                .reversed()
                .reduce(into: [predicates.combinations(ofCount: predicates.count)]) {
                    $0.append(predicates.combinations(ofCount: $1))
                }
                .flatMap(\.self)
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
}
