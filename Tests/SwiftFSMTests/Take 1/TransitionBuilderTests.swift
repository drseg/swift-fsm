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

extension EmptyBlock {
    var withShortFileName: Self {
        .init(file.lastPathComponent, line)
    }
}

class TestingBase: XCTestCase {
    typealias State = TurnstileState
    typealias Event = TurnstileEvent
        
    var s: SuperState<State, Event>!
    
    typealias TR = TableRow<State, Event>
    
    func assertEmptyBlock(
        atLineOffset offset: UInt = 0,
        file: StaticString = #file,
        line: UInt = #line,
        _ er: () -> any ErrorRow
    ) {
        assertEmptyBlock(atLineOffset: offset, file: file, line: line) { [er()] }
    }
    
    func assertEmptyBlock(
        atLineOffset offset: UInt = 0,
        file: StaticString = #file,
        line: UInt = #line,
        _ er: () -> [any ErrorRow]
    ) {
        assertEmptyBlocks(atLineOffsets: [offset], file: file, line: line, er)
    }
    
    func assertEmptyBlocks(
        atLineOffsets offsets: [UInt] = [0],
        file: StaticString = #file,
        line: UInt = #line,
        _ er: () -> any ErrorRow
    ) {
        assertEmptyBlocks(atLineOffsets: offsets, file: file, line: line) {
            [er()]
        }
    }
    
    func assertEmptyBlocks(
        atLineOffsets offsets: [UInt] = [0],
        file: StaticString = #file,
        line: UInt = #line,
        _ er: () -> [any ErrorRow]
    ) {
        let er = er()
        let errors = er.map(\.errors).flatten
        
        guard errors.count == offsets.count else {
            XCTFail("""
Incorrect number of errors found
Expected: \(offsets.count)
Actual: \(errors.count)

Errors found:
\(errors.map(\.withShortFileName))
""",
                    file: file,
                    line: line
            )
            return
        }
        
        offsets.enumerated().forEach {
            XCTAssertEqual(errors[$0.offset].line,
                           Int(line + $0.element),
                           file: file,
                           line: line + $0.element)
            
            XCTAssertEqual(errors[$0.offset].file,
                           file.description,
                           file: file,
                           line: line + $0.element)
        }
    }
    
    func assertFileAndLine(
        _ l: Int,
        forEvent e: Event,
        in ss: SuperState<State, Event>,
        file f: StaticString = #file,
        errorLine el: UInt = #line
    ) {
        assertFileAndLine(f, l, [e], ss.wtams, errorLine: el)
    }
    
    func assertFileAndLine(
        _ l: Int,
        forEvent e: Event,
        in tr: TR,
        file f: StaticString = #file,
        errorLine el: UInt = #line
    ) {
        assertFileAndLine(f, l, [e], tr.wtams, errorLine: el)
    }
    
    func assertFileAndLine(
        _ l: Int,
        forEvents e: [Event],
        in tr: TR,
        file f: StaticString = #file,
        errorLine el: UInt = #line
    ) {
        assertFileAndLine(f, l, e, tr.wtams, errorLine: el)
    }
    
    func assertFileAndLine(
        _ expectedFile: StaticString = #file,
        _ expectedLine: Int,
        _ events: [Event],
        _ wtams: [WTAM<State, Event>],
        errorLine: UInt = #line
    ) {
        XCTAssertEqual(
            wtams.first { $0.events == events }?.line ?? -1, expectedLine,
            file: expectedFile,
            line: errorLine
        )
        
        let unexpectedFiles = wtams
            .filter { $0.file != expectedFile.description }
            .map(\.file.lastPathComponent)
            .joined(by: "\n")
        
        let actualFiles = wtams
            .map(\.file.lastPathComponent)
            .joined(by: "\n")
        
        XCTAssertTrue(
            wtams.allSatisfy { $0.file == expectedFile.description },
            "Unexpected files:\n\(unexpectedFiles)\nFound in:\n(\(actualFiles)",
            file: expectedFile,
            line: errorLine
        )
    }
#warning("tests that use this do not test the default line impl")
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
    
    func testEmptyBlockDescription() {
        let error = EmptyBlock("cat://cat/Cat.cat", 1)
        let expected = "Empty context block found at Cat.cat: 1"
        XCTAssertEqual(expected, error.localizedDescription)
    }
    
    func testEmptyDefineBlock() {
        assertEmptyBlock { define(.unlocked) { } }
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
    
    func testWhenDefaultFileAndLine() {
        let l1 = #line; let w1 = when(.coin)
        let l2 = #line; let w2 = when([.coin])
        
        XCTAssertEqual(w1.file, #file)
        XCTAssertEqual(w2.file, #file)
        
        XCTAssertEqual(w1.line, l1)
        XCTAssertEqual(w2.line, l2)
    }
    
    func testWhenOverloadsProduceIdenticalResults() {
        XCTAssertEqual(when([.pass]), when(.pass))
        XCTAssertEqual(when([.pass, .coin]), when(.pass, .coin))
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
    
    func testEmptyActionsBlock() {
        assertEmptyBlock { action({ }) { }    }
        assertEmptyBlock { actions({ }) { }   }
        assertEmptyBlock { actions([{ }]) { } }
        
        assertEmptyBlock(atLineOffset: 2) {
            define(.unlocked) {
                action({ }) { }
            }
        }
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
        var output = ""
        
        let tr = define(.locked) {
            actions([{ output += "1" }, { output += "2" }]) {
                when(.coin, line: 10)  | then(.unlocked)
            }
            
            actions({ output += "3" }, { output += "4" }) {
                when(.coin, line: 10)  | then(.unlocked)
            }

            action({ output += "5" }) {
                when(.pass, line: 20)  | then(.locked) | { output += "6" }
            }
        }

        assertContains(.locked, .coin, .unlocked, tr)
        assertContains(.locked, .pass, .locked, tr)
        
        assertFileAndLine(10, forEvent: .coin, in: tr)
        assertFileAndLine(20, forEvent: .pass, in: tr)
        
        tr.wtams.map(\.actions).flatten.executeAll()
        
        XCTAssertEqual(output, "123456")
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
        String("(\(givenState), \(event), \(nextState))\n")
    }
}
