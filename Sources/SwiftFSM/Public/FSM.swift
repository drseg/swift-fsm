import Foundation

public enum StateActionsPolicy {
    case executeAlways, executeOnChangeOnly
}

public class FSM<State: FSMHashable, Event: FSMHashable> {
    public enum PredicateHandling { case eager, lazy }
    
    typealias Precondition = (
        @autoclosure () -> Bool,
        @autoclosure () -> String,
        StaticString,
        UInt
    ) -> ()
    
    var assertsIsolation: Bool
    var isolation: (any Actor) = NonIsolated()
    var isolationWasSet = false
    var _precondition: Precondition = Swift.precondition

    var fsm: Base
    
    public init(
        type: PredicateHandling = .eager,
        initialState initial: State,
        actionsPolicy policy: StateActionsPolicy = .executeOnChangeOnly,
        enforceConcurrency: Bool = false
    ) {
        fsm = switch type {
        case .eager: Eager(initialState: initial, actionsPolicy: policy)
        case .lazy: Lazy(initialState: initial, actionsPolicy: policy)
        }
        
        self.assertsIsolation = enforceConcurrency
    }

    public func buildTable(
        file: StaticString = #file,
        line: Int = #line,
        isolation: isolated (any Actor)? = #isolation,
        @TableBuilder _ block: @isolated(any) () -> [Syntax.Define<State, Event>]
    ) throws {
        verifyIsolation(isolation, file: file, line: UInt(line))
        try fsm.buildTable(file: "\(file)", line: line, isolation: isolation, block)
    }
    
    public func handleEvent(
        _ event: Event,
        predicates: (any Predicate)...,
        isolation: isolated (any Actor)? = #isolation,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        verifyIsolation(isolation, file: file, line: line)
        await handleEvent(event, predicates: predicates, isolation: isolation)
    }
    
    internal func handleEvent(
        _ event: Event,
        predicates: [any Predicate],
        isolation: isolated (any Actor)? = #isolation,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        await fsm.handleEvent(event, predicates: predicates, isolation: isolation)
    }
}

extension FSM {
    private actor NonIsolated { }
    
    internal func verifyIsolation(
        _ isolation: (any Actor)?,
        caller: StaticString = #function,
        file: StaticString,
        line: UInt
    ) {
#if(DEVELOPMENT)
        guard assertsIsolation else { return }
        
        let isolation = isolation ?? NonIsolated()
        
        if isolationWasSet {
            assertIsolation(isolation, caller: caller, file: file, line: line)
        } else {
            setIsolation(isolation)
        }
#endif
    }
    
    private func assertIsolation(
        _ isolation: (any Actor),
        caller: StaticString,
        file: StaticString,
        line: UInt
    ) {
        let current = type(of: isolation)
        let previous = type(of: self.isolation)
        let message = "Concurrency violation: \(caller) called by \(current) (expected \(previous))"
        
        _precondition(current == previous, message, file, UInt(line))
    }
    
    private func setIsolation(_ isolation: (any Actor)) {
        self.isolation = isolation
        isolationWasSet = true
    }
}

extension FSM {
    @MainActor
    public class Isolated {
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
        file: StaticString = #file,
        line: Int = #line,
        @TableBuilder _ block: @MainActor () -> [Syntax.Define<State, Event>]
        ) throws {
            try fsm.buildTable(file: file, line: line, block)
        }
        
        public func handleEvent(
            _ event: Event,
            predicates: any Predicate...
        ) async {
            await fsm.handleEvent(event, predicates: predicates)
        }
    }
}
