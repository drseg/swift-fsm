//
//  TransitionBuilderTests.swift
//
//  Created by Daniel Segall on 03/03/2023.
//

import Foundation
import XCTest
@testable import SwiftFSM

final class SyntaxBuilderTests: XCTestCase, TransitionBuilder {
    typealias State = Int
    typealias Event = Int
    
    func assertMatching(
        _ m: Syntax.Matching,
        any: any Predicate...,
        all: any Predicate...,
        line: Int,
        testLine: UInt = #line
    ) {
        XCTAssertTrue(m.node.rest.isEmpty, line: testLine)
        assertMatching(m.node, any: any, all: all, line: line, testLine: testLine)
    }
    
    func assertMatching(
        _ node: MatchNode,
        any: [any Predicate] = [],
        all: [any Predicate] = [],
        line: Int,
        testLine: UInt = #line
    ) {
        XCTAssertEqual(any.erase(), node.match.matchAny, line: testLine)
        XCTAssertEqual(all.erase(), node.match.matchAll, line: testLine)
        
        XCTAssertEqual(#file, node.file, line: testLine)
        XCTAssertEqual(line, node.line, line: testLine)
        XCTAssertEqual("match", node.caller, line: testLine)
    }
    
    func testMatch() {
        let m1 = matching(P.a); let l1 = #line
        let m2 = Syntax.Matching(P.a); let l2 = #line
        
        assertMatching(m1, all: P.a, line: l1)
        assertMatching(m2, all: P.a, line: l2)
        
        let m3 = matching(any: P.a, P.b); let l3 = #line
        let m4 = Syntax.Matching(any: P.a, P.b); let l4 = #line

        assertMatching(m3, any: P.a, P.b, line: l3)
        assertMatching(m4, any: P.a, P.b, line: l4)
        
        let m5 = matching(all: P.a, Q.a); let l5 = #line
        let m6 = Syntax.Matching(all: P.a, Q.a); let l6 = #line
        
        assertMatching(m5, all: P.a, Q.a, line: l5)
        assertMatching(m6, all: P.a, Q.a, line: l6)
        
        let m7 = matching(any: P.a, P.b, all: Q.a, R.a); let l7 = #line
        let m8 = Syntax.Matching(any: P.a, P.b, all: Q.a, R.a); let l8 = #line
        
        assertMatching(m7, any: P.a, P.b, all: Q.a, R.a, line: l7)
        assertMatching(m8, any: P.a, P.b, all: Q.a, R.a, line: l8)
    }
        
    func assertWhen<E>(_ w: Syntax.When<E>, line: Int, testLine: UInt = #line) {
        XCTAssertTrue(w.node.rest.isEmpty, line: testLine)
        assertWhen(w.node, line: line, testLine: testLine)
    }
    
    func assertWhen(_ node: WhenNode, line: Int, testLine: UInt = #line) {
        XCTAssertEqual([1, 2], node.events.map(\.base), line: testLine)
        XCTAssertEqual([#file, #file], node.events.map(\.file), line: testLine)
        XCTAssertEqual([line, line], node.events.map(\.line), line: testLine)
        
        XCTAssertEqual(#file, node.file, line: testLine)
        XCTAssertEqual(line, node.line, line: testLine)
        XCTAssertEqual("when", node.caller, line: testLine)
    }
    
    func testWhen() {
        
        let w1 = when(1, 2); let l1 = #line
        let w2 = Syntax.When(1, 2); let l2 = #line
        
        assertWhen(w1, line: l1)
        assertWhen(w2, line: l2)
    }
    
    func assertThen(_ n: ThenNode, state: State?, testLine: Int?, file: String? = nil, line: UInt = #line) {
        XCTAssertEqual(state, n.state?.base as? State, line: line)
        XCTAssertEqual(file, n.state?.file, line: line)
        XCTAssertEqual(testLine, n.state?.line, line: line)
    }
    
    func testThen() {
        let n1 = then(1).node; let l1 = #line
        let n2 = Syntax.Then(1).node; let l2 = #line
        
        let n3 = then().node
        let n4 = Syntax.Then<AnyHashable>().node
        
        assertThen(n1, state: 1, testLine: l1, file: #file)
        assertThen(n2, state: 1, testLine: l2, file: #file)

        assertThen(n3, state: nil, testLine: nil)
        assertThen(n4, state: nil, testLine: nil)
    }
    
    func testMatchingWhen() {
        let mw = matching(P.a) | when(1, 2); let line = #line
        let whenNode = mw.node
        let matchNode = whenNode.rest.first! as! MatchNode
        
        XCTAssertEqual(1, whenNode.rest.count)
        
        assertWhen(whenNode, line: line)
        assertMatching(matchNode, all: [P.a], line: line)
    }
    
    func testMatchingWhenThen() {
        let mwt = matching(P.a) | when(1, 2) | then(1); let line = #line
        let thenNode = mwt.node
        let whenNode = thenNode.rest.first! as! WhenNode
        let matchNode = whenNode.rest.first! as! MatchNode
        
        assertThen(thenNode, state: 1, testLine: line, file: #file)
        assertWhen(whenNode, line: line)
        assertMatching(matchNode, all: [P.a], line: line)
    }
}
