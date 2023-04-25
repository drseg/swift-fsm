import Foundation
import Algorithms

class LazyFSM<State: Hashable, Event: Hashable>: FSMBase<State>, FSMProtocol {
    typealias MRN = LazyMatchResolvingNode
    
    func handleEvent(_ event: Event, predicates: [any Predicate]) {
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
