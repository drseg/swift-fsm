import XCTest
@testable import SwiftFSM

class OverrideBlockTests: BlockTestsBase {
    func testOverride() {
        let o = overriding { mwtaBlock }
        XCTAssert((o.nodes.first as! OverridableNode).isOverride)
    }

    func testNestedOverride() {
        let d = define(1) {
            overriding {
                mwtaBlock
            }
            mwtaBlock
        }

        let g = d.node.rest.first as! GivenNode

        XCTAssertEqual(4, g.rest.count)

        let overridden = g.rest.prefix(2).map { $0 as! OverridableNode }
        let notOverridden = g.rest.suffix(2).map { $0 as! OverridableNode }

        overridden.forEach {
            XCTAssertTrue($0.isOverride)
        }

        notOverridden.forEach {
            XCTAssertFalse($0.isOverride)
        }
    }
}

