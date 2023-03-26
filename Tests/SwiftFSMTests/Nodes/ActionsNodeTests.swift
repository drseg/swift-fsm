//
//  ActionsNodeTests.swift
//  
//  Created by Daniel Segall on 20/03/2023.
//

import XCTest
@testable import SwiftFSM

final class ActionsNodeTests: SyntaxNodeTests {
    func testEmptyActions() {
        let finalised = ActionsNode(actions: [], rest: []).finalised()
        let output = finalised.output
        let errors = finalised.errors
        
        XCTAssertTrue(errors.isEmpty)
        guard assertCount(output, expected: 1) else { return }
        assertEqual((match: Match(), event: nil, state: nil, actions: actions), output.first)
    }
    
    func testEmptyActionsBlockIsError() {
        assertEmptyNodeWithError(ActionsBlockNode(actions: [], rest: []))
    }
    
    func testEmptyActionsBlockHasNoOutput() {
        assertCount(ActionsBlockNode(actions: [], rest: []).finalised().output, expected: 0)
    }
    
    func testActionsFinalisesCorrectly() {
        let n = actionsNode
        n.finalised().output.executeAll()
        XCTAssertEqual("12", actionsOutput)
        XCTAssertTrue(n.finalised().errors.isEmpty)
    }
    
    func testActionsPlusChainFinalisesCorrectly() {
        let a = ActionsNode(actions: [{ self.actionsOutput += "action" }])
        assertDefaultIONodeChains(node: a, expectedOutput: "actionchain")
    }
}
