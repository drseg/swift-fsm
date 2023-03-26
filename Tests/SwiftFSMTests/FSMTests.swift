//
//  FSMTests.swift
//
//  Created by Daniel Segall on 03/03/2023.
//

import Foundation
import XCTest
@testable import SwiftFSM

final class FSMTests: XCTestCase, TableBuilder {
    typealias State = Int
    typealias Event = Double
    
    var fsm: FSM<State, Event> = FSM(initialState: 1)
    
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
                Syntax.Define(1) {
                    Syntax.Matching(1) | Syntax.When(1.1) | Syntax.Then(2)
                }
            }
        }
        
        assertThrowsError(TypeClashError.self) {
            try fsm.buildTable {
                Syntax.Define(1) {
                    Syntax.Matching(1.1) | Syntax.When(1.1) | Syntax.Then(2)
                }
            }
        }
    }
    
    func testValidTableDoesNotThrow() {
        XCTAssertNoThrow(
            try fsm.buildTable {
                define(1) { when(1.1) | then(2) }
            }
        )
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
    
    func testHandleEventWithoutPredicate() {
        try? fsm.buildTable {
            define(1) {
                when(1.1) | then(2) | { self.actionsOutput = "pass" }
            }
        }
        
        assertHandleEvent(1.1, state: 2, output: "pass")
        assertHandleEvent(1.2, state: 1, output: "")
    }
    
    func testHandleEventWithSinglePredicate() {
        try? fsm.buildTable {
            define(1) {
                matching(P.a) | when(1.1) | then(2) | { self.actionsOutput = "pass" }
            }
            
            define(1) {
                matching(P.b) | when(1.1) | then(3) | { self.actionsOutput = "pass" }
            }
        }
        
        assertHandleEvent(1.1, predicates: P.a, state: 2, output: "pass")
        assertHandleEvent(1.1, predicates: P.b, state: 3, output: "pass")
    }
    
    func testHandlEventWithMultiplePredicates() {
        func pass() {
            actionsOutput = "pass"
        }
        
        try? fsm.buildTable {
            define(1) {
                matching(any: P.a, Q.a) | when(1.1) | then(2) | pass
            }
            
            define(1) {
                matching(any: P.b, Q.b) | when(1.1) | then(3) | pass
            }
            
            define(1) {
                matching(all: P.b, Q.b) | when(1.1) | then(4) | pass
            }
        }
        
        assertHandleEvent(1.1, predicates: P.a, state: 2, output: "pass")
        assertHandleEvent(1.1, predicates: P.b, state: 3, output: "pass")
        assertHandleEvent(1.1, predicates: Q.a, state: 2, output: "pass")
        assertHandleEvent(1.1, predicates: Q.b, state: 3, output: "pass")
        
        assertHandleEvent(1.1, predicates: P.b, Q.b, state: 4, output: "pass")
    }
}

class FSMIntegrationTests: XCTestCase, TableBuilder {
    typealias State = TurnstileState
    typealias Event = TurnstileEvent
    
    enum TurnstileState: String, CustomStringConvertible {
        case locked, unlocked, alarming
        var description: String { rawValue  }
    }

    enum TurnstileEvent: String, CustomStringConvertible {
        case reset, coin, pass
        var description: String { rawValue }
    }
    
    var actions = [String]()
    
    func alarmOn()  { actions.append("alarmOn")  }
    func alarmOff() { actions.append("alarmOff") }
    func lock()     { actions.append("lock")     }
    func unlock()   { actions.append("unlock")   }
    func thankyou() { actions.append("thankyou") }
    
    let fsm = FSM<State, Event>(initialState: .locked)
    var actual = [String]()
}

final class FSMIntegrationTests_Turnstile: FSMIntegrationTests {
    func testTurnstile() {
        func assertEventAction(_ e: Event, _ a: String, line: UInt = #line) {
            assertEventAction(e, [a], line: line)
        }
        
        func assertEventAction(_ e: Event, _ a: [String], line: UInt = #line) {
            actual += a
            fsm.handleEvent(e)
            XCTAssertEqual(actions, actual, line: line)
        }
                
        try? fsm.buildTable {
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
    func idiot() { actions.append("idiot")    }
    
    enum EnforcementStyle: Predicate {
        case strong, weak
    }
    
    enum RewardStyle: Predicate {
        case punishing, rewarding
    }
    
    func assertEventAction(_ e: Event, _ a: String, line: UInt = #line) {
        assertEventAction(e, [a], line: line)
    }
    
    func assertEventAction(_ e: Event, _ a: [String], line: UInt = #line) {
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
        try? fsm.buildTable {
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
    
    func testDeduplicatedPredicateTurnstile() {
        try? fsm.buildTable {
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
                    matching(RewardStyle.rewarding) | when(.coin) | thankyou
                    matching(RewardStyle.punishing) | when(.coin) | idiot
                }
                
                when(.pass) | then(.locked)
            }
            
            define(.alarming, superState: resetable, onEntry: [alarmOn], onExit: [alarmOff])
        }
        
        assertTable()
    }
    
    func testTypealiasSyntaxTurnstile() {
        typealias D = Syntax.Define<State>
        typealias W = Syntax.When<Event>
        typealias T = Syntax.Then<State>
        typealias M = Syntax.Matching
        typealias SS = SuperState
        
        try? fsm.buildTable {
            let resetable = SS {
                W(.reset) | T(.locked)
            }
            
            D(.locked, superState: resetable, onEntry: [lock]) {
                W(.pass) {
                    M(EnforcementStyle.weak)   | T(.locked)
                    M(EnforcementStyle.strong) | T(.alarming)
                }
                
                W(.coin) | T(.unlocked)
            }
            
            D(.unlocked, superState: resetable, onEntry: [unlock]) {
                T(.unlocked) {
                    M(RewardStyle.rewarding) | W(.coin) | thankyou
                    M(RewardStyle.punishing) | W(.coin) | idiot
                }
                
                W(.pass) | T(.locked)
            }
            
            D(.alarming, superState: resetable, onEntry: [alarmOn], onExit: [alarmOff])
        }
        
        assertTable()
    }
    
    // TODO: add syntax:
    // when() -> MWA with empty match and actions
    // onEntry/onExit: () -> ()... allowing varargs in both functions and classes
    
    func testActionsBlockSyntax() {
        try? fsm.buildTable {
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

final class FSMIntegrationTests_Predicates: FSMIntegrationTests {
    func testMultiplePredicateBlocks() throws {
        try? fsm.buildTable {
            define(.locked) {
                matching(any: P.a, P.b) {
                    matching(Q.a) {
                        matching(all: R.a, S.a) {
                            matching(all: T.a, U.a) {
                                when(.coin) | then(.locked) | thankyou
                            }
                        }
                    }
                }
            }
        }
        
        fsm.handleEvent(.coin, predicates: P.a, Q.a, R.a, S.a, T.a, U.a)
        XCTAssertEqual(["thankyou"], actions)
        
        fsm.handleEvent(.coin, predicates: P.b, Q.a, R.a, S.a, T.a, U.a)
        XCTAssertEqual(["thankyou", "thankyou"], actions)
        
        fsm.handleEvent(.coin, predicates: P.c, Q.a, R.a, S.a, T.a, U.a)
        XCTAssertEqual(["thankyou", "thankyou"], actions)
    }
}

extension Int: Predicate {
    public static var allCases: [Int] { [] }
}

extension Double: Predicate {
    public static var allCases: [Double] { [] }
}
