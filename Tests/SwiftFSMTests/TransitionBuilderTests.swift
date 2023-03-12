//
//  TransitionBuilderTests.swift
//
//  Created by Daniel Segall on 03/03/2023.
//

import Foundation
import XCTest
@testable import SwiftFSM

class SyntaxTestsBase: XCTestCase, TransitionBuilder {
    typealias State = Int
    typealias Event = Int
    
    typealias Define = Syntax.Define<State>
    typealias Matching = Syntax.Matching
    typealias When = Syntax.When<Event>
    typealias Then = Syntax.Then<State>
    typealias Actions = Syntax.Actions
    
    typealias MatchingWhenThen = Internal.MatchingWhenThen
    typealias MatchingWhen = Internal.MatchingWhen
    
    typealias MWTABuilder = Internal.MWTABuilder
    typealias MWABuilder = Internal.MWABuilder
    typealias MTABuilder = Internal.MTABuilder
    
    typealias AnyNode = any Node
    
    var output = ""
    
    func assertMatching(
        _ m: Matching,
        any: any Predicate...,
        all: any Predicate...,
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) {
        XCTAssertTrue(m.node.rest.isEmpty, line: xl)
        assertMatching(m.node, any: any, all: all, sutLine: sl, xctLine: xl)
    }
    
    func assertMatching(
        _ node: MatchNodeBase,
        any: [any Predicate] = [],
        all: [any Predicate] = [],
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) {
        XCTAssertEqual(any.erase(), node.match.matchAny, line: xl)
        XCTAssertEqual(all.erase(), node.match.matchAll, line: xl)
        
        if let node = node as? MatchBlockNode {
            assertNeverEmptyNode(node, caller: "match", sutLine: sl, xctLine: xl)
        }
    }
    
    func assertWhen(_ w: When, sutLine: Int, xctLine xl: UInt = #line) {
        XCTAssertTrue(w.node.rest.isEmpty, line: xl)
        assertWhen(w.node, sutLine: sutLine, xctLine: xl)
    }
    
    func assertWhen(_ node: WhenNodeBase, sutLine sl: Int, xctLine xl: UInt = #line) {
        XCTAssertEqual([1, 2], node.events.map(\.base), line: xl)
        XCTAssertEqual([#file, #file], node.events.map(\.file), line: xl)
        XCTAssertEqual([sl, sl], node.events.map(\.line), line: xl)
        
        if let node = node as? any NeverEmptyNode {
            assertNeverEmptyNode(node, caller: "when", sutLine: sl, xctLine: xl)
        }
    }
    
    func assertThen(
        _ n: ThenNodeBase,
        state: State?,
        sutLine sl: Int?,
        file: String? = nil,
        xctLine xl: UInt = #line
    ) {
        XCTAssertEqual(state, n.state?.base as? State, line: xl)
        XCTAssertEqual(file, n.state?.file, line: xl)
        XCTAssertEqual(sl, n.state?.line, line: xl)
        
        if let node = n as? ThenBlockNode {
            assertNeverEmptyNode(node, caller: "then", sutLine: sl ?? -1, xctLine: xl)
        }
    }
    
    func assertActionsNode(
        _ n: ActionsNodeBase,
        expectedOutput eo: String,
        state: State?,
        file: String? = #file,
        sutLine sl: Int?,
        xctLine xl: UInt = #line
    ) {
        let thenNode = n.rest.first as! ThenNode
        assertThen(thenNode, state: state, sutLine: sl, file: file, xctLine: xl)
        assertActions(n.actions, expectedOutput: eo, xctLine: xl)
    }
    
    func assertNeverEmptyNode(
        _ node: any NeverEmptyNode,
        caller: String,
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) {
        XCTAssertEqual(#file, node.file, line: xl)
        XCTAssertEqual(sl, node.line, line: xl)
        XCTAssertEqual(caller, node.caller, line: xl)
    }
    
    func pass() { output += "pass" }
    
    func assertMWTA(
        _ n: AnyNode,
        expectedOutput eo: String = "pass",
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) {
        let actions = n as! ActionsNode
        let then = actions.rest.first as! ThenNode
        let when = then.rest.first as! WhenNode
        let match = when.rest.first as! MatchNode
        
        XCTAssertEqual(1, actions.rest.count, line: xl)
        XCTAssertEqual(1, then.rest.count, line: xl)
        XCTAssertEqual(1, when.rest.count, line: xl)
        XCTAssertEqual(0, match.rest.count, line: xl)
        
        assertActionsNode(actions, expectedOutput: eo, state: 1, sutLine: sl, xctLine: xl)
        assertThen(then, state: 1, sutLine: sl, file: #file, xctLine: xl)
        assertWhen(when, sutLine: sl, xctLine: xl)
        assertMatching(match, all: [P.a], sutLine: sl, xctLine: xl)
    }
    
    func assertMWA(
        _ n: AnyNode,
        expectedOutput eo: String = "pass",
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) {
        let actions = n as! ActionsNode
        let when = actions.rest.first as! WhenNode
        let match = when.rest.first as! MatchNode
        
        XCTAssertEqual(1, actions.rest.count, line: xl)
        XCTAssertEqual(1, when.rest.count, line: xl)
        XCTAssertEqual(0, match.rest.count, line: xl)
        
        assertActions(actions.actions, expectedOutput: eo, xctLine: xl)
        assertWhen(when, sutLine: sl, xctLine: xl)
        assertMatching(match, all: [P.a], sutLine: sl, xctLine: xl)
    }
    
    func assertMTA(
        _ n: AnyNode,
        expectedOutput eo: String = "pass",
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) {
        let actions = n as! ActionsNode
        let then = actions.rest.first as! ThenNode
        let match = then.rest.first as! MatchNode
        
        XCTAssertEqual(1, actions.rest.count, line: xl)
        XCTAssertEqual(1, then.rest.count, line: xl)
        XCTAssertEqual(0, match.rest.count, line: xl)
        
        assertActions(actions.actions, expectedOutput: eo, xctLine: xl)
        assertThen(then, state: 1, sutLine: sl, file: #file, xctLine: xl)
        assertMatching(match, all: [P.a], sutLine: sl, xctLine: xl)
    }
    
    func assertWTA(
        _ n: AnyNode,
        expectedOutput eo: String = "pass",
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) {
        let actions = n as! ActionsNode
        let then = actions.rest.first as! ThenNode
        let when = then.rest.first as! WhenNode
        
        XCTAssertEqual(1, actions.rest.count, line: xl)
        XCTAssertEqual(1, then.rest.count, line: xl)
        XCTAssertEqual(0, when.rest.count, line: xl)
        
        assertActionsNode(actions, expectedOutput: eo, state: 1, sutLine: sl, xctLine: xl)
        assertThen(then, state: 1, sutLine: sl, file: #file, xctLine: xl)
        assertWhen(when, sutLine: sl, xctLine: xl)
    }
    
    func assertWA(
        _ n: AnyNode,
        expectedOutput eo: String = "pass",
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) {
        let actions = n as! ActionsNode
        let when = actions.rest.first as! WhenNode
        
        XCTAssertEqual(1, actions.rest.count, line: xl)
        XCTAssertEqual(0, when.rest.count, line: xl)
        
        assertActions(actions.actions, expectedOutput: eo, xctLine: xl)
        assertWhen(when, sutLine: sl, xctLine: xl)
    }
    
    func assertTA(
        _ n: AnyNode,
        expectedOutput eo: String = "pass",
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) {
        let actions = n as! ActionsNode
        let then = actions.rest.first as! ThenNode
        
        XCTAssertEqual(1, actions.rest.count, line: xl)
        XCTAssertEqual(0, then.rest.count, line: xl)
        
        assertActions(actions.actions, expectedOutput: eo, xctLine: xl)
        assertThen(then, state: 1, sutLine: sl, file: #file, xctLine: xl)
    }
    
    func assertActions(
        _ actions: [() -> ()],
        expectedOutput eo: String,
        xctLine xl: UInt = #line
    ) {
        actions.executeAll()
        XCTAssertEqual(eo, output, line: xl)
        output = ""
    }
    
    func assertMWTAResult(
        _ result: [AnyNode],
        expectedOutput eo: String = "pass",
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) {
        assertMWTA(result[0], expectedOutput: eo, sutLine: sl, xctLine: xl)
        assertWTA(result[1], expectedOutput: eo, sutLine: sl + 1, xctLine: xl)
    }
    
    func assertMWAResult(
        _ result: [AnyNode],
        expectedOutput eo: String = "pass",
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) {
        assertMWA(result[0], expectedOutput: eo, sutLine: sl, xctLine: xl)
        
        if result.count == 2 {
            assertWA(result[1],
                     expectedOutput: eo,
                     sutLine: sl + 1,
                     xctLine: xl)
        }
    }
    
    func assertMTAResult(
        _ result: [AnyNode],
        expectedOutput eo: String = "pass",
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) {
        assertMTA(result[0], expectedOutput: eo, sutLine: sl, xctLine: xl)
        
        if result.count == 2 {
            assertTA(result[1],
                     expectedOutput: eo,
                     sutLine: sl + 1,
                     xctLine: xl)
        }
    }
}

final class ComponentTests: SyntaxTestsBase {
    func testMatching() {
        let m1 = matching(P.a); let l1 = #line
        let m2 = Matching(P.a); let l2 = #line
        
        assertMatching(m1, all: P.a, sutLine: l1)
        assertMatching(m2, all: P.a, sutLine: l2)
        
        let m3 = matching(any: P.a, P.b, line: -1)
        let m4 = Matching(any: P.a, P.b, line: -1)

        assertMatching(m3, any: P.a, P.b, sutLine: -1)
        assertMatching(m4, any: P.a, P.b, sutLine: -1)
        
        let m5 = matching(all: P.a, Q.a, line: -1)
        let m6 = Matching(all: P.a, Q.a, line: -1)
        
        assertMatching(m5, all: P.a, Q.a, sutLine: -1)
        assertMatching(m6, all: P.a, Q.a, sutLine: -1)
        
        let m7 = matching(any: P.a, P.b, all: Q.a, R.a, line: -1)
        let m8 = Matching(any: P.a, P.b, all: Q.a, R.a, line: -1)
        
        assertMatching(m7, any: P.a, P.b, all: Q.a, R.a, sutLine: -1)
        assertMatching(m8, any: P.a, P.b, all: Q.a, R.a, sutLine: -1)
    }
            
    func testWhen() {
        let w1 = when(1, 2); let l1 = #line
        let w2 = When(1, 2); let l2 = #line
        
        assertWhen(w1, sutLine: l1)
        assertWhen(w2, sutLine: l2)
    }
    
    func testThen() {
        let n1 = then(1).node; let l1 = #line
        let n2 = Then(1).node; let l2 = #line
        
        let n3 = then().node
        let n4 = Then().node
        
        assertThen(n1, state: 1, sutLine: l1, file: #file)
        assertThen(n2, state: 1, sutLine: l2, file: #file)

        assertThen(n3, state: nil, sutLine: nil)
        assertThen(n4, state: nil, sutLine: nil)
    }
    
    func testMatchingWhen() {
        func assertMW(_ mw: MatchingWhen, sutLine sl: Int, xctLine xl: UInt = #line) {
            let whenNode = mw.node
            let matchNode = whenNode.rest.first as! MatchNode
            
            XCTAssertEqual(1, whenNode.rest.count, line: xl)
            XCTAssertEqual(0, matchNode.rest.count, line: xl)
            
            assertWhen(whenNode, sutLine: sl, xctLine: xl)
            assertMatching(matchNode, all: [P.a], sutLine: sl, xctLine: xl)
        }

        assertMW(matching(P.a) | when(1, 2), sutLine: #line)
        assertMW(Matching(P.a) | When(1, 2), sutLine: #line)
    }
    
    func testMatchingWhenThen() {
        func assertMWT(_ mwt: MatchingWhenThen, sutLine sl: Int, xctLine xl: UInt = #line) {
            let then = mwt.node
            let when = then.rest.first as! WhenNode
            let match = when.rest.first as! MatchNode
            
            XCTAssertEqual(1, then.rest.count, line: xl)
            XCTAssertEqual(1, when.rest.count, line: xl)
            XCTAssertEqual(0, match.rest.count, line: xl)
            
            assertThen(then, state: 1, sutLine: sl, file: #file, xctLine: xl)
            assertWhen(when, sutLine: sl, xctLine: xl)
            assertMatching(match, all: [P.a], sutLine: sl, xctLine: xl)
        }
        
        assertMWT(matching(P.a) | when(1, 2) | then(1), sutLine: #line)
        assertMWT(Matching(P.a) | When(1, 2) | Then(1), sutLine: #line)
    }
    
    func testMatchingWhenThenActions() {
        let mwta1 = matching(P.a) | when(1, 2) | then(1) | pass; let l1 = #line
        let mwta2 = Matching(P.a) | When(1, 2) | Then(1) | pass; let l2 = #line

        assertMWTA(mwta1.node, sutLine: l1)
        assertMWTA(mwta2.node, sutLine: l2)
    }
    
    func testWhenThen() {
        func assertWT(_ wt: MatchingWhenThen, sutLine sl: Int, xctLine xl: UInt = #line) {
            let then = wt.node
            let when = then.rest.first as! WhenNode

            XCTAssertEqual(1, then.rest.count, line: xl)
            XCTAssertEqual(0, when.rest.count, line: xl)

            assertThen(then, state: 1, sutLine: sl, file: #file, xctLine: xl)
            assertWhen(when, sutLine: sl, xctLine: xl)
        }

        assertWT(when(1, 2) | then(1), sutLine: #line)
        assertWT(When(1, 2) | Then(1), sutLine: #line)
    }
    
    func testWhenThenActions() {
        let wta1 = when(1, 2) | then(1) | pass; let l1 = #line
        let wta2 = When(1, 2) | Then(1) | pass; let l2 = #line
        
        assertWTA(wta1.node, sutLine: l1)
        assertWTA(wta2.node, sutLine: l2)
    }
}

class BlockComponentTests: SyntaxTestsBase {
    func buildMWTA(@MWTABuilder _ block: () -> ([any MWTAProtocol])) -> [any MWTAProtocol] {
        block()
    }
    
    func testMWTABuilder() {
        let s0 = buildMWTA { }
        
        let l1 = #line + 1; let s1 = buildMWTA {
            matching(P.a) | when(1, 2) | then(1) | pass
                            when(1, 2) | then(1) | pass
        }
        
        let l2 = #line + 1; let s2 = buildMWTA {
            Matching(P.a) | When(1, 2) | Then(1) | pass
                            When(1, 2) | Then(1) | pass
        }
        
        XCTAssertTrue(s0.isEmpty)
        assertMWTAResult(s1.nodes, sutLine: l1)
        assertMWTAResult(s2.nodes, sutLine: l2)
    }
    
    func testSuperState() {
        let l1 = #line + 1; let s1 = SuperState {
            matching(P.a) | when(1, 2) | then(1) | pass
            when(1, 2) | then(1) | pass
        }
        
        let l2 = #line + 1; let s2 = SuperState {
            Matching(P.a) | When(1, 2) | Then(1) | pass
            When(1, 2) | Then(1) | pass
        }
        
        assertMWTAResult(s1.nodes, sutLine: l1)
        assertMWTAResult(s2.nodes, sutLine: l2)
    }
    
    func testDefine() {
        func assertDefine(
            _ d: Define,
            sutLine sl: Int,
            elementLine el: Int,
            xctLine xl: UInt = #line
        ) {
            assertNeverEmptyNode(d.node, caller: "define", sutLine: sl, xctLine: xl)
            
            XCTAssertEqual(1, d.node.rest.count, line: xl)
            let gNode = d.node.rest.first as! GivenNode
            XCTAssertEqual([1, 2], gNode.states.map(\.base))
            assertMWTAResult(gNode.rest, sutLine: el, xctLine: xl)
            
            assertActions(d.node.entryActions + d.node.exitActions,
                          expectedOutput: "entryexit",
                          xctLine: xl)
        }
        
        func entry() { output += "entry" }
        func exit() { output += "exit" }
        
        func assertEmpty(_ d: Define, xctLine: UInt = #line) {
            XCTAssertEqual(0, d.node.rest.count, line: xctLine)
        }
        
        let l0 = #line + 1; let s = SuperState {
            matching(P.a) | when(1, 2) | then(1) | pass
                            when(1, 2) | then(1) | pass
        }
        
        let l1 = #line; let d1 = define(1, 2,
                                        superState: s,
                                        entryActions: [entry],
                                        exitActions: [exit])
        
        let l2 = #line; let d2 = Define(1, 2,
                                        superState: s,
                                        entryActions: [entry],
                                        exitActions: [exit])
        
        assertDefine(d1, sutLine: l1, elementLine: l0)
        assertDefine(d2, sutLine: l2, elementLine: l0)
        
        let l3 = #line; let d3 = define(1, 2,
                                        entryActions: [entry],
                                        exitActions: [exit]) {
            matching(P.a) | when(1, 2) | then(1) | pass
                            when(1, 2) | then(1) | pass
        }
        
        let l4 = #line; let d4 = Define(1, 2,
                                        entryActions: [entry],
                                        exitActions: [exit]) {
            matching(P.a) | when(1, 2) | then(1) | pass
                            when(1, 2) | then(1) | pass
        }
        
        assertDefine(d3, sutLine: l3, elementLine: l3 + 3)
        assertDefine(d4, sutLine: l4, elementLine: l4 + 3)
        
        let d5 = define(1, 2,
                        superState: s,
                        entryActions: [entry],
                        exitActions: [exit]) { }
        
        let d6 = Define(1, 2,
                        superState: s,
                        entryActions: [entry],
                        exitActions: [exit]) { }
        
        // technically valid/non-empty but need to flag empty trailing block
        assertEmpty(d5)
        assertEmpty(d6)
        
        let d7 = define(1, 2, entryActions: [entry], exitActions: [exit]) { }
        let d8 = Define(1, 2, entryActions: [entry], exitActions: [exit]) { }
        
        assertEmpty(d7)
        assertEmpty(d8)
    }
    
    func testOptionalActions() {
        let l1 = #line; let mwtas1 = buildMWTA {
            matching(P.a) | when(1, 2) | then(1)
                            when(1, 2) | then(1)
        }
        
        let l2 = #line; let mwtas2 = buildMWTA {
            Matching(P.a) | When(1, 2) | Then(1)
                            When(1, 2) | Then(1)
        }
        
        assertMWTAResult(mwtas1.nodes, expectedOutput: "", sutLine: l1 + 1)
        assertMWTAResult(mwtas2.nodes, expectedOutput: "", sutLine: l2 + 1)
    }
}

class DefaultIOBlockTestsBase: SyntaxTestsBase {
    let mwtaLine = #line; @MWTABuilder var mwtaBlock: [any MWTAProtocol] {
        Matching(P.a) | When(1, 2) | Then(1) | pass
                        When(1, 2) | Then(1) | pass
    }
    
    let mwaLine = #line; @MWABuilder var mwaBlock: [any MWAProtocol] {
        Matching(P.a) | When(1, 2) | pass
                        When(1, 2) | pass
    }
    
    let mtaLine = #line; @MTABuilder var mtaBlock: [any MTAProtocol] {
        Matching(P.a) | Then(1) | pass
                        Then(1) | pass
    }
}

class ActionsBlockTests: DefaultIOBlockTestsBase {
    func abnComponents(of s: Sentence) -> (ActionsBlockNode, ActionsBlockNode) {
        let a1 = abn(s.node)
        let a2 = abn(a1.rest.first!)
        return (a1, a2)
    }
    
    func abn(_ n: any Node<DefaultIO>) -> ActionsBlockNode {
        n as! ActionsBlockNode
    }
    
    func assertMWTANode(
        _ b: ActionsBlockNode,
        expectedNodeOutput eo: String,
        nodeLine nl: Int,
        restLine rl: Int,
        xctLine xl: UInt
    ) {
        assertActionsBlock(b, expectedOutput: eo, sutLine: nl, xctLine: xl)
        assertMWTAResult(b.rest, sutLine: rl, xctLine: xl)
    }
    
    func assertMWANode(
        _ b: ActionsBlockNode,
        expectedNodeOutput eno: String,
        expectedRestOutput ero: String,
        nodeLine nl: Int,
        restLine rl: Int,
        xctLine xl: UInt
    ) {
        assertActionsBlock(b, expectedOutput: eno, sutLine: nl, xctLine: xl)
        assertMWAResult(b.rest, expectedOutput: ero, sutLine: rl, xctLine: xl)
    }
    
    func assertMTANode(
        _ b: ActionsBlockNode,
        expectedNodeOutput eno: String,
        expectedRestOutput ero: String,
        nodeLine nl: Int,
        restLine rl: Int,
        xctLine xl: UInt
    ) {
        assertActionsBlock(b, expectedOutput: eno, sutLine: nl, xctLine: xl)
        assertMTAResult(b.rest, expectedOutput: ero, sutLine: rl, xctLine: xl)
    }
    
    func assertActionsBlock(
        _ b: ActionsBlockNode,
        expectedOutput eo: String = "pass",
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) {
        assertNeverEmptyNode(b, caller: "actions", sutLine: sl, xctLine: xl)
        assertActions(b.actions, expectedOutput: eo, xctLine: xl)
    }
    
    func testMWTABlocks() {
        func assertMWTABlock(
            _ b: Internal.MWTASentence,
            expectedNodeOutput eo: String = "pass",
            sutLine sl: Int,
            xctLine xl: UInt = #line
        ) {
            assertMWTANode(abn(b.node),
                           expectedNodeOutput: eo,
                           nodeLine: sl,
                           restLine: mwtaLine + 1,
                           xctLine: xl)
        }
        
        let l1 = #line; let a1 = actions(pass) { mwtaBlock }
        let l2 = #line; let a2 = Actions(pass) { mwtaBlock }
        let l3 = #line; let a3 = Actions([pass, pass]) { mwtaBlock }
        
        assertMWTABlock(a1, sutLine: l1)
        assertMWTABlock(a2, sutLine: l2)
        assertMWTABlock(a3, expectedNodeOutput: "passpass", sutLine: l3)
    }
    
    func testMWABlocks() {
        func assertMWABlock(
            _ b: Internal.MWASentence,
            expectedNodeOutput eno: String = "pass",
            expectedRestOutput ero: String = "pass",
            nodeLine sl: Int,
            restLine rl: Int = mwaLine + 1,
            xctLine xl: UInt = #line
        ) {
            assertMWANode(abn(b.node),
                          expectedNodeOutput: eno,
                          expectedRestOutput: ero,
                          nodeLine: sl,
                          restLine: rl,
                          xctLine: xl)
        }
        
        let l1 = #line; let a1 = actions(pass) { mwaBlock }
        let l2 = #line; let a2 = Actions(pass) { mwaBlock }
        let l3 = #line; let a3 = actions(pass) { Matching(P.a) | When(1, 2) }
        let l4 = #line; let a4 = Actions(pass) { Matching(P.a) | When(1, 2) }
        
        assertMWABlock(a1, nodeLine: l1)
        assertMWABlock(a2, nodeLine: l2)
        assertMWABlock(a3, expectedRestOutput: "", nodeLine: l3, restLine: l3)
        assertMWABlock(a4, expectedRestOutput: "", nodeLine: l4, restLine: l4)
    }
    
    func testMTABlocks() {
        func assertMTABlock(
            _ b: Internal.MTASentence,
            expectedNodeOutput eno: String = "pass",
            expectedRestOutput ero: String = "pass",
            nodeLine nl: Int,
            restLine rl: Int = mtaLine + 1,
            xctLine xl: UInt = #line
        ) {
            assertMTANode(abn(b.node),
                          expectedNodeOutput: eno,
                          expectedRestOutput: ero,
                          nodeLine: nl,
                          restLine: rl,
                          xctLine: xl)
        }
        
        let l1 = #line; let a1 = actions(pass) { mtaBlock }
        let l2 = #line; let a2 = Actions(pass) { mtaBlock }
        let l3 = #line; let a3 = actions(pass) { Matching(P.a) | Then(1) }
        let l4 = #line; let a4 = Actions(pass) { Matching(P.a) | Then(1) }
        
        assertMTABlock(a1, nodeLine: l1)
        assertMTABlock(a2, nodeLine: l2)
        assertMTABlock(a3, expectedRestOutput: "", nodeLine: l3, restLine: l3)
        assertMTABlock(a4, expectedRestOutput: "", nodeLine: l4, restLine: l4)
    }
    
    func testCompoundMWTABlocks() {
        func assertCompoundMWTABlock(
            _ b: Internal.MWTASentence,
            expectedNodeOutput eo: String = "pass",
            sutLine sl: Int,
            xctLine xl: UInt = #line
        ) {
            let c = abnComponents(of: b)
            
            assertActionsBlock(c.0, expectedOutput: eo, sutLine: sl, xctLine: xl)
            assertMWTANode(c.1, expectedNodeOutput: eo, nodeLine: sl, restLine: mwtaLine + 1, xctLine: xl)
        }
        
        let l1 = #line; let a1 = actions(pass) { actions(pass) { mwtaBlock } }
        let l2 = #line; let a2 = Actions(pass) { actions(pass) { mwtaBlock } }
        
        assertCompoundMWTABlock(a1, sutLine: l1)
        assertCompoundMWTABlock(a2, sutLine: l2)
    }
    
    func testCompoundMWABlocks() {
        func assertCompoundMWABlock(
            _ b: Internal.MWASentence,
            expectedNodeOutput eno: String = "pass",
            expectedRestOutput ero: String = "pass",
            sutLine sl: Int,
            xctLine xl: UInt = #line
        ) {
            let c = abnComponents(of: b)
            
            assertActionsBlock(c.0, expectedOutput: eno, sutLine: sl, xctLine: xl)
            assertMWANode(c.1,
                          expectedNodeOutput: eno,
                          expectedRestOutput: ero,
                          nodeLine: sl,
                          restLine: mwaLine + 1,
                          xctLine: xl)
        }
        
        let l1 = #line; let a1 = actions(pass) { actions(pass) { mwaBlock } }
        let l2 = #line; let a2 = Actions(pass) { actions(pass) { mwaBlock } }
        
        assertCompoundMWABlock(a1, sutLine: l1)
        assertCompoundMWABlock(a2, sutLine: l2)
    }
    
    func testCompoundMTABlocks() {
        func assertCompoundMTABlock(
            _ b: Internal.MTASentence,
            expectedNodeOutput eno: String = "pass",
            expectedRestOutput ero: String = "pass",
            sutLine sl: Int,
            xctLine xl: UInt = #line
        ) {
            let c = abnComponents(of: b)
            
            assertActionsBlock(c.0, expectedOutput: eno, sutLine: sl, xctLine: xl)
            assertMTANode(c.1,
                          expectedNodeOutput: eno,
                          expectedRestOutput: ero,
                          nodeLine: sl,
                          restLine: mtaLine + 1,
                          xctLine: xl)
        }
        
        let l1 = #line; let a1 = actions(pass) { actions(pass) { mtaBlock } }
        let l2 = #line; let a2 = Actions(pass) { actions(pass) { mtaBlock } }
        
        assertCompoundMTABlock(a1, sutLine: l1)
        assertCompoundMTABlock(a2, sutLine: l2)
    }
}

class MatchingBlockTests: DefaultIOBlockTestsBase {
    func mbnComponents(of s: Sentence) -> (MatchBlockNode, MatchBlockNode) {
        let a1 = mbn(s.node)
        let a2 = mbn(a1.rest.first!)
        return (a1, a2)
    }
    
    func mbn(_ n: any Node<DefaultIO>) -> MatchBlockNode {
        n as! MatchBlockNode
    }
    
    func assertMWTANode(
        _ b: MatchBlockNode,
        any: [any Predicate],
        all: [any Predicate],
        nodeLine nl: Int,
        restLine rl: Int,
        xctLine xl: UInt
    ) {
        assertMatchBlock(b, any: any, all: all, sutLine: nl, xctLine: xl)
        assertMWTAResult(b.rest, sutLine: rl, xctLine: xl)
    }
    
    func assertMWANode(
        _ b: MatchBlockNode,
        any: [any Predicate],
        all: [any Predicate],
        nodeLine nl: Int,
        restLine rl: Int,
        xctLine xl: UInt
    ) {
        assertMatchBlock(b, any: any, all: all, sutLine: nl, xctLine: xl)
        assertMWAResult(b.rest, sutLine: rl, xctLine: xl)
    }
    
    func assertMTANode(
        _ b: MatchBlockNode,
        any: [any Predicate],
        all: [any Predicate],
        nodeLine nl: Int,
        restLine rl: Int,
        xctLine xl: UInt
    ) {
        assertMatchBlock(b, any: any, all: all, sutLine: nl, xctLine: xl)
        assertMTAResult(b.rest, sutLine: rl, xctLine: xl)
    }
    
    func assertMatchBlock(
        _ b: MatchBlockNode,
        any: [any Predicate],
        all: [any Predicate],
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) {
        assertNeverEmptyNode(b, caller: "match", sutLine: sl, xctLine: xl)
        assertMatching(b, any: any, all: all, sutLine: sl, xctLine: xl)
    }

    func testMWTABlocks() {
        func assertMWTABlock(
            _ b: Internal.MWTASentence,
            any: [any Predicate] = [],
            all: [any Predicate] = [],
            nodeLine sl: Int,
            xctLine xl: UInt = #line
        ) {
            assertMWTANode(
                mbn(b.node),
                any: any,
                all: all,
                nodeLine: sl,
                restLine: mwtaLine + 1,
                xctLine: xl
            )
        }
    
        let l1 = #line; let m1 = matching(Q.a) { mwtaBlock }
        let l2 = #line; let m2 = Matching(Q.a) { mwtaBlock }
        
        assertMWTABlock(m1, all: [Q.a], nodeLine: l1)
        assertMWTABlock(m2, all: [Q.a], nodeLine: l2)
        
        let l3 = #line; let m3 = matching(all: Q.a, R.a) { mwtaBlock }
        let l4 = #line; let m4 = Matching(all: Q.a, R.a) { mwtaBlock }
        
        assertMWTABlock(m3, all: [Q.a, R.a], nodeLine: l3)
        assertMWTABlock(m4, all: [Q.a, R.a], nodeLine: l4)
        
        let l5 = #line; let m5 = matching(any: Q.a, R.a) { mwtaBlock }
        let l6 = #line; let m6 = Matching(any: Q.a, R.a) { mwtaBlock }
        
        assertMWTABlock(m5, any: [Q.a, R.a], nodeLine: l5)
        assertMWTABlock(m6, any: [Q.a, R.a], nodeLine: l6)
        
        let l7 = #line; let m7 = matching(any: Q.a, R.a, all: Q.a, R.a) { mwtaBlock }
        let l8 = #line; let m8 = Matching(any: Q.a, R.a, all: Q.a, R.a) { mwtaBlock }
        
        assertMWTABlock(m7, any: [Q.a, R.a], all: [Q.a, R.a], nodeLine: l7)
        assertMWTABlock(m8, any: [Q.a, R.a], all: [Q.a, R.a], nodeLine: l8)
    }

    func testMWABlocks() {
        func assertMWABlock(
            _ b: Internal.MWASentence,
            any: [any Predicate] = [],
            all: [any Predicate] = [],
            nodeLine nl: Int,
            xctLine xl: UInt = #line
        ) {
            assertMWANode(mbn(b.node),
                          any: any,
                          all: all,
                          nodeLine: nl,
                          restLine: mwaLine + 1,
                          xctLine: xl)
        }
        
        let l1 = #line; let m1 = matching(Q.a) { mwaBlock }
        let l2 = #line; let m2 = Matching(Q.a) { mwaBlock }
        
        assertMWABlock(m1, all: [Q.a], nodeLine: l1)
        assertMWABlock(m2, all: [Q.a], nodeLine: l2)
        
        let l3 = #line; let m3 = matching(all: Q.a, R.a) { mwaBlock }
        let l4 = #line; let m4 = Matching(all: Q.a, R.a) { mwaBlock }

        assertMWABlock(m3, all: [Q.a, R.a], nodeLine: l3)
        assertMWABlock(m4, all: [Q.a, R.a], nodeLine: l4)
        
        let l5 = #line; let m5 = matching(any: Q.a, R.a) { mwaBlock }
        let l6 = #line; let m6 = Matching(any: Q.a, R.a) { mwaBlock }
        
        assertMWABlock(m5, any: [Q.a, R.a], nodeLine: l5)
        assertMWABlock(m6, any: [Q.a, R.a], nodeLine: l6)
        
        let l7 = #line; let m7 = matching(any: Q.a, R.a, all: Q.a, R.a)  { mwaBlock }
        let l8 = #line; let m8 = Matching(any: Q.a, R.a, all: Q.a, R.a)  { mwaBlock }

        assertMWABlock(m7, any: [Q.a, R.a], all: [Q.a, R.a], nodeLine: l7)
        assertMWABlock(m8, any: [Q.a, R.a], all: [Q.a, R.a], nodeLine: l8)
    }

    func testMTABlocks() {
        func assertMTABlock(
            _ b: Internal.MTASentence,
            any: [any Predicate] = [],
            all: [any Predicate] = [],
            nodeLine nl: Int,
            xctLine xl: UInt = #line
        ) {
            assertMTANode(mbn(b.node),
                          any: any,
                          all: all,
                          nodeLine: nl,
                          restLine: mtaLine + 1,
                          xctLine: xl)
        }
        
        let l1 = #line; let m1 = matching(Q.a) { mtaBlock }
        let l2 = #line; let m2 = Matching(Q.a) { mtaBlock }
        
        assertMTABlock(m1, all: [Q.a], nodeLine: l1)
        assertMTABlock(m2, all: [Q.a], nodeLine: l2)
        
        let l3 = #line; let m3 = matching(all: Q.a, R.a) { mtaBlock }
        let l4 = #line; let m4 = Matching(all: Q.a, R.a) { mtaBlock }

        assertMTABlock(m3, all: [Q.a, R.a], nodeLine: l3)
        assertMTABlock(m4, all: [Q.a, R.a], nodeLine: l4)
        
        let l5 = #line; let m5 = matching(any: Q.a, R.a) { mtaBlock }
        let l6 = #line; let m6 = Matching(any: Q.a, R.a) { mtaBlock }
        
        assertMTABlock(m5, any: [Q.a, R.a], nodeLine: l5)
        assertMTABlock(m6, any: [Q.a, R.a], nodeLine: l6)
        
        let l7 = #line; let m7 = matching(any: Q.a, R.a, all: Q.a, R.a)  { mtaBlock }
        let l8 = #line; let m8 = Matching(any: Q.a, R.a, all: Q.a, R.a)  { mtaBlock }

        assertMTABlock(m7, any: [Q.a, R.a], all: [Q.a, R.a], nodeLine: l7)
        assertMTABlock(m8, any: [Q.a, R.a], all: [Q.a, R.a], nodeLine: l8)
    }

    func testCompoundMWTABlocks() {
        func assertCompoundMWTABlock(
            _ b: Internal.MWTASentence,
            any: [any Predicate] = [],
            all: [any Predicate] = [],
            nodeLine nl: Int,
            xctLine xl: UInt = #line
        ) {
            let c = mbnComponents(of: b)

            assertMatchBlock(c.0, any: any, all: all, sutLine: nl, xctLine: xl)
            assertMWTANode(c.1,
                           any: any,
                           all: all,
                           nodeLine: nl,
                           restLine: mwtaLine + 1,
                           xctLine: xl)
        }

        let l1 = #line; let m1 = matching(Q.a) { matching(Q.a) { mwtaBlock } }
        let l2 = #line; let m2 = Matching(Q.a) { Matching(Q.a) { mwtaBlock } }
        
        assertCompoundMWTABlock(m1, all: [Q.a], nodeLine: l1)
        assertCompoundMWTABlock(m2, all: [Q.a], nodeLine: l2)
    }
    
    func testCompoundMWABlocks() {
        func assertCompoundMWABlock(
            _ b: Internal.MWASentence,
            any: [any Predicate] = [],
            all: [any Predicate] = [],
            nodeLine nl: Int,
            xctLine xl: UInt = #line
        ) {
            let c = mbnComponents(of: b)

            assertMatchBlock(c.0, any: any, all: all, sutLine: nl, xctLine: xl)
            assertMWANode(c.1,
                          any: any,
                          all: all,
                          nodeLine: nl,
                          restLine: mwaLine + 1,
                          xctLine: xl)
        }

        let l1 = #line; let m1 = matching(Q.a) { matching(Q.a) { mwaBlock } }
        let l2 = #line; let m2 = Matching(Q.a) { Matching(Q.a) { mwaBlock } }
        
        assertCompoundMWABlock(m1, all: [Q.a], nodeLine: l1)
        assertCompoundMWABlock(m2, all: [Q.a], nodeLine: l2)
    }
    
    func testCompoundMTABlocks() {
        func assertCompoundMTABlock(
            _ b: Internal.MTASentence,
            any: [any Predicate] = [],
            all: [any Predicate] = [],
            nodeLine nl: Int,
            xctLine xl: UInt = #line
        ) {
            let c = mbnComponents(of: b)

            assertMatchBlock(c.0, any: any, all: all, sutLine: nl, xctLine: xl)
            assertMTANode(c.1,
                          any: any,
                          all: all,
                          nodeLine: nl,
                          restLine: mtaLine + 1,
                          xctLine: xl)
        }

        let l1 = #line; let m1 = matching(Q.a) { matching(Q.a) { mtaBlock } }
        let l2 = #line; let m2 = Matching(Q.a) { Matching(Q.a) { mtaBlock } }
        
        assertCompoundMTABlock(m1, all: [Q.a], nodeLine: l1)
        assertCompoundMTABlock(m2, all: [Q.a], nodeLine: l2)
    }
}

class WhenBlockTests: DefaultIOBlockTestsBase {
    /*
     then(1) {
         Matching(P.a) | When(1, 2)        // √√
         Matching(P.a) | When(1, 2) | pass // √√
                         When(1, 2) | pass // √√
     }
     
     missing cases with no matching and no action?
     
     when(1, 2) {
         Matching(P.a) | Then(1)           // √√
         Matching(P.a) | Then(1)    | pass // √√
                         Then(1)    | pass // Do we allow this?
     }
     */
    
    func assertMTANode(
        _ b: Internal.MTASentence,
        nodeLine nl: Int,
        restLine rl: Int,
        xctLine xl: UInt = #line
    ) {
        let node = b.node as! WhenBlockNode
        assertWhen(node, sutLine: nl, xctLine: xl)
        assertMTAResult(node.rest, sutLine: rl + 1, xctLine: xl)
    }
    
    func testWhenBlock() {
        let l1 = #line; let w1 = when(1, 2) { mtaBlock }
        let l2 = #line; let w2 = When(1, 2) { mtaBlock }

        assertMTANode(w1, nodeLine: l1, restLine: mtaLine)
        assertMTANode(w2, nodeLine: l2, restLine: mtaLine)
    }
}

class ThenBlockTests: DefaultIOBlockTestsBase {
    func assertMWANode(
        _ b: Internal.MWASentence,
        nodeLine nl: Int,
        restLine rl: Int,
        xctLine xl: UInt = #line
    ) {
        let node = b.node as! ThenBlockNode
        assertThen(node, state: 1, sutLine: nl, file: #file, xctLine: xl)
        assertMWAResult(node.rest, sutLine: rl + 1, xctLine: xl)
    }
    
    func testThenBlock() {
        let l1 = #line; let t1 = then(1) { mwaBlock }
        let l2 = #line; let t2 = Then(1) { mwaBlock }

        assertMWANode(t1, nodeLine: l1, restLine: mwaLine)
        assertMWANode(t2, nodeLine: l2, restLine: mwaLine)
    }
}

