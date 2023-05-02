import Foundation

open class FSM<State: Hashable, Event: Hashable>: _FSMBase<State, Event> {
    public override init(
        initialState: State,
        actionsPolicy: EntryExitActionsPolicy = .executeOnStateChangeOnly
    ) {
        super.init(initialState: initialState, actionsPolicy: actionsPolicy)
    }
    
    override func makeMRN(rest: [any Node<IntermediateIO>]) -> any MRNProtocol {
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

