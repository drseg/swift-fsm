import Foundation
import XCTest
@testable import FiniteStateMachine

enum TurnstileState: String, SP {
    case locked, unlocked, alarming
}

enum TurnstileEvent: String, EP {
    case reset, coin, pass
}

class TestingBase: XCTestCase {
    typealias State = TurnstileState
    typealias Event = TurnstileEvent
    
    func assertContains(
        _ e: Event,
        _ s: State,
        _ ss: SuperState<State, Event>,
        _ line: UInt = #line
    ) {
        XCTAssertTrue(
            ss.wtas.contains(where: {
                $0.state == s && $0.events.contains(e)
            })
            , "\n(\(e), \(s)) not found in: \n\(ss.description)",
            line: line)
    }
    
    func assertContains(
        _ g: State,
        _ w: Event,
        _ t: State,
        _ tr: TableRow<State, Event>,
        _ line: UInt = #line
    ) {
        XCTAssertTrue(
            tr.transitions.contains(
                Transition(g: g,
                           w: w,
                           t: t,
                           a: [],
                           p: [],
                           f: "",
                           l: 0)
            )
            , "\n(\(g), \(w), \(t)) not found in: \n\(tr.description)",
            line: line)
    }
    
    var s: SuperState<State, Event>!
}

class TransitionBuilderTests: TestingBase, TransitionBuilder {
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
    
    func testDefaultThen() {
        let tr = define(.locked) {
            when(.reset) | ()
            when(.pass)  | () | {}
        }
        
        assertContains(.locked, .reset, .locked, tr)
        assertContains(.locked, .pass, .locked, tr)
    }
    
    func testActions() {
        let e = expectation(description: "action")
        e.expectedFulfillmentCount = 3
        let tr = define(.locked) {
            when(.reset) | then(.unlocked) | e.fulfill
            when(.reset) | then(.unlocked) | [e.fulfill]
            when(.reset) | then(.unlocked) | [{ }, e.fulfill]
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
                when(.coin)  | then(.unlocked)
                when(.reset) | ()
            }

            context(action: e.fulfill) {
                when(.pass)  | then(.locked)
            }
        }

        assertContains(.locked, .coin, .unlocked, tr)
        assertContains(.locked, .reset, .locked, tr)
        assertContains(.locked, .pass, .locked, tr)

        tr.transitions.first?.actions.first?()
        tr.transitions.first?.actions.last?()
        tr.transitions.last?.actions.last?()
        waitForExpectations(timeout: 0.1)
    }
        
    func testEntryActions() {
        let tr = define(.locked) {
            onEnter({ }, { })
        }
        
        XCTAssertEqual(2, tr.modifiers.entryActions.count)
    }
    
    func testExitActions() {
        let tr = define(.locked) {
            onExit({}, {})
        }
        
        XCTAssertEqual(2, tr.modifiers.exitActions.count)
    }
    
    func testAllModifiers() {
        let tr = define(.locked) {
            implements(s); onEnter({ }, { }); onExit({ }, { })
        }
        
        let trs = tr.modifiers.superStates.first!
        assertContains(.reset, .unlocked, trs)
        assertContains(.coin, .unlocked, trs)
        assertContains(.pass, .locked, trs)
        
        XCTAssertEqual(2, tr.modifiers.entryActions.count)
        XCTAssertEqual(2, tr.modifiers.exitActions.count)
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

extension WhensThenActionsPredicates<TurnstileState, TurnstileEvent> {
    var description: String {
        events.reduce("") {
            $0 + String("(\($1.rawValue), \(state?.rawValue))\n")
        }
    }
}

extension Transition<TurnstileState, TurnstileEvent> {
    var description: String {
        String("(\(givenState.rawValue), \(event.rawValue), \(nextState.rawValue))\n")
    }
}
