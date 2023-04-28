import XCTest
@testable import SwiftFSM

typealias OHN = OverrideHandlingNode

class OverrideHandlingNodeTests: DefineConsumer {
    func testErrorIfNothingToOverride() {
        let id = UUID()
        let d1 = defineNode(s1, Match(), e1, s2, groupID: id, isOverride: true)
        let a = ARN(rest: [d1])
        
        let finalised = OHN(rest: [a]).finalised()
        assertCount(finalised.errors, expected: 1)
        assertCount(finalised.output, expected: 0)
        
        guard let error = finalised.errors.first as? OHN.NothingToOverride else {
            XCTFail(); return
        }
        
        let expectedOverride = IntermediateIO(s1, Match(), e1, s2, [], id, true)
        XCTAssertEqual(expectedOverride, error.override)
    }
    
    func testErrorIfOverrideBeforeOverridden() {
        let id1 = UUID()
        let id2 = UUID()
        
        let d1 = defineNode(s1, Match(), e1, s2, groupID: id1, isOverride: true)
        let d2 = defineNode(s1, Match(), e1, s2, groupID: id2, isOverride: false)
        let a = ARN(rest: [d1, d2])
        
        let finalised = OHN(rest: [a]).finalised()
        assertCount(finalised.errors, expected: 1)
        assertCount(finalised.output, expected: 0)
        
        guard let error = finalised.errors.first as? OHN.OverrideOutOfOrder else {
            XCTFail(); return
        }
        
        let expectedOverride = IntermediateIO(s1, Match(), e1, s2, [], id1, true)
        let expectedOutOfOrder = IntermediateIO(s1, Match(), e1, s2, [], id2, false)
        
        XCTAssertEqual(expectedOverride, error.override)
        XCTAssertEqual([expectedOutOfOrder], error.outOfOrder)
    }
    
    func testNoErrorIfValidOverride() {
        let d1 = defineNode(s1, Match(), e1, s2, groupID: UUID(), isOverride: false)
        let d2 = defineNode(s1, Match(), e1, s2, groupID: UUID(), isOverride: true)
        let a = ARN(rest: [d1, d2])
        
        let finalised = OHN(rest: [a]).finalised()
        assertCount(finalised.errors, expected: 0)
        assertCount(finalised.output, expected: 1)
        
        XCTAssertEqual(true, finalised.output.first?.isOverride)
    }
    
    func testNoOutOfOrderErrorIfStatesDiffer() {
        let d1 = defineNode(s1, Match(), e1, s1, groupID: UUID(), isOverride: false)
        let d2 = defineNode(s1, Match(), e1, s2, groupID: UUID(), isOverride: true)
        let d3 = defineNode(s2, Match(), e1, s3, groupID: UUID(), isOverride: false)
        let a = ARN(rest: [d1, d2, d3])
        
        let finalised = OHN(rest: [a]).finalised()
        assertCount(finalised.errors, expected: 0)
        assertCount(finalised.output, expected: 2)
        
        XCTAssertEqual([s2, s3], finalised.output.map(\.nextState))
    }
    
    func testOverrideChain() {
        let d1 = defineNode(s1, Match(), e1, s1, groupID: UUID(), isOverride: false)
        let d2 = defineNode(s1, Match(), e1, s2, groupID: UUID(), isOverride: true)
        let d3 = defineNode(s1, Match(), e1, s3, groupID: UUID(), isOverride: true)

        let a = ARN(rest: [d1, d2, d3])
        
        let finalised = OHN(rest: [a]).finalised()
        assertCount(finalised.errors, expected: 0)
        assertCount(finalised.output, expected: 1)
                
        XCTAssertEqual(true, finalised.output.first?.isOverride)
        XCTAssertEqual(s3, finalised.output.first?.nextState)
    }
}
