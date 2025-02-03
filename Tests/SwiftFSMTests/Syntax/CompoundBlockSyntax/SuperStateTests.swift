import XCTest
@testable import SwiftFSM

class SuperStateTests: BlockTestsBase {
    func testSuperStateAddsSuperStateNodes() async {
        let s1 = SuperState { mwtaBlock }
        let nodes = SuperState(adopts: s1, s1).nodes

        XCTAssertEqual(4, nodes.count)
        await assertMWTAResult(Array(nodes.prefix(2)), sutLine: mwtaLine)
        await assertMWTAResult(Array(nodes.suffix(2)), sutLine: mwtaLine)
    }

    func testSuperStateSetsGroupIDForOwnNodesOnly() {
        let s1 = SuperState {
            when(1) | then(1) | pass
        }

        let s2 = SuperState(adopts: s1) {
            when(1) | then(2) | pass
            when(2) | then(3) | pass
        }

        assertGroupID(s2.nodes)
    }

    func testSuperStateCombinesSuperStateNodesParentFirst() async {
        let l1 = #line + 1; let s1 = SuperState {
            matching(P.a) | when(1, or: 2) | then(1) | pass
                            when(1, or: 2) | then(1) | pass
        }

        let l2 = #line + 1; let s2 = SuperState(adopts: s1) {
            matching(P.a) | when(1, or: 2) | then(1) | pass
                            when(1, or: 2) | then(1) | pass
        }

        let nodes = s2.nodes
        XCTAssertEqual(4, nodes.count)
        await assertMWTAResult(Array(nodes.prefix(2)), sutFile: #file, sutLine: l1)
        await assertMWTAResult(Array(nodes.suffix(2)), sutFile: #file, sutLine: l2)
    }

    func testSuperStateAddsEntryExitActions() async {
        let s1 = SuperState(onEntry: entry1, onExit: exit1) { mwtaBlock }
        let s2 = SuperState(adopts: s1)

        await assertActions(s2.onEntry, expectedOutput: "entry1")
        await assertActions(s2.onExit, expectedOutput: "exit1")
    }

    func testSuperStateCombinesEntryExitActions() async {
        let s1 = SuperState(onEntry: entry1, onExit: exit1) { mwtaBlock }
        let s2 = SuperState(adopts: s1, onEntry: entry2, onExit: exit2) { mwtaBlock }

        await assertActions(s2.onEntry, expectedOutput: "entry1entry2")
        await assertActions(s2.onExit, expectedOutput: "exit1exit2")
    }

    func testSuperStateBlock() async {
        let s = SuperState { mwtaBlock }
        await assertMWTAResult(s.nodes, sutLine: mwtaLine)
    }
}

