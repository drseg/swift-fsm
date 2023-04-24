import Foundation

class LazyFSM<State: Hashable, Event: Hashable>: FSMProtocol {
    typealias MRN = LazyMatchResolvingNode
    
    var table: [FSMKey: Transition] = [:]
    var state: AnyHashable
    
    required init(initialState: State) {
        self.state = initialState
    }
    
    func handleEvent(_ event: Event, predicates: [any Predicate]) {
        
    }
}
