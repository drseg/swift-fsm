//
//  FSMTests.swift
//
//  Created by Daniel Segall on 03/03/2023.
//

import Foundation
import XCTest
@testable import SwiftFSM

final class FSMTests: XCTestCase, TableBuilder {
    typealias StateType = Int
    typealias EventType = Double
    
    var fsm: FSM<StateType, EventType> = FSM(initialState: 1)
    
    func assertThrowsError<T: Error>(
        _ type: T.Type,
        count: Int = 1,
        line: UInt = #line,
        block: () throws -> ()
    ) {
        XCTAssertThrowsError(try block(), line: line) {
            let errors = ($0 as? CompoundError)?.errors
            XCTAssertEqual(count, errors?.count, line: line)
            XCTAssertTrue(errors?.first is T, String(describing: errors), line: line)
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
        let fsm1 = FSM<NSObject, Int>(initialState: NSObject())
        let fsm2 = FSM<Int, NSObject>(initialState: 1)
        
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
    
    func testThrowsStateEventTypeClash() {
        assertThrowsError(TypeClashError.self) {
            try FSM<Int, Int>(initialState: 1).buildTable {
                Syntax.Define(1) { Syntax.When(1) | Syntax.Then(2) }
            }
        }
    }
    
    func testThrowsPredicateEventTypeClash() {
        assertThrowsError(TypeClashError.self) {
            try fsm.buildTable {
                Syntax.Define(1) { Syntax.Matching(1) | Syntax.When(1.1) | Syntax.Then(2) }
            }
        }
        
        assertThrowsError(TypeClashError.self) {
            try fsm.buildTable {
                Syntax.Define(1) { Syntax.Matching(1.1) | Syntax.When(1.1) | Syntax.Then(2) }
            }
        }
    }
    
    func testValidTableDoesNotThrow() {
        XCTAssertNoThrow(
            try fsm.buildTable { define(1) { when(1.1) | then(2) } }
        )
    }
    
    var actionsOutput = ""
    func assertHandleEvent(
        _ event: EventType,
        predicates: any Predicate...,
        state: StateType,
        output: String,
        line: UInt = #line
    ) {
        fsm.handleEvent(event, predicates: predicates)
        XCTAssertEqual(state, fsm.state, line: line)
        XCTAssertEqual(output, actionsOutput, line: line)
        
        actionsOutput = ""
        fsm.state = 1
    }
    
    func testHandleEventWithoutPredicate() throws {
        try fsm.buildTable {
            define(1) { when(1.1) | then(2) | { self.actionsOutput = "pass" } }
        }
        
        assertHandleEvent(1.1, state: 2, output: "pass")
        assertHandleEvent(1.2, state: 1, output: "")
    }
    
    func testHandleEventWithSinglePredicate() throws {
        try fsm.buildTable {
            define(1) { matching(P.a) | when(1.1) | then(2) | { self.actionsOutput = "pass" } }
            define(1) { matching(P.b) | when(1.1) | then(3) | { self.actionsOutput = "pass" } }
        }
        
        assertHandleEvent(1.1, predicates: P.a, state: 2, output: "pass")
        assertHandleEvent(1.1, predicates: P.b, state: 3, output: "pass")
    }
    
    func testHandlEventWithMultiplePredicates() throws {
        func pass() {
            actionsOutput = "pass"
        }
        
        try fsm.buildTable {
            define(1) { matching(P.a, or: Q.a) | when(1.1) | then(2) | pass }
            define(1) { matching(P.b, or: Q.b) | when(1.1) | then(3) | pass }
            define(1) { matching(P.b, and: Q.b) | when(1.1) | then(4) | pass }
        }
        
        assertHandleEvent(1.1, predicates: P.a, state: 2, output: "pass")
        assertHandleEvent(1.1, predicates: P.b, state: 3, output: "pass")
        assertHandleEvent(1.1, predicates: Q.a, state: 2, output: "pass")
        assertHandleEvent(1.1, predicates: Q.b, state: 3, output: "pass")
        
        assertHandleEvent(1.1, predicates: P.b, Q.b, state: 4, output: "pass")
    }
}

class FSMIntegrationTests: XCTestCase, TableBuilder {
    enum StateType: String, CustomStringConvertible {
        case locked, unlocked, alarming
        var description: String { rawValue  }
    }

    enum EventType: String, CustomStringConvertible {
        case reset, coin, pass
        var description: String { rawValue }
    }
    
    var actions = [String]()
    
    func alarmOn()  { actions.append("alarmOn")  }
    func alarmOff() { actions.append("alarmOff") }
    func lock()     { actions.append("lock")     }
    func unlock()   { actions.append("unlock")   }
    func thankyou() { actions.append("thankyou") }
    
    let fsm = FSM<StateType, EventType>(initialState: .locked)
    var actual = [String]()
}

final class FSMIntegrationTests_Turnstile: FSMIntegrationTests {
    func testTurnstile() throws {
        func assertEventAction(_ e: EventType, _ a: String, line: UInt = #line) {
            assertEventAction(e, [a], line: line)
        }
        
        func assertEventAction(_ e: EventType, _ a: [String], line: UInt = #line) {
            actual += a
            fsm.handleEvent(e)
            XCTAssertEqual(actions, actual, line: line)
        }
                
        try fsm.buildTable {
            let resetable = SuperState {
                when(.reset) | then(.locked)
            }

            define(.locked, superState: resetable, onEntry: [lock]) {
                when(.coin) | then(.unlocked)
                when(.pass) | then(.alarming)
            }

            define(.unlocked, superState: resetable, onEntry: [unlock]) {
                when(.coin) | then(.unlocked) | thankyou
                when(.pass) | then(.locked)
            }

            define(.alarming, superState: resetable, onEntry: [alarmOn], onExit: [alarmOff])
        }
        
        assertEventAction(.coin,  "unlock")
        assertEventAction(.pass,  "lock")
        assertEventAction(.pass,  "alarmOn")
        assertEventAction(.reset, ["alarmOff", "lock"])
        assertEventAction(.coin,  "unlock")
        assertEventAction(.coin,  "thankyou")
        assertEventAction(.coin,  "thankyou")
        assertEventAction(.reset, "lock")
    }
}

final class FSMIntegrationTests_PredicateTurnstile: FSMIntegrationTests {
    enum EnforcementStyle: Predicate { case strong, weak }
    enum RewardStyle: Predicate { case punishing, rewarding }
    
    func idiot() { actions.append("idiot")    }
    
    func assertEventAction(_ e: EventType, _ a: String, line: UInt = #line) {
        assertEventAction(e, [a], line: line)
    }
    
    func assertEventAction(_ e: EventType, _ a: [String], line: UInt = #line) {
        if !(a.first?.isEmpty ?? false) {
            actual += a
        }
        fsm.handleEvent(e, predicates: [EnforcementStyle.weak, RewardStyle.punishing])
        XCTAssertEqual(actions, actual, line: line)
    }
    
    func assertTable() {
        assertEventAction(.coin,  "unlock")
        assertEventAction(.pass,  "lock")
        assertEventAction(.pass,  "")
        assertEventAction(.reset, "")
        assertEventAction(.coin,  "unlock")
        assertEventAction(.coin,  "idiot")
        assertEventAction(.coin,  "idiot")
        assertEventAction(.reset, "lock")
    }
    
    func testPredicateTurnstile() throws {
        try fsm.buildTable {
            let resetable = SuperState {
                when(.reset) | then(.locked)
            }
            
            define(.locked, superState: resetable, onEntry: [lock]) {
                matching(EnforcementStyle.weak)   | when(.pass) | then(.locked)
                matching(EnforcementStyle.strong) | when(.pass) | then(.alarming)
                
                when(.coin) | then(.unlocked)
            }
            
            define(.unlocked, superState: resetable, onEntry: [unlock]) {
                matching(RewardStyle.rewarding) | when(.coin) | then(.unlocked) | thankyou
                matching(RewardStyle.punishing) | when(.coin) | then(.unlocked) | idiot
                
                when(.pass) | then(.locked)
            }
            
            define(.alarming, superState: resetable, onEntry: [alarmOn], onExit: [alarmOff])
        }
        
        assertTable()
    }
    
    func testDeduplicatedPredicateTurnstile() throws {
        try fsm.buildTable {
            let resetable = SuperState {
                when(.reset) | then(.locked)
            }
            
            define(.locked, superState: resetable, onEntry: [lock]) {
                when(.pass) {
                    matching(EnforcementStyle.weak)   | then(.locked)
                    matching(EnforcementStyle.strong) | then(.alarming)
                }
                
                when(.coin) | then(.unlocked)
            }
            
            define(.unlocked, superState: resetable, onEntry: [unlock]) {
                when(.coin) {
                    then(.unlocked) {
                        matching(RewardStyle.rewarding) | thankyou
                        matching(RewardStyle.punishing) | idiot
                    }
                }
                
                when(.pass) | then(.locked)
            }
            
            define(.alarming, superState: resetable, onEntry: [alarmOn], onExit: [alarmOff])
        }
        
        assertTable()
    }
    
    func testTypealiasSyntaxTurnstile() throws {
        typealias State = Syntax.Define<StateType>
        typealias Event = Syntax.When<EventType>
        typealias NextState = Syntax.Then<StateType>
        typealias If = Syntax.Matching
        
        try fsm.buildTable {
            let resetable = SuperState {
                Event(.reset) | NextState(.locked)
            }
            
            State(.locked, superState: resetable, onEntry: [lock]) {
                Event(.pass) {
                    If(EnforcementStyle.weak)   | NextState(.locked)
                    If(EnforcementStyle.strong) | NextState(.alarming)
                }
                
                Event(.coin) | NextState(.unlocked)
            }
            
            State(.unlocked, superState: resetable, onEntry: [unlock]) {
                NextState(.unlocked) {
                    If(RewardStyle.rewarding) | Event(.coin) | thankyou
                    If(RewardStyle.punishing) | Event(.coin) | idiot
                }
                
                Event(.pass) | NextState(.locked)
            }
            
            State(.alarming, superState: resetable, onEntry: [alarmOn], onExit: [alarmOff])
        }
        
        assertTable()
    }
    
    func testActionsBlockTurnstile() throws {
        try fsm.buildTable {
            let resetable = SuperState {
                when(.reset) | then(.locked)
            }
            
            define(.locked, superState: resetable, onEntry: [lock]) {
                when(.pass) {
                    matching(EnforcementStyle.weak)   | then(.locked)
                    matching(EnforcementStyle.strong) | then(.alarming)
                }
                
                when(.coin) | then(.unlocked)
            }
            
            define(.unlocked, superState: resetable, onEntry: [unlock]) {
                then(.unlocked) {
                    actions(thankyou) {
                        matching(RewardStyle.rewarding) | when(.coin)
                    }
                    
                    actions(idiot) {
                        matching(RewardStyle.punishing) | when(.coin)
                    }
                }
                
                when(.pass) | then(.locked)
            }
            
            define(.alarming, superState: resetable, onEntry: [alarmOn], onExit: [alarmOff])
        }
        
        assertTable()
    }
}

final class FSMIntegrationTests_NestedBlocks: FSMIntegrationTests {
    func testMultiplePredicateBlocks() throws {
        try fsm.buildTable {
            define(.locked) {
                matching(P.a, or: P.b) {
                    matching(Q.a) {
                        matching(R.a, and: S.a) {
                            matching(T.a, and: U.a) {
                                matching(V.a) | when(.coin) | then() | thankyou
                            }
                        }
                    }
                }
            }
        }
        
        fsm.handleEvent(.coin, predicates: P.a, Q.a, R.a, S.a, T.a, U.a, V.a)
        XCTAssertEqual(["thankyou"], actions)
        
        fsm.handleEvent(.coin, predicates: P.b, Q.a, R.a, S.a, T.a, U.a, V.a)
        XCTAssertEqual(["thankyou", "thankyou"], actions)
        
        actions = []
        fsm.handleEvent(.coin, predicates: P.c, Q.a, R.a, S.a, T.a, U.a, V.a)
        XCTAssertEqual([], actions)
    }
    
    func testMultiplActionsBlocks() throws {
        try fsm.buildTable {
            define(.locked) {
                actions(thankyou) {
                    actions(lock) {
                        matching(P.a) | when(.coin) | then(.locked) | unlock
                    }
                }
            }
        }
        
        fsm.handleEvent(.coin, predicates: P.a)
        XCTAssertEqual(["thankyou", "lock", "unlock"], actions)
    }
}

final class FSMIntegrationTests_Errors: FSMIntegrationTests {
    func assertEmptyError(_ e: EmptyBuilderError?,
                     expectedCaller: String,
                     expectedLine: Int,
                     line: UInt = #line
    ) {
        XCTAssertEqual(expectedCaller, e?.caller, line: line)
        XCTAssertEqual("file", e?.file, line: line)
        XCTAssertEqual(expectedLine, e?.line, line: line)
    }
    
    func testEmptyBlockThrowsError() {
        XCTAssertThrowsError (
            try fsm.buildTable {
                define(.locked, file: "file", line: -1 ) { }
            }
        ) {
            let errors = ($0 as? CompoundError)?.errors
            XCTAssertEqual(1, errors?.count)
            let error = errors?.first as? EmptyBuilderError
            
            assertEmptyError(error, expectedCaller: "define", expectedLine: -1)
        }
    }
    
    func testEmptyBlocksThrowErrors() {
        XCTAssertThrowsError (
            try fsm.buildTable {
                define(.locked) {
                    matching(P.a, file: "file", line: -1) {}
                    then(.locked, file: "file", line: -2) {}
                    when(.pass,   file: "file", line: -3) {}
                }
            }
        ) {
            let errors = ($0 as? CompoundError)?.errors
            XCTAssertEqual(3, errors?.count)
            
            let e1 = errors?(0) as? EmptyBuilderError
            assertEmptyError(e1, expectedCaller: "matching", expectedLine: -1)
            
            let e2 = errors?(1) as? EmptyBuilderError
            assertEmptyError(e2, expectedCaller: "then", expectedLine: -2)
            
            let e3 = errors?(2) as? EmptyBuilderError
            assertEmptyError(e3, expectedCaller: "when", expectedLine: -3)
        }
    }
    
    func testDuplicatesAndClashesThrowErrors() {
        typealias DE = SemanticValidationNode.DuplicatesError
        typealias CE = SemanticValidationNode.ClashError
        
        XCTAssertThrowsError (
            try fsm.buildTable {
                define(.locked) {
                    matching(P.a) | when(.coin) | then(.unlocked)
                    matching(P.a) | when(.coin) | then(.unlocked)
                    matching(P.a) | when(.coin) | then(.locked)
                }
            }
        ) {
            let errors = ($0 as? CompoundError)?.errors
            XCTAssertEqual(2, errors?.count)
            
            let e1 = errors?.compactMap { $0 as? DE }.first?.duplicates.values
            let e2 = errors?.compactMap { $0 as? CE }.first?.clashes.values

            XCTAssertEqual(1, e1?.count)
            XCTAssertEqual(1, e2?.count)
            
            let duplicates = e1?.first ?? []
            let clashes = e2?.first ?? []
            
            XCTAssertEqual(2, duplicates.count)
            XCTAssertEqual(2, clashes.count)
            
            XCTAssert(
                duplicates.allSatisfy {
                    $0.match == Match(all: P.a) &&
                    $0.state.base == AnyHashable(StateType.locked) &&
                    $0.event.base == AnyHashable(EventType.coin) &&
                    $0.nextState.base == AnyHashable(StateType.unlocked)
                }, "\(duplicates)"
            )
            
            XCTAssert(
                clashes.allSatisfy {
                    $0.match == Match(all: P.a) &&
                    $0.state.base == AnyHashable(StateType.locked) &&
                    $0.event.base == AnyHashable(EventType.coin)
                }, "\(clashes)"
            )
            
            XCTAssert(clashes.contains { $0.nextState.base == AnyHashable(StateType.locked) })
            XCTAssert(clashes.contains { $0.nextState.base == AnyHashable(StateType.unlocked) })
        }
    }
    
    func testImplicitMatchClashesThrowErrors() {
        XCTAssertThrowsError (
            try fsm.buildTable {
                define(.locked) {
                    #warning("this file and line data is thrown away...")
                    matching(P.a, file: "f1", line: -1)  | when(.coin) | then(.unlocked)
                    matching(Q.a, file: "f2", line: -2)  | when(.coin) | then(.locked)
                }
            }
        ) {
            let errors = ($0 as? CompoundError)?.errors
            XCTAssertEqual(1, errors?.count)
            
            let error = errors?.first as? MatchResolvingNode.ImplicitClashesError
            let clashes = error?.clashes.values
            XCTAssertEqual(1, clashes?.count)
            
            let clash = clashes?.first
            XCTAssertEqual(2, clash?.count)
            
            XCTAssert(clash?.allSatisfy {
                $0.state.base == AnyHashable(StateType.locked) &&
                $0.event.base == AnyHashable(EventType.coin) &&
                $0.predicates == Set([P.a, Q.a].erased())
            } ?? false)
            
            XCTAssertEqual(AnyHashable(StateType.unlocked), clash?.first?.nextState.base)
            XCTAssertEqual(AnyHashable(StateType.locked), clash?.last?.nextState.base)
        }
    }
    
    func testMatchesThrowErrors() {
        XCTAssertThrowsError (
            try fsm.buildTable {
                define(.locked) {
                    matching(P.a, or: P.a, file: "f1", line: -1)  | when(.coin) | then(.unlocked)
                    matching(P.a, and: P.a, file: "f2", line: -2) | when(.coin) | then(.locked)
                }
            }
        ) {
            func assertError(
                _ e: MatchError?,
                expectedFile: String,
                expectedLine: Int,
                line: UInt = #line
            ) {
                XCTAssertEqual([expectedFile], e?.files, line: line)
                XCTAssertEqual([expectedLine], e?.lines, line: line)
                XCTAssert(e?.description.contains("P.a, P.a") ?? false, line: line)
            }
            
            let errors = ($0 as? CompoundError)?.errors
            XCTAssertEqual(2, errors?.count)
            
            assertError(errors?.first as? MatchError, expectedFile: "f1", expectedLine: -1)
            assertError(errors?.last as? MatchError, expectedFile: "f2", expectedLine: -2)
        }
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
