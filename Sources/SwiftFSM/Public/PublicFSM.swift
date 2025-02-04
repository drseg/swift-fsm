import Foundation

public enum StateActionsPolicy {
    case executeAlways, executeOnChangeOnly
}

public class FSM<State: FSMHashable, Event: FSMHashable> {
    public enum PredicateHandling { case eager, lazy }

    var fsm: any FSMProtocol<State, Event>

    public init(
        type: PredicateHandling = .eager,
        initialState initial: State,
        actionsPolicy policy: StateActionsPolicy = .executeOnChangeOnly,
        isolation: isolated (any Actor)? = #isolation
    ) {
        fsm = switch type {
        case .eager: EagerFSM(initialState: initial, actionsPolicy: policy)
        case .lazy: LazyFSM(initialState: initial, actionsPolicy: policy)
        }
    }

    public func buildTable(
        file: String = #file,
        line: Int = #line,
        isolation: isolated (any Actor)? = #isolation,
        @TableBuilder<State, Event> _ block: () -> [Internal.Define<State, Event>]
    ) throws {
        try fsm.buildTable(file: file, line: line, block)
    }

    public func handleEvent(
        _ event: Event,
        isolation: isolated (any Actor)? = #isolation
    ) async {
        await fsm.handleEvent(event, isolation: isolation)
    }

    public func handleEvent(
        _ event: Event,
        predicates: any Predicate...,
        isolation: isolated (any Actor)? = #isolation
    ) async {
        await fsm.handleEvent(event, predicates: predicates, isolation: isolation)
    }
}
