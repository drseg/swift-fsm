import Foundation

public enum StateActionsPolicy {
    case executeAlways, executeOnChangeOnly
}

@MainActor
public class MainActorFSM<State: FSMHashable, Event: FSMHashable> {
    var fsm: FSM<State, Event>
    
    public init(
        type: FSM<State, Event>.PredicateHandling = .eager,
        initialState initial: State,
        actionsPolicy policy: StateActionsPolicy = .executeOnChangeOnly
    ) {
        fsm = FSM(
            type: type,
            initialState: initial,
            actionsPolicy: policy
        )
    }
    
    public func buildTable(
        file: String = #file,
        line: Int = #line,
        @TableBuilder<State, Event> _ block: @isolated(any) () -> [Internal.Define<State, Event>]
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
        isolation: isolated (any Actor)? = #isolation,
        @TableBuilder<State, Event> _ block: @isolated(any) () -> [Internal.Define<State, Event>]
    ) throws {
        try fsm.buildTable(file: file, line: line, isolation: isolation, block)
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
        await handleEvent(event, predicates: predicates, isolation: isolation)
    }
    
    internal func handleEvent(
        _ event: Event,
        predicates: [any Predicate],
        isolation: isolated (any Actor)? = #isolation
    ) async {
        await fsm.handleEvent(event, predicates: predicates, isolation: isolation)
    }
}
