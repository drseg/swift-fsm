import Testing
@testable import SwiftFSM

class DefineTests: BlockTestsBase {
    @Test func define() async {
        func verify(
            _ d: Define,
            hasEvent: Bool = false,
            sutLine sl: Int = #line,
            elementLine el: Int = mwtaLine,
            location: SourceLocation = #_sourceLocation
        ) async {
            assertNeverEmptyNode(d.node, caller: "define", sutLine: sl, location: location)

            #expect(1 == d.node.rest.count, sourceLocation: location)
            let gNode = d.node.rest.first as! GivenNode
            #expect([1] == gNode.states.map(\.base), sourceLocation: location)
            
            await assertMWTAResult(gNode.rest, sutLine: el, location: location)
            await assertActions(
                d.node.onEntry + d.node.onExit,
                expectedOutput: "entry1exit1",
                location: location
            )
        }
        
        func assertEmpty(_ d: Define, location: SourceLocation = #_sourceLocation) {
            #expect(0 == d.node.rest.count, sourceLocation: location)
        }

        let s = SuperState { mwtaBlock }

        await verify(define(1, adopts: s, onEntry: entry1, onExit: exit1))
        await verify(define(1, onEntry: entry1, onExit: exit1) { mwtaBlock })

        assertEmpty(define(1, onEntry: entry1, onExit: exit1) { })

        // technically valid/non-empty but need to flag empty trailing block
        assertEmpty(define(1, adopts: s, onEntry: entry1, onExit: exit1) { })
    }

    @Test func defineAddsSuperStateEntryExitActions() async {
        let s1 = SuperState(onEntry: entry1, onExit: exit1) {
            matching(P.a) | when(1, or: 2) | then(1) | pass
                            when(1, or: 2) | then(1) | pass
        }

        let d1 = define(1, adopts: s1, s1, onEntry: entry2, onExit: exit2)

        await assertActions(d1.node.onEntry, expectedOutput: "entry1entry1entry2")
        await assertActions(d1.node.onExit, expectedOutput: "exit1exit1exit2")
    }

    @Test func defineAddsMultipleSuperStateNodes() async {
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

    @Test func defineAddsBlockAndSuperStateNodesTogetherParentFirst() async {
        func assertDefine(_ n: DefineNode, location: SourceLocation = #_sourceLocation) async {
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

            #expect([1] == givenStates(givens(0)), sourceLocation: location)
            #expect([[1], [2]] == [events(whens(0)), events(whens(1))], sourceLocation: location)
            #expect([1, 2] == [thenState(thens(0)), thenState(thens(1))], sourceLocation: location)
            
            await assertActions(actions.map(\.actions).flattened,
                                expectedOutput: "passpass",
                                location: location)
        }

        let s = SuperState            { when(1) | then(1) | pass }
        let d1 = define(1, adopts: s) { when(2) | then(2) | pass }
        await assertDefine(d1.node)
    }

    @Test func defineSetsUniqueGroupIDForOwnNodesOnly() {
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

    @Test func optionalActions() async {
        let l1 = #line; let d = define(1) {
            matching(P.a) | when(1, or: 2) | then(1)
                            when(1, or: 2) | then(1)
        }

        await assertMWTAResult(
            d.node.rest.nodes,
            expectedOutput: "",
            sutFile: #file,
            sutLine: l1 + 1
        )
    }
}

