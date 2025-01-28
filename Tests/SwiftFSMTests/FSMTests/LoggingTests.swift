import XCTest
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

class LoggerTests: XCTestCase {
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
    
    func assertStack(_ expected: [String], line: UInt = #line) {
        XCTAssertEqual(expected, logger.callStack, line: line)
    }
    
    func testTransitionNotFoundCallsForString() {
        logger.transitionNotFound(1, [])
        assertStack(["transitionNotFoundString"])
    }
    
    func testTransitionNotFoundString() {
        let output = logger.transitionNotFoundString(1, [])
        XCTAssertEqual("no transition found for event '1'", output)
    }
    
    func testTransitionNotFoundStringWithPredicate() {
        enum P: Predicate, CustomStringConvertible {
            case a; var description: String { "P.a" }
        }
        
        let output = logger.transitionNotFoundString(1, [P.a])
        XCTAssertEqual(
            "no transition found for event '1' matching predicates [P.a]",
            output
        )
    }
    
    func testTransitionNotExecutedCallsForString() {
        logger.transitionNotExecuted(Transition(nil, 1, [], 1, 1, []))
        assertStack(["transitionNotExecutedString"])
    }
    
    func testTransitionNotExecutedString() {
        let output = logger.transitionNotExecutedString(Transition(nil, 1, [], 1, 1, []))
        XCTAssertEqual(
            "conditional transition { define(1) | when(1) | then(1) } not executed",
            output
        )
    }

    func testTransitionNotExecutedStringWithPredicates() {
        let output = logger.transitionNotExecutedString(Transition(nil, 1, [P.a.erased()], 1, 1, []))
        XCTAssertEqual(
            "conditional transition { define(1) | matching([P.a]) | when(1) | then(1) } not executed",
            output
        )
    }

    func testTransitionExecutedCallsForString() {
        logger.transitionExecuted(Transition(nil, 1, [], 1, 1, []))
        assertStack(["transitionExecutedString"])
    }

    func testTransitionExecutedString() {
        let output = logger.transitionExecutedString(Transition(nil, 1, [], 1, 1, []))
        XCTAssertEqual(
            "transition { define(1) | when(1) | then(1) } was executed",
            output
        )
    }

    func testTransitionExecutedStringWithPredicates() {
        let output = logger.transitionExecutedString(Transition(nil, 1, [P.a.erased()], 1, 1, []))
        XCTAssertEqual(
            "transition { define(1) | matching([P.a]) | when(1) | then(1) } was executed",
            output
        )
    }
}

class FSMLoggingTests: XCTestCase, ExpandedSyntaxBuilder {
    typealias State = Int
    typealias Event = Int
    
    class FSMSpy: EagerFSM<Int, Int>, LoggableFSM {
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
    
    class LazyFSMSpy: LazyFSM<Int, Int>, LoggableFSM {
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
    
    func buildTable(@TableBuilder<Int, Int> _ block: () -> [Syntax.Define<Int, Int>]) {
        try! fsm.buildTable(block)
        try! lazyFSM.buildTable(block)
    }
    
    @MainActor
    func handleEvent(_ event: Int, _ predicates: any Predicate...) async {
        try! fsm.handleEvent(event, predicates: predicates)
        fsm.state = 1
        await fsm.handleEventAsync(event, predicates: predicates)
        fsm.state = 1
        
        try! lazyFSM.handleEvent(event, predicates: predicates)
        lazyFSM.state = 1
        await lazyFSM.handleEventAsync(event, predicates: predicates)
        lazyFSM.state = 1
    }
    
    func assertEqual<T: Equatable>(
        _ expected: [T],
        _ actual: KeyPath<LoggableFSM, [T]>,
        line: UInt = #line
    ) {
        XCTAssertEqual(expected, fsm[keyPath: actual], line: line)
        XCTAssertEqual(expected, lazyFSM[keyPath: actual], line: line)
    }

    func testTransitionExecutedIsLogged() async {
        buildTable {
            define(1) {
                when(2) | then(3)
            }
        }
        await handleEvent(2)

        let t = Transition(nil, 1, [], 2, 3, [])
        assertEqual([t, t], \.loggedTransitions)
    }

    func testTransitionNotFoundIsLogged() async {
        enum P: Predicate { case a }
        await handleEvent(1, P.a)
        assertEqual([LogData(1, [P.a]), LogData(1, [P.a])], \.loggedEvents)
    }
    
    func testTransitionNotExecutedIsLogged() async {
        buildTable {
            define(1) {
                condition({ false }) | when(2) | then(3)
            }
        }
        await handleEvent(2)

        let t = Transition(nil, 1, [], 2, 3, [])
        assertEqual([t, t], \.loggedTransitions)
    }
}

extension Transition: @retroactive Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.state == rhs.state &&
        lhs.predicates == rhs.predicates &&
        lhs.event == rhs.event &&
        lhs.nextState == rhs.nextState
    }
}
