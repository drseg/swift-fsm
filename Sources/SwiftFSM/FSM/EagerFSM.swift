import Foundation

public class FSM<State: Hashable, Event: Hashable>: _FSMBase<State, Event>, _FSMProtocol, FSMProtocol {
    public typealias State = State
    public typealias Event = Event

    public override init(
        initialState: State,
        actionsPolicy: StateActionsPolicy = .executeOnChangeOnly
    ) {
        super.init(initialState: initialState, actionsPolicy: actionsPolicy)
    }

    func makeMatchResolvingNode(rest: [any Node<IntermediateIO>]) -> any MatchResolvingNode {
        EagerMatchResolvingNode(rest: rest)
    }

    @MainActor
    public func handleEvent(_ event: Event, predicates: [any Predicate]) {
        handleResult(_handleEvent(event, predicates: predicates),
                     for: event,
                     with: predicates)
    }

    @MainActor
    public func handleEventAsync(_ event: Event, predicates: [any Predicate]) async {
        handleResult(await _handleEventAsync(event, predicates: predicates),
                     for: event,
                     with: predicates)
    }

    private func handleResult(_ result: TransitionResult<Event>, for event: Event, with predicates: [any Predicate]) {
        switch result {
        case let .notExecuted(transition):
            logTransitionNotExecuted(transition)
        case .notFound:
            logTransitionNotFound(event, predicates)
        case .executed:
            return
        }
    }
}
