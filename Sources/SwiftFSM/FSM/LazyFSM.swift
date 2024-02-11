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

    #warning("There must be some way to reduce this duplication")
    @MainActor
    func handleEvent(_ event: Event, predicates: [any Predicate]) throws {
        for p in makeCombinations(predicates) {
            switch try _handleEvent(event, predicates: p) {
            case let .executed(transition):
                logTransitionExecuted(transition)
                return
            case let .notExecuted(transition):
                logTransitionNotExecuted(transition)
                return
            case .notFound:
                break
            }
        }

        logTransitionNotFound(event, predicates)
    }

    @MainActor
    func handleEventAsync(_ event: Event, predicates: [any Predicate]) async {
        for p in makeCombinations(predicates) {
            switch await _handleEventAsync(event, predicates: p) {
            case let .executed(transition):
                logTransitionExecuted(transition)
                return
            case let .notExecuted(transition):
                logTransitionNotExecuted(transition)
                return
            case .notFound:
                break
            }
        }

        logTransitionNotFound(event, predicates)
    }

    func makeCombinations(_ predicates: [any Predicate]) -> [[any Predicate]] {
        (0..<predicates.count)
            .lazy
            .reversed()
            .reduce(into: [predicates]) {
            $0.append(contentsOf: predicates.combinations(ofCount: $1))
        }
    }
}
