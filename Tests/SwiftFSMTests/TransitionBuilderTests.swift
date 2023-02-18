import Foundation
import XCTest
@testable import SwiftFSM

enum TurnstileState: String, SP {
    case locked, unlocked, alarming
}

enum TurnstileEvent: String, EP {
    case reset, coin, pass
}

class TestingBase: XCTestCase {
    typealias State = TurnstileState
    typealias Event = TurnstileEvent
        
    var s: SuperState<State, Event>!
}

class TransitionBuilderTests: TestingBase, TransitionBuilder {
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
            file: file,
            line: line)
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
            tr.wtaps.contains(
                WTAP(events: [w],
                     state: t,
                     actions: [],
                     match: .none,
                     file: #file,
                     line: #line)
            ) && tr.givenStates.contains(g)
            , "\n(\(w), \(t)) not found in: \n\(tr.description)",
            file: file,
            line: line)
    }
#warning("poor failure output and && is hopeless")
    
    func assertContains(
        _ g: State,
        _ w: [Event],
        _ t: State,
        _ tr: TableRow<State, Event>,
        _ file: StaticString = #file,
        _ line: UInt = #line
    ) {
        XCTAssertTrue(
            tr.wtaps.contains(
                WTAP(events: w,
                     state: t,
                     actions: [],
                     match: .none,
                     file: #file,
                     line: #line)
            ) && tr.givenStates.contains(g)
            , "\n(\(g), \(w), \(t)) not found in: \n\(tr.description)",
            file: file,
            line: line)
    }
#warning("poor failure output and && is hopeless")
    
    override func setUp() {
        s = SuperState {
            when(.reset) | then(.unlocked) | []
            when(.coin)  | then(.unlocked) | {}
            when(.pass)  | then(.locked)
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
        
        assertContains(.locked, [.reset, .coin], .unlocked, tr)
    }
    
    func testDefaultThen() {
        let tr = define(.locked) {
            when(.reset) | then()
            when(.pass)  | then() | {}
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
        
        tr[0].actions[0]()
        tr[1].actions[0]()
        tr[2].actions[1]()
        
        waitForExpectations(timeout: 0.1)
    }
    
    func testActionBlock() {
        let e = expectation(description: "action")
        e.expectedFulfillmentCount = 4
        
        let tr = define(.locked) {
            actions(e.fulfill, e.fulfill) {
                when(.coin)  | then(.unlocked)
            }

            action(e.fulfill) {
                when(.pass)  | then(.locked) | e.fulfill
            }
        }

        assertContains(.locked, .coin, .unlocked, tr)
        assertContains(.locked, .pass, .locked, tr)

        tr.wtaps.first?.actions.first?()
        tr.wtaps.first?.actions.last?()
        tr.wtaps.last?.actions.first?()
        tr.wtaps.last?.actions.last?()
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
        wtaps.map(\.description).reduce("", +)
    }
}

extension SuperState<TurnstileState, TurnstileEvent> {
    var description: String {
        wtas.map(\.description).reduce("", +)
    }
}

extension WTAP<TurnstileState, TurnstileEvent> {
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
