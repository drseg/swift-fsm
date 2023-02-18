import Foundation
import XCTest
@testable import SwiftFSM

enum TurnstileState: String, SP, CustomStringConvertible {
    case locked, unlocked, alarming
    
    var description: String {
        rawValue
    }
}

enum TurnstileEvent: String, EP, CustomStringConvertible {
    case reset, coin, pass
    
    var description: String {
        rawValue
    }
}

class TestingBase: XCTestCase {
    typealias State = TurnstileState
    typealias Event = TurnstileEvent
        
    var s: SuperState<State, Event>!
    
    typealias TR = TableRow<State, Event>
    
    func assertFileAndLine(
        _ l: Int,
        forEvent e: Event,
        in ss: SuperState<State, Event>,
        file f: String = #file,
        errorFile ef: StaticString = #file,
        errorLine el: UInt = #line
    ) {
        assertFileAndLine(f, l, [e], ss.wtams, errorFile: ef, errorLine: el)
    }
    
    func assertFileAndLine(
        _ l: Int,
        forEvent e: Event,
        in tr: TR,
        file f: String = #file,
        errorFile ef: StaticString = #file,
        errorLine el: UInt = #line
    ) {
        assertFileAndLine(f, l, [e], tr.wtams, errorFile: ef, errorLine: el)
    }
    
    func assertFileAndLine(
        _ l: Int,
        forEvents e: [Event],
        in tr: TR,
        file f: String = #file,
        errorFile ef: StaticString = #file,
        errorLine el: UInt = #line
    ) {
        assertFileAndLine(f, l, e, tr.wtams, errorFile: ef, errorLine: el)
    }
    
    func assertFileAndLine(
        _ expectedFile: String = #file,
        _ expectedLine: Int,
        _ events: [Event],
        _ wtams: [WTAM<State, Event>],
        errorFile: StaticString = #file,
        errorLine: UInt = #line
    ) {
        XCTAssertEqual(
            wtams.first { $0.events == events }?.line ?? -1, expectedLine,
            file: errorFile,
            line: errorLine
        )
        
        XCTAssertEqual(
            wtams.first { $0.events == events }?.file ?? "nil", expectedFile,
            file: errorFile,
            line: errorLine
        )
    }
}

class TransitionBuilderTests: TestingBase, TransitionBuilder {
    func assertContains(
        _ e: Event,
        _ s: State,
        _ ss: SuperState<State, Event>,
        _ line: UInt = #line
    ) {
        assertContains([e], s, ss, line)
    }
    
    func assertContains(
        _ e: [Event],
        _ s: State,
        _ ss: SuperState<State, Event>,
        _ line: UInt = #line
    ) {
        XCTAssertTrue(
            ss.wtams.contains(where: {
                $0.state == s && $0.events == e
            })
            , "\n(\(e), \(s)) \nnot found in: \n\(ss.description)",
            line: line)
    }
    
    func assertContains(
        _ g: State,
        _ w: Event,
        _ t: State,
        _ tr: TR,
        _ line: UInt = #line
    ) {
        assertContains(g, [w], t, tr, line)
    }
    
    func assertContains(
        _ g: State,
        _ w: [Event],
        _ t: State,
        _ tr: TR,
        _ line: UInt = #line
    ) {
        XCTAssertTrue(
            tr.wtams.contains(
                WTAM(events: w,
                     state: t,
                     actions: [],
                     match: .none,
                     file: #file,
                     line: #line)
            ),
            "\n(\(w), \(t)), \nnot found in: \n\(tr.matchlessDescription)",
            line: line)
        
        XCTAssertTrue(tr.givenStates.contains(g),
                      "\n'\(g)' not found in: \(tr.givenStates)",
                      line: line)
    }
    
    override func setUp() {
        s = SuperState {
            when(.reset, line: 10) | then(.unlocked) | []
            when(.coin)            | then(.unlocked) | {}
            when(.pass)            | then(.locked)
        }
    }
        
    func testSuperState() {
        assertContains(.reset, .unlocked, s)
        assertContains(.coin, .unlocked, s)
        assertContains(.pass, .locked, s)
        
        assertFileAndLine(10, forEvent: .reset, in: s)
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
            when(.reset, line: 10) | then(.unlocked) | []
            when(.coin)            | then(.unlocked) | { }
            when(.pass)            | then(.locked)
        }
        
        assertContains(.locked, .reset, .unlocked, tr)
        assertContains(.locked, .coin, .unlocked, tr)
        assertContains(.locked, .pass, .locked, tr)
        
        assertContains(.unlocked, .reset, .unlocked, tr)
        assertContains(.unlocked, .coin, .unlocked, tr)
        assertContains(.unlocked, .pass, .locked, tr)
        
        assertFileAndLine(10, forEvent: .reset, in: tr)
    }
    
    func testMultipleWhens() {
        let tr = define(.locked) {
            when(.reset, .coin, line: 10) | then(.unlocked) | []
        }
        
        assertContains(.locked, [.reset, .coin], .unlocked, tr)
        assertFileAndLine(10, forEvents: [.reset, .coin], in: tr)
    }
    
    func testDefaultThen() {
        let tr = define(.locked) {
            when(.reset, line: 10) | then()
            when(.pass)            | then() | {}
        }
                
        assertContains(.locked, .reset, .locked, tr)
        assertContains(.locked, .pass, .locked, tr)
        
        assertFileAndLine(10, forEvent: .reset, in: tr)
    }
    
    func testActions() {
        let e = expectation(description: "action")
        e.expectedFulfillmentCount = 3
        let tr = define(.locked) {
            when(.reset, line: 10) | then(.unlocked) | e.fulfill
            when(.reset)           | then(.unlocked) | [e.fulfill]
            when(.reset)           | then(.unlocked) | [{ }, e.fulfill]
        }
        
        tr[0].actions[0]()
        tr[1].actions[0]()
        tr[2].actions[1]()
        
        assertFileAndLine(10, forEvent: .reset, in: tr)
        
        waitForExpectations(timeout: 0.1)
    }
    
    func testActionBlock() {
        let e = expectation(description: "action")
        e.expectedFulfillmentCount = 4
        
        let tr = define(.locked) {
            actions(e.fulfill, e.fulfill) {
                when(.coin, line: 10)  | then(.unlocked)
            }

            action(e.fulfill) {
                when(.pass)            | then(.locked) | e.fulfill
            }
        }

        assertContains(.locked, .coin, .unlocked, tr)
        assertContains(.locked, .pass, .locked, tr)
        
        assertFileAndLine(10, forEvent: .coin, in: tr)

        tr.wtams.first?.actions.first?()
        tr.wtams.first?.actions.last?()
        tr.wtams.last?.actions.first?()
        tr.wtams.last?.actions.last?()
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
        wtams.map(\.description).reduce("", +)
    }
    
    var matchlessDescription: String {
        wtams.map(\.matchlessDescription).reduce("", +)
    }
}

extension SuperState<TurnstileState, TurnstileEvent> {
    var description: String {
        wtams.map(\.description).reduce("", +)
    }
}

extension WTAM<TurnstileState, TurnstileEvent> {
    var description: String {
        "(\(events), \(state?.description ?? "nil"), \(match))\n"
    }
    
    var matchlessDescription: String {
        "(\(events), \(state?.description ?? "nil"))\n"
    }
}

extension Transition<TurnstileState, TurnstileEvent> {
    var description: String {
        String("(\(givenState.rawValue), \(event.rawValue), \(nextState.rawValue))\n")
    }
}
