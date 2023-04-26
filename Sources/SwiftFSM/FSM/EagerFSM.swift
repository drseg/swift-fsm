import Foundation

open class FSM<State: Hashable, Event: Hashable>: FSMBase<State, Event> {
    public override init(
        initialState: State,
        actionsPolicy: EntryExitActionsPolicy = .executeOnStateChangeOnly
    ) {
        super.init(initialState: initialState, actionsPolicy: actionsPolicy)
    }
    
    override func makeMRN(rest: [any Node<IntermediateIO>]) -> MRNBase {
        EagerMatchResolvingNode(rest: rest)
    }
    
    public override func handleEvent(_ event: Event, predicates: [any Predicate]) {
        _handleEvent(event, predicates: predicates)
    }
}

