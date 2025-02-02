import Foundation
import Algorithms

/// Swift bug:
///
/// https://github.com/apple/swift/issues/63377
/// https://github.com/apple/swift/issues/62906
/// https://github.com/apple/swift/issues/66740
///
/// It should be possible to inherit from:
///
/// BaseFSM<State, Event> & FSMProtocol<Event>
///
/// but the compiler currently won't allow it (even though it is officially supported).

class LazyFSM<State: FSMHashable, Event: FSMHashable>: BaseFSM<State, Event>, FSMProtocol {
    func makeMatchResolvingNode(rest: [any Node<IntermediateIO>]) -> any MatchResolvingNode {
        LazyMatchResolvingNode(rest: rest)
    }

    @MainActor
    func handleEvent(_ event: Event, predicates: [any Predicate]) throws {
        for combinations in makeCombinationsSequences(predicates) {
            for predicates in combinations {
                if logTransitionStatus(try _handleEvent(event, predicates: predicates)) {
                    return
                }
            }
        }

        logTransitionNotFound(event, predicates)
    }

    @MainActor
    func handleEventAsync(_ event: Event, predicates: [any Predicate]) async {
        for combinations in makeCombinationsSequences(predicates) {
            for predicates in combinations {
                if logTransitionStatus(await _handleEventAsync(event, predicates: predicates)) {
                    return
                }
            }
        }

        logTransitionNotFound(event, predicates)
    }

    private func logTransitionStatus(_ tr: TransitionStatus<Event>) -> Bool {
        switch tr {
        case let .executed(transition):
            logTransitionExecuted(transition)
            return true
        case let .notExecuted(transition):
            logTransitionNotExecuted(transition)
            return true
        case .notFound:
            return false
        }
    }

    func makeCombinationsSequences(
        _ predicates: [any Predicate]
    ) -> [some Sequence<[any Predicate]>] {
        (0..<predicates.count)
            .reversed()
            .reduce(into: [predicates.combinations(ofCount: predicates.count)]) {
                $0.append(predicates.combinations(ofCount: $1))
            }
    }
}
