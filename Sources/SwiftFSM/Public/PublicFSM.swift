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
        actionsPolicy policy: StateActionsPolicy = .executeOnChangeOnly
    ) {
        fsm = switch type {
        case .eager: EagerFSM(initialState: initial, actionsPolicy: policy)
        case .lazy: LazyFSM(initialState: initial, actionsPolicy: policy)
        }
    }

    public func buildTable(
        file: String = #file,
        line: Int = #line,
        @TableBuilder<State, Event> _ block: () -> [Internal.Define<State, Event>]
    ) throws {
        try fsm.buildTable(file: file, line: line, block)
    }

    public func handleEvent(_ event: Event) async {
        await fsm.handleEvent(event)
    }

    public func handleEvent(_ event: Event, predicates: any Predicate...) async {
        await fsm.handleEvent(event, predicates: predicates)
    }
}
