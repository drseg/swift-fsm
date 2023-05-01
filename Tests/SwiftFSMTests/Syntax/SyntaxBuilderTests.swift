import Foundation
import XCTest
@testable import SwiftFSM

class SyntaxTestsBase: XCTestCase, ExpandedSyntaxBuilder {
    typealias State = Int
    typealias Event = Int
    
    typealias Define = Syntax.Define<State>
    typealias Matching = Syntax.Expanded.Matching
    typealias Condition = Syntax.Expanded.Condition
    typealias When = Syntax.When<Event>
    typealias Then = Syntax.Then<State>
    typealias Actions = Syntax.Actions
    typealias Override = Syntax.Override
    
    typealias MatchingWhenThen = Internal.MatchingWhenThen
    typealias MatchingWhen = Internal.MatchingWhen
    
    typealias AnyNode = any UnsafeNode

    var output = ""
    
    func pass() { output += "pass" }
    
    func assertMatching(
        _ m: Matching,
        any: any Predicate...,
        all: any Predicate...,
        sutFile sf: String = #file,
        xctFile xf: StaticString = #file,
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) {
        XCTAssertTrue(m.node.rest.isEmpty, file: xf, line: xl)
        assertMatchNode(m.node,
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
        xctFile xf: StaticString = #file,
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) {
        XCTAssertTrue(c.node.rest.isEmpty, file: xf, line: xl)
        XCTAssertEqual(expected, c.node.match.condition?(), file: xf, line: xl)
        assertMatchNode(c.node,
                        condition: expected,
                        sutFile: sf,
                        xctFile: xf,
                        sutLine: sl,
                        xctLine: xl)
    }
    
    func assertMatchNode(
        _ node: MatchNodeBase,
        any: [[any Predicate]] = [],
        all: [any Predicate] = [],
        condition: Bool? = nil,
        caller: String = "matching",
        sutFile sf: String = #file,
        xctFile xf: StaticString = #file,
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) {
        let any = any.map { $0.erased() }.filter { !$0.isEmpty }
        
        XCTAssertEqual(any, node.match.matchAny, file: xf, line: xl)
        XCTAssertEqual(all.erased(), node.match.matchAll, file: xf, line: xl)
        XCTAssertEqual(condition, node.match.condition?(), file: xf, line: xl)
        XCTAssertEqual(node.match.file, sf, file: xf, line: xl)
        XCTAssertEqual(node.match.line, sl, file: xf, line: xl)
        
        if let node = node as? MatchBlockNode {
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
        xctFile xf: StaticString = #file,
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) {
        XCTAssertTrue(w.node.rest.isEmpty, file: xf, line: xl)
        assertWhenNode(w.node, events: events, sutFile: sf, xctFile: xf, sutLine: sl, xctLine: xl)
    }
    
    func assertWhenNode(
        _ node: WhenNodeBase,
        events: [Int] = [1, 2],
        sutFile sf: String = #file,
        xctFile xf: StaticString = #file,
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
        xctFile xf: StaticString = #file,
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
        expectedOutput eo: String,
        state: State?,
        sutFile sf: String? = #file,
        xctFile xf: StaticString = #file,
        sutLine sl: Int?,
        xctLine xl: UInt
    ) {
        let thenNode = n.rest.first as! ThenNode
        assertThenNode(thenNode, state: state, sutFile: sf, xctFile: xf, sutLine: sl, xctLine: xl)
        assertActions(n.actions, expectedOutput: eo, file: xf, xctLine: xl)
    }
    
    func assertNeverEmptyNode(
        _ node: any NeverEmptyNode,
        caller: String,
        sutFile sf: String? = #file,
        xctFile xf: StaticString = #file,
        sutLine sl: Int,
        xctLine xl: UInt
    ) {
        XCTAssertEqual(sf, node.file, file: xf, line: xl)
        XCTAssertEqual(sl, node.line, file: xf, line: xl)
        XCTAssertEqual(caller, node.caller, file: xf, line: xl)
    }
    
    func assertMWTA(
        _ n: AnyNode,
        expectedOutput eo: String = "pass",
        sutFile sf: String = #file,
        xctFile xf: StaticString = #file,
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) {
        let actions = n as! ActionsNode
        let then = actions.rest.first as! ThenNode
        let when = then.rest.first as! WhenNode
        let match = when.rest.first as! MatchNode
        
        XCTAssertEqual(1, actions.rest.count, file: xf, line: xl)
        XCTAssertEqual(1, then.rest.count, file: xf,  line: xl)
        XCTAssertEqual(1, when.rest.count, file: xf, line: xl)
        XCTAssertEqual(0, match.rest.count, file: xf, line: xl)
        
        assertActionsThenNode(actions,
                              expectedOutput: eo,
                              state: 1,
                              sutFile: sf,
                              xctFile: xf,
                              sutLine: sl,
                              xctLine: xl)
        
        assertWhenNode(when, sutFile: sf, xctFile: xf, sutLine: sl, xctLine: xl)
        assertMatchNode(match, all: [P.a], sutFile: sf, xctFile: xf, sutLine: sl, xctLine: xl)
    }
    
    func assertMWA(
        _ n: AnyNode,
        expectedOutput eo: String = "pass",
        sutFile sf: String,
        xctFile xf: StaticString,
        sutLine sl: Int,
        xctLine xl: UInt
    ) {
        let actions = n as! ActionsNode
        let when = actions.rest.first as! WhenNode
        let match = when.rest.first as! MatchNode
        
        XCTAssertEqual(1, actions.rest.count, file: xf, line: xl)
        XCTAssertEqual(1, when.rest.count, file: xf, line: xl)
        XCTAssertEqual(0, match.rest.count, file: xf, line: xl)
        
        assertActions(actions.actions, expectedOutput: eo, file: xf, xctLine: xl)
        assertWhenNode(when, sutFile: sf, xctFile: xf, sutLine: sl, xctLine: xl)
        assertMatchNode(match, all: [P.a], sutFile: sf, xctFile: xf, sutLine: sl, xctLine: xl)
    }
    
    func assertMTA(
        _ n: AnyNode,
        expectedOutput eo: String = "pass",
        sutFile sf: String,
        xctFile xf: StaticString,
        sutLine sl: Int,
        xctLine xl: UInt
    ) {
        let actions = n as! ActionsNode
        let then = actions.rest.first as! ThenNode
        let match = then.rest.first as! MatchNode
        
        XCTAssertEqual(1, actions.rest.count, line: xl)
        XCTAssertEqual(1, then.rest.count, line: xl)
        XCTAssertEqual(0, match.rest.count, line: xl)
        
        assertActionsThenNode(actions,
                              expectedOutput: eo,
                              state: 1,
                              sutFile: sf,
                              xctFile: xf,
                              sutLine: sl,
                              xctLine: xl)
        
        assertMatchNode(match, all: [P.a], sutFile: sf, xctFile: xf, sutLine: sl, xctLine: xl)
    }
    
    func assertWTA(
        _ n: AnyNode,
        expectedOutput eo: String = "pass",
        sutFile sf: String = #file,
        xctFile xf: StaticString = #file,
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) {
        let actions = n as! ActionsNode
        let then = actions.rest.first as! ThenNode
        let when = then.rest.first as! WhenNode
        
        XCTAssertEqual(1, actions.rest.count, file: xf, line: xl)
        XCTAssertEqual(1, then.rest.count, file: xf, line: xl)
        XCTAssertEqual(0, when.rest.count, file: xf, line: xl)
        
        assertActionsThenNode(actions,
                              expectedOutput: eo,
                              state: 1,
                              sutFile: sf,
                              xctFile: xf,
                              sutLine: sl,
                              xctLine: xl)
        
        assertWhenNode(when, sutFile: sf, xctFile: xf, sutLine: sl, xctLine: xl)
    }
    
    func assertWA(
        _ n: AnyNode,
        expectedOutput eo: String = "pass",
        sutFile sf: String,
        xctFile xf: StaticString,
        sutLine sl: Int,
        xctLine xl: UInt
    ) {
        let actions = n as! ActionsNode
        let when = actions.rest.first as! WhenNode
        
        XCTAssertEqual(1, actions.rest.count, file: xf, line: xl)
        XCTAssertEqual(0, when.rest.count, file: xf, line: xl)
        
        assertActions(actions.actions, expectedOutput: eo, file: xf, xctLine: xl)
        assertWhenNode(when, sutFile: sf, xctFile: xf, sutLine: sl, xctLine: xl)
    }
    
    func assertTA(
        _ n: AnyNode,
        expectedOutput eo: String = "pass",
        sutFile sf: String,
        xctFile xf: StaticString,
        sutLine sl: Int,
        xctLine xl: UInt
    ) {
        let actions = n as! ActionsNode
        let then = actions.rest.first as! ThenNode
        
        XCTAssertEqual(1, actions.rest.count, file: xf, line: xl)
        XCTAssertEqual(0, then.rest.count, file: xf, line: xl)
        
        assertActionsThenNode(actions,
                              expectedOutput: eo,
                              state: 1,
                              sutFile: sf,
                              xctFile: xf,
                              sutLine: sl,
                              xctLine: xl)
    }
    
    func assertActions(
        _ actions: [Action],
        expectedOutput eo: String,
        file: StaticString = #file,
        xctLine xl: UInt = #line
    ) {
        actions.executeAll()
        XCTAssertEqual(eo, output, file: file, line: xl)
        output = ""
    }
}

