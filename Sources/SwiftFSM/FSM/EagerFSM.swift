import Foundation

class FSM<State: Hashable, Event: Hashable>: FSMBase<State>, FSMProtocol {
    typealias MRN = EagerMatchResolvingNode
    
    func handleEvent(_ event: Event, predicates: [any Predicate]) {
        _handleEvent(event, predicates: predicates)
    }
}
