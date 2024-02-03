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

public protocol HandleEventProtocol<Event> {
    associatedtype Event: Hashable

    @MainActor func handleEvent(_ event: Event, predicates: [any Predicate])
    @MainActor func handleEventAsync(_ event: Event, predicates: [any Predicate]) async
}

public extension HandleEventProtocol {
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
}

public typealias FSMBase<State: Hashable, Event: Hashable> = 
_FSMBase<State, Event> & HandleEventProtocol<Event>

public enum FSMFactory<State: Hashable, Event: Hashable> {
    public static func makeEager(
        initialState: State,
        actionsPolicy: _FSMBase<State, Event>.StateActionsPolicy
    ) -> some FSMBase<State, Event> {
        FSM(initialState: initialState, actionsPolicy: actionsPolicy)
    }

    public static func makeLazy(
        initialState: State,
        actionsPolicy: _FSMBase<State, Event>.StateActionsPolicy
    ) -> some FSMBase<State, Event> {
        LazyFSM(initialState: initialState, actionsPolicy: actionsPolicy)
    }
}

public class _FSMBase<State: Hashable, Event: Hashable> {
    struct Key: Hashable {
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

    enum TransitionResult {
        case executed, notFound(Event, [any Predicate]), notExecuted(Transition)
    }

    let stateActionsPolicy: StateActionsPolicy

    var table: [Key: Transition] = [:]
    var state: AnyHashable
    let logger = Logger<Event>()

    init(initialState: State, actionsPolicy: StateActionsPolicy = .executeOnChangeOnly) {
        self.state = initialState
        self.stateActionsPolicy = actionsPolicy
    }

    public func buildTable(
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
    func _handleEvent(_ event: Event, predicates: [any Predicate]) -> TransitionResult {
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

    @discardableResult @MainActor
    func _handleEventAsync(_ event: Event, predicates: [any Predicate]) async -> TransitionResult {
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
        table[Key(state: state,
                     predicates: Set(predicates.erased()),
                     event: event)]
    }

    @MainActor
    private func shouldExecute(_ t: Transition) -> Bool {
        t.condition?() ?? true
    }

    func makeMatchResolvingNode(rest: [any Node<IntermediateIO>]) -> any MatchResolvingNode {
        fatalError("subclasses must implement")
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

        let stateEvent = (result.output.first?.state, result.output.first?.event)
        if deepDescription(stateEvent).contains("NSObject") {
            throw makeError(NSObjectError())
        }
    }

    func makeTable(_ output: [Transition]) {
        output.forEach { table[Key($0)] = $0 }
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
