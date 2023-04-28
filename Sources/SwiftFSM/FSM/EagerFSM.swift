import Foundation

open class FSM<State: Hashable, Event: Hashable>: _FSMBase<State, Event> {
    public override init(
        initialState: State,
        actionsPolicy: EntryExitActionsPolicy = .executeOnStateChangeOnly,
        ignoreErrors: Bool? = nil
    ) {
        super.init(initialState: initialState,
                   actionsPolicy: actionsPolicy,
                   ignoreErrors: ignoreErrors)
    }
    
    override func makeMRN(rest: [any Node<IntermediateIO>]) -> MRNBase {
        EagerMatchResolvingNode(rest: rest)
    }
    
    public override func handleEvent(_ event: Event, predicates: [any Predicate]) {
        switch _handleEvent(event, predicates: predicates) {
        case let .notExecuted(transition):
            logTransitionNotExecuted(transition)
        case .notFound:
            logTransitionNotFound(event, predicates)
        case .executed:
            return
        }
    }
}

