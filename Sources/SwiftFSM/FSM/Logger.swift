import Foundation

class Logger<Event: Hashable> {
    func transitionNotFound(_ event: Event, _ predicates: [any Predicate]) {
#if DEBUG
        print(transitionNotFoundString(event, predicates))
#endif
    }
    
    func transitionNotFoundString(
        _ event: Event,
        _ predicates: [any Predicate]
    ) -> String {
        let warning = "SwiftFSM warning: no transition found for event '\(event)'"
        
        return predicates.isEmpty
        ? warning
        : warning + " matching predicates \(predicates)"
    }
    
    func transitionNotExecuted(_ t: Transition) {
#if DEBUG
        print(transitionNotExecutedString(t))
#endif
    }
    
    func transitionNotExecutedString(_ t: Transition) -> String {
        "SwiftFSM info: conditional transition \(t) not executed"
    }
}
