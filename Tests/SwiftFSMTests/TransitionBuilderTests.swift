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
    
    func testMatch() {
        func assertMatching(
            _ m: Syntax.Matching,
            any: any Predicate...,
            all: any Predicate...,
            line: Int,
            testLine: UInt = #line
        ) {
            let node = m.node
            
            XCTAssertTrue(node.rest.isEmpty, line: testLine)
            
            XCTAssertEqual(any.erase(), node.match.matchAny, line: testLine)
            XCTAssertEqual(all.erase(), node.match.matchAll, line: testLine)
            
            XCTAssertEqual(#file, node.file, line: testLine)
            XCTAssertEqual(line, node.line, line: testLine)
            XCTAssertEqual("match", node.caller, line: testLine)
        }
        
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
        
    func testWhen() {
        func assertWhen<E>(_ w: Syntax.When<E>, line: Int, testLine: UInt = #line) {
            let node = w.node
            
            XCTAssertTrue(node.rest.isEmpty, line: testLine)
            
            XCTAssertEqual([1, 2], node.events.map(\.base), line: testLine)
            XCTAssertEqual([#file, #file], node.events.map(\.file), line: testLine)
            XCTAssertEqual([line, line], node.events.map(\.line), line: testLine)
            
            XCTAssertEqual(#file, node.file, line: testLine)
            XCTAssertEqual(line, node.line, line: testLine)
            XCTAssertEqual("when", node.caller, line: testLine)
        }
        
        let w1 = when(1, 2); let l1 = #line
        let w2 = Syntax.When(1, 2); let l2 = #line
        
        assertWhen(w1, line: l1)
        assertWhen(w2, line: l2)
    }
    
    func testThen() {
        let n1 = then(1).node; let line = #line
        let n2 = then().node
        
        XCTAssertTrue(n1.rest.isEmpty)
        XCTAssertTrue(n2.rest.isEmpty)
        XCTAssertNil(n2.state)
        
        XCTAssertEqual(1, n1.state!.base)
        XCTAssertEqual(#file, n1.state!.file)
        XCTAssertEqual(line, n1.state!.line)
    }
}
