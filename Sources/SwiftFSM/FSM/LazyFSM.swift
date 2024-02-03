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
/// _FSMBase<State, Event> & HandleEventProtocol<Event>
///
/// but the compiler currently won't allow it (even though it is officially supported).

class LazyFSM<State: Hashable, Event: Hashable>: BaseFSM<State, Event>, FSMProtocol {
    override init(
        initialState: State,
        actionsPolicy: StateActionsPolicy = .executeOnChangeOnly
    ) {
        super.init(initialState: initialState, actionsPolicy: actionsPolicy)
    }

    func makeMatchResolvingNode(rest: [any Node<IntermediateIO>]) -> any MatchResolvingNode {
        LazyMatchResolvingNode(rest: rest)
    }

    @MainActor
    func handleEvent(_ event: Event, predicates: [any Predicate]) {
        for p in makeCombinations(predicates) {
            switch _handleEvent(event, predicates: p) {
            case let .notExecuted(transition):
                logTransitionNotExecuted(transition)
            case .executed:
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
            case let .notExecuted(transition):
                logTransitionNotExecuted(transition)
            case .executed:
                return
            case .notFound:
                break
            }
        }

        logTransitionNotFound(event, predicates)
    }

    func makeCombinations(_ predicates: [any Predicate]) -> [[any Predicate]] {
        (0..<predicates.count).reversed().reduce(into: [predicates]) {
            $0.append(contentsOf: predicates.combinations(ofCount: $1))
        }
    }
}
