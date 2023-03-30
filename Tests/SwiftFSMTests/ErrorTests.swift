//
//  ErrorTests.swift
//
//  Created by Daniel Segall on 20/03/2023.
//

import XCTest
@testable import SwiftFSM

final class ErrorTests: SyntaxNodeTests {
    var e: Error!
    
    func testCompoundError() {
        e = CompoundError(errors: ["Error1", "Error2"])
        let message = String.build {
            "- SwiftFSM Errors -"
            ""
            "2 errors were found:"
            ""
            "Error1"
            "Error2"
            ""
            "- End -"
        }

        e.assertDescription(message)
        XCTAssertEqual((e as CustomStringConvertible).description, message)
    }

    func testEmptyBlockError() {
        e = EmptyBuilderError(caller: "caller", file: "testfile", line: 10)
        e.assertDescription(
            "Empty @resultBuilder block passed to 'caller' in testfile at line 10"
        )
    }
}

extension Error {
    func assertDescription(_ expected: String, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(expected, localizedDescription, file: file, line: line)
    }
}
