//
//  TransitionBuilderProtocolTests.swift
//  FiniteStateMachineTests
//
//  Created by Daniel Segall on 12/02/2023.
//

import XCTest
@testable import FiniteStateMachine

enum TurnstileState: String, SP {
    case locked, unlocked, alarming
}

enum TurnstileEvent: String, EP {
    case reset, coin, pass
}

class TransitionBuilderTests: XCTestCase, TransitionBuilder {
    typealias State = TurnstileState
    typealias Event = TurnstileEvent
    
    func assertContains(
        _ e: Event,
        _ s: State,
        _ ss: SuperState<State, Event>,
        _ file: StaticString = #file,
        _ line: UInt = #line
    ) {
        XCTAssertTrue(
            ss.wtas.contains(where: {
                $0.state == s && $0.events.contains(e)
            })
            , "\n(\(e), \(s)) not found in: \n\(ss.description)",
            file: file, line: line)
    }
    
    func assertContains(
        _ g: State,
        _ w: Event,
        _ t: State,
        _ tr: TableRow<State, Event>,
        _ file: StaticString = #file,
        _ line: UInt = #line
    ) {
        XCTAssertTrue(
            tr.transitions.contains(
                Transition(givenState: g,
                           event: w,
                           nextState: t,
                           actions: [],
                           file: "",
                           line: 0)
            )
            , "\n(\(g), \(w), \(t)) not found in: \n\(tr.description)",
            file: file, line: line)
    }
    
    var s: SuperState<State, Event>!
    
    override func setUp() {
        s = SuperState {
            when(.reset) | then(.unlocked) | []
            when(.coin) | then(.unlocked) | {}
            when(.pass) | then(.locked)
        }
    }
        
    func testSuperState() {
        assertContains(.reset, .unlocked, s)
        assertContains(.coin, .unlocked, s)
        assertContains(.pass, .locked, s)
    }
    
    func testImplements() {
        let tr = define(.locked) {
            implements(s)
        }
        
        let trs = tr.modifiers.superStates.first!
        assertContains(.reset, .unlocked, trs)
        assertContains(.coin, .unlocked, trs)
        assertContains(.pass, .locked, trs)
    }
    
    func testDoubleImplements() {
        let tr = define(.locked) {
            implements(s)
            implements(s, s)
        }
        
        XCTAssertEqual(1, tr.modifiers.superStates.count)
    }
    
    func testSimpleTransitionsWithOperators() {
        let tr = define(.locked, .unlocked) {
            when(.reset) | then(.unlocked) | []
            when(.coin)  | then(.unlocked) | { }
            when(.pass)  | then(.locked)
        }
        
        assertContains(.locked, .reset, .unlocked, tr)
        assertContains(.locked, .coin, .unlocked, tr)
        assertContains(.locked, .pass, .locked, tr)
        
        assertContains(.unlocked, .reset, .unlocked, tr)
        assertContains(.unlocked, .coin, .unlocked, tr)
        assertContains(.unlocked, .pass, .locked, tr)
    }
    
    func testMultipleWhens() {
        let tr = define(.locked) {
            when(.reset, .coin) | then(.unlocked) | []
        }
        
        assertContains(.locked, .reset, .unlocked, tr)
        assertContains(.locked, .coin, .unlocked, tr)
    }
    
    func testActions() {
        let e = expectation(description: "action")
        e.expectedFulfillmentCount = 3
        let tr = define(.locked) {
            when(.reset) | then(.unlocked) | e.fulfill
            when(.reset) | then(.unlocked) | [e.fulfill]
            when(.reset) | then(.unlocked) | [ {}, e.fulfill ]
        }
        
        tr.transitions[0].actions[0]()
        tr.transitions[1].actions[0]()
        tr.transitions[2].actions[1]()
        
        waitForExpectations(timeout: 0.1)
    }
    
    func testActionBlock() {
        let e = expectation(description: "action")
        e.expectedFulfillmentCount = 3
        
        let tr = define(.locked) {
            context(actions: e.fulfill, e.fulfill) {
                when(.coin) | then(.unlocked)
            }

            context(action: e.fulfill) {
                when(.pass) | then(.locked)
            }
        }

        assertContains(.locked, .coin, .unlocked, tr)
        assertContains(.locked, .pass, .locked, tr)

        tr.transitions.first?.actions.first?()
        tr.transitions.first?.actions.last?()
        tr.transitions.last?.actions.last?()
        waitForExpectations(timeout: 0.1)
    }
    
    let twoActions = [{}, {}]
    
    func testEntryActions() {
        let tr = define(.locked) {
            onEnter(twoActions)
        }
        
        XCTAssertEqual(2, tr.modifiers.entryActions.count)
    }
    
    func testExitActions() {
        let tr = define(.locked) {
            onExit(twoActions)
        }
        
        XCTAssertEqual(2, tr.modifiers.exitActions.count)
    }
    
    func testAllModifiers() {
        let tr = define(.locked) {
            implements(s); onEnter(twoActions); onExit(twoActions)
        }
        
        let trs = tr.modifiers.superStates.first!
        assertContains(.reset, .unlocked, trs)
        assertContains(.coin, .unlocked, trs)
        assertContains(.pass, .locked, trs)
        
        XCTAssertEqual(2, tr.modifiers.entryActions.count)
        XCTAssertEqual(2, tr.modifiers.exitActions.count)
    }
}

class FSMBuilderTests: XCTestCase, TransitionBuilder {
    typealias State = TurnstileState
    typealias Event = TurnstileEvent

    var actions = [String]()
    
    func alarmOn()  { actions.append("alarmOn")  }
    func alarmOff() { actions.append("alarmOff") }
    func lock()     { actions.append("lock")     }
    func unlock()   { actions.append("unlock")   }
    func thankyou() { actions.append("thankyou") }
    
    let fsm = FSM<State, Event>(initialState: .unlocked)
    var s: SuperState<State, Event>!
    
    override func setUp() {
        s = SuperState {
            when(.reset) | then(.locked) | [alarmOff, lock]
        }
    }
    
    func testSuperState() {
        try? fsm.buildTransitions {
            define(.unlocked) {
                implements(s)
            }
        }
        
        fsm.handleEvent(.reset)
        fsm.handleEvent(.coin)
        fsm.handleEvent(.coin)
        fsm.handleEvent(.coin)
        XCTAssertEqual(actions, ["alarmOff", "lock"])
        XCTAssertEqual(fsm.state, .locked)
    }
    
    func testEntryAction() {
        try? fsm.buildTransitions {
            define(.locked) {
                onEnter(thankyou)
            }
            
            define(.unlocked) {
                when(.reset) | then(.locked) | [alarmOff, lock]
            }
        }
        
        fsm.handleEvent(.reset)
        XCTAssertEqual(actions.last, "thankyou")
    }
    
    func testEntryActionNotCalledIfAlreadyInState() {
        try? fsm.buildTransitions {
            define(.unlocked) {
                onEnter(thankyou)
                
                when(.reset) | then(.unlocked) | [alarmOff, lock]
            }
        }
        
        fsm.handleEvent(.reset)
        XCTAssertEqual(actions,  ["alarmOff", "lock"])
    }
    
    func testExitAction() {
        try? fsm.buildTransitions {
            define(.unlocked) {
                onExit(thankyou)
                
                when(.reset) | then(.locked) | [alarmOff, lock]
            }
        }
        
        fsm.handleEvent(.reset)
        XCTAssertEqual(actions.last, "thankyou")
    }
    
    func testExitActionNotCalledIfRemainingInState() {
        try? fsm.buildTransitions {
            define(.unlocked) {
                onExit(thankyou)
                
                when(.reset) | then(.unlocked) | [alarmOff, lock]
            }
        }
        
        fsm.handleEvent(.reset)
        XCTAssertEqual(actions, ["alarmOff", "lock"])
    }
    
    func testSuperStateFileLine() {
        let file = #file
        let line = #line + 4
        
        try? fsm.buildTransitions {
            let s = SuperState {
                when(.coin) | then(.locked)
            }
            
            define(.locked) {
                implements(s)
            }
        }
        
        XCTAssertEqual(fsm.firstTransition?.file, file)
        XCTAssertEqual(fsm.firstTransition?.line, line)
    }
    
    func testTransitionFileLine() {
        let file = #file
        let line = #line + 4
        
        try? fsm.buildTransitions {
            define(.locked) {
                when(.coin) | then(.locked)
            }
        }
        
        XCTAssertEqual(fsm.firstTransition?.file, file)
        XCTAssertEqual(fsm.firstTransition?.line, line)
    }
    
    func buildTurnstile() {
        fsm.state = .locked
        
        try? fsm.buildTransitions {
            let resetable = SuperState {
                when(.reset) | then(.locked)
            }

            define(.locked) {
                implements(resetable); onEnter(lock)
                
                when(.coin) | then(.unlocked)
                when(.pass) | then(.alarming)
            }

            define(.unlocked) {
                implements(resetable); onEnter(unlock)
                
                when(.coin) | then(.unlocked) | thankyou
                when(.pass) | then(.locked)
            }

            define(.alarming) {
                implements(resetable); onEnter(alarmOn); onExit(alarmOff)
            }
        }
    }
    
    func assertEventActions(_ eas: (Event, [String])..., line: UInt = #line) {
        var actual = [String]()
        eas.forEach {
            actual += $0.1
            fsm.handleEvent($0.0)
            XCTAssertEqual(actions, actual, line: line)
        }
    }
    
    var actual = [String]()
    func assertEventAction(_ e: Event, _ a: String..., line: UInt = #line) {
        actual += a
        fsm.handleEvent(e)
        XCTAssertEqual(actions, actual, line: line)
    }
    
    func testTurnstile() {
        buildTurnstile()
        
        assertEventAction(.coin,  "unlock")
        assertEventAction(.pass,  "lock")
        assertEventAction(.pass,  "alarmOn")
        assertEventAction(.reset, "alarmOff", "lock")
        assertEventAction(.coin,  "unlock")
        assertEventAction(.coin,  "thankyou")
        assertEventAction(.coin,  "thankyou")
        assertEventAction(.reset, "lock")
    }
}

extension TableRow<TurnstileState, TurnstileEvent> {
    var description: String {
        transitions.map(\.description).reduce("", +)
    }
}

extension SuperState<TurnstileState, TurnstileEvent> {
    var description: String {
        wtas.map(\.description).reduce("", +)
    }
}

extension WhensThenActions<TurnstileState, TurnstileEvent> {
    var description: String {
        events.reduce("") {
            $0 + String("(\($1.rawValue), \(state.rawValue))\n")
        }
    }
}

extension Transition<TurnstileState, TurnstileEvent> {
    var description: String {
        String("(\(givenState.rawValue), \(event.rawValue), \(nextState.rawValue))\n")
    }
}

extension FSM<TurnstileState, TurnstileEvent> {
    var firstTransition: Transition<TurnstileState, TurnstileEvent>? {
        transitionTable.values.first
    }
}
