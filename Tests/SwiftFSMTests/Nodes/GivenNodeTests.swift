//
//  GivenNodeTests.swift
//
//  Created by Daniel Segall on 20/03/2023.
//

import XCTest
@testable import SwiftFSM

final class GivenNodeTests: SyntaxNodeTests {
    func testEmptyGivenNode() {
        assertEmptyNodeWithoutError(GivenNode(states: [], rest: []))
    }
    
    func testGivenNodeWithEmptyStates() {
        assertEmptyNodeWithoutError(GivenNode(states: [], rest: [whenNode]))
    }
    
    func testGivenNodeWithEmptyRest() {
        assertEmptyNodeWithoutError(GivenNode(states: [s1, s2], rest: []))
    }

    func testGivenNodeFinalisesFillingInEmptyNextStates() {
        let expected = [(m1, s1, e1, s1),
                        (m1, s1, e2, s1),
                        (m1, s2, e1, s2),
                        (m1, s2, e2, s2)]
        
        assertGivenNode(expected: expected,
                        actionsOutput: "12121212",
                        node: givenNode(thenState: nil,
                                        actionsNode: actionsNode))
    }
    
    func testGivenNodeFinalisesWithNextStates() {
        let expected = [(m1, s1, e1, s3),
                        (m1, s1, e2, s3),
                        (m1, s2, e1, s3),
                        (m1, s2, e2, s3)]
        
        assertGivenNode(expected: expected,
                        actionsOutput: "12121212",
                        node: givenNode(thenState: s3,
                                        actionsNode: actionsNode))
    }
    
    func testGivenNodeCanSetRestAfterInitialisation() {
        let t = ThenNode(state: s3, rest: [actionsNode])
        let w = WhenNode(events: [e1, e2], rest: [t])
        let m = MatchNode(match: m1, rest: [w])
        var g = GivenNode(states: [s1, s2])
        g.rest.append(m)
        
        let expected = [(m1, s1, e1, s3),
                        (m1, s1, e2, s3),
                        (m1, s2, e1, s3),
                        (m1, s2, e2, s3)]
        
        assertGivenNode(expected: expected,
                        actionsOutput: "12121212",
                        node: g)
    }
    
    func testGivenNodeWithMultipleWhenNodes() {
        let t = ThenNode(state: s3, rest: [actionsNode])
        let w = WhenNode(events: [e1, e2], rest: [t])
        let m = MatchNode(match: m1, rest: [w, w])
        let g = GivenNode(states: [s1, s2], rest: [m])
        
        let expected = [(m1, s1, e1, s3),
                        (m1, s1, e2, s3),
                        (m1, s1, e1, s3),
                        (m1, s1, e2, s3),
                        (m1, s2, e1, s3),
                        (m1, s2, e2, s3),
                        (m1, s2, e1, s3),
                        (m1, s2, e2, s3)]
        
        assertGivenNode(expected: expected,
                        actionsOutput: "1212121212121212",
                        node: g)
    }
}
