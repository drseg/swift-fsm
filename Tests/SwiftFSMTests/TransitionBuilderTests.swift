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
        
    func testWhen() {
        let node = when(1).node; let line = #line
                
        XCTAssertTrue(node.rest.isEmpty)
        
        XCTAssertEqual([1], node.events.map(\.base))
        XCTAssertEqual([#file], node.events.map(\.file))
        XCTAssertEqual([line], node.events.map(\.line))
        
        XCTAssertEqual(#file, node.file)
        XCTAssertEqual(line, node.line)
        XCTAssertEqual("when", node.caller)
    }
}
