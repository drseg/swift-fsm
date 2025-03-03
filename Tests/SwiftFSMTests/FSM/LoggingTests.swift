import Testing
@testable import SwiftFSM

struct LogData: Equatable {
    let event: Int
    let predicates: [AnyPredicate]
    
    init(_ event: Int, _ predicates: [any Predicate]) {
        self.event = event
        self.predicates = predicates.erased()
    }
}

protocol LoggableFSM {
    var loggedEvents: [LogData] { get set }
    var loggedTransitions: [Transition] { get set }
}

class LoggerTests {
    class LoggerSpy: Logger<Int> {
        var callStack = [String]()
        
        func appendFunctionName(_ magicName: String) {
            callStack.append(String(magicName.prefix { $0 != "(" }))
        }
        
        override func transitionNotFoundString(
            _ event: Int,
            _ predicates: [any Predicate]
        ) -> String {
            appendFunctionName(#function)
            return super.transitionNotFoundString(event, predicates)
        }
        
        override func transitionNotExecutedString(_ t: Transition) -> String {
            appendFunctionName(#function)
            return super.transitionNotExecutedString(t)
        }

        override func transitionExecutedString(_ t: Transition) -> String {
            appendFunctionName(#function)
            return super.transitionExecutedString(t)
        }
    }
    
    let logger = LoggerSpy()
    
    func assertStack(_ expected: [String], location: SourceLocation = #_sourceLocation) {
        #expect(expected == logger.callStack, sourceLocation: location)
    }
    
    @Test func transitionNotFoundCallsForString() {
        logger.transitionNotFound(1, [])
        assertStack(["transitionNotFoundString"])
    }
    
    @Test func transitionNotFoundString() {
        let output = logger.transitionNotFoundString(1, [])
        #expect("no transition found for event '1'" == output)
    }
    
    @Test func transitionNotFoundStringWithPredicate() {
        enum P: Predicate, CustomStringConvertible {
            case a; var description: String { "P.a" }
        }
        
        let output = logger.transitionNotFoundString(1, [P.a])
        #expect(
            "no transition found for event '1' matching predicates [P.a]" ==
            output
        )
    }
    
    @Test func transitionNotExecutedCallsForString() {
        logger.transitionNotExecuted(Transition(nil, 1, [], 1, 1, []))
        assertStack(["transitionNotExecutedString"])
    }
    
    @Test func transitionNotExecutedString() {
        let output = logger.transitionNotExecutedString(Transition(nil, 1, [], 1, 1, []))
        #expect(
            "conditional transition { define(1) | when(1) | then(1) } not executed" ==
            output
        )
    }

    @Test func transitionNotExecutedStringWithPredicates() {
        let output = logger.transitionNotExecutedString(Transition(nil, 1, [P.a.erased()], 1, 1, []))
        #expect(
            "conditional transition { define(1) | matching([P.a]) | when(1) | then(1) } not executed" ==
            output
        )
    }

    @Test func transitionExecutedCallsForString() {
        logger.transitionExecuted(Transition(nil, 1, [], 1, 1, []))
        assertStack(["transitionExecutedString"])
    }

    @Test func transitionExecutedString() {
        let output = logger.transitionExecutedString(Transition(nil, 1, [], 1, 1, []))
        #expect(
            "transition { define(1) | when(1) | then(1) } was executed" ==
            output
        )
    }

    @Test func transitionExecutedStringWithPredicates() {
        let output = logger.transitionExecutedString(Transition(nil, 1, [P.a.erased()], 1, 1, []))
        #expect(
            "transition { define(1) | matching([P.a]) | when(1) | then(1) } was executed" ==
            output
        )
    }
}

class FSMLoggingTests: ExpandedSyntaxBuilder {
    typealias State = Int
    typealias Event = Int
    
    class FSMSpy: FSM<State, Event>.Eager, LoggableFSM, @unchecked Sendable {
        var loggedEvents: [LogData] = []
        var loggedTransitions: [Transition] = []
        
        override func logTransitionNotFound(_ event: Int, _ predicates: [any Predicate]) {
            loggedEvents.append(LogData(event, predicates))
        }
        
        override func logTransitionNotExecuted(_ t: Transition) {
            loggedTransitions.append(t)
        }

        override func logTransitionExecuted(_ t: Transition) {
            loggedTransitions.append(t)
        }
    }
    
    class LazyFSMSpy: FSM<State, Event>.Lazy, LoggableFSM, @unchecked Sendable {
        var loggedEvents: [LogData] = []
        var loggedTransitions: [Transition] = []
        
        override func logTransitionNotFound(_ event: Int, _ predicates: [any Predicate]) {
            loggedEvents.append(LogData(event, predicates))
        }
        
        override func logTransitionNotExecuted(_ t: Transition) {
            loggedTransitions.append(t)
        }

        override func logTransitionExecuted(_ t: Transition) {
            loggedTransitions.append(t)
        }
    }

    let fsm = FSMSpy(initialState: 1)
    let lazyFSM = LazyFSMSpy(initialState: 1)
    
    func buildTable(@FSM<Int, Int>.TableBuilder _ block: () -> [Syntax.Define<Int, Int>]) {
        try! fsm.buildTable(block)
        try! lazyFSM.buildTable(block)
    }
    
    func handleEvent(_ event: Int, _ predicates: any Predicate...) async {
        await fsm.handleEvent(event, predicates: predicates)
        fsm.state = 1

        await lazyFSM.handleEvent(event, predicates: predicates)
        lazyFSM.state = 1
    }
    
    func assertEqual<T: Equatable>(
        _ expected: [T],
        _ actual: KeyPath<LoggableFSM, [T]>,
        location: SourceLocation = #_sourceLocation
    ) {
        #expect(expected == fsm[keyPath: actual], sourceLocation: location)
        #expect(expected == lazyFSM[keyPath: actual], sourceLocation: location)
    }

    @Test func transitionExecutedIsLogged() async {
        buildTable {
            define(1) {
                when(2) | then(3)
            }
        }
        await handleEvent(2)

        let t = Transition(nil, 1, [], 2, 3, [])
        assertEqual([t], \.loggedTransitions)
    }

    @Test func transitionNotFoundIsLogged() async {
        enum P: Predicate { case a }
        await handleEvent(1, P.a)
        assertEqual([LogData(1, [P.a])], \.loggedEvents)
    }
    
    @Test func transitionNotExecutedIsLogged() async {
        buildTable {
            define(1) {
                condition({ false }) | when(2) | then(3)
            }
        }
        await handleEvent(2)

        let t = Transition(nil, 1, [], 2, 3, [])
        assertEqual([t], \.loggedTransitions)
    }
}

extension Transition: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.state == rhs.state &&
        lhs.predicates == rhs.predicates &&
        lhs.event == rhs.event &&
        lhs.nextState == rhs.nextState
    }
}
