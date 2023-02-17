import XCTest
@testable import SwiftFSM

class FSMTests: TestingBase {
    let fsm = FSM<State, Event>(initialState: .unlocked)
    
    func buildTransitions(
        @TableBuilder<State, Event> _ tableRows: () -> [TableRow<State, Event>]
    ) {
        try? fsm.buildTransitions(tableRows)
    }
}

class FSMBuilderTests: FSMTests, TransitionBuilder {
    var actions = [String]()
    
    func alarmOn()  { actions.append("alarmOn")  }
    func alarmOff() { actions.append("alarmOff") }
    func lock()     { actions.append("lock")     }
    func unlock()   { actions.append("unlock")   }
    func thankyou() { actions.append("thankyou") }
        
    override func setUp() {
        s = SuperState {
            when(.reset) | then(.locked) | [alarmOff, lock]
        }
    }
    
    func testSuperState() {
        buildTransitions {
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
        buildTransitions {
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
        buildTransitions {
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
        buildTransitions {
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
        
        buildTransitions {
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
        
        buildTransitions {
            define(.locked) {
                when(.coin) | then(.locked)
            }
        }
        
        XCTAssertEqual(fsm.firstTransition?.file, file)
        XCTAssertEqual(fsm.firstTransition?.line, line)
    }
    
    func testThrowsErrorWhenGivenDuplicates() {
        let file = URL(string: #file)!.lastPathComponent
        let l1 = #line + 7
        let l2 = #line + 7
        let l3 = #line + 7
        let l4 = #line + 7
        
        XCTAssertThrowsError (try fsm.buildTransitions {
            define(.alarming) {
                when(.coin) | then(.locked)
                when(.coin) | then(.locked)
                when(.coin) | then(.unlocked)
                when(.coin) | then(.unlocked)
            }
        }) {
            let e = $0 as! DuplicateTransitions<State, Event>
            XCTAssertEqual(e.description
                .split(separator: "\n")
                .suffix(4)
                .joined(separator: "\n"),
"""
alarming | coin | *locked* (\(file): \(l1))
alarming | coin | *locked* (\(file): \(l2))
alarming | coin | *unlocked* (\(file): \(l3))
alarming | coin | *unlocked* (\(file): \(l4))
"""
            )
        }
    }
    
    func buildTurnstile() {
        fsm.state = .locked
        
        buildTransitions {
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
    
    func testTurnstile() {
        var actual = [String]()
        func assertEventAction(
            _ e: Event,
            _ a: String...,
            line: UInt = #line
        ) {
            actual += a
            fsm.handleEvent(e)
            XCTAssertEqual(actions, actual, line: line)
        }
        
        buildTurnstile()
        
        assertEventAction(.coin,  "unlock")
        assertEventAction(.pass,  "lock")
        assertEventAction(.pass,  "alarmOn")
#warning("variadics seem to mess with highlighting, should allow arrays everywhere")
        assertEventAction(.reset, "alarmOff", "lock")
        assertEventAction(.coin,  "unlock")
        assertEventAction(.coin,  "thankyou")
        assertEventAction(.coin,  "thankyou")
        assertEventAction(.reset, "lock")
    }
}

class FSMPerformanceTests: FSMTests, TransitionBuilder {
    func compareTime(
        repeats: Int,
        times: Int,
        maxRatio: Int,
        b1: @escaping @autoclosure () -> (),
        b2: @escaping @autoclosure () -> (),
        line: UInt = #line
    ) {
        let first = measureTime(repeats: repeats) {
            times.times { b1() }
        }
        
        let second = measureTime(repeats: repeats) {
            times.times { b2() }
        }
        
        let multiplier = first / second
        let message = "first: \(first),"
        + " second: \(second),"
        + " multiplier: \(multiplier)"
        
        print(message)
        XCTAssertLessThan(first, second * Double(maxRatio), message, line: line)
    }
    
    func measureTime(
        repeats: Int,
        _ block: @escaping () -> Void
    ) -> TimeInterval {
        var total: TimeInterval = 0
        
        repeats.times {
            let started = Date()
            block()
            let finished = Date()
            total += finished.timeIntervalSince(started)
        }
        
        return total / Double(repeats)
    }
    
    func testPerformance() throws {
        var callCount = 0
        func pass() {
            callCount += 1
        }
        
        class SwitchFSM: FSM<State, Event> {
            let pass: () -> ()
            
            init(pass: @escaping () -> ()) {
                self.pass = pass
                super.init(initialState: .unlocked)
            }
            
            override func handleEvent(_ event: FSMPerformanceTests.Event) {
                switch event { case .reset: pass(); default: { }() }
            }
        }
        
        let switcher = SwitchFSM(pass: pass)
        let transitions = define(.unlocked) {
            when(.reset) | then() | pass
        }
        
        try? switcher.buildTransitions { transitions }
        try? fsm.buildTransitions { transitions }
        
        let repeats = 10
        let times = 15000
        
        compareTime(repeats: repeats,
                    times: times,
                    maxRatio: 10,
                    b1: self.fsm.handleEvent(.reset),
                    b2: switcher.handleEvent(.reset))
        
        XCTAssertEqual(repeats * times * 2, callCount)
    }
}

protocol TestingSP: SP { init() }
protocol TestingEP: EP { init() }

extension NSObject: TestingSP { }
extension NSObject: TestingEP { }
extension String:   TestingSP { }
extension String:   TestingEP { }

class NSObjectTestBase<S: TestingSP, E: TestingEP>: XCTestCase, TransitionBuilder {
    typealias State = S
    typealias Event = E
    
    func test() {
        let fsm = FSM<State, Event>(initialState: State())
        
        XCTAssertThrowsError(
            try fsm.buildTransitions {
                define(State()) {
                    when(Event()) | then(State())
                }
            }
        ) { XCTAssertTrue($0 is NSObjectError) }
    }
}

struct NSState: TestingSP { let s = NSObject() }
struct NSEvent: TestingEP { let e = NSObject() }

class FSMRejectsNSObjectStates: NSObjectTestBase<NSObject, String> { }
class FSMRejectsNSObjectEvents: NSObjectTestBase<String, NSObject> { }

class FSMRejectsStatesHoldingNSObject: NSObjectTestBase<NSState, String> { }
class FSMRejectsEventsHoldingNSObject: NSObjectTestBase<String, NSEvent> { }

extension Int {
    func times(_ block: @escaping () -> ()) {
        for _ in 1...self { block() }
    }
}

extension FSM<TurnstileState, TurnstileEvent> {
    var firstTransition: Transition<TurnstileState, TurnstileEvent>? {
        transitionTable.values.first
    }
}
