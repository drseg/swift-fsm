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

protocol FSMProtocol<State, Event>: AnyObject {
    associatedtype State: Hashable
    associatedtype Event: Hashable
    associatedtype MRN: MRNBase
    
    var table: [FSMKey: Transition] { get set }
    var state: AnyHashable { get set }
    
    init(initialState: State)

    func buildTable(
        file: String,
        line: Int,
        @TableBuilder<State> _ block: () -> [Syntax.Define<State>]
    ) throws
    
    func handleEvent(_ event: Event, predicates: any Predicate...)
    func handleEvent(_ event: Event, predicates: [any Predicate])
}

extension FSMProtocol {
    func buildTable(
        file: String = #file,
        line: Int = #line,
        @TableBuilder<State> _ block: () -> [Syntax.Define<State>]
    ) throws {
        guard table.isEmpty else {
            throw makeError(TableAlreadyBuiltError(file: file, line: line))
        }
        
        let transitionNode = ActionsResolvingNode(rest: block().map(\.node))
        let validationNode = SemanticValidationNode(rest: [transitionNode])
        let tableNode = MRN.init(rest: [validationNode])
        let result = (tableNode as! any Node<Transition>).finalised()
        
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
