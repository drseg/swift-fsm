import Testing
import Foundation
@testable import SwiftFSM

final class SemanticValidationNodeTests: DefineConsumer {
    typealias SVN = SemanticValidationNode
    typealias ARN = ActionsResolvingNode
    
    func actionsResolvingNode(
        _ g: AnyTraceable,
        _ m: MatchDescriptorChain,
        _ w: AnyTraceable,
        _ t: AnyTraceable,
        overrideGroupID: UUID = testGroupID,
        isOverride: Bool = false
    ) -> ARN {
        ARN(rest: [defineNode(g, m, w, t,
                              overrideGroupID: overrideGroupID,
                              isOverride: isOverride)])
    }
    
    func assertEqual(
        _ lhs: SVN.Output?,
        _ rhs: SVN.Output?,
        location: SourceLocation = #_sourceLocation
    ) {
        guard let lhs else {
            Issue.record("lhs unexpectedly nil", sourceLocation: location); return
        }
        guard let rhs else {
            Issue.record("rhs unexpectedly nil", sourceLocation: location); return
        }
        
        #expect(SVN.DuplicatesKey(lhs) == SVN.DuplicatesKey(rhs), sourceLocation: location)
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
    
    @Test func emptyNode() {
        let finalised = SVN(rest: []).resolve()
        
        #expect(finalised.output.isEmpty)
        #expect(finalised.errors.isEmpty)
    }
    
    @Test func duplicate() throws {
        let a = actionsResolvingNode(s1, MatchDescriptorChain(), e1, s2)
        let finalised = SVN(rest: [a, a]).resolve()
        
        try #require(finalised.errors.count == 1)
        try #require(finalised.output.count == 0)
        
        let duplicates = firstDuplicates(in: finalised)
        let expected = a.resolve().output[0]
        let duplicate = duplicates[SVN.DuplicatesKey(expected)]
        
        assertEqual(expected, duplicate?.first)
        assertEqual(expected, duplicate?.last)
    }
    
    @Test func clash() throws {
        let a1 = actionsResolvingNode(s1, MatchDescriptorChain(), e1, s2)
        let a2 = actionsResolvingNode(s1, MatchDescriptorChain(), e1, s3)

        let finalised = SVN(rest: [a1, a2]).resolve()
        
        try #require(finalised.errors.count == 1)
        try #require(finalised.output.count == 0)

        let clashes = firstClashes(in: finalised)
            
        let firstExpected = a1.resolve().output[0]
        let secondExpected = a2.resolve().output[0]
        
        let firstClash = clashes[SVN.ClashesKey(firstExpected)]
        let secondClash = clashes[SVN.ClashesKey(secondExpected)]

        assertEqual(firstExpected, firstClash?.first)
        assertEqual(secondExpected, secondClash?.last)
    }
    
    @Test func noError() async throws {
        let a1 = actionsResolvingNode(s1, MatchDescriptorChain(), e1, s2)
        let a2 = actionsResolvingNode(s1, MatchDescriptorChain(), e2, s3)
        
        let finalised = SVN(rest: [a1, a2]).resolve()

        try #require(finalised.errors.count == 0)
        try #require(finalised.output.count == 2)
        
        let firstExpected = a1.resolve().output[0]
        let secondExpected = a2.resolve().output[0]
        
        assertEqual(firstExpected, finalised.output[0])
        await assertActions(finalised.output[0].actions, expectedOutput: "12")
        
        assertEqual(secondExpected, finalised.output[1])
        await assertActions(finalised.output[1].actions, expectedOutput: "12")
    }
    
    @Test func errorIfNothingToOverride() throws {
        let id = UUID()
        let d1 = defineNode(s1, MatchDescriptorChain(), e1, s2, overrideGroupID: id, isOverride: true)
        let a = ARN(rest: [d1])
        
        let finalised = SVN(rest: [a]).resolve()
        try #require(finalised.errors.count == 1)
        try #require(finalised.output.count == 0)
        
        guard let error = finalised.errors.first as? SVN.NothingToOverride else {
            Issue.record(); return
        }
        
        let expectedOverride = OverrideSyntaxDTO(s1, MatchDescriptorChain(), e1, s2, [], id, true)
        #expect(expectedOverride == error.override)
    }
    
    @Test func errorIfOverrideBeforeOverridden() throws {
        let id1 = UUID()
        let id2 = UUID()
        
        let d1 = defineNode(s1, MatchDescriptorChain(), e1, s2, overrideGroupID: id1, isOverride: true)
        let d2 = defineNode(s1, MatchDescriptorChain(), e1, s2, overrideGroupID: id2, isOverride: false)
        let a = ARN(rest: [d1, d2])
        
        let finalised = SVN(rest: [a]).resolve()
        try #require(finalised.errors.count == 1)
        try #require(finalised.output.count == 0)
        
        guard let error = finalised.errors.first as? SVN.OverrideOutOfOrder else {
            Issue.record(); return
        }
        
        let expectedOverride = OverrideSyntaxDTO(s1, MatchDescriptorChain(), e1, s2, [], id1, true)
        let expectedOutOfOrder = OverrideSyntaxDTO(s1, MatchDescriptorChain(), e1, s2, [], id2, false)
        
        #expect(expectedOverride == error.override)
        #expect([expectedOutOfOrder] == error.outOfOrder)
    }
    
    @Test func noErrorIfValidOverride() throws {
        let d1 = defineNode(s1, MatchDescriptorChain(), e1, s2, overrideGroupID: UUID(), isOverride: false)
        let d2 = defineNode(s1, MatchDescriptorChain(), e1, s2, overrideGroupID: UUID(), isOverride: true)
        let a = ARN(rest: [d1, d2])
        
        let finalised = SVN(rest: [a]).resolve()
        try #require(finalised.errors.count == 0)
        try #require(finalised.output.count == 1)
        
        #expect(finalised.output.first?.isOverride ?? false)
    }
    
    @Test func noOutOfOrderErrorIfStatesDiffer() throws {
        let d1 = defineNode(s1, MatchDescriptorChain(), e1, s1, overrideGroupID: UUID(), isOverride: false)
        let d2 = defineNode(s1, MatchDescriptorChain(), e1, s2, overrideGroupID: UUID(), isOverride: true)
        let d3 = defineNode(s2, MatchDescriptorChain(), e1, s3, overrideGroupID: UUID(), isOverride: false)
        let a = ARN(rest: [d1, d2, d3])
        
        let finalised = SVN(rest: [a]).resolve()
        try #require(finalised.errors.count == 0)
        try #require(finalised.output.count == 2)
        
        #expect([s2, s3] == finalised.output.map(\.nextState))
    }
    
    @Test func overrideChain() throws {
        let d1 = defineNode(s1, MatchDescriptorChain(), e1, s1, overrideGroupID: UUID(), isOverride: false)
        let d2 = defineNode(s1, MatchDescriptorChain(), e1, s2, overrideGroupID: UUID(), isOverride: true)
        let d3 = defineNode(s1, MatchDescriptorChain(), e1, s3, overrideGroupID: UUID(), isOverride: true)

        let a = ARN(rest: [d1, d2, d3])
        
        let finalised = SVN(rest: [a]).resolve()
        try #require(finalised.errors.count == 0)
        try #require(finalised.output.count == 1)
                
        #expect(finalised.output.first?.isOverride ?? false)
        #expect(s3 == finalised.output.first?.nextState)
    }
}
