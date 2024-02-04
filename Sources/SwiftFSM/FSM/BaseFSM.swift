import Foundation
import ReflectiveEquality

/// Swift bug:
///
/// https://github.com/pointfreeco/swift-composable-architecture/issues/2666
/// https://github.com/apple/swift/issues/69927
///
/// The struct TableBuilder below should be internal, but when marked as such, Swift fails to link when compiling in release mode

@resultBuilder
public struct TableBuilder<State: Hashable, Event: Hashable>: ResultBuilder {
    public typealias T = Syntax.Define<State, Event>
}

struct TableKey: Hashable {
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

enum TransitionStatus<Event: Hashable> {
    case executed, notFound(Event, [any Predicate]), notExecuted(Transition)
}

protocol FSMProtocol<State, Event>: AnyObject {
    associatedtype State: Hashable
    associatedtype Event: Hashable

    var stateActionsPolicy: StateActionsPolicy { get }
    var table: [TableKey: Transition] { get set }
    var state: AnyHashable { get set }

    @MainActor func handleEvent(_ event: Event, predicates: [any Predicate])
    @MainActor func handleEventAsync(_ event: Event, predicates: [any Predicate]) async
    func makeMatchResolvingNode(rest: [any Node<IntermediateIO>]) -> any MatchResolvingNode
    func buildTable(
        file: String,
        line: Int,
        @TableBuilder<State, Event> _ block: () -> [Syntax.Define<State, Event>]
    ) throws
}

extension FSMProtocol {
    @MainActor
    func handleEvent(_ event: Event) {
        handleEvent(event, predicates: [])
    }

    @MainActor
    func handleEventAsync(_ event: Event) async {
        await handleEventAsync(event, predicates: [])
    }

    @MainActor
    func handleEvent(_ event: Event, predicates: any Predicate...) {
        handleEvent(event, predicates: predicates)
    }

    @MainActor
    func handleEventAsync(_ event: Event, predicates: any Predicate...) async {
        await handleEventAsync(event, predicates: predicates)
    }

    func buildTable(
        file: String = #file,
        line: Int = #line,
        @TableBuilder<State, Event> _ block: () -> [Syntax.Define<State, Event>]
    ) throws {
        guard table.isEmpty else {
            throw makeError(TableAlreadyBuiltError(file: file, line: line))
        }

        let arn = makeActionsResolvingNode(rest: block().map(\.node))
        let svn = SemanticValidationNode(rest: [arn])
        let result = makeMatchResolvingNode(rest: [svn]).finalised()

        try checkForErrors(result)
        makeTable(result.output)
    }

    @discardableResult @MainActor
    func _handleEvent(
        _ event: Event,
        predicates: [any Predicate]
    ) -> TransitionStatus<Event> {
        guard let transition = transition(event, predicates) else {
            return .notFound(event, predicates)
        }

        guard shouldExecute(transition) else {
            return .notExecuted(transition)
        }

        state = transition.nextState
        transition.executeActions(event: event)
        return .executed
    }

    @discardableResult @MainActor
    func _handleEventAsync(
        _ event: Event,
        predicates: [any Predicate]
    ) async -> TransitionStatus<Event> {
        guard let transition = transition(event, predicates) else {
            return .notFound(event, predicates)
        }

        guard shouldExecute(transition) else {
            return .notExecuted(transition)
        }

        state = transition.nextState
        await transition.executeActions(event: event)
        return .executed
    }

    @MainActor
    private func transition(_ event: Event, _ predicates: [any Predicate]) -> Transition? {
        table[TableKey(state: state,
                     predicates: Set(predicates.erased()),
                     event: event)]
    }

    @MainActor
    private func shouldExecute(_ t: Transition) -> Bool {
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
        
        let firstOutput = result.output.first
        let stateEvent = (firstOutput?.state, firstOutput?.event)
        if deepDescription(stateEvent).contains("NSObject") {
            throw makeError(NSObjectError())
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

class BaseFSM<State: Hashable, Event: Hashable> {
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
}

@MainActor
private extension Transition {
    func executeActions<E: Hashable>(event: E) {
        actions.forEach { try! $0(event) }
    }

    func executeActions<E: Hashable>(event: E) async {
        for action in actions {
            await action(event)
        }
    }
}
