//
//  BlockComponentTests.swift
//  
//  Created by Daniel Segall on 20/03/2023.
//

import XCTest
@testable import SwiftFSM

class BlockTests: SyntaxTestsBase {
    typealias MWTABuilder = Internal.MWTABuilder
    typealias MWABuilder = Internal.MWABuilder
    typealias MTABuilder = Internal.MTABuilder
    
    func assertMWTAResult(
        _ result: [AnyNode],
        expectedOutput eo: String = "pass",
        sutFile sf: String = #file,
        xctFile xf: StaticString = #file,
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) {
        assertMWTA(result[0],
                   expectedOutput: eo,
                   sutFile: sf,
                   xctFile: xf,
                   sutLine: sl,
                   xctLine: xl)
        
        assertWTA(result[1],
                  expectedOutput: eo,
                  sutFile: sf,
                  xctFile: xf,
                  sutLine: sl + 1,
                  xctLine: xl)
    }
    
    func assertMWAResult(
        _ result: [AnyNode],
        expectedOutput eo: String = "pass",
        sutFile sf: String = #file,
        xctFile xf: StaticString = #file,
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) {
        assertMWA(result[0], expectedOutput: eo, sutFile: sf, xctFile: xf, sutLine: sl, xctLine: xl)
        
        if result.count == 2 {
            assertWA(result[1],
                     expectedOutput: eo,
                     sutFile: sf,
                     xctFile: xf,
                     sutLine: sl + 1,
                     xctLine: xl)
        }
    }
    
    func assertMTAResult(
        _ result: [AnyNode],
        expectedOutput eo: String = "pass",
        sutFile sf: String = #file,
        xctFile xf: StaticString = #file,
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) {
        assertMTA(result[0], expectedOutput: eo, sutFile: sf, xctFile: xf, sutLine: sl, xctLine: xl)
        
        if result.count == 2 {
            assertTA(result[1],
                     expectedOutput: eo,
                     sutFile: sf,
                     xctFile: xf,
                     sutLine: sl + 1,
                     xctLine: xl)
        }
    }
}

class BlockComponentTests: BlockTests {
    func buildMWTA(@MWTABuilder _ block: () -> ([any MWTA])) -> [any MWTA] {
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
            assertActions(d.node.onEntry + d.node.onExit, expectedOutput: "entryexit", xctLine: xl)
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
        
        let l1 = #line; let d1 = define(1, 2, superState: s, onEntry: [entry], onExit: [exit])
        let l2 = #line; let d2 = Define(1, 2, superState: s, onEntry: [entry], onExit: [exit])
        
        assertDefine(d1, sutLine: l1, elementLine: l0)
        assertDefine(d2, sutLine: l2, elementLine: l0)
        
        let l3 = #line; let d3 = define(1, 2, onEntry: [entry], onExit: [exit]) {
            matching(P.a) | when(1, 2) | then(1) | pass
                            when(1, 2) | then(1) | pass
        }
        
        let l4 = #line; let d4 = Define(1, 2, onEntry: [entry], onExit: [exit]) {
            matching(P.a) | when(1, 2) | then(1) | pass
                            when(1, 2) | then(1) | pass
        }
        
        assertDefine(d3, sutLine: l3, elementLine: l3 + 1)
        assertDefine(d4, sutLine: l4, elementLine: l4 + 1)
        
        let d5 = define(1, 2,superState: s, onEntry: [entry],  onExit: [exit]) { }
        let d6 = Define(1, 2, superState: s, onEntry: [entry], onExit: [exit]) { }
        
        // technically valid/non-empty but need to flag empty trailing block
        assertEmpty(d5)
        assertEmpty(d6)
        
        let d7 = define(1, 2, onEntry: [entry], onExit: [exit]) { }
        let d8 = Define(1, 2, onEntry: [entry], onExit: [exit]) { }
        
        assertEmpty(d7)
        assertEmpty(d8)
    }
    
    func testDefineAddsBlockAndSuperStateNodesTogether() {
        #warning("This test is not sufficient")
        let s = SuperState                { when(1) | then(1) | pass }
        let d1 = define(1, superState: s) { when(2) | then(2) | pass }
        let d2 = Define(1, superState: s) { when(2) | then(2) | pass }
        
        let given1 = d1.node.rest.first as? GivenNode
        let given2 = d2.node.rest.first as? GivenNode

        let io1 = given1?.rest
        let io2 = given2?.rest
        
        XCTAssertEqual(2, io1?.count)
        XCTAssertEqual(2, io2?.count)
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

class DefaultIOBlockTests: BlockTests {
    let mwtaLine = #line; @MWTABuilder var mwtaBlock: [any MWTA] {
        Matching(P.a) | When(1, 2) | Then(1) | pass
                        When(1, 2) | Then(1) | pass
    }
    
    let mwaLine = #line; @MWABuilder var mwaBlock: [any MWA] {
        Matching(P.a) | When(1, 2) | pass
                        When(1, 2) | pass
    }
    
    let mtaLine = #line; @MTABuilder var mtaBlock: [any MTA] {
        Matching(P.a) | Then(1) | pass
                        Then(1) | pass
    }
}

class ActionsBlockTests: DefaultIOBlockTests {
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
            assertMWTANode(c.1,
                           expectedNodeOutput: eo,
                           nodeLine: sl,
                           restLine: mwtaLine + 1,
                           xctLine: xl)
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

class MatchingBlockTests: DefaultIOBlockTests {
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
        assertMatchNode(b, any: [any], all: all, sutLine: sl, xctLine: xl)
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
        
        let l3 = #line; let m3 = matching(Q.a, and: R.a) { mwtaBlock }
        let l4 = #line; let m4 = Matching(Q.a, and: R.a) { mwtaBlock }
        
        assertMWTABlock(m3, all: [Q.a, R.a], nodeLine: l3)
        assertMWTABlock(m4, all: [Q.a, R.a], nodeLine: l4)
        
        let l5 = #line; let m5 = matching(Q.a, or: R.a) { mwtaBlock }
        let l6 = #line; let m6 = Matching(Q.a, or: R.a) { mwtaBlock }
        
        assertMWTABlock(m5, any: [Q.a, R.a], nodeLine: l5)
        assertMWTABlock(m6, any: [Q.a, R.a], nodeLine: l6)
        
        let l7 = #line; let m7 = matching(Q.a, or: R.a, and: Q.a, R.a) { mwtaBlock }
        let l8 = #line; let m8 = Matching(Q.a, or: R.a, and: Q.a, R.a) { mwtaBlock }
        
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
        
        let l3 = #line; let m3 = matching(Q.a, and: R.a) { mwaBlock }
        let l4 = #line; let m4 = Matching(Q.a, and: R.a) { mwaBlock }

        assertMWABlock(m3, all: [Q.a, R.a], nodeLine: l3)
        assertMWABlock(m4, all: [Q.a, R.a], nodeLine: l4)
        
        let l5 = #line; let m5 = matching(Q.a, or: R.a) { mwaBlock }
        let l6 = #line; let m6 = Matching(Q.a, or: R.a) { mwaBlock }
        
        assertMWABlock(m5, any: [Q.a, R.a], nodeLine: l5)
        assertMWABlock(m6, any: [Q.a, R.a], nodeLine: l6)
        
        let l7 = #line; let m7 = matching(Q.a, or: R.a, and: Q.a, R.a)  { mwaBlock }
        let l8 = #line; let m8 = Matching(Q.a, or: R.a, and: Q.a, R.a)  { mwaBlock }

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
        
        let l3 = #line; let m3 = matching(Q.a, and: R.a) { mtaBlock }
        let l4 = #line; let m4 = Matching(Q.a, and: R.a) { mtaBlock }

        assertMTABlock(m3, all: [Q.a, R.a], nodeLine: l3)
        assertMTABlock(m4, all: [Q.a, R.a], nodeLine: l4)
        
        let l5 = #line; let m5 = matching(Q.a, or: R.a) { mtaBlock }
        let l6 = #line; let m6 = Matching(Q.a, or: R.a) { mtaBlock }
        
        assertMTABlock(m5, any: [Q.a, R.a], nodeLine: l5)
        assertMTABlock(m6, any: [Q.a, R.a], nodeLine: l6)
        
        let l7 = #line; let m7 = matching(Q.a, or: R.a, and: Q.a, R.a)  { mtaBlock }
        let l8 = #line; let m8 = Matching(Q.a, or: R.a, and: Q.a, R.a)  { mtaBlock }

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

class WhenBlockTests: DefaultIOBlockTests {
    func assert(
        _ b: Internal.MWTASentence,
        nodeLine nl: Int,
        restLine rl: Int,
        xctLine xl: UInt = #line
    ) {
        let node = b.node as! WhenBlockNode
        assertWhenNode(node, sutLine: nl, xctLine: xl)
        assertMTAResult(node.rest, sutLine: rl + 1, xctLine: xl)
    }
    
    func assert(
        _ b: Internal.MWASentence,
        nodeLine nl: Int,
        restLine rl: Int,
        xctLine xl: UInt = #line
    ) {
        let node = b.node as! WhenBlockNode
        assertWhenNode(node, sutLine: nl, xctLine: xl)
        let actionsNode = node.rest.first as! ActionsNode
        assertActions(actionsNode.actions, expectedOutput: "pass")
        let matchNode = actionsNode.rest.first as! MatchNode
        assertMatchNode(matchNode, all: [P.a], sutLine: nl)
    }
    
    func testWhenBlockWithMTA() {
        let l1 = #line; let w1 = when(1, 2) { mtaBlock }
        let l2 = #line; let w2 = When(1, 2) { mtaBlock }
    
        assert(w1, nodeLine: l1, restLine: mtaLine)
        assert(w2, nodeLine: l2, restLine: mtaLine)
    }
    
    func testWhenBlockWithMA() {
        let l1 = #line; let w1 = when(1, 2) { Matching(P.a) | pass }
        let l2 = #line; let w2 = When(1, 2) { Matching(P.a) | pass }
        
        assert(w1, nodeLine: l1, restLine: l1)
        assert(w2, nodeLine: l2, restLine: l2)
    }
}

class ThenBlockTests: DefaultIOBlockTests {
    func assert(
        _ b: Internal.MWTASentence,
        nodeLine nl: Int,
        restLine rl: Int,
        xctLine xl: UInt = #line
    ) {
        let node = b.node as! ThenBlockNode
        assertThenNode(node, state: 1, sutFile: #file, sutLine: nl, xctLine: xl)
        assertMWAResult(node.rest, sutLine: rl + 1, xctLine: xl)
    }
    
    func assert(
        _ b: Internal.MTASentence,
        nodeLine nl: Int,
        restLine rl: Int,
        xctLine xl: UInt = #line
    ) {
        let node = b.node as! ThenBlockNode
        assertThenNode(node, state: 1, sutFile: #file, sutLine: nl, xctLine: xl)
        let actionsNode = node.rest.first as! ActionsNode
        assertActions(actionsNode.actions, expectedOutput: "pass")
        let matchNode = actionsNode.rest.first as! MatchNode
        assertMatchNode(matchNode, all: [P.a], sutLine: nl)
    }
    
    func testThenBlockWithMTA() {
        let l1 = #line; let t1 = then(1) { mwaBlock }
        let l2 = #line; let t2 = Then(1) { mwaBlock }

        assert(t1, nodeLine: l1, restLine: mwaLine)
        assert(t2, nodeLine: l2, restLine: mwaLine)
    }
    
    func testThenBlockWithMA() {
        let l1 = #line; let w1 = then(1) { Matching(P.a) | pass }
        let l2 = #line; let w2 = Then(1) { Matching(P.a) | pass }
        
        assert(w1, nodeLine: l1, restLine: l1)
        assert(w2, nodeLine: l2, restLine: l2)
    }
}
