//
//  SyntaxBuilderTests.swift
//
//  Created by Daniel Segall on 03/03/2023.
//

import Foundation
import XCTest
@testable import SwiftFSM

class SyntaxTestsBase: XCTestCase, ExpandedSyntaxBuilder {
    typealias StateType = Int
    typealias EventType = Int
    
    typealias Define = Syntax.Define<StateType>
    typealias Matching = Syntax.Expanded.Matching
    typealias When = Syntax.When<EventType>
    typealias Then = Syntax.Then<StateType>
    typealias Actions = Syntax.Actions
    
    typealias MatchingWhenThen = Internal.MatchingWhenThen
    typealias MatchingWhen = Internal.MatchingWhen
    
    typealias AnyNode = any Node

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
    
    func assertMatchNode(
        _ node: MatchNodeBase,
        any: [[any Predicate]] = [],
        all: [any Predicate] = [],
        sutFile sf: String = #file,
        xctFile xf: StaticString = #file,
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) {
        let any = any.map { $0.erased() }.filter { !$0.isEmpty }
        
        XCTAssertEqual(any, node.match.matchAny, file: xf, line: xl)
        XCTAssertEqual(all.erased(), node.match.matchAll, file: xf, line: xl)
        XCTAssertEqual(node.match.file, sf, file: xf, line: xl)
        XCTAssertEqual(node.match.line, sl, file: xf, line: xl)
        
        if let node = node as? MatchBlockNode {
            assertNeverEmptyNode(node,
                                 caller: "matching",
                                 sutFile: sf,
                                 xctFile: xf,
                                 sutLine: sl,
                                 xctLine: xl)
        }
    }
    
    func assertWhen(
        _ w: When,
        sutFile sf: String = #file,
        xctFile xf: StaticString = #file,
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) {
        XCTAssertTrue(w.node.rest.isEmpty, file: xf, line: xl)
        assertWhenNode(w.node, sutFile: sf, xctFile: xf, sutLine: sl, xctLine: xl)
    }
    
    func assertWhenNode(
        _ node: WhenNodeBase,
        sutFile sf: String = #file,
        xctFile xf: StaticString = #file,
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) {
        XCTAssertEqual([1, 2], node.events.map(\.base), file: xf, line: xl)
        XCTAssertEqual([sf, sf], node.events.map(\.file), file: xf, line: xl)
        XCTAssertEqual([sl, sl], node.events.map(\.line), file: xf, line: xl)
        
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
        state: StateType?,
        sutFile sf: String? = nil,
        xctFile xf: StaticString = #file,
        sutLine sl: Int?,
        xctLine xl: UInt = #line
    ) {
        XCTAssertEqual(state, n.state?.base as? StateType, file: xf, line: xl)
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
        state: StateType?,
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
        _ actions: [() -> ()],
        expectedOutput eo: String,
        file: StaticString = #file,
        xctLine xl: UInt = #line
    ) {
        actions.executeAll()
        XCTAssertEqual(eo, output, file: file, line: xl)
        output = ""
    }
}

