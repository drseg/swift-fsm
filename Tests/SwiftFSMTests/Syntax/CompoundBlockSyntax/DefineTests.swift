import XCTest
@testable import SwiftFSM

class DefineTests: BlockTestsBase {
    func testDefine() async {
        func verify(
            _ d: Define,
            hasEvent: Bool = false,
            sutLine sl: Int = #line,
            elementLine el: Int = mwtaLine,
            xctLine xl: UInt = #line
        ) async {
            assertNeverEmptyNode(d.node, caller: "define", sutLine: sl, xctLine: xl)

            XCTAssertEqual(1, d.node.rest.count, line: xl)
            let gNode = d.node.rest.first as! GivenNode
            XCTAssertEqual([1], gNode.states.map(\.base))
            
            await assertMWTAResult(gNode.rest, sutLine: el, xctLine: xl)
            await assertActions(d.node.onEntry + d.node.onExit,
                                expectedOutput: "entry1exit1",
                                xctLine: xl)
        }
        
        func assertEmpty(_ d: Define, xctLine: UInt = #line) {
            XCTAssertEqual(0, d.node.rest.count, line: xctLine)
        }

        let s = SuperState { mwtaBlock }

        await verify(define(1, adopts: s, onEntry: entry1, onExit: exit1))
        await verify(define(1, onEntry: entry1, onExit: exit1) { mwtaBlock })

        assertEmpty(define(1, onEntry: entry1, onExit: exit1) { })

        // technically valid/non-empty but need to flag empty trailing block
        assertEmpty(define(1, adopts: s, onEntry: entry1, onExit: exit1) { })
    }

    func testDefineAddsSuperStateEntryExitActions() async {
        let s1 = SuperState(onEntry: entry1, onExit: exit1) {
            matching(P.a) | when(1, or: 2) | then(1) | pass
                            when(1, or: 2) | then(1) | pass
        }

        let d1 = define(1, adopts: s1, s1, onEntry: entry2, onExit: exit2)

        await assertActions(d1.node.onEntry, expectedOutput: "entry1entry1entry2")
        await assertActions(d1.node.onExit, expectedOutput: "exit1exit1exit2")
    }

    func testDefineAddsMultipleSuperStateNodes() async {
        let l1 = #line + 1; let s1 = SuperState(onEntry: entry1, onExit: exit1) {
            matching(P.a) | when(1, or: 2) | then(1) | pass
                            when(1, or: 2) | then(1) | pass
        }

        let g1 = define(1, adopts: s1, s1, onEntry: entry1, onExit: exit1)
            .node
            .rest[0] as! GivenNode

        await assertMWTAResult(Array(g1.rest.prefix(2)), sutFile: #file, sutLine: l1)
        await assertMWTAResult(Array(g1.rest.suffix(2)), sutFile: #file, sutLine: l1)
    }

    func testDefineAddsBlockAndSuperStateNodesTogetherParentFirst() async {
        func assertDefine(_ n: DefineNode, line: UInt = #line) async {
            func castRest<T: SyntaxNode, U: SyntaxNode>(_ n: [U], to: T.Type) -> [T] {
                n.map { $0.rest }.flattened as! [T]
            }

            let givens = n.rest as! [GivenNode]
            let actions = castRest(givens, to: ActionsNode.self)
            let thens = castRest(actions, to: ThenNode.self)
            let whens = castRest(thens, to: WhenNode.self)

            func givenStates(_ n: GivenNode?) -> [AnyHashable] { bases(n?.states) }
            func events(_ n: WhenNode?)       -> [AnyHashable] { bases(n?.events) }
            func thenState(_ n: ThenNode?)    -> AnyHashable   { n?.state?.base }
            func bases(_ t: [AnyTraceable]?)  -> [AnyHashable] { t?.map(\.base) ?? [] }

            XCTAssertEqual([1], givenStates(givens(0)), line: line)
            XCTAssertEqual([[1], [2]], [events(whens(0)), events(whens(1))], line: line)
            XCTAssertEqual([1, 2], [thenState(thens(0)), thenState(thens(1))], line: line)

            await assertActions(actions.map(\.actions).flattened,
                          expectedOutput: "passpass",
                          xctLine: line)
        }

        let s = SuperState            { when(1) | then(1) | pass }
        let d1 = define(1, adopts: s) { when(2) | then(2) | pass }
        await assertDefine(d1.node)
    }

    func testDefineSetsUniqueGroupIDForOwnNodesOnly() {
        let s = SuperState {
            when(1) | then(1) | pass
        }

        let d = define(1, adopts: s) {
            when(2) | then(2) | pass
            when(3) | then(3) | pass
        }

        let given = d.node.rest.first as! GivenNode
        assertGroupID(given.rest)
    }

    func testOptionalActions() async {
        let l1 = #line; let d = define(1) {
            matching(P.a) | when(1, or: 2) | then(1)
                            when(1, or: 2) | then(1)
        }

        await assertMWTAResult(d.node.rest.nodes, expectedOutput: "", sutFile: #file, sutLine: l1 + 1)
    }
}

