import Testing
@testable import SwiftFSM

class OverrideBlockTests: BlockTestsBase {
    @Test func override() {
        let o = overriding { mwtaBlock }
        #expect((o.nodes.first as! OverridableNode).isOverride)
    }

    @Test func nestedOverride() {
        let d = define(1) {
            overriding {
                mwtaBlock
            }
            mwtaBlock
        }

        let g = d.node.rest.first as! GivenNode

        #expect(4 == g.rest.count)

        let overridden = g.rest.prefix(2).map { $0 as! OverridableNode }
        let notOverridden = g.rest.suffix(2).map { $0 as! OverridableNode }

        overridden.forEach {
            #expect($0.isOverride)
        }

        notOverridden.forEach {
            #expect(!$0.isOverride)
        }
    }
}

