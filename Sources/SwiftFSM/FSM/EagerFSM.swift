import Foundation

open class FSM<State: Hashable, Event: Hashable>: _FSMBase<State, Event> {
    public override init(
        initialState: State,
        actionsPolicy: StateActionsPolicy = .executeOnChangeOnly
    ) {
        super.init(initialState: initialState, actionsPolicy: actionsPolicy)
    }

    override func makeMatchResolvingNode(rest: [any Node<IntermediateIO>]) -> any MatchResolvingNode {
        EagerMatchResolvingNode(rest: rest)
    }

    @MainActor
    public override func handleEvent(_ event: Event, predicates: [any Predicate]) {
        handleResult(_handleEvent(event, predicates: predicates),
                     for: event,
                     with: predicates)
    }

    @MainActor
    public override func handleEvent(_ event: Event, predicates: [any Predicate]) async {
        handleResult(await _handleEvent(event, predicates: predicates),
                     for: event,
                     with: predicates)
    }

    private func handleResult(_ result: TransitionResult, for event: Event, with predicates: [any Predicate]) {
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
