import Foundation
import XCTest
@testable import SwiftFSM

class SyntaxTestsBase: XCTestCase, ExpandedSyntaxBuilder, @unchecked Sendable {
    static let defaultOutput = "pass"
    static let defaultOutputWithEvent = "\(SyntaxTestsBase.defaultOutput), event: \(SyntaxTestsBase.defaultEvent)"
    static let defaultEvent = 111

    typealias State = Int
    typealias Event = Int
    
    typealias Define = Internal.Define<State, Event>
    typealias Matching = Internal.Matching<State, Event>
    typealias Condition = Internal.Condition<State, Event>
    typealias When = Internal.When<State, Event>
    typealias Then = Internal.Then<State, Event>
    typealias Actions = Internal.Actions
    typealias Override = Internal.Override
    
    typealias MatchingWhenThen = Internal.MatchingWhenThen
    typealias MatchingWhen = Internal.MatchingWhen
    
    typealias AnyNode = any Node
    
    var output = ""
    
    func pass() { output += Self.defaultOutput }
    func passAsync() async { pass() }
    func passWithEvent(_ event: Event) {
        output += Self.defaultOutput + ", event: " + String(event)
    }
    func passWithEventAsync(_ event: Event) async {
        passWithEvent(event)
    }
    
    func assertMatching(
        _ m: Matching,
        any: any Predicate...,
        all: any Predicate...,
        sutFile sf: String = #file,
        xctFile xf: StaticString = #filePath,
        sutLine sl: Int = #line,
        xctLine xl: UInt = #line
    ) async {
        XCTAssertTrue(m.node.rest.isEmpty, file: xf, line: xl)
        await assertMatchNode(m.node,
                              any: [any],
                              all: all,
                              sutFile: sf,
                              xctFile: xf,
                              sutLine: sl,
                              xctLine: xl)
    }
    
    func assertCondition(
        _ c: Condition,
        expected: Bool,
        sutFile sf: String = #file,
        xctFile xf: StaticString = #filePath,
        sutLine sl: Int = #line,
        xctLine xl: UInt = #line
    ) async {
        XCTAssertTrue(c.node.rest.isEmpty, file: xf, line: xl)
        let condition = await c.node.descriptor.condition?()
        XCTAssertEqual(expected, condition, file: xf, line: xl)
        await assertMatchNode(c.node,
                              condition: expected,
                              sutFile: sf,
                              xctFile: xf,
                              sutLine: sl,
                              xctLine: xl)
    }
    
    func assertMatchNode(
        _ node: MatchingNodeBase,
        any: [[any Predicate]] = [],
        all: [any Predicate] = [],
        condition: Bool? = nil,
        caller: String = "matching",
        sutFile sf: String = #file,
        xctFile xf: StaticString = #filePath,
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) async {
        let any = any.map { $0.erased() }.filter { !$0.isEmpty }
        let condition = await node.descriptor.condition?()
        
        XCTAssertEqual(any, node.descriptor.matchingAny, file: xf, line: xl)
        XCTAssertEqual(all.erased(), node.descriptor.matchingAll, file: xf, line: xl)
        XCTAssertEqual(condition, condition, file: xf, line: xl)
        XCTAssertEqual(node.descriptor.file, sf, file: xf, line: xl)
        XCTAssertEqual(node.descriptor.line, sl, file: xf, line: xl)
        
        if let node = node as? MatchingBlockNode {
            assertNeverEmptyNode(node,
                                 caller: caller,
                                 sutFile: sf,
                                 xctFile: xf,
                                 sutLine: sl,
                                 xctLine: xl)
        }
    }
    
    func assertWhen(
        _ w: When,
        events: [Int] = [1, 2],
        sutFile sf: String = #file,
        xctFile xf: StaticString = #filePath,
        sutLine sl: Int = #line,
        xctLine xl: UInt = #line
    ) {
        XCTAssertTrue(w.node.rest.isEmpty, file: xf, line: xl)
        assertWhenNode(w.node, events: events, sutFile: sf, xctFile: xf, sutLine: sl, xctLine: xl)
    }

    func assertThen(
        _ t: Then,
        state: Int? = 1,
        sutFile sf: String? = nil,
        xctFile xf: StaticString = #filePath,
        sutLine sl: Int? = #line,
        xctLine xl: UInt = #line
    ) {
        XCTAssertTrue(t.node.rest.isEmpty, file: xf, line: xl)
        assertThenNode(t.node, state: state, sutFile: sf, xctFile: xf, sutLine: sl, xctLine: xl)
    }

    func assertWhenNode(
        _ node: WhenNodeBase,
        events: [Int] = [1, 2],
        sutFile sf: String = #file,
        xctFile xf: StaticString = #filePath,
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) {
        let files = [String](repeating: sf, count: events.count)
        let lines = [Int](repeating: sl, count: events.count)
        
        XCTAssertEqual(events, node.events.map(\.base), file: xf, line: xl)
        XCTAssertEqual(files, node.events.map(\.file), file: xf, line: xl)
        XCTAssertEqual(lines, node.events.map(\.line), file: xf, line: xl)
        
        if let node = node as? any NeverEmptyNode {
            assertNeverEmptyNode(node,
                                 caller: "when",
                                 sutFile: sf,
                                 xctFile: xf,
                                 sutLine: sl,
                                 xctLine: xl)
        }
    }
    
    func assertThenNode(
        _ n: ThenNodeBase,
        state: State?,
        sutFile sf: String? = nil,
        xctFile xf: StaticString = #filePath,
        sutLine sl: Int?,
        xctLine xl: UInt = #line
    ) {
        XCTAssertEqual(state, n.state?.base as? State, file: xf, line: xl)
        XCTAssertEqual(sf, n.state?.file, file: xf, line: xl)
        XCTAssertEqual(sl, n.state?.line, file: xf, line: xl)
        
        if let node = n as? ThenBlockNode {
            assertNeverEmptyNode(node,
                                 caller: "then",
                                 sutFile: sf,
                                 xctFile: xf,
                                 sutLine: sl ?? -1,
                                 xctLine: xl)
        }
    }
    
    func assertActionsThenNode(
        _ n: ActionsNodeBase,
        event e: Event = SyntaxTestsBase.defaultEvent,
        expectedOutput eo: String,
        state: State?,
        sutFile sf: String? = #file,
        xctFile xf: StaticString = #filePath,
        sutLine sl: Int?,
        xctLine xl: UInt
    ) async {
        let thenNode = n.rest.first as! ThenNode
        assertThenNode(thenNode, state: state, sutFile: sf, xctFile: xf, sutLine: sl, xctLine: xl)
        await assertActions(n.actions, event: e, expectedOutput: eo, file: xf, xctLine: xl)
    }

    func assertActionsMatchNode(
        _ n: ActionsNodeBase,
        event e: Event = SyntaxTestsBase.defaultEvent,
        expectedOutput eo: String,
        state: State?,
        sutFile sf: String = #file,
        xctFile xf: StaticString = #filePath,
        sutLine sl: Int,
        xctLine xl: UInt
    ) async {
        let matchNode = n.rest.first as! MatchingNode
        await assertMatchNode(matchNode, all: [P.a], sutFile: sf, xctFile: xf, sutLine: sl, xctLine: xl)
        await assertActions(n.actions, event: e, expectedOutput: eo, file: xf, xctLine: xl)
    }

    func assertNeverEmptyNode(
        _ node: any NeverEmptyNode,
        caller: String,
        sutFile sf: String? = #file,
        xctFile xf: StaticString = #filePath,
        sutLine sl: Int,
        xctLine xl: UInt
    ) {
        XCTAssertEqual(sf, node.file, file: xf, line: xl)
        XCTAssertEqual(sl, node.line, file: xf, line: xl)
        XCTAssertEqual(caller, node.caller, file: xf, line: xl)
    }
    
    func assertMWTA(
        _ n: AnyNode,
        event e: Event = SyntaxTestsBase.defaultEvent,
        expectedOutput eo: String = SyntaxTestsBase.defaultOutput,
        sutFile sf: String = #file,
        xctFile xf: StaticString = #filePath,
        sutLine sl: Int = #line,
        xctLine xl: UInt = #line
    ) async {
        let actions = n as! ActionsNode
        let then = actions.rest.first as! ThenNode
        let when = then.rest.first as! WhenNode
        let match = when.rest.first as! MatchingNode
        
        XCTAssertEqual(1, actions.rest.count, file: xf, line: xl)
        XCTAssertEqual(1, then.rest.count, file: xf,  line: xl)
        XCTAssertEqual(1, when.rest.count, file: xf, line: xl)
        XCTAssertEqual(0, match.rest.count, file: xf, line: xl)
        
        await assertActionsThenNode(
            actions,
            event: e,
            expectedOutput: eo,
            state: 1,
            sutFile: sf,
            xctFile: xf,
            sutLine: sl,
            xctLine: xl
        )
        
        assertWhenNode(when, sutFile: sf, xctFile: xf, sutLine: sl, xctLine: xl)
        await assertMatchNode(match, all: [P.a], sutFile: sf, xctFile: xf, sutLine: sl, xctLine: xl)
    }
    
    func assertMWA(
        _ n: AnyNode,
        event: Event = BlockTestsBase.defaultEvent,
        expectedOutput eo: String = SyntaxTestsBase.defaultOutput,
        sutFile sf: String = #file,
        xctFile xf: StaticString = #filePath,
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) async {
        let actions = n as! ActionsNode
        let when = actions.rest.first as! WhenNode
        let match = when.rest.first as! MatchingNode
        
        XCTAssertEqual(1, actions.rest.count, file: xf, line: xl)
        XCTAssertEqual(1, when.rest.count, file: xf, line: xl)
        XCTAssertEqual(0, match.rest.count, file: xf, line: xl)
        
        await assertActions(actions.actions, event: event, expectedOutput: eo, file: xf, xctLine: xl)
        assertWhenNode(when, sutFile: sf, xctFile: xf, sutLine: sl, xctLine: xl)
        await assertMatchNode(match, all: [P.a], sutFile: sf, xctFile: xf, sutLine: sl, xctLine: xl)
    }
    
    func assertMTA(
        _ n: AnyNode,
        event: Event = BlockTestsBase.defaultEvent,
        expectedOutput eo: String = SyntaxTestsBase.defaultOutput,
        sutFile sf: String = #file,
        xctFile xf: StaticString = #filePath,
        sutLine sl: Int = #line,
        xctLine xl: UInt = #line
    ) async {
        let actions = n as! ActionsNode
        let then = actions.rest.first as! ThenNode
        let match = then.rest.first as! MatchingNode
        
        XCTAssertEqual(1, actions.rest.count, line: xl)
        XCTAssertEqual(1, then.rest.count, line: xl)
        XCTAssertEqual(0, match.rest.count, line: xl)
        
        await assertActionsThenNode(
            actions,
            event: event,
            expectedOutput: eo,
            state: 1,
            sutFile: sf,
            xctFile: xf,
            sutLine: sl,
            xctLine: xl
        )
        
        await assertMatchNode(match, all: [P.a], sutFile: sf, xctFile: xf, sutLine: sl, xctLine: xl)
    }
    
    func assertWTA(
        _ n: AnyNode,
        event: Event = SyntaxTestsBase.defaultEvent,
        expectedOutput eo: String = SyntaxTestsBase.defaultOutput,
        sutFile sf: String = #file,
        xctFile xf: StaticString = #filePath,
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) async {
        let actions = n as! ActionsNode
        let then = actions.rest.first as! ThenNode
        let when = then.rest.first as! WhenNode
        
        XCTAssertEqual(1, actions.rest.count, file: xf, line: xl)
        XCTAssertEqual(1, then.rest.count, file: xf, line: xl)
        XCTAssertEqual(0, when.rest.count, file: xf, line: xl)
        
        await assertActionsThenNode(
            actions,
            event: event,
            expectedOutput: eo,
            state: 1,
            sutFile: sf,
            xctFile: xf,
            sutLine: sl,
            xctLine: xl
        )
        
        assertWhenNode(when, sutFile: sf, xctFile: xf, sutLine: sl, xctLine: xl)
    }
    
    func assertWA(
        _ n: AnyNode,
        event: Event = BlockTestsBase.defaultEvent,
        expectedOutput eo: String = SyntaxTestsBase.defaultOutput,
        sutFile sf: String = #file,
        xctFile xf: StaticString = #filePath,
        sutLine sl: Int = #line,
        xctLine xl: UInt = #line
    ) async {
        let actions = n as! ActionsNode
        let when = actions.rest.first as! WhenNode
        
        XCTAssertEqual(1, actions.rest.count, file: xf, line: xl)
        XCTAssertEqual(0, when.rest.count, file: xf, line: xl)
        
        await assertActions(actions.actions, event: event, expectedOutput: eo, file: xf, xctLine: xl)
        assertWhenNode(when, sutFile: sf, xctFile: xf, sutLine: sl, xctLine: xl)
    }
    
    func assertTA(
        _ n: AnyNode,
        event: Event = BlockTestsBase.defaultEvent,
        expectedOutput eo: String = SyntaxTestsBase.defaultOutput,
        sutFile sf: String = #file,
        xctFile xf: StaticString = #filePath,
        sutLine sl: Int = #line,
        xctLine xl: UInt = #line
    ) async {
        let actions = n as! ActionsNode
        let then = actions.rest.first as! ThenNode
        
        XCTAssertEqual(1, actions.rest.count, file: xf, line: xl)
        XCTAssertEqual(0, then.rest.count, file: xf, line: xl)
        
        await assertActionsThenNode(
            actions,
            event: event,
            expectedOutput: eo,
            state: 1,
            sutFile: sf,
            xctFile: xf,
            sutLine: sl,
            xctLine: xl
        )
    }
    
    func assertMA(
        _ n: AnyNode,
        event: Event = BlockTestsBase.defaultEvent,
        expectedOutput eo: String = SyntaxTestsBase.defaultOutput,
        sutFile sf: String = #file,
        xctFile xf: StaticString = #filePath,
        sutLine sl: Int = #line,
        xctLine xl: UInt = #line
    ) async {
        let actions = n as! ActionsNode
        let match = actions.rest.first as! MatchingNode

        XCTAssertEqual(1, actions.rest.count, file: xf, line: xl)
        XCTAssertEqual(0, match.rest.count, file: xf, line: xl)
        
        await assertActionsMatchNode(actions,
                                     event: event,
                                     expectedOutput: eo,
                                     state: 1,
                                     sutFile: sf,
                                     xctFile: xf,
                                     sutLine: sl,
                                     xctLine: xl)
    }
    
    func assertActions(
        _ actions: [FSMAction],
        expectedOutput eo: String,
        file: StaticString = #filePath,
        xctLine xl: UInt = #line
    ) async {
        await assertActions(actions.map(AnyAction.init),
                            expectedOutput: eo,
                            file: file,
                            xctLine: xl)
    }
    
    func assertActions(
        _ actions: [AnyAction],
        event e: Event = SyntaxTestsBase.defaultEvent,
        expectedOutput eo: String,
        file: StaticString = #filePath,
        xctLine xl: UInt = #line
    ) async {
        await actions.executeAll(e)
        XCTAssertEqual(eo, output, file: file, line: xl)
        output = ""
    }
}

