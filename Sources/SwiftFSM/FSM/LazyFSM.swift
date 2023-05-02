import Foundation
import Algorithms

open class LazyFSM<State: Hashable, Event: Hashable>: _FSMBase<State, Event>  {
    public override init(
        initialState: State,
        actionsPolicy: EntryExitActionsPolicy = .executeOnStateChangeOnly
    ) {
        super.init(initialState: initialState, actionsPolicy: actionsPolicy)
    }
    
    override func makeMRN(rest: [any UnsafeNode]) -> any MRNProtocol {
        LazyMatchResolvingNode(rest: rest)
    }
    
    public override func handleEvent(_ event: Event, predicates: [any Predicate]) {
        for p in makeCombinations(predicates) {
            switch _handleEvent(event, predicates: p) {
            case let .notExecuted(transition):
                logTransitionNotExecuted(transition)
            case .executed:
                return
            case .notFound:
                break
            }
        }
        
        logTransitionNotFound(event, predicates)
    }
    
    func makeCombinations(_ predicates: [any Predicate]) -> [[any Predicate]] {
        return (0..<predicates.count).reversed().reduce(into: [predicates]) {
            $0.append(contentsOf: predicates.combinations(ofCount: $1))
        }
    }
}
