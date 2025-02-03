import Foundation

class EagerFSM<State: FSMHashable, Event: FSMHashable>: BaseFSM<State, Event>, FSMProtocol {
    func makeMatchResolvingNode(rest: [any Node<IntermediateIO>]) -> any MatchResolvingNode {
        EagerMatchResolvingNode(rest: rest)
    }
    
    func handleEvent(_ event: Event, predicates: [any Predicate]) async {
        handleResult(
            await _handleEvent(event, predicates: predicates),
            for: event,
            with: predicates
        )
    }
    
    private func handleResult(
        _ result: TransitionStatus<Event>,
        for event: Event,
        with predicates: [any Predicate]
    ) {
        switch result {
        case let .executed(transition):
            logTransitionExecuted(transition)
        case let .notExecuted(transition):
            logTransitionNotExecuted(transition)
        case .notFound:
            logTransitionNotFound(event, predicates)
        }
    }
}
