import Foundation

class Logger<Event: FSMHashable> {
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
        "conditional transition \(t.toString) not executed"
    }

    func transitionExecuted(_ t: Transition) {
#if DEBUG
        info(transitionExecutedString(t))
#endif
    }

    func transitionExecutedString(_ t: Transition) -> String {
        "transition \(t.toString) was executed"
    }

    private func warning(_ s: String) {
        print(intro + "Warning: " + s)
    }

    private func info(_ s: String) {
        print(intro + "Info: " + s)
    }

    private var intro: String {
        "[\(Date().formatted(date: .omitted, time: .standard)) SwiftFSM] "
    }
}

private extension Transition {
    var toString: String {
        predicates.isEmpty 
        ? "{ define(\(state)) | when(\(event)) | then(\(nextState)) }"
        : "{ define(\(state)) | matching(\(predicates)) | when(\(event)) | then(\(nextState)) }"
    }
}
