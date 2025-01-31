import XCTest
@testable import SwiftFSM

final class SemanticValidationNodeTests: DefineConsumer {
    typealias SVN = SemanticValidationNode
    typealias ARN = ActionsResolvingNodeBase
    
    func actionsResolvingNode(
        _ g: AnyTraceable,
        _ m: MatchDescriptor,
        _ w: AnyTraceable,
        _ t: AnyTraceable,
        overrideGroupID: UUID = testGroupID,
        isOverride: Bool = false
    ) -> ARN {
        ARN(rest: [defineNode(g, m, w, t,
                              overrideGroupID: overrideGroupID,
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
        let finalised = SVN(rest: []).resolve()
        
        assertCount(finalised.output, expected: 0)
        assertCount(finalised.errors, expected: 0)
    }
    
    func testDuplicate() {
        let a = actionsResolvingNode(s1, MatchDescriptor(), e1, s2)
        let finalised = SVN(rest: [a, a]).resolve()
        
        guard assertCount(finalised.errors, expected: 1),
              assertCount(finalised.output, expected: 0) else { return }
        
        let duplicates = firstDuplicates(in: finalised)
        let expected = a.resolve().output[0]
        let duplicate = duplicates[SVN.DuplicatesKey(expected)]
        
        assertEqual(expected, duplicate?.first)
        assertEqual(expected, duplicate?.last)
    }
    
    func testClash() {
        let a1 = actionsResolvingNode(s1, MatchDescriptor(), e1, s2)
        let a2 = actionsResolvingNode(s1, MatchDescriptor(), e1, s3)

        let finalised = SVN(rest: [a1, a2]).resolve()
        
        guard assertCount(finalised.errors, expected: 1),
              assertCount(finalised.output, expected: 0) else { return }

        let clashes = firstClashes(in: finalised)
            
        let firstExpected = a1.resolve().output[0]
        let secondExpected = a2.resolve().output[0]
        
        let firstClash = clashes[SVN.ClashesKey(firstExpected)]
        let secondClash = clashes[SVN.ClashesKey(secondExpected)]

        assertEqual(firstExpected, firstClash?.first)
        assertEqual(secondExpected, secondClash?.last)
    }
    
    func testNoError() {
        let a1 = actionsResolvingNode(s1, MatchDescriptor(), e1, s2)
        let a2 = actionsResolvingNode(s1, MatchDescriptor(), e2, s3)
        
        let finalised = SVN(rest: [a1, a2]).resolve()

        guard assertCount(finalised.errors, expected: 0),
              assertCount(finalised.output, expected: 2) else { return }
        
        let firstExpected = a1.resolve().output[0]
        let secondExpected = a2.resolve().output[0]
        
        assertEqual(firstExpected, finalised.output[0])
        assertActions(finalised.output[0].actions, expectedOutput: "12")
        
        assertEqual(secondExpected, finalised.output[1])
        assertActions(finalised.output[1].actions, expectedOutput: "12")
    }
    
    func testErrorIfNothingToOverride() {
        let id = UUID()
        let d1 = defineNode(s1, MatchDescriptor(), e1, s2, overrideGroupID: id, isOverride: true)
        let a = ARN(rest: [d1])
        
        let finalised = SVN(rest: [a]).resolve()
        assertCount(finalised.errors, expected: 1)
        assertCount(finalised.output, expected: 0)
        
        guard let error = finalised.errors.first as? SVN.NothingToOverride else {
            XCTFail(); return
        }
        
        let expectedOverride = IntermediateIO(s1, MatchDescriptor(), e1, s2, [], id, true)
        XCTAssertEqual(expectedOverride, error.override)
    }
    
    func testErrorIfOverrideBeforeOverridden() {
        let id1 = UUID()
        let id2 = UUID()
        
        let d1 = defineNode(s1, MatchDescriptor(), e1, s2, overrideGroupID: id1, isOverride: true)
        let d2 = defineNode(s1, MatchDescriptor(), e1, s2, overrideGroupID: id2, isOverride: false)
        let a = ARN(rest: [d1, d2])
        
        let finalised = SVN(rest: [a]).resolve()
        assertCount(finalised.errors, expected: 1)
        assertCount(finalised.output, expected: 0)
        
        guard let error = finalised.errors.first as? SVN.OverrideOutOfOrder else {
            XCTFail(); return
        }
        
        let expectedOverride = IntermediateIO(s1, MatchDescriptor(), e1, s2, [], id1, true)
        let expectedOutOfOrder = IntermediateIO(s1, MatchDescriptor(), e1, s2, [], id2, false)
        
        XCTAssertEqual(expectedOverride, error.override)
        XCTAssertEqual([expectedOutOfOrder], error.outOfOrder)
    }
    
    func testNoErrorIfValidOverride() {
        let d1 = defineNode(s1, MatchDescriptor(), e1, s2, overrideGroupID: UUID(), isOverride: false)
        let d2 = defineNode(s1, MatchDescriptor(), e1, s2, overrideGroupID: UUID(), isOverride: true)
        let a = ARN(rest: [d1, d2])
        
        let finalised = SVN(rest: [a]).resolve()
        assertCount(finalised.errors, expected: 0)
        assertCount(finalised.output, expected: 1)
        
        XCTAssertEqual(true, finalised.output.first?.isOverride)
    }
    
    func testNoOutOfOrderErrorIfStatesDiffer() {
        let d1 = defineNode(s1, MatchDescriptor(), e1, s1, overrideGroupID: UUID(), isOverride: false)
        let d2 = defineNode(s1, MatchDescriptor(), e1, s2, overrideGroupID: UUID(), isOverride: true)
        let d3 = defineNode(s2, MatchDescriptor(), e1, s3, overrideGroupID: UUID(), isOverride: false)
        let a = ARN(rest: [d1, d2, d3])
        
        let finalised = SVN(rest: [a]).resolve()
        assertCount(finalised.errors, expected: 0)
        assertCount(finalised.output, expected: 2)
        
        XCTAssertEqual([s2, s3], finalised.output.map(\.nextState))
    }
    
    func testOverrideChain() {
        let d1 = defineNode(s1, MatchDescriptor(), e1, s1, overrideGroupID: UUID(), isOverride: false)
        let d2 = defineNode(s1, MatchDescriptor(), e1, s2, overrideGroupID: UUID(), isOverride: true)
        let d3 = defineNode(s1, MatchDescriptor(), e1, s3, overrideGroupID: UUID(), isOverride: true)

        let a = ARN(rest: [d1, d2, d3])
        
        let finalised = SVN(rest: [a]).resolve()
        assertCount(finalised.errors, expected: 0)
        assertCount(finalised.output, expected: 1)
                
        XCTAssertEqual(true, finalised.output.first?.isOverride)
        XCTAssertEqual(s3, finalised.output.first?.nextState)
    }
}
