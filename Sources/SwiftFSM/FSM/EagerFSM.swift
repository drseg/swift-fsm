import Foundation

open class FSM<State: Hashable, Event: Hashable>: FSMBase<State, Event> {
    public override init(initialState: State) {
        super.init(initialState: initialState)
    }
    
    override func makeMRN(rest: [any Node<IntermediateIO>]) -> MRNBase {
        EagerMatchResolvingNode(rest: rest)
    }
    
    public override func handleEvent(_ event: Event, predicates: [any Predicate]) {
        _handleEvent(event, predicates: predicates)
    }
}

