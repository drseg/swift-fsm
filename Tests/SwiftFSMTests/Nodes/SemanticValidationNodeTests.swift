//
//  SemanticValidationNodeTests.swift
//  
//  Created by Daniel Segall on 18/03/2023.
//

import XCTest
@testable import SwiftFSM

final class SemanticValidationNodeTests: DefineConsumer {
    typealias SVN = SemanticValidationNode
    
    func transitionNode(
        _ g: AnyTraceable,
        _ m: Match,
        _ w: AnyTraceable,
        _ t: AnyTraceable
    ) -> ActionsResolvingNode {
        ActionsResolvingNode(rest: [defineNode(g, m, w, t)])
    }
    
    func assertEqual(_ lhs: SVN.Output?, _ rhs: SVN.Output?, line: UInt = #line) {
        guard let lhs else { XCTFail("lhs unexpectedly nil", line: line); return }
        guard let rhs else { XCTFail("rhs unexpectedly nil", line: line); return }
        
        XCTAssertEqual(SVN.DuplicatesKey(lhs), SVN.DuplicatesKey(rhs), line: line)
    }
    
    func firstDuplicates(
        in finalised: (output: [SVN.Output], errors: [Error])
    ) -> SVN.DuplicatesDictionary {
        (finalised.errors[0] as? SVN.DuplicatesError)?.duplicates ?? [:]
    }
    
    func firstClashes(
        in finalised: (output: [SVN.Output], errors: [Error])
    ) -> SVN.ClashesDictionary {
        (finalised.errors[0] as? SVN.ClashError)?.clashes ?? [:]
    }
    
    func testEmptyNode() {
        let finalised = SVN(rest: []).finalised()
        
        assertCount(finalised.output, expected: 0)
        assertCount(finalised.errors, expected: 0)
    }
    
    func testDuplicate() {
        let t = transitionNode(s1, Match(), e1, s2)
        let finalised = SVN(rest: [t, t]).finalised()
        
        guard assertCount(finalised.errors, expected: 1) else { return }
        guard assertCount(finalised.output, expected: 0) else { return }
        
        let duplicates = firstDuplicates(in: finalised)
        let expected = t.finalised().output[0]
        let duplicate = duplicates[SVN.DuplicatesKey(expected)]
        
        assertEqual(expected, duplicate?.first)
        assertEqual(expected, duplicate?.last)
    }
    
    func testClash() {
        let t1 = transitionNode(s1, Match(), e1, s2)
        let t2 = transitionNode(s1, Match(), e1, s3)

        let finalised = SVN(rest: [t1, t2]).finalised()
        
        guard assertCount(finalised.errors, expected: 1) else { return }
        guard assertCount(finalised.output, expected: 0) else { return }

        let clashes = firstClashes(in: finalised)
            
        let firstExpected = t1.finalised().output[0]
        let secondExpected = t2.finalised().output[0]
        
        let firstClash = clashes[SVN.ClashesKey(firstExpected)]
        let secondClash = clashes[SVN.ClashesKey(secondExpected)]

        assertEqual(firstExpected, firstClash?.first)
        assertEqual(secondExpected, secondClash?.last)
    }
    
    func testNoError() {
        let t1 = transitionNode(s1, Match(), e1, s2)
        let t2 = transitionNode(s1, Match(), e2, s3)
        
        let finalised = SVN(rest: [t1, t2]).finalised()

        guard assertCount(finalised.errors, expected: 0),
              assertCount(finalised.output, expected: 2) else { return }
        
        let firstExpected = t1.finalised().output[0]
        let secondExpected = t2.finalised().output[0]
        
        assertEqual(firstExpected, finalised.output[0])
        assertActions(finalised.output[0].actions, expectedOutput: "12")
        
        assertEqual(secondExpected, finalised.output[1])
        assertActions(finalised.output[1].actions, expectedOutput: "12")
    }
}
