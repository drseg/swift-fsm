import Foundation
import ReflectiveEquality

@resultBuilder
struct TableBuilder<State: Hashable>: ResultBuilder {
    typealias T = Syntax.Define<State>
}

struct FSMKey: Hashable {
    let state: AnyHashable,
        predicates: PredicateSet,
        event: AnyHashable

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

open class _FSMBase<State: Hashable, Event: Hashable> {
    public enum StateActionsPolicy {
        case executeAlways, executeOnChangeOnly
    }

    let stateActionsPolicy: StateActionsPolicy

    var table: [FSMKey: Transition] = [:]
    var state: AnyHashable
    let logger = Logger<Event>()

    public func handleEvent(_ event: Event, predicates: [any Predicate]) {
        fatalError("subclasses must implement")
    }

    func makeMRN(rest: [any Node<IntermediateIO>]) -> any MRNProtocol {
        fatalError("subclasses must implement")
    }

    func makeARN(rest: [DefineNode]) -> ActionsResolvingNodeBase {
        return switch stateActionsPolicy {
        case .executeAlways: ActionsResolvingNode(rest: rest)
        case .executeOnChangeOnly: ConditionalActionsResolvingNode(rest: rest)
        }
    }

    init(initialState: State, actionsPolicy: StateActionsPolicy = .executeOnChangeOnly) {
        self.state = initialState
        self.stateActionsPolicy = actionsPolicy
    }

    public func handleEvent(_ event: Event) {
        handleEvent(event, predicates: [])
    }

    public func handleEvent(_ event: Event, predicates: any Predicate...) {
        handleEvent(event, predicates: predicates)
    }

    public func buildTable(
        file: String = #file,
        line: Int = #line,
        @TableBuilder<State> _ block: () -> [Syntax.Define<State>]
    ) throws {
        guard table.isEmpty else {
            throw makeError(TableAlreadyBuiltError(file: file, line: line))
        }

        let arn = makeARN(rest: block().map(\.node))
        let svn = SemanticValidationNode(rest: [arn])
        let result = makeMRN(rest: [svn]).finalised()

        try checkForErrors(result)
        makeTable(result.output)
    }

    enum TransitionResult {
        case executed, notFound(Event, [any Predicate]), notExecuted(Transition)
    }

    @discardableResult
    func _handleEvent(_ event: Event, predicates: [any Predicate]) -> TransitionResult {
        guard let transition = table[FSMKey(state: state,
                                            predicates: Set(predicates.erased()),
                                            event: event)] else {
            return .notFound(event, predicates)
        }

        guard transition.condition?() ?? true else {
            return .notExecuted(transition)
        }

        state = transition.nextState
        transition.actions.forEach { $0(event) }
        return .executed
    }

    func checkForErrors(_ result: (output: [Transition], errors: [Error])) throws {
        if !result.errors.isEmpty {
            throw makeError(result.errors)
        }

        if result.output.isEmpty {
            throw makeError(EmptyTableError())
        }

        let stateEvent = (result.output.first?.state, result.output.first?.event)
        if deepDescription(stateEvent).contains("NSObject") {
            throw makeError(NSObjectError())
        }
    }

    func makeTable(_ output: [Transition]) {
        output.forEach { table[FSMKey($0)] = $0 }
    }

    func makeError(_ error: Error) -> SwiftFSMError {
        makeError([error])
    }

    func makeError(_ errors: [Error]) -> SwiftFSMError {
        SwiftFSMError(errors: errors)
    }

    func logTransitionNotFound(_ event: Event, _ predicates: [any Predicate]) {
        logger.transitionNotFound(event, predicates)
    }

    func logTransitionNotExecuted(_ t: Transition) {
        logger.transitionNotExecuted(t)
    }
}
