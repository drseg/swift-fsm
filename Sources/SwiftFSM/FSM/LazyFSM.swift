import Foundation
import Algorithms

open class LazyFSM<State: Hashable, Event: Hashable>: FSMBase<State, Event>  {
    public override init(initialState: State) {
        super.init(initialState: initialState)
    }
    
    override func makeMRN(rest: [any Node<IntermediateIO>]) -> MRNBase {
        LazyMatchResolvingNode(rest: rest)
    }
    
    public override func handleEvent(_ event: Event, predicates: [any Predicate]) {
        for p in makeCombinations(predicates) {
            if _handleEvent(event, predicates: p) { return }
        }
    }
    
    func makeCombinations(_ predicates: [any Predicate]) -> [[any Predicate]] {
        return (0..<predicates.count).reversed().reduce(into: [predicates]) {
            $0.append(contentsOf: predicates.combinations(ofCount: $1))
        }
    }
}
