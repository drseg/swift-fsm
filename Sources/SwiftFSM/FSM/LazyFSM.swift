import Foundation
import Algorithms

public class LazyFSM<State: Hashable, Event: Hashable>: _FSMBase<State, Event>, _FSMProtocol, FSMProtocol {
    public typealias State = State
    public typealias Event = Event

    public override init(
        initialState: State,
        actionsPolicy: StateActionsPolicy = .executeOnChangeOnly
    ) {
        super.init(initialState: initialState, actionsPolicy: actionsPolicy)
    }

    func makeMatchResolvingNode(rest: [any Node<IntermediateIO>]) -> any MatchResolvingNode {
        LazyMatchResolvingNode(rest: rest)
    }

    @MainActor
    public func handleEvent(_ event: Event, predicates: [any Predicate]) {
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
    public func handleEventAsync(_ event: Event, predicates: [any Predicate]) async {
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
