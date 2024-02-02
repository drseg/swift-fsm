import Foundation
import ReflectiveEquality

/// Swift bug:
///
/// https://github.com/pointfreeco/swift-composable-architecture/issues/2666
/// https://github.com/apple/swift/issues/69927
///
/// The struct TableBuidler below should be internal, but when marked as such, Swift fails to link when compiling in release mode

@resultBuilder
public struct TableBuilder<State: Hashable, Event: Hashable>: ResultBuilder {
    public typealias T = Syntax.Define<State, Event>
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

public enum StateActionsPolicy {
    case executeAlways, executeOnChangeOnly
}

enum TransitionResult<Event: Hashable> {
    case executed, notFound(Event, [any Predicate]), notExecuted(Transition)
}

protocol FSMProtocol<State, Event>: AnyObject {
    associatedtype State: Hashable
    associatedtype Event: Hashable

    @MainActor func handleEvent(_ event: Event, predicates: [any Predicate])
    @MainActor func handleEventAsync(_ event: Event, predicates: [any Predicate]) async
    func makeMatchResolvingNode(rest: [any Node<IntermediateIO>]) -> any MatchResolvingNode

    var state: AnyHashable { get set }
    var table: [FSMKey: Transition] { get set }
    var logger: Logger<Event> { get }
    var stateActionsPolicy: StateActionsPolicy { get }
}

extension FSMProtocol {
    @MainActor
    public func handleEvent(_ event: Event, predicates: any Predicate...) {
        handleEvent(event, predicates: predicates)
    }

    @MainActor
    public func handleEventAsync(_ event: Event, predicates: any Predicate...) async {
        await handleEventAsync(event, predicates: predicates)
    }

    public func buildTable(
        file: String = #file,
        line: Int = #line,
        @TableBuilder<State, Event> _ block: () -> [Syntax.Define<State, Event>]
    ) throws {
        guard table.isEmpty else {
            throw makeError(TableAlreadyBuiltError(file: file, line: line))
        }

        let arn = makeActionsResovingNode(rest: block().map(\.node))
        let svn = SemanticValidationNode(rest: [arn])
        let result = makeMatchResolvingNode(rest: [svn]).finalised()

        try checkForErrors(result)
        makeTable(result.output)
    }

    @MainActor
    func _handleEvent(_ event: Event, predicates: [any Predicate]) -> TransitionResult<Event> {
        guard let transition = transition(for: event, with: predicates) else {
            return .notFound(event, predicates)
        }

        guard shouldExecute(transition) else {
            return .notExecuted(transition)
        }

        state = transition.nextState
        transition.executeActions(event: event)
        return .executed
    }

    @MainActor
    func _handleEventAsync(_ event: Event, predicates: [any Predicate]) async -> TransitionResult<Event> {
        guard let transition = transition(for: event, with: predicates) else {
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
    private func transition(for event: Event, with predicates: [any Predicate]) -> Transition? {
        table[FSMKey(state: state,
                     predicates: Set(predicates.erased()),
                     event: event)]
    }

    @MainActor
    private func shouldExecute(_ t: Transition) -> Bool {
        t.condition?() ?? true
    }

    func makeActionsResovingNode(rest: [DefineNode]) -> ActionsResolvingNodeBase {
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
}

public class _FSMBase<State: Hashable, Event: Hashable> {
    let stateActionsPolicy: StateActionsPolicy

    var table: [FSMKey: Transition] = [:]
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
