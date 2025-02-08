import Foundation

class EagerFSM<State: FSMHashable, Event: FSMHashable>: FSMBase<State, Event> {
    override func makeMatchResolvingNode(
        rest: [any Node<IntermediateIO>]
    ) -> any MatchResolvingNode {
        EagerMatchResolvingNode(rest: rest)
    }
    
    @discardableResult
    override func handleEvent(
        _ event: Event,
        predicates: [any Predicate],
        isolation: isolated (any Actor)? = #isolation
    ) async -> TransitionStatus {
        let status = await super.handleEvent(
            event,
            predicates: predicates,
            isolation: isolation
        )
        
        logTransitionStatus(status, for: event, with: predicates)
        return status
    }
    
    private func logTransitionStatus(
        _ status: TransitionStatus,
        for event: Event,
        with predicates: [any Predicate]
    ) {
        switch status {
        case let .executed(transition):
            logTransitionExecuted(transition)
        case let .notExecuted(transition):
            logTransitionNotExecuted(transition)
        case .notFound:
            logTransitionNotFound(event, predicates)
        }
    }
}
