//
//  ErrorTests.swift
//
//  Created by Daniel Segall on 20/03/2023.
//

import XCTest
@testable import SwiftFSM

final class ErrorTests: SyntaxNodeTests {
    func testEmptyBlockError() {
        let error = EmptyBuilderError(file: "file", line: 10)
        
        XCTAssertEqual("testEmptyBlockError", error.caller)
        XCTAssertEqual(10, error.line)
        XCTAssertEqual("file", error.file)
    }
}
