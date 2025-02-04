import Foundation

/// Swift bug:
///
/// https://github.com/pointfreeco/swift-composable-architecture/issues/2666
/// https://github.com/apple/swift/issues/69927
///
/// The struct TableBuilder below should be internal, but when marked as such, Swift fails to link when compiling in release mode

@resultBuilder
public struct TableBuilder<State: FSMHashable, Event: FSMHashable>: ResultBuilder {
    public typealias T = Internal.Define<State, Event>
}

struct TableKey: @unchecked Sendable, Hashable {
    let state: AnyHashable
    let predicates: PredicateSet
    let event: AnyHashable

    init(state: AnyHashable, predicates: PredicateSet, event: AnyHashable) {
        self.state = state
        self.predicates = predicates
        self.event = event
    }

    init(_ value: Transition) {
        state = value.state
        predicates = value.predicates
        event = value.event
    }
}

enum TransitionStatus<Event: FSMHashable> {
    case executed(Transition), notFound(Event, [any Predicate]), notExecuted(Transition)
}

protocol FSMProtocol<State, Event>: AnyObject {
    associatedtype State: FSMHashable
    associatedtype Event: FSMHashable

    var stateActionsPolicy: StateActionsPolicy { get }
    var table: [TableKey: Transition] { get set }
    var state: AnyHashable { get set }

    func handleEvent(
        _ event: Event,
        predicates: [any Predicate],
        isolation: isolated (any Actor)?
    ) async
    func makeMatchResolvingNode(rest: [any Node<IntermediateIO>]) -> any MatchResolvingNode
    func buildTable(
        file: String,
        line: Int,
        isolation: isolated (any Actor)?,
        @TableBuilder<State, Event> _ block: () -> [Internal.Define<State, Event>]
    ) throws
}

extension FSMProtocol {
    func handleEvent(
        _ event: Event,
        predicates: any Predicate...,
        isolation: isolated (any Actor)? = #isolation
    ) async {
        await handleEvent(event, predicates: predicates, isolation: isolation)
    }

    func buildTable(
        file: String = #file,
        line: Int = #line,
        isolation: isolated (any Actor)? = #isolation,
        @TableBuilder<State, Event> _ block: () -> [Internal.Define<State, Event>]
    ) throws {
        guard table.isEmpty else {
            throw makeError(TableAlreadyBuiltError(file: file, line: line))
        }

        let arn = makeActionsResolvingNode(rest: block().map(\.node))
        let svn = SemanticValidationNode(rest: [arn])
        let result = makeMatchResolvingNode(rest: [svn]).resolve()

        try checkForErrors(result)
        makeTable(result.output)
    }

    @discardableResult
    func _handleEvent(
        _ event: Event,
        predicates: [any Predicate],
        isolation: isolated (any Actor)? = #isolation
    ) async -> TransitionStatus<Event> {
        guard let transition = transition(event, predicates) else {
            return .notFound(event, predicates)
        }

        guard await shouldExecute(transition, isolation: isolation) else {
            return .notExecuted(transition)
        }

        state = transition.nextState
        await transition.executeActions(event: event)
        return .executed(transition)
    }

    func transition(_ event: Event, _ predicates: [any Predicate]) -> Transition? {
        table[TableKey(state: state,
                       predicates: Set(predicates.erased()),
                       event: event)]
    }

    func shouldExecute(
        _ t: Transition,
        isolation: isolated (any Actor)?
    ) async -> Bool {
        t.condition?() ?? true
    }

    func makeActionsResolvingNode(rest: [DefineNode]) -> ActionsResolvingNodeBase {
        switch stateActionsPolicy {
        case .executeAlways: ActionsResolvingNode(rest: rest)
        case .executeOnChangeOnly: ConditionalActionsResolvingNode(rest: rest)
        }
    }

    func checkForErrors(_ result: (output: [Transition], errors: [Error])) throws {
        if !result.errors.isEmpty {
            throw makeError(result.errors)
        }

        if result.output.isEmpty {
            throw makeError(EmptyTableError())
        }
    }

    func makeTable(_ output: [Transition]) {
        output.forEach { table[TableKey($0)] = $0 }
    }

    func makeError(_ error: Error) -> SwiftFSMError {
        makeError([error])
    }

    func makeError(_ errors: [Error]) -> SwiftFSMError {
        SwiftFSMError(errors: errors)
    }
}

class BaseFSM<State: FSMHashable, Event: FSMHashable> {
    let stateActionsPolicy: StateActionsPolicy

    var table: [TableKey: Transition] = [:]
    var state: AnyHashable
    let logger = Logger<Event>()

    init(initialState: State, actionsPolicy: StateActionsPolicy = .executeOnChangeOnly) {
        self.state = initialState
        self.stateActionsPolicy = actionsPolicy
    }

    func logTransitionNotFound(_ event: Event, _ predicates: [any Predicate]) {
        logger.transitionNotFound(event, predicates)
    }

    func logTransitionNotExecuted(_ t: Transition) {
        logger.transitionNotExecuted(t)
    }

    func logTransitionExecuted(_ t: Transition) {
        logger.transitionExecuted(t)
    }
}

private extension Transition {
    func executeActions<E: FSMHashable>(event: E) async {
        for action in actions {
            await action(event)
        }
    }
}
