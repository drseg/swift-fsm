//
//  AnyActionTests.swift
//  
//
//  Created by Daniel Segall on 12/01/2024.
//

import XCTest
@testable import SwiftFSM

final class AnyActionTests: XCTestCase {
    func testCanCallActionWithNoArgs() {
        var output = ""
        let action = AnyAction { output = "pass" }
        action()

        XCTAssertEqual(output, "pass")
    }

    func testCanCallActionWithEventArg() {
        var output = ""
        let action = AnyAction { output = $0 }
        action("pass")

        XCTAssertEqual(output, "pass")
    }
}
