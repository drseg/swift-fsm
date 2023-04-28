import Foundation

class Logger<Event: Hashable> {
    func transitionNotFound(_ event: Event, _ predicates: [any Predicate]) {
#if DEBUG
        warning(transitionNotFoundString(event, predicates))
#endif
    }
    
    func transitionNotFoundString(
        _ event: Event,
        _ predicates: [any Predicate]
    ) -> String {
        let warning = "no transition found for event '\(event)'"
        
        return predicates.isEmpty
        ? warning
        : warning + " matching predicates \(predicates)"
    }
    
    func transitionNotExecuted(_ t: Transition) {
#if DEBUG
        info(transitionNotExecutedString(t))
#endif
    }
    
    func transitionNotExecutedString(_ t: Transition) -> String {
        "conditional transition \(t) not executed"
    }
    
    private func warning(_ s: String) {
        print(intro + "warning: " + s)
    }
    
    private func info(_ s: String) {
        print(intro + "info: " + s)
    }
    
    private var intro: String {
        "SwiftFSM "
    }
}
