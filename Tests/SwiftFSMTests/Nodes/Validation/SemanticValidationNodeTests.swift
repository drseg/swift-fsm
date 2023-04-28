import XCTest
@testable import SwiftFSM

typealias SVN = SemanticValidationNode
typealias ARN = ActionsResolvingNodeBase

final class SemanticValidationNodeTests: DefineConsumer {
    func actionsResolvingNode(
        _ g: AnyTraceable,
        _ m: Match,
        _ w: AnyTraceable,
        _ t: AnyTraceable,
        groupID: UUID = testGroupID,
        isOverride: Bool = false
    ) -> ARN {
        ARN(rest: [defineNode(g, m, w, t,
                              groupID: groupID,
                              isOverride: isOverride)])
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
        let a = actionsResolvingNode(s1, Match(), e1, s2)
        let finalised = SVN(rest: [a, a]).finalised()
        
        guard assertCount(finalised.errors, expected: 1),
              assertCount(finalised.output, expected: 0) else { return }
        
        let duplicates = firstDuplicates(in: finalised)
        let expected = a.finalised().output[0]
        let duplicate = duplicates[SVN.DuplicatesKey(expected)]
        
        assertEqual(expected, duplicate?.first)
        assertEqual(expected, duplicate?.last)
    }
    
    func testClash() {
        let a1 = actionsResolvingNode(s1, Match(), e1, s2)
        let a2 = actionsResolvingNode(s1, Match(), e1, s3)

        let finalised = SVN(rest: [a1, a2]).finalised()
        
        guard assertCount(finalised.errors, expected: 1),
              assertCount(finalised.output, expected: 0) else { return }

        let clashes = firstClashes(in: finalised)
            
        let firstExpected = a1.finalised().output[0]
        let secondExpected = a2.finalised().output[0]
        
        let firstClash = clashes[SVN.ClashesKey(firstExpected)]
        let secondClash = clashes[SVN.ClashesKey(secondExpected)]

        assertEqual(firstExpected, firstClash?.first)
        assertEqual(secondExpected, secondClash?.last)
    }
    
    func testNoError() {
        let a1 = actionsResolvingNode(s1, Match(), e1, s2)
        let a2 = actionsResolvingNode(s1, Match(), e2, s3)
        
        let finalised = SVN(rest: [a1, a2]).finalised()

        guard assertCount(finalised.errors, expected: 0),
              assertCount(finalised.output, expected: 2) else { return }
        
        let firstExpected = a1.finalised().output[0]
        let secondExpected = a2.finalised().output[0]
        
        assertEqual(firstExpected, finalised.output[0])
        assertActions(finalised.output[0].actions, expectedOutput: "12")
        
        assertEqual(secondExpected, finalised.output[1])
        assertActions(finalised.output[1].actions, expectedOutput: "12")
    }
    
    func testRespectsErrorPolicy() {
        let d = defineNode(s1, Match(), e1, s2, groupID: UUID(), isOverride: true)
        let svn1 = SVN(rest: [ARN(rest: [d, d])])
        let svn2 = SVN(rest: [ARN(rest: [d, d])])
        
        assertCount(svn1.finalised(ignoreErrors: false).errors, expected: 1)
        assertCount(svn2.finalised(ignoreErrors: true).errors, expected: 0)
    }
}
