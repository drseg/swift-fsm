//
//  ErrorTests.swift
//
//  Created by Daniel Segall on 20/03/2023.
//

import XCTest
@testable import SwiftFSM

final class ErrorTests: SyntaxNodeTests {
    var e: Error!
    
    func testSwiftFSMError() {
        e = SwiftFSMError(errors: ["Error1", "Error2"])
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
    
    func testDuplicateMatchTypes() {
        e = DuplicateMatchTypes(predicates: [P.a, P.b].erased(),
                                files: ["f1"],
                                lines: [1])
        e.assertDescription(
            String.build {
                "'matching(P.a AND P.b)' is ambiguous - type P appears multiple times"
                "This combination was found in a 'matching' statement at file f1, line 1"
            }
        )
    }
    
    func testDuplicateMatchTypesThroughAddition() {
        e = DuplicateMatchTypes(predicates: [P.a, P.b, Q.a, Q.b].erased(),
                                files: ["f1", "f2"],
                                lines: [1, 2])
        e.assertDescription(
            String.build {
                let preds = "'matching(P.a AND P.b AND Q.a AND Q.b)'"
                "\(preds) is ambiguous - types P, Q appear multiple times"
                "This combination was formed by AND-ing 'matching' statements at:"
                "file f1, line 1"
                "file f2, line 2"
            }
        )
    }
    
    func testDuplicateMatchValues() {
        e = DuplicateAnyValues(predicates: [P.a, P.a, P.b, P.b].erased(),
                                 files: ["f1"],
                                 lines: [1])
        e.assertDescription(
            String.build {
                "'matching(P.a OR P.a OR P.b OR P.b)' contains multiple instances of P.a, P.b"
                "This combination was found in a 'matching' statement at file f1, line 1"
            }
        )
    }
    
    func testDuplicateMatchValuesThroughAddition() {
        e = DuplicateAnyValues(predicates: [P.a, P.a, P.b, P.b].erased(),
                                 files: ["f1", "f2"],
                                 lines: [1, 2])
        e.assertDescription(
            String.build {
                "'matching(P.a OR P.a OR P.b OR P.b)' contains multiple instances of P.a, P.b"
                "This combination was formed by AND-ing 'matching' statements at:"
                "file f1, line 1"
                "file f2, line 2"
            }
        )
    }
    
    func testDuplicateMatchAnyAllValues() {
        e = DuplicateAnyAllValues(predicates: [P.a, P.a, P.b, P.b].erased(),
                                  files: ["f1"],
                                  lines: [1])
        e.assertDescription(
            "'matching' statement at file f1, line 1 contains multiple instances of P.a, P.b"
        )
    }
    
    func testDuplicateMatchAnyAllValuesThroughAddition() {
        e = DuplicateAnyAllValues(predicates: [P.a, P.a, P.b, P.b].erased(),
                                  files: ["f1", "f2"],
                                  lines: [1, 2])
        e.assertDescription(
            String.build {
                "When combined, 'matching' statements at:"
                "file f1, line 1"
                "file f2, line 2"
                "...contain multiple instances of P.a, P.b"
            }
        )
    }
}

extension Error {
    func assertDescription(_ expected: String, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(expected, localizedDescription, file: file, line: line)
    }
}
