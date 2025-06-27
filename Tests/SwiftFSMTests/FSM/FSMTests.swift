import Foundation
import Testing
@testable import SwiftFSM

class FSMTestsBase<State: FSMHashable, Event: FSMHashable>: ExpandedSyntaxBuilder {
    typealias SUT = FSM<State, Event>.Base
    
    class var eagerAndLazy: [SUT] { [makeEager(), makeLazy()] }
    class var initialState: State { fatalError("subclasses must implement") }
    
    static func makeEager() -> FSM<State, Event>.Base {
        FSM<State, Event>.Eager(
            initialState: initialState,
            actionsPolicy: .executeOnChangeOnly
        )
    }

    static func makeLazy() -> FSM<State, Event>.Base {
        FSM<State, Event>.Lazy(
            initialState: initialState,
            actionsPolicy: .executeOnChangeOnly
        )
    }
    
    func assertThrowsError<T: Error>(
        _ type: T.Type,
        count: Int = 1,
        location: SourceLocation = #_sourceLocation,
        block: () throws -> (),
        completion: (T?) -> () = { _ in }
    ) {
        #expect(performing: {
            try block()
        }, throws: { e in
            let errors = (e as? SwiftFSMError)?.errors
            let description = String(describing: errors)
            #expect(
                count == errors?.count,
                "\(description)",
                sourceLocation: location
            )
            #expect(errors?.first is T, "\(description)", sourceLocation: location)
            completion(errors?.first as? T)
            return true
        })
    }
}

extension FSM.Base: @unchecked Sendable { }

class FSMTests: FSMTestsBase<Int, Double> {
    class override var initialState: Int { 1 }
    
    @Test
    func makeMRNInBaseIsAbstract() async {
        await #expect(processExitsWith: .failure) {
            let _ = FSM<Int, Int>.Base(initialState: 1).makeMatchResolvingNode(rest: [])
        }
    }
    
    @Test(arguments: eagerAndLazy)
    func successfulInit(_ fsm: SUT) {
        #expect(1 == fsm.state as! Int)
    }
    
    @Test(arguments: eagerAndLazy)
    func buildEmptyTableThrowsError(_ fsm: SUT) {
        assertThrowsError(EmptyTableError.self) {
            try fsm.buildTable { }
        }
    }

    @Test(arguments: eagerAndLazy)
    func throwsErrorsFromNodes(_ fsm: SUT) {
        assertThrowsError(EmptyBuilderError.self) {
            try fsm.buildTable { define(1) { } }
        }
    }

    @Test(arguments: eagerAndLazy)
    func validTableDoesNotThrow(_ fsm: SUT) {
        #expect(throws: Never.self) {
            try fsm.buildTable { define(1) { when(1.1) | then(2) } }
        }
    }

    @Test(arguments: eagerAndLazy)
    func callingBuildTableTwiceThrows(_ fsm: SUT) throws {
        try fsm.buildTable { define(1) { when(1.1) | then(2) } }
        assertThrowsError(TableAlreadyBuiltError.self) {
            try fsm.buildTable(file: "f", line: 1) { define(1) { when(1.1) | then(2) } }
        } completion: {
            #expect("f" == $0?.file)
            #expect(1 == $0?.line)
        }
    }

    class HandleEventTests: FSMTests {
        var actionsOutput = ""
        
        func assertHandleEvent(
            _ event: Event,
            predicates: any Predicate...,
            state: State,
            output: String,
            fsm: SUT,
            location: SourceLocation = #_sourceLocation
        ) async {
            await fsm.handleEvent(event, predicates: predicates, isolation: nil)
            assertEventHandled(state: state, output: output, fsm: fsm, location: location)
        }
        
        func assertEventHandled(
            state: State,
            output: String,
            fsm: SUT,
            location: SourceLocation = #_sourceLocation
        ) {
            #expect(state == fsm.state as! Int, sourceLocation: location)
            #expect(output == actionsOutput, sourceLocation: location)
            
            actionsOutput = ""
            fsm.state = 1
        }
        
        func pass() {
            actionsOutput = "pass"
        }
        
        func passAsync() async {
            pass()
        }
        
        func passWithEvent(_ event: Event) {
            actionsOutput = "pass, event: \(event)"
        }
        
        func passWithEventAsync(_ event: Event) async {
            passWithEvent(event)
        }
        
        @Test(arguments: eagerAndLazy)
        func handleEventWithoutPredicate(fsm: SUT) async throws {
            try fsm.buildTable {
                define(1) {
                    when(1.1) | then(2) | passAsync
                    when(1.3) | then(2) | passWithEventAsync
                }
            }
            
            await assertHandleEvent(1.1, state: 2, output: "pass", fsm: fsm)
            await assertHandleEvent(1.2, state: 1, output: "", fsm: fsm)
            await assertHandleEvent(1.3, state: 2, output: "pass, event: 1.3", fsm: fsm)
        }
        
        @Test(arguments: eagerAndLazy)
        func handleEventWithSinglePredicate(_ fsm: SUT) async throws {
            try fsm.buildTable {
                define(1) {
                    matching(P.a) | when(1.1) | then(2) | passAsync
                    matching(P.b) | when(1.1) | then(3) | passAsync
                }
            }
            
            await assertHandleEvent(1.1, predicates: P.a, state: 2, output: "pass", fsm: fsm)
            await assertHandleEvent(1.1, predicates: P.b, state: 3, output: "pass", fsm: fsm)
        }
        
        @Test(arguments: eagerAndLazy)
        func handleEventWithMultiplePredicates(_ fsm: SUT) async throws {
            try fsm.buildTable {
                define(1) {
                    matching(P.a, or: P.b)  | when(1.1) | then(2) | passAsync
                    matching(Q.a, and: R.a) | when(1.1) | then(3) | passAsync
                }
            }
            
            await assertHandleEvent(1.1, predicates: P.a, Q.b, R.a, state: 2, output: "pass", fsm: fsm)
            await assertHandleEvent(1.1, predicates: P.a, Q.a, R.a, state: 3, output: "pass", fsm: fsm)
        }
        
        @Test(arguments: eagerAndLazy)
        func handleEventWithImplicitPredicatesAsync(_ fsm: SUT) async throws {
            try fsm.buildTable {
                define(1) {
                    matching(P.a) | when(1.1) | then(2) | passAsync
                    when(1.1) | then(3) | passAsync
                }
            }
            
            await assertHandleEvent(1.1, predicates: P.a, state: 2, output: "pass", fsm: fsm)
            await assertHandleEvent(1.1, predicates: P.c, state: 3, output: "pass", fsm: fsm)
        }
        
        @Test(arguments: eagerAndLazy)
        func handleEventPredicateVarargOverloadsAsync(_ fsm: SUT) async throws {
            try fsm.buildTable {
                define(1) {
                    matching(P.a) | when(1.1) | then(2) | pass
                    matching(Q.b) | when(1.2) | then(2) | pass
                }
            }
            
            await fsm.handleEvent(1.1, predicates: P.a, Q.b)
            assertEventHandled(state: 2, output: "pass", fsm: fsm)
            
            await fsm.handleEvent(1.1)
            assertEventHandled(state: 1, output: "", fsm: fsm)
        }
        
        func onEntryAsync() async { onEntry() }
        func onEntry() { actionsOutput += "entry" }
        func onExitAsync() async  { onExit() }
        func onExit()  { actionsOutput += "exit" }
        
        @Test(arguments: eagerAndLazy)
        func handleEventWithConditionalEntryExitActions(_ fsm: SUT) async throws {
            try fsm.buildTable {
                define(1, onEntry: Array(onEntryAsync), onExit: Array(onExitAsync)) {
                    when(1.0) | then(1)
                    when(1.1) | then(2)
                }
                
                define(2, onEntry: Array(onEntryAsync), onExit: Array(onExitAsync)) {
                    when(1.1) | then(1)
                }
            }
            
            await assertHandleEvent(1.0, state: 1, output: "", fsm: fsm)
            await assertHandleEvent(1.1, state: 2, output: "exitentry", fsm: fsm)
            fsm.state = 2
            await assertHandleEvent(1.1, state: 1, output: "exitentry", fsm: fsm)
        }
        
        @Test(arguments: eagerAndLazy)
        func handleEventWithUnconditionalEntryExitActions(_ fsm: SUT) async throws {
            fsm.stateActionsPolicy = .executeAlways
            
            try fsm.buildTable {
                define(1, onEntry: Array(onEntry), onExit: Array(onExit)) {
                    when(1.0) | then(1)
                    when(1.1) | then(2)
                }
                
                define(2, onEntry: Array(onEntry), onExit: Array(onExit)) {
                    when(1.1) | then(1)
                }
            }
            
            await assertHandleEvent(1.0, state: 1, output: "exitentry", fsm: fsm)
            await assertHandleEvent(1.1, state: 2, output: "exitentry", fsm: fsm)
            fsm.state = 2
            await assertHandleEvent(1.1, state: 1, output: "exitentry", fsm: fsm)
        }
        
        @Test(arguments: eagerAndLazy)
        func handleEventWithCondition(_ fsm: SUT) async throws {
            try fsm.buildTable {
                define(1) { condition { false } | when(1.1) | then(2) | pass }
                define(2) { condition { true  } | when(1.1) | then(3) | pass }
            }
            
            await assertHandleEvent(1.1, state: 1, output: "", fsm: fsm)
            fsm.state = 2
            await assertHandleEvent(1.1, state: 3, output: "pass", fsm: fsm)
        }
        
        @Test func handleEventEarlyReturnAsync() async throws {
            let fsm = Self.makeLazy()
            
            try fsm.buildTable {
                define(1) {
                    matching(P.a) | when(1.1) | then(1) | passAsync
                    when(1.1) | then(2) | passAsync
                }
            }
            
            await assertHandleEvent(1.1, predicates: P.a, state: 1, output: "pass", fsm: fsm)
            await assertHandleEvent(1.1, predicates: P.b, state: 2, output: "pass", fsm: fsm)
        }
        
        @Test func handleEventEarlyReturnWithConditionAsync() async throws {
            class EarlyReturnSpy: FSM<State, Event>.Lazy, @unchecked Sendable {
                override func logTransitionNotFound(_ event: Event, _ predicates: [any Predicate]) {
                    Issue.record("should never be called in this test")
                }
            }
            
            let fsm = EarlyReturnSpy(initialState: 1)
            
            try fsm.buildTable {
                define(1) {
                    condition { false } | when(1.1) | then(1) | passAsync
                }
            }
            
            await assertHandleEvent(1.1, predicates: P.a, state: 1, output: "", fsm: fsm)
        }
    }
}

extension Int: @retroactive CaseIterable {}
extension Int: Predicate {
    public static var allCases: [Int] { [] }
}

extension Double: @retroactive CaseIterable {}
extension Double: Predicate {
    public static var allCases: [Double] { [] }
}

extension Array {
    func callAsFunction(_ i: Index) -> Element? {
        guard i < count else { return nil }
        return self[i]
    }
}
