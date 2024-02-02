import XCTest
@testable import SwiftFSM

class OverrideBlockTests: BlockTestsBase {
    func testOverride() {
        #warning("this syntax is unusable, change to something unique")
        let o = override { mwtaBlock }
        XCTAssert((o.nodes.first as! OverridableNode).isOverride)
    }

    func testNestedOverride() {
        let d = define(1) {
            override {
                mwtaBlock
            }
            mwtaBlock
        }

        let g = d.node.rest.first as! GivenNode

        XCTAssertEqual(8, g.rest.count)

        let overridden = g.rest.prefix(4).map { $0 as! OverridableNode }
        let notOverridden = g.rest.suffix(4).map { $0 as! OverridableNode }

        overridden.forEach {
            XCTAssertTrue($0.isOverride)
        }

        notOverridden.forEach {
            XCTAssertFalse($0.isOverride)
        }
    }
}

