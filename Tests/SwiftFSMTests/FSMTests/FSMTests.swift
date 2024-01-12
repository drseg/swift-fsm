import Foundation
import XCTest
@testable import SwiftFSM

class FSMTestsBase<State: Hashable, Event: Hashable>: XCTestCase, ExpandedSyntaxBuilder {
    var fsm: _FSMBase<State, Event>!
    
    override func setUp() {
        fsm = makeSUT(initialState: initialState)
    }
    
    var initialState: State {
        fatalError("subclasses must implement")
    }
    
    func makeSUT<_State: Hashable, _Event: Hashable>(
        initialState: _State,
        actionsPolicy: _FSMBase<_State, _Event>.StateActionsPolicy = .executeOnChangeOnly
    ) -> _FSMBase<_State, _Event> {
        fatalError("subclasses must implement")
    }
}

class LazyFSMTests: FSMTests {
    override func makeSUT<_State: Hashable, _Event: Hashable>(
        initialState: _State,
        actionsPolicy: _FSMBase<_State, _Event>.StateActionsPolicy = .executeOnChangeOnly
    ) -> _FSMBase<_State, _Event> {
        LazyFSM<_State, _Event>(initialState: initialState, actionsPolicy: actionsPolicy)
    }
    
    func testHandleEventEarlyReturn() throws {
        try fsm.buildTable {
            define(1) {
                matching(P.a) | when(1.1) | then(1) | pass
                                when(1.1) | then(2) | pass
            }
        }

        assertHandleEvent(1.1, predicates: P.a, state: 1, output: "pass")
        assertHandleEvent(1.1, predicates: P.b, state: 2, output: "pass")
    }
}

class FSMTests: FSMTestsBase<Int, Double> {
    override var initialState: Int { 1 }
    
    override func makeSUT<_State: Hashable, _Event: Hashable>(
        initialState: _State,
        actionsPolicy: _FSMBase<_State, _Event>.StateActionsPolicy = .executeOnChangeOnly
    ) -> _FSMBase<_State, _Event> {
        FSM<_State, _Event>(initialState: initialState, actionsPolicy: actionsPolicy)
    }
    
    func assertThrowsError<T: Error>(
        _ type: T.Type,
        count: Int = 1,
        line: UInt = #line,
        block: () throws -> (),
        completion: (T?) -> () = { _ in }
    ) {
        XCTAssertThrowsError(try block(), line: line) {
            let errors = ($0 as? SwiftFSMError)?.errors
            XCTAssertEqual(count, errors?.count, line: line)
            XCTAssertTrue(errors?.first is T, String(describing: errors), line: line)
            completion(errors?.first as? T)
        }
    }
    
    func testSuccessfulInit() {
        XCTAssertEqual(1, fsm.state)
    }
    
    func testBuildEmptyTable() {
        assertThrowsError(EmptyTableError.self) {
            try fsm.buildTable { }
        }
    }

    func testThrowsErrorsFromNodes() {
        assertThrowsError(EmptyBuilderError.self) {
            try fsm.buildTable { define(1) { } }
        }
    }

    func testThrowsNSObjectError()  {
        let fsm1: _FSMBase<NSObject, Int> = makeSUT(initialState: NSObject())
        let fsm2: _FSMBase<Int, NSObject> = makeSUT(initialState: 1)

        assertThrowsError(NSObjectError.self) {
            try fsm1.buildTable {
                Syntax.Define(NSObject()) { Syntax.When(1) | Syntax.Then(NSObject()) }
            }
        }

        assertThrowsError(NSObjectError.self) {
            try fsm2.buildTable {
                Syntax.Define(1) { Syntax.When(NSObject()) | Syntax.Then(2) }
            }
        }
    }

    func testValidTableDoesNotThrow() {
        XCTAssertNoThrow(
            try fsm.buildTable { define(1) { when(1.1) | then(2) } }
        )
    }

    func testCallingBuildTableTwiceThrows() throws {
        try fsm.buildTable { define(1) { when(1.1) | then(2) } }
        assertThrowsError(TableAlreadyBuiltError.self) {
            try fsm.buildTable(file: "f", line: 1) { define(1) { when(1.1) | then(2) } }
        } completion: {
            XCTAssertEqual("f", $0?.file)
            XCTAssertEqual(1, $0?.line)
        }
    }

    var actionsOutput = ""
    func assertHandleEvent(
        _ event: Event,
        predicates: any Predicate...,
        state: State,
        output: String,
        line: UInt = #line
    ) {
        fsm.handleEvent(event, predicates: predicates)
        XCTAssertEqual(state, fsm.state, line: line)
        XCTAssertEqual(output, actionsOutput, line: line)

        actionsOutput = ""
        fsm.state = 1
    }

    func pass() {
        actionsOutput = "pass"
    }

    func passWithEvent(_ event: Event) {
        actionsOutput = "pass, event: \(event)"
    }

    func testHandleEventWithoutPredicate() throws {
        try fsm.buildTable {
            define(1) {
                when(1.1) | then(2) | pass
                when(1.3) | then(2) | passWithEvent
            }
        }

        assertHandleEvent(1.1, state: 2, output: "pass")
        assertHandleEvent(1.2, state: 1, output: "")
        assertHandleEvent(1.3, state: 2, output: "pass, event: 1.3")
    }

    func testHandleEventWithSinglePredicate() throws {
        try fsm.buildTable {
            define(1) {
                matching(P.a) | when(1.1) | then(2) | pass
                matching(P.b) | when(1.1) | then(3) | pass
            }
        }

        assertHandleEvent(1.1, predicates: P.a, state: 2, output: "pass")
        assertHandleEvent(1.1, predicates: P.b, state: 3, output: "pass")
    }

    func testHandlEventWithMultiplePredicates() throws {
        try fsm.buildTable {
            define(1) {
                matching(P.a, or: P.b)  | when(1.1) | then(2) | pass
                matching(Q.a, and: R.a) | when(1.1) | then(3) | pass
            }
        }

        assertHandleEvent(1.1, predicates: P.a, Q.b, R.a, state: 2, output: "pass")
        assertHandleEvent(1.1, predicates: P.a, Q.a, R.a, state: 3, output: "pass")
    }
    
    func testHandlEventWithImplicitPredicates() throws {
        try fsm.buildTable {
            define(1) {
                matching(P.a) | when(1.1) | then(2) | pass
                                when(1.1) | then(3) | pass
            }
        }

        assertHandleEvent(1.1, predicates: P.a, state: 2, output: "pass")
        assertHandleEvent(1.1, predicates: P.c, state: 3, output: "pass")
    }
    
    func onEntry() { actionsOutput += "entry" }
    func onExit()  { actionsOutput += "exit" }
    
    func testHandleEventWithConditionalEntryExitActions() throws {
        try fsm.buildTable {
            define(1, onEntry: [onEntry], onExit: [onExit]) {
                when(1.0) | then(1)
                when(1.1) | then(2)
            }
            
            define(2, onEntry: [onEntry], onExit: [onExit]) {
                when(1.1) | then(1)
            }
        }
        
        assertHandleEvent(1.0, state: 1, output: "")
        assertHandleEvent(1.1, state: 2, output: "exitentry")
        fsm.state = 2
        assertHandleEvent(1.1, state: 1, output: "exitentry")
    }
    
    func testHandleEventWithUnconditionalEntryExitActions() throws {
        fsm = makeSUT(initialState: 1, actionsPolicy: .executeAlways)
        try fsm.buildTable {
            define(1, onEntry: [onEntry], onExit: [onExit]) {
                when(1.0) | then(1)
                when(1.1) | then(2)
            }
            
            define(2, onEntry: [onEntry], onExit: [onExit]) {
                when(1.1) | then(1)
            }
        }

        assertHandleEvent(1.0, state: 1, output: "exitentry")
        assertHandleEvent(1.1, state: 2, output: "exitentry")
        fsm.state = 2
        assertHandleEvent(1.1, state: 1, output: "exitentry")
    }

    func testHandlEventWithCondition() throws {
        try fsm.buildTable {
            define(1) { condition { false } | when(1.1) | then(2) | pass }
            define(2) { condition { true  } | when(1.1) | then(3) | pass }
        }

        assertHandleEvent(1.1, state: 1, output: "")
        fsm.state = 2
        assertHandleEvent(1.1, state: 3, output: "pass")
    }
}

extension Int: Predicate {
    public static var allCases: [Int] { [] }
}

extension Double: Predicate {
    public static var allCases: [Double] { [] }
}

extension Array {
    func callAsFunction(_ i: Index) -> Element? {
        guard i < count else { return nil }
        return self[i]
    }
}
