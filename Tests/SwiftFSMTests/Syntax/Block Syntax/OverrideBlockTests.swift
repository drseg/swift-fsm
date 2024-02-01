import XCTest
@testable import SwiftFSM

class OverrideBlockTests: BlockTestsBase {
    func testOverride() {
        let o1 = override { mwtaBlock }
        let o2 = Override { mwtaBlock }

        let nodes = [o1, o2].flattened.nodes.map { $0 as! OverridableNode }
        nodes.forEach {
            XCTAssert($0.isOverride)
        }
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

