import Foundation
import ReflectiveEquality

class FSM<State: Hashable, Event: Hashable>: FSMProtocol {
    typealias MRN = EagerMatchResolvingNode
    
    var table: [FSMKey: Transition] = [:]
    var state: AnyHashable
    
    required init(initialState: State) {
        self.state = initialState
    }
    
    func handleEvent(_ event: Event, predicates: any Predicate...) {
        handleEvent(event, predicates: predicates)
    }
    
    func handleEvent(_ event: Event, predicates: [any Predicate]) {
        if let transition = table[FSMKey(state: state,
                                         predicates: Set(predicates.erased()),
                                         event: event)],
           transition.condition?() ?? true
        {
            state = transition.nextState
            transition.actions.forEach { $0() }
        }
    }
}
