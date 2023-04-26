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

open class FSMBase<State: Hashable, Event: Hashable> {
    public enum EntryExitActionsPolicy {
        case executeAlways, executeOnStateChangeOnly
    }

    var entryExitActionsPolicy = EntryExitActionsPolicy.executeOnStateChangeOnly
    
    public func setEntryExitActionsPolicy(_ newValue: EntryExitActionsPolicy) throws {
        guard table.isEmpty else { throw makeError(SetEntryExitActionsPolicyError()) }
        entryExitActionsPolicy = newValue
    }
    
    var table: [FSMKey: Transition] = [:]
    var state: AnyHashable
    
    public func handleEvent(_ event: Event, predicates: [any Predicate]) {
        fatalError("subclasses must implement")
    }
    
    func makeMRN(rest: [any Node<IntermediateIO>]) -> MRNBase {
        fatalError("subclasses must implement")
    }
    
    func makeARN(rest: [DefineNode]) -> ActionsResolvingNodeBase {
        switch entryExitActionsPolicy {
        case .executeAlways: return ActionsResolvingNode(rest: rest)
        case .executeOnStateChangeOnly: return ConditionalActionsResolvingNode(rest: rest)
        }
    }
    
    init(initialState: State) {
        self.state = initialState
    }
    
    public func handleEvent(_ event: Event, predicates: any Predicate...) {
        handleEvent(event, predicates: predicates)
    }
    
    @discardableResult
    func _handleEvent(_ event: Event, predicates: [any Predicate]) -> Bool {
        if let transition = table[FSMKey(state: state,
                                         predicates: Set(predicates.erased()),
                                         event: event)],
           transition.condition?() ?? true
        {
            state = transition.nextState
            transition.actions.forEach { $0() }
            return true
        }
        
        return false
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
        let mrn = makeMRN(rest: [svn])
        let result = (mrn as! any Node<Transition>).finalised()
        
        try checkForErrors(result)
        makeTable(result.output)
    }
    
    func checkForErrors(_ result: (output: [Transition], errors: [Error])) throws {
        if !result.errors.isEmpty {
            throw makeError(result.errors)
        }
        
        if result.output.isEmpty {
            throw makeError(EmptyTableError())
        }
        
        let stateEvent = (result.output[0].state, result.output[0].event)
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
