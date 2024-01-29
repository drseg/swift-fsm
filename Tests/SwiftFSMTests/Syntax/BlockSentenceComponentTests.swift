import XCTest
@testable import SwiftFSM

class BlockTests: SyntaxTestsBase {
    typealias MWTABuilder = Internal.MWTABuilder
    typealias MWABuilder = Internal.MWABuilder
    typealias MTABuilder = Internal.MTABuilder
    typealias Actions = Syntax.Actions<Event>

    let mwtaLine = #line + 1; @MWTABuilder var mwtaBlock: [MWTA] {
        Matching(P.a) | When(1, or: 2) | Then(1) | pass
                        When(1, or: 2) | Then(1) | pass
        Matching(P.a) | When(1, or: 2) | Then(1) | passAsync
                        When(1, or: 2) | Then(1) | passAsync
    }

    let mwtaLineWithEvent = #line + 1; @MWTABuilder var mwtaBlockWithEvent: [MWTA] {
        Matching(P.a) | When(1, or: 2) | Then(1) | passWithEvent
                        When(1, or: 2) | Then(1) | passWithEvent
        Matching(P.a) | When(1, or: 2) | Then(1) | passWithEventAsync
                        When(1, or: 2) | Then(1) | passWithEventAsync
    }

    let mwaLine = #line + 1; @MWABuilder var mwaBlock: [MWA] {
        Matching(P.a) | When(1, or: 2) | pass
                        When(1, or: 2) | pass
        Matching(P.a) | When(1, or: 2) | passAsync
                        When(1, or: 2) | passAsync
    }

    let mwaLineWithEvent = #line + 1; @MWABuilder var mwaBlockWithEvent: [MWA] {
        Matching(P.a) | When(1, or: 2) | passWithEvent
                        When(1, or: 2) | passWithEvent
        Matching(P.a) | When(1, or: 2) | passWithEventAsync
                        When(1, or: 2) | passWithEventAsync
    }

    let mtaLineWithEvent = #line + 1; @MTABuilder var mtaBlockWithEvent: [MTA] {
        Matching(P.a) | Then(1) | passWithEvent
                        Then(1) | passWithEvent
        Matching(P.a) | Then(1) | passWithEventAsync
                        Then(1) | passWithEventAsync
    }

    let mtaLine = #line + 1; @MTABuilder var mtaBlock: [MTA] {
        Matching(P.a) | Then(1) | pass
                        Then(1) | pass
        Matching(P.a) | Then(1) | passAsync
                        Then(1) | passAsync
    }

    let maLineSync = #line + 1; var maBlockSync: MA {
        Matching(P.a) | pass
    }

    let maLineAsync = #line + 1; var maBlockAsync: MA {
        Matching(P.a) | passAsync
    }

    let maLineWithEventSync = #line + 1; var maBlockWithEventSync: MA {
        Matching(P.a) | passWithEvent
    }

    let maLineWithEventAsync = #line + 1; var maBlockWithEventAsync: MA {
        Matching(P.a) | passWithEventAsync
    }

#warning("missing actions with events")
    var entry1: [FSMSyncAction] { [{ self.output += "entry1" }] }
    var entry1Async: [FSMAsyncAction] { [{ self.output += "entry1" }] }
    var entry2: [FSMSyncAction] { [{ self.output += "entry2" }] }
    var entry2Async: [FSMAsyncAction] { [{ self.output += "entry2" }] }

    var exit1: [FSMSyncAction]  { [{ self.output += "exit1"  }] }
    var exit1Async: [FSMAsyncAction]  { [{ self.output += "exit1"  }] }
    var exit2: [FSMSyncAction]  { [{ self.output += "exit2"  }] }
    var exit2Async: [FSMAsyncAction]  { [{ self.output += "exit2"  }] }

    func assertMWTAResult(
        _ result: [AnyNode],
        event: Event = BlockTests.defaultEvent,
        expectedOutput eo: String = BlockTests.defaultOutput,
        sutFile sf: String = #file,
        xctFile xf: StaticString = #file,
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) {
        for i in stride(from: 0, to: result.count, by: 2) {
            assertMWTA(result[i],
                       event: event,
                       expectedOutput: eo,
                       sutFile: sf,
                       xctFile: xf,
                       sutLine: sl + i,
                       xctLine: xl)
        }

        for i in stride(from: 1, to: result.count, by: 2) {
            assertWTA(result[i],
                       event: event,
                       expectedOutput: eo,
                       sutFile: sf,
                       xctFile: xf,
                       sutLine: sl + i,
                       xctLine: xl)
        }
    }

    func assertMWAResult(
        _ result: [AnyNode],
        expectedOutput eo: String = BlockTests.defaultOutput,
        sutFile sf: String = #file,
        xctFile xf: StaticString = #file,
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) {
        for i in stride(from: 0, to: result.count, by: 2) {
            assertMWA(result[i],
                      expectedOutput: eo,
                      sutFile: sf,
                      xctFile: xf,
                      sutLine: sl + i,
                      xctLine: xl)
        }

        for i in stride(from: 1, to: result.count, by: 2) {
            assertWA(result[i],
                      expectedOutput: eo,
                      sutFile: sf,
                      xctFile: xf,
                      sutLine: sl + i,
                      xctLine: xl)
        }
    }

    func assertMTAResult(
        _ result: [AnyNode],
        expectedOutput eo: String = BlockTests.defaultOutput,
        sutFile sf: String = #file,
        xctFile xf: StaticString = #file,
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) {
        for i in stride(from: 0, to: result.count, by: 2) {
            assertMTA(result[i],
                      expectedOutput: eo,
                      sutFile: sf,
                      xctFile: xf,
                      sutLine: sl + i,
                      xctLine: xl)
        }

        for i in stride(from: 1, to: result.count, by: 2) {
            assertTA(result[i],
                     expectedOutput: eo,
                     sutFile: sf,
                     xctFile: xf,
                     sutLine: sl + i,
                     xctLine: xl)
        }
    }

    func assertMAResult(
        _ result: [AnyNode],
        expectedOutput eo: String = BlockTests.defaultOutput,
        sutFile sf: String = #file,
        xctFile xf: StaticString = #file,
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) {
        for i in 0..<result.count {
            assertMA(result[i],
                     expectedOutput: eo,
                     sutFile: sf,
                     xctFile: xf,
                     sutLine: sl + i,
                     xctLine: xl)
        }
    }

    func assertGroupID(_ nodes: [any Node<DefaultIO>], line: UInt = #line) {
        let output = nodes.map { $0.finalised().output }
        XCTAssertEqual(3, output.count, line: line)

        let defineOutput = output.dropFirst().flattened
        defineOutput.forEach {
            XCTAssertEqual(defineOutput.first?.groupID, $0.groupID, line: line)
        }

        XCTAssertNotEqual(output.flattened.first?.groupID,
                          output.flattened.last?.groupID,
                          line: line)
    }
}

class SuperStateTests: BlockTests {
    func testSuperStateAddsSuperStateNodes() {
        let s1 = SuperState { mwtaBlock }
        let nodes = SuperState(adopts: s1, s1).nodes

        XCTAssertEqual(8, nodes.count)
        assertMWTAResult(Array(nodes.prefix(4)), sutLine: mwtaLine)
        assertMWTAResult(Array(nodes.suffix(4)), sutLine: mwtaLine)
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

    func testSuperStateCombinesSuperStateNodesParentFirst() {
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
        assertMWTAResult(Array(nodes.prefix(2)), sutLine: l1)
        assertMWTAResult(Array(nodes.suffix(2)), sutLine: l2)
    }

    func testSuperStateAddsEntryExitActions() {
        let s1 = SuperState(onEntry: entry1, onExit: exit1) { mwtaBlock }
        let s2 = SuperState(adopts: s1)

        assertActions(s2.onEntry, expectedOutput: "entry1")
        assertActions(s2.onExit, expectedOutput: "exit1")
    }

    func testSuperStateAddsEntryExitActions_Async() async {
        let s1 = SuperState(onEntry: entry1Async, onExit: exit1Async) { mwtaBlock }
        let s2 = SuperState(adopts: s1)

        await assertActions(s2.onEntry, expectedOutput: "entry1")
        await assertActions(s2.onExit, expectedOutput: "exit1")
    }

    func testSuperStateCombinesEntryExitActions() {
        let s1 = SuperState(onEntry: entry1, onExit: exit1) { mwtaBlock }
        let s2 = SuperState(adopts: s1, onEntry: entry2, onExit: exit2) { mwtaBlock }

        assertActions(s2.onEntry, expectedOutput: "entry1entry2")
        assertActions(s2.onExit, expectedOutput: "exit1exit2")
    }

    func testSuperStateCombinesEntryExitActions_Async() async {
        let s1 = SuperState(onEntry: entry1Async, onExit: exit1Async) { mwtaBlock }
        let s2 = SuperState(adopts: s1, onEntry: entry2Async, onExit: exit2Async) { mwtaBlock }

        await assertActions(s2.onEntry, expectedOutput: "entry1entry2")
        await assertActions(s2.onExit, expectedOutput: "exit1exit2")
    }

    func testSuperStateBlock() {
        let s = SuperState { mwtaBlock }
        assertMWTAResult(s.nodes, sutLine: mwtaLine)
    }
}

class DefineTests: BlockTests {
    func buildMWTA(@MWTABuilder _ block: () -> [MWTA]) -> [MWTA] {
        block()
    }

    func testMWTABuilder() {
        let s0 = buildMWTA { }
        let s1 = buildMWTA { mwtaBlock }

        XCTAssertTrue(s0.isEmpty)
        assertMWTAResult(s1.nodes, sutLine: mwtaLine)
    }

    func testDefine() {
        func assertDefine(
            _ d: Define,
            sutLine sl: Int = #line,
            elementLine el: Int = mwtaLine,
            xctLine xl: UInt = #line
        ) {
            assertNeverEmptyNode(d.node, caller: "define", sutLine: sl, xctLine: xl)

            XCTAssertEqual(1, d.node.rest.count, line: xl)
            let gNode = d.node.rest.first as! GivenNode
            XCTAssertEqual([1], gNode.states.map(\.base))

            assertMWTAResult(gNode.rest, sutLine: el, xctLine: xl)
            assertActions(d.node.onEntry + d.node.onExit, expectedOutput: "entry1exit1", xctLine: xl)
        }

        func assertEmpty(_ d: Define, xctLine: UInt = #line) {
            XCTAssertEqual(0, d.node.rest.count, line: xctLine)
        }

        let s = SuperState { mwtaBlock }

        /// define with superstate and no other transitions
        assertDefine(define(1, adopts: s, onEntry: entry1, onExit: exit1))
        assertDefine(define(1, adopts: s, onEntry: entry1, onExit: exit1Async))
        assertDefine(define(1, adopts: s, onEntry: entry1Async, onExit: exit1))
        assertDefine(define(1, adopts: s, onEntry: entry1Async, onExit: exit1Async))

        /// define with no superstate and transitions
        assertDefine(define(1, onEntry: entry1, onExit: exit1) { mwtaBlock })
        assertDefine(define(1, onEntry: entry1, onExit: exit1Async) { mwtaBlock })
        assertDefine(define(1, onEntry: entry1Async, onExit: exit1) { mwtaBlock })
        assertDefine(define(1, onEntry: entry1Async, onExit: exit1Async) { mwtaBlock })

        /// Define (struct) with superstate and no other transitions
        assertDefine(Define(1, adopts: s, onEntry: entry1, onExit: exit1))
        assertDefine(Define(1, adopts: s, onEntry: entry1, onExit: exit1Async))
        assertDefine(Define(1, adopts: s, onEntry: entry1Async, onExit: exit1))
        assertDefine(Define(1, adopts: s, onEntry: entry1Async, onExit: exit1Async))

        /// Define (struct) with no superstate and transitions
        assertDefine(Define(1, onEntry: entry1, onExit: exit1) { mwtaBlock })
        assertDefine(Define(1, onEntry: entry1, onExit: exit1Async) { mwtaBlock })
        assertDefine(Define(1, onEntry: entry1Async, onExit: exit1) { mwtaBlock })
        assertDefine(Define(1, onEntry: entry1Async, onExit: exit1Async) { mwtaBlock })

        /// technically valid/non-empty but need to flag empty trailing block
        /// empty define with superstate
        assertEmpty(define(1, adopts: s, onEntry: entry1, onExit: exit1) { })
        assertEmpty(define(1, adopts: s, onEntry: entry1Async, onExit: exit1) { })
        assertEmpty(define(1, adopts: s, onEntry: entry1, onExit: exit1Async) { })
        assertEmpty(define(1, adopts: s, onEntry: entry1Async, onExit: exit1Async) { })

        /// empty define with superstate
        assertEmpty(define(1, onEntry: entry1, onExit: exit1) { })
        assertEmpty(define(1, onEntry: entry1Async, onExit: exit1) { })
        assertEmpty(define(1, onEntry: entry1, onExit: exit1Async) { })
        assertEmpty(define(1, onEntry: entry1Async, onExit: exit1Async) { })

        /// technically valid/non-empty but need to flag empty trailing block
        /// empty Define (struct) with superstate
        assertEmpty(Define(1, adopts: s, onEntry: entry1, onExit: exit1) { })
        assertEmpty(Define(1, adopts: s, onEntry: entry1Async, onExit: exit1) { })
        assertEmpty(Define(1, adopts: s, onEntry: entry1, onExit: exit1Async) { })
        assertEmpty(Define(1, adopts: s, onEntry: entry1Async, onExit: exit1Async) { })

        /// empty Define (struct) with superstate
        assertEmpty(Define(1, onEntry: entry1, onExit: exit1) { })
        assertEmpty(Define(1, onEntry: entry1Async, onExit: exit1) { })
        assertEmpty(Define(1, onEntry: entry1, onExit: exit1Async) { })
        assertEmpty(Define(1, onEntry: entry1Async, onExit: exit1Async) { })
    }

    func testDefineAddsSuperStateEntryExitActions() {
        let s1 = SuperState(onEntry: entry1, onExit: exit1) {
            matching(P.a) | when(1, or: 2) | then(1) | pass
            when(1, or: 2) | then(1) | pass
        }

        let d1 = define(1, adopts: s1, s1, onEntry: entry2, onExit: exit2)
        let d2 = Define(1, adopts: s1, s1, onEntry: entry2, onExit: exit2)

        assertActions(d1.node.onEntry, expectedOutput: "entry1entry1entry2")
        assertActions(d1.node.onExit, expectedOutput: "exit1exit1exit2")
        assertActions(d2.node.onEntry, expectedOutput: "entry1entry1entry2")
        assertActions(d2.node.onExit, expectedOutput: "exit1exit1exit2")
    }

    func testDefineAddsMultipleSuperStateNodes() {
        let l1 = #line + 1; let s1 = SuperState(onEntry: entry1, onExit: exit1) {
            matching(P.a) | when(1, or: 2) | then(1) | pass
                            when(1, or: 2) | then(1) | pass
        }

        let g1 = define(1, adopts: s1, s1, onEntry: entry1, onExit: exit1)
            .node
            .rest[0] as! GivenNode
        let g2 = Define(1, adopts: s1, s1, onEntry: entry1, onExit: exit1)
            .node
            .rest[0] as! GivenNode

        assertMWTAResult(Array(g1.rest.prefix(2)), sutLine: l1)
        assertMWTAResult(Array(g1.rest.suffix(2)), sutLine: l1)
        assertMWTAResult(Array(g2.rest.prefix(2)), sutLine: l1)
        assertMWTAResult(Array(g2.rest.suffix(2)), sutLine: l1)
    }

    func testDefineAddsBlockAndSuperStateNodesTogetherParentFirst() {
        func assertDefine(_ n: DefineNode, line: UInt = #line) {
            func castRest<T: Node, U: Node>(_ n: [U], to: T.Type) -> [T] {
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

            assertActions(actions.map(\.actions).flattened,
                          expectedOutput: "passpass",
                          xctLine: line)
        }

        let s = SuperState            { when(1) | then(1) | pass }
        let d1 = define(1, adopts: s) { when(2) | then(2) | pass }
        let d2 = Define(1, adopts: s) { when(2) | then(2) | pass }

        assertDefine(d1.node)
        assertDefine(d2.node)
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

    func testOptionalActions() {
        let l1 = #line; let mwtas1 = buildMWTA {
            matching(P.a) | when(1, or: 2) | then(1)
                            when(1, or: 2) | then(1)
        }

        let l2 = #line; let mwtas2 = buildMWTA {
            Matching(P.a) | When(1, or: 2) | Then(1)
                            When(1, or: 2) | Then(1)
        }

        assertMWTAResult(mwtas1.nodes, expectedOutput: "", sutLine: l1 + 1)
        assertMWTAResult(mwtas2.nodes, expectedOutput: "", sutLine: l2 + 1)
    }
}

class ActionsBlockTests: BlockTests {
    let eventOutput = ActionsBlockTests.defaultOutputWithEvent

    func abnComponents(of s: Sentence) -> (ActionsBlockNode, ActionsBlockNode) {
        let a1 = abn(s.node)
        let a2 = abn(a1.rest.first!)
        return (a1, a2)
    }

    func abn(_ n: any Node<DefaultIO>) -> ActionsBlockNode {
        n as! ActionsBlockNode
    }

    func assertMWTANode(
        _ b: ActionsBlockNode,
        event: Event = BlockTests.defaultEvent,
        expectedNodeOutput eo: String,
        expectedRestOutput er: String = BlockTests.defaultOutput,
        nodeLine nl: Int,
        restLine rl: Int,
        xctLine xl: UInt
    ) {
        assertActionsBlock(b, expectedOutput: eo, sutLine: nl, xctLine: xl)
        assertMWTAResult(b.rest, expectedOutput: er, sutLine: rl, xctLine: xl)
    }

    func assertMWANode(
        _ b: ActionsBlockNode,
        event: Event = BlockTests.defaultEvent,
        expectedNodeOutput eno: String,
        expectedRestOutput ero: String,
        nodeLine nl: Int,
        restLine rl: Int,
        xctLine xl: UInt
    ) {
        assertActionsBlock(b, expectedOutput: eno, sutLine: nl, xctLine: xl)
        assertMWAResult(b.rest, expectedOutput: ero, sutLine: rl, xctLine: xl)
    }

    func assertMTANode(
        _ b: ActionsBlockNode,
        event: Event = BlockTests.defaultEvent,
        expectedNodeOutput eno: String,
        expectedRestOutput ero: String,
        nodeLine nl: Int,
        restLine rl: Int,
        xctLine xl: UInt
    ) {
        assertActionsBlock(b, expectedOutput: eno, sutLine: nl, xctLine: xl)
        assertMTAResult(b.rest, expectedOutput: ero, sutLine: rl, xctLine: xl)
    }

    func assertActionsBlock(
        _ b: ActionsBlockNode,
        event: Event = BlockTests.defaultEvent,
        expectedOutput eo: String = BlockTests.defaultOutput,
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) {
        assertNeverEmptyNode(b, caller: "actions", sutLine: sl, xctLine: xl)
        assertActions(b.actions, event: event, expectedOutput: eo, xctLine: xl)
    }

    func testMWTABlocks() {
        func assertMWTA(
            _ b: Internal.MWTASentence,
            expectedNodeOutput eo: String = Self.defaultOutput,
            expectedRestOutput er: String = Self.defaultOutput,
            sutLine sl: Int = #line,
            restLine rl: Int = mwtaLine,
            xctLine xl: UInt = #line
        ) {
            assertMWTANode(abn(b.node),
                           expectedNodeOutput: eo,
                           expectedRestOutput: er,
                           nodeLine: sl,
                           restLine: rl,
                           xctLine: xl)
        }

        assertMWTA(actions(pass) { mwtaBlock })
        assertMWTA(Actions(pass) { mwtaBlock })
        assertMWTA(Actions([pass, pass]) { mwtaBlock },
                   expectedNodeOutput: "passpass") // internal only

        assertMWTA(actions(passAsync) { mwtaBlock })
        assertMWTA(Actions(passAsync) { mwtaBlock })
        assertMWTA(Actions([passAsync, passAsync]) { mwtaBlock },
                   expectedNodeOutput: "passpass") // internal only

        assertMWTA(Actions(passWithEvent) { mwtaBlockWithEvent },
                   expectedNodeOutput: eventOutput,
                   expectedRestOutput: eventOutput,
                   restLine: mwtaLineWithEvent)
        assertMWTA(actions(passWithEvent) { mwtaBlockWithEvent },
                   expectedNodeOutput: eventOutput,
                   expectedRestOutput: eventOutput,
                   restLine: mwtaLineWithEvent)
        assertMWTA(Actions([passWithEvent, passWithEvent]) { mwtaBlockWithEvent },
                   expectedNodeOutput: eventOutput + eventOutput,
                   expectedRestOutput: eventOutput,
                   restLine: mwtaLineWithEvent) // internal only

        assertMWTA(Actions(passWithEventAsync) { mwtaBlockWithEvent },
                   expectedNodeOutput: eventOutput,
                   expectedRestOutput: eventOutput,
                   restLine: mwtaLineWithEvent)
        assertMWTA(actions(passWithEventAsync) { mwtaBlockWithEvent },
                   expectedNodeOutput: eventOutput,
                   expectedRestOutput: eventOutput,
                   restLine: mwtaLineWithEvent)
        assertMWTA(Actions([passWithEventAsync, passWithEventAsync]) { mwtaBlockWithEvent },
                   expectedNodeOutput: eventOutput + eventOutput,
                   expectedRestOutput: eventOutput,
                   restLine: mwtaLineWithEvent) // internal only
    }

    func testMWABlocks() {
        func assertMWA(
            _ b: Internal.MWASentence,
            expectedNodeOutput eno: String = BlockTests.defaultOutput,
            expectedRestOutput ero: String = BlockTests.defaultOutput,
            nodeLine sl: Int = #line,
            restLine rl: Int = #line,
            xctLine xl: UInt = #line
        ) {
            assertMWANode(abn(b.node),
                          expectedNodeOutput: eno,
                          expectedRestOutput: ero,
                          nodeLine: sl,
                          restLine: rl,
                          xctLine: xl)
        }

        assertMWA(actions(pass) { mwaBlock }, restLine: mwaLine)
        assertMWA(Actions(pass) { mwaBlock }, restLine: mwaLine)
        assertMWA(actions(pass) { Matching(P.a) | When(1, or: 2) }, expectedRestOutput: "")
        assertMWA(Actions(pass) { Matching(P.a) | When(1, or: 2) }, expectedRestOutput: "")

        assertMWA(actions(passAsync) { mwaBlock }, restLine: mwaLine)
        assertMWA(Actions(passAsync) { mwaBlock }, restLine: mwaLine)
        assertMWA(actions(passAsync) { Matching(P.a) | When(1, or: 2) }, expectedRestOutput: "")
        assertMWA(Actions(passAsync) { Matching(P.a) | When(1, or: 2) }, expectedRestOutput: "")

        assertMWA(Actions(passWithEvent) { mwaBlockWithEvent },
                  expectedNodeOutput: eventOutput,
                  expectedRestOutput: eventOutput,
                  restLine: mwaLineWithEvent)
        assertMWA(actions(passWithEvent) { mwaBlockWithEvent },
                  expectedNodeOutput: eventOutput,
                  expectedRestOutput: eventOutput,
                  restLine: mwaLineWithEvent)

        assertMWA(Actions(passWithEventAsync) { mwaBlockWithEvent },
                  expectedNodeOutput: eventOutput,
                  expectedRestOutput: eventOutput,
                  restLine: mwaLineWithEvent)
        assertMWA(actions(passWithEventAsync) { mwaBlockWithEvent },
                  expectedNodeOutput: eventOutput,
                  expectedRestOutput: eventOutput,
                  restLine: mwaLineWithEvent)
    }

    func testMTABlocks() {
        func assertMTA(
            _ b: Internal.MTASentence,
            expectedNodeOutput eno: String = BlockTests.defaultOutput,
            expectedRestOutput ero: String = BlockTests.defaultOutput,
            nodeLine nl: Int = #line,
            restLine rl: Int = #line,
            xctLine xl: UInt = #line
        ) {
            assertMTANode(abn(b.node),
                          expectedNodeOutput: eno,
                          expectedRestOutput: ero,
                          nodeLine: nl,
                          restLine: rl,
                          xctLine: xl)
        }

        assertMTA(actions(pass) { mtaBlock }, restLine: mtaLine)
        assertMTA(Actions(pass) { mtaBlock }, restLine: mtaLine)
        assertMTA(actions(pass) { Matching(P.a) | Then(1) }, expectedRestOutput: "")
        assertMTA(Actions(pass) { Matching(P.a) | Then(1) }, expectedRestOutput: "")

        assertMTA(actions(passAsync) { mtaBlock }, restLine: mtaLine)
        assertMTA(Actions(passAsync) { mtaBlock }, restLine: mtaLine)
        assertMTA(actions(passAsync) { Matching(P.a) | Then(1) }, expectedRestOutput: "")
        assertMTA(Actions(passAsync) { Matching(P.a) | Then(1) }, expectedRestOutput: "")

        assertMTA(Actions(passWithEvent) { mtaBlockWithEvent },
                  expectedNodeOutput: eventOutput,
                  expectedRestOutput: eventOutput,
                  restLine: mtaLineWithEvent)
        assertMTA(actions(passWithEvent) { mtaBlockWithEvent },
                  expectedNodeOutput: eventOutput,
                  expectedRestOutput: eventOutput,
                  restLine: mtaLineWithEvent)

        assertMTA(Actions(passWithEventAsync) { mtaBlockWithEvent },
                  expectedNodeOutput: eventOutput,
                  expectedRestOutput: eventOutput,
                  restLine: mtaLineWithEvent)
        assertMTA(actions(passWithEventAsync) { mtaBlockWithEvent },
                  expectedNodeOutput: eventOutput,
                  expectedRestOutput: eventOutput,
                  restLine: mtaLineWithEvent)

    }

    func testCompoundMWTABlocks() {
        func assertMWTA(
            _ b: Internal.MWTASentence,
            expectedNodeOutput eo: String = BlockTests.defaultOutput,
            expectedRestOutput er: String = BlockTests.defaultOutput,
            sutLine sl: Int = #line,
            restLine rl: Int = mwtaLine,
            xctLine xl: UInt = #line
        ) {
            let c = abnComponents(of: b)

            assertActionsBlock(c.0, expectedOutput: eo, sutLine: sl, xctLine: xl)
            assertMWTANode(c.1,
                           expectedNodeOutput: eo,
                           expectedRestOutput: er,
                           nodeLine: sl,
                           restLine: rl,
                           xctLine: xl)
        }

        assertMWTA(actions(pass) { actions(pass) { mwtaBlock } })
        assertMWTA(Actions(pass) { Actions(pass) { mwtaBlock } })

        assertMWTA(actions(passAsync) { actions(passAsync) { mwtaBlock } })
        assertMWTA(Actions(passAsync) { Actions(passAsync) { mwtaBlock } })

        assertMWTA(actions(pass) { actions(passAsync) { mwtaBlock } })
        assertMWTA(Actions(pass) { Actions(passAsync) { mwtaBlock } })

        assertMWTA(actions(passWithEvent) { actions(passWithEvent) { mwtaBlockWithEvent }},
                   expectedNodeOutput: eventOutput,
                   expectedRestOutput: eventOutput,
                   restLine: mwtaLineWithEvent)
        assertMWTA(Actions(passWithEvent) { Actions(passWithEvent) { mwtaBlockWithEvent }},
                   expectedNodeOutput: eventOutput,
                   expectedRestOutput: eventOutput,
                   restLine: mwtaLineWithEvent)

        assertMWTA(actions(passWithEventAsync) { actions(passWithEventAsync) {
            mwtaBlockWithEvent
        }},
                   expectedNodeOutput: eventOutput,
                   expectedRestOutput: eventOutput,
                   restLine: mwtaLineWithEvent)
        assertMWTA(Actions(passWithEventAsync) { Actions(passWithEventAsync) {
            mwtaBlockWithEvent
        }},
                   expectedNodeOutput: eventOutput,
                   expectedRestOutput: eventOutput,
                   restLine: mwtaLineWithEvent)

        assertMWTA(actions(passWithEvent) { actions(passWithEventAsync) {
            mwtaBlockWithEvent
        }},
                   expectedNodeOutput: eventOutput,
                   expectedRestOutput: eventOutput,
                   restLine: mwtaLineWithEvent)
        assertMWTA(Actions(passWithEvent) { Actions(passWithEventAsync) {
            mwtaBlockWithEvent
        }},
                   expectedNodeOutput: eventOutput,
                   expectedRestOutput: eventOutput,
                   restLine: mwtaLineWithEvent)
    }

    func testCompoundMWABlocks() {
        func assertMWA(
            _ b: Internal.MWASentence,
            expectedNodeOutput eno: String = BlockTests.defaultOutput,
            expectedRestOutput ero: String = BlockTests.defaultOutput,
            sutLine sl: Int = #line,
            restLine rl: Int = mwaLine,
            xctLine xl: UInt = #line
        ) {
            let c = abnComponents(of: b)

            assertActionsBlock(c.0, expectedOutput: eno, sutLine: sl, xctLine: xl)
            assertMWANode(c.1,
                          expectedNodeOutput: eno,
                          expectedRestOutput: ero,
                          nodeLine: sl,
                          restLine: rl,
                          xctLine: xl)
        }

        assertMWA(actions(pass) { actions(pass) { mwaBlock } })
        assertMWA(Actions(pass) { Actions(pass) { mwaBlock } })

        assertMWA(actions(passAsync) { actions(passAsync) { mwaBlock } })
        assertMWA(Actions(passAsync) { Actions(passAsync) { mwaBlock } })

        assertMWA(actions(pass) { actions(passAsync) { mwaBlock } })
        assertMWA(Actions(pass) { Actions(passAsync) { mwaBlock } })

        assertMWA(Actions(passWithEvent) { Actions(passWithEvent) { mwaBlockWithEvent }},
                  expectedNodeOutput: eventOutput,
                  expectedRestOutput: eventOutput,
                  restLine: mwaLineWithEvent)
        assertMWA(Actions(passWithEvent) { Actions(passWithEvent) { mwaBlockWithEvent }},
                  expectedNodeOutput: eventOutput,
                  expectedRestOutput: eventOutput,
                  restLine: mwaLineWithEvent)

        assertMWA(Actions(passWithEventAsync) { Actions(passWithEventAsync) { mwaBlockWithEvent }},
                  expectedNodeOutput: eventOutput,
                  expectedRestOutput: eventOutput,
                  restLine: mwaLineWithEvent)
        assertMWA(Actions(passWithEventAsync) { Actions(passWithEventAsync) { mwaBlockWithEvent }},
                  expectedNodeOutput: eventOutput,
                  expectedRestOutput: eventOutput,
                  restLine: mwaLineWithEvent)

        assertMWA(Actions(passWithEvent) { Actions(passWithEventAsync) { mwaBlockWithEvent }},
                  expectedNodeOutput: eventOutput,
                  expectedRestOutput: eventOutput,
                  restLine: mwaLineWithEvent)
        assertMWA(Actions(passWithEvent) { Actions(passWithEventAsync) { mwaBlockWithEvent }},
                  expectedNodeOutput: eventOutput,
                  expectedRestOutput: eventOutput,
                  restLine: mwaLineWithEvent)
    }

    func testCompoundMTABlocks() {
        func assertMTA(
            _ b: Internal.MTASentence,
            expectedNodeOutput eno: String = BlockTests.defaultOutput,
            expectedRestOutput ero: String = BlockTests.defaultOutput,
            sutLine sl: Int = #line,
            restLine rl: Int = mtaLine,
            xctLine xl: UInt = #line
        ) {
            let c = abnComponents(of: b)

            assertActionsBlock(c.0, expectedOutput: eno, sutLine: sl, xctLine: xl)
            assertMTANode(c.1,
                          expectedNodeOutput: eno,
                          expectedRestOutput: ero,
                          nodeLine: sl,
                          restLine: rl,
                          xctLine: xl)
        }

        assertMTA(actions(pass) { actions(pass) { mtaBlock } })
        assertMTA(Actions(pass) { Actions(pass) { mtaBlock } })

        assertMTA(actions(passAsync) { actions(passAsync) { mtaBlock } })
        assertMTA(Actions(passAsync) { Actions(passAsync) { mtaBlock } })

        assertMTA(actions(pass) { actions(passAsync) { mtaBlock } })
        assertMTA(Actions(pass) { Actions(passAsync) { mtaBlock } })

        assertMTA(actions(passWithEvent) { actions(passWithEvent) { mtaBlockWithEvent }},
                  expectedNodeOutput: eventOutput,
                  expectedRestOutput: eventOutput,
                  restLine: mtaLineWithEvent)
        assertMTA(Actions(passWithEvent) { Actions(passWithEvent) { mtaBlockWithEvent }},
                  expectedNodeOutput: eventOutput,
                  expectedRestOutput: eventOutput,
                  restLine: mtaLineWithEvent)

        assertMTA(actions(passWithEventAsync) { actions(passWithEventAsync) { mtaBlockWithEvent }},
                  expectedNodeOutput: eventOutput,
                  expectedRestOutput: eventOutput,
                  restLine: mtaLineWithEvent)
        assertMTA(Actions(passWithEventAsync) { Actions(passWithEventAsync) { mtaBlockWithEvent }},
                  expectedNodeOutput: eventOutput,
                  expectedRestOutput: eventOutput,
                  restLine: mtaLineWithEvent)

        assertMTA(actions(passWithEvent) { actions(passWithEventAsync) { mtaBlockWithEvent }},
                  expectedNodeOutput: eventOutput,
                  expectedRestOutput: eventOutput,
                  restLine: mtaLineWithEvent)
        assertMTA(Actions(passWithEvent) { Actions(passWithEventAsync) { mtaBlockWithEvent }},
                  expectedNodeOutput: eventOutput,
                  expectedRestOutput: eventOutput,
                  restLine: mtaLineWithEvent)
    }
}

class MatchingBlockTests: BlockTests {
    func mbnComponents(of s: Sentence) -> (MatchBlockNode, MatchBlockNode) {
        let a1 = mbn(s.node)
        let a2 = mbn(a1.rest.first!)
        return (a1, a2)
    }

    func mbn(_ n: any Node<DefaultIO>) -> MatchBlockNode {
        n as! MatchBlockNode
    }

    func assertMWTANode(
        _ b: MatchBlockNode,
        any: [any Predicate],
        all: [any Predicate],
        nodeLine nl: Int,
        restLine rl: Int,
        xctLine xl: UInt
    ) {
        assertMatchBlock(b, any: any, all: all, sutLine: nl, xctLine: xl)
        assertMWTAResult(b.rest, sutLine: rl, xctLine: xl)
    }

    func assertMWANode(
        _ b: MatchBlockNode,
        any: [any Predicate],
        all: [any Predicate],
        nodeLine nl: Int,
        restLine rl: Int,
        xctLine xl: UInt
    ) {
        assertMatchBlock(b, any: any, all: all, sutLine: nl, xctLine: xl)
        assertMWAResult(b.rest, sutLine: rl, xctLine: xl)
    }

    func assertMTANode(
        _ b: MatchBlockNode,
        any: [any Predicate],
        all: [any Predicate],
        nodeLine nl: Int,
        restLine rl: Int,
        xctLine xl: UInt
    ) {
        assertMatchBlock(b, any: any, all: all, sutLine: nl, xctLine: xl)
        assertMTAResult(b.rest, sutLine: rl, xctLine: xl)
    }

    func assertMatchBlock(
        _ b: MatchBlockNode,
        any: [any Predicate],
        all: [any Predicate],
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) {
        assertNeverEmptyNode(b, caller: "matching", sutLine: sl, xctLine: xl)
        assertMatchNode(b, any: [any], all: all, sutLine: sl, xctLine: xl)
    }

    func testMWTABlocks() {
        func assertMWTABlock(
            _ b: Internal.MWTASentence,
            any: [any Predicate] = [],
            all: [any Predicate] = [],
            nodeLine sl: Int,
            xctLine xl: UInt = #line
        ) {
            assertMWTANode(
                mbn(b.node),
                any: any,
                all: all,
                nodeLine: sl,
                restLine: mwtaLine,
                xctLine: xl
            )
        }

        let l1 = #line; let m1 = matching(Q.a) { mwtaBlock }
        let l2 = #line; let m2 = Matching(Q.a) { mwtaBlock }

        assertMWTABlock(m1, all: [Q.a], nodeLine: l1)
        assertMWTABlock(m2, all: [Q.a], nodeLine: l2)

        let l3 = #line; let m3 = matching(Q.a, and: R.a) { mwtaBlock }
        let l4 = #line; let m4 = Matching(Q.a, and: R.a) { mwtaBlock }

        assertMWTABlock(m3, all: [Q.a, R.a], nodeLine: l3)
        assertMWTABlock(m4, all: [Q.a, R.a], nodeLine: l4)

        let l5 = #line; let m5 = matching(Q.a, or: Q.b) { mwtaBlock }
        let l6 = #line; let m6 = Matching(Q.a, or: Q.b) { mwtaBlock }

        assertMWTABlock(m5, any: [Q.a, Q.b], nodeLine: l5)
        assertMWTABlock(m6, any: [Q.a, Q.b], nodeLine: l6)

        let l7 = #line; let m7 = matching(Q.a, or: Q.b, and: R.a, S.a) { mwtaBlock }
        let l8 = #line; let m8 = Matching(Q.a, or: Q.b, and: R.a, S.a) { mwtaBlock }

        assertMWTABlock(m7, any: [Q.a, Q.b], all: [R.a, S.a], nodeLine: l7)
        assertMWTABlock(m8, any: [Q.a, Q.b], all: [R.a, S.a], nodeLine: l8)
    }

    func testMWABlocks() {
        func assertMWABlock(
            _ b: Internal.MWASentence,
            any: [any Predicate] = [],
            all: [any Predicate] = [],
            nodeLine nl: Int,
            xctLine xl: UInt = #line
        ) {
            assertMWANode(mbn(b.node),
                          any: any,
                          all: all,
                          nodeLine: nl,
                          restLine: mwaLine,
                          xctLine: xl)
        }

        let l1 = #line; let m1 = matching(Q.a) { mwaBlock }
        let l2 = #line; let m2 = Matching(Q.a) { mwaBlock }

        assertMWABlock(m1, all: [Q.a], nodeLine: l1)
        assertMWABlock(m2, all: [Q.a], nodeLine: l2)

        let l3 = #line; let m3 = matching(Q.a, and: R.a) { mwaBlock }
        let l4 = #line; let m4 = Matching(Q.a, and: R.a) { mwaBlock }

        assertMWABlock(m3, all: [Q.a, R.a], nodeLine: l3)
        assertMWABlock(m4, all: [Q.a, R.a], nodeLine: l4)

        let l5 = #line; let m5 = matching(Q.a, or: Q.b) { mwaBlock }
        let l6 = #line; let m6 = Matching(Q.a, or: Q.b) { mwaBlock }

        assertMWABlock(m5, any: [Q.a, Q.b], nodeLine: l5)
        assertMWABlock(m6, any: [Q.a, Q.b], nodeLine: l6)

        let l7 = #line; let m7 = matching(Q.a, or: Q.b, and: R.a, S.a)  { mwaBlock }
        let l8 = #line; let m8 = Matching(Q.a, or: Q.b, and: R.a, S.a)  { mwaBlock }

        assertMWABlock(m7, any: [Q.a, Q.b], all: [R.a, S.a], nodeLine: l7)
        assertMWABlock(m8, any: [Q.a, Q.b], all: [R.a, S.a], nodeLine: l8)
    }

    func testMTABlocks() {
        func assertMTABlock(
            _ b: Internal.MTASentence,
            any: [any Predicate] = [],
            all: [any Predicate] = [],
            nodeLine nl: Int,
            xctLine xl: UInt = #line
        ) {
            assertMTANode(mbn(b.node),
                          any: any,
                          all: all,
                          nodeLine: nl,
                          restLine: mtaLine,
                          xctLine: xl)
        }

        let l1 = #line; let m1 = matching(Q.a) { mtaBlock }
        let l2 = #line; let m2 = Matching(Q.a) { mtaBlock }

        assertMTABlock(m1, all: [Q.a], nodeLine: l1)
        assertMTABlock(m2, all: [Q.a], nodeLine: l2)

        let l3 = #line; let m3 = matching(Q.a, and: R.a) { mtaBlock }
        let l4 = #line; let m4 = Matching(Q.a, and: R.a) { mtaBlock }

        assertMTABlock(m3, all: [Q.a, R.a], nodeLine: l3)
        assertMTABlock(m4, all: [Q.a, R.a], nodeLine: l4)

        let l5 = #line; let m5 = matching(Q.a, or: Q.b) { mtaBlock }
        let l6 = #line; let m6 = Matching(Q.a, or: Q.b) { mtaBlock }

        assertMTABlock(m5, any: [Q.a, Q.b], nodeLine: l5)
        assertMTABlock(m6, any: [Q.a, Q.b], nodeLine: l6)

        let l7 = #line; let m7 = matching(Q.a, or: Q.b, and: R.a, S.a)  { mtaBlock }
        let l8 = #line; let m8 = Matching(Q.a, or: Q.b, and: R.a, S.a)  { mtaBlock }

        assertMTABlock(m7, any: [Q.a, Q.b], all: [R.a, S.a], nodeLine: l7)
        assertMTABlock(m8, any: [Q.a, Q.b], all: [R.a, S.a], nodeLine: l8)
    }

    func testCompoundMWTABlocks() {
        func assertCompoundMWTABlock(
            _ b: Internal.MWTASentence,
            any: [any Predicate] = [],
            all: [any Predicate] = [],
            nodeLine nl: Int,
            xctLine xl: UInt = #line
        ) {
            let c = mbnComponents(of: b)

            assertMatchBlock(c.0, any: any, all: all, sutLine: nl, xctLine: xl)
            assertMWTANode(c.1,
                           any: any,
                           all: all,
                           nodeLine: nl,
                           restLine: mwtaLine,
                           xctLine: xl)
        }

        let l1 = #line; let m1 = matching(Q.a) { matching(Q.a) { mwtaBlock } }
        let l2 = #line; let m2 = Matching(Q.a) { Matching(Q.a) { mwtaBlock } }

        assertCompoundMWTABlock(m1, all: [Q.a], nodeLine: l1)
        assertCompoundMWTABlock(m2, all: [Q.a], nodeLine: l2)
    }

    func testCompoundMWABlocks() {
        func assertCompoundMWABlock(
            _ b: Internal.MWASentence,
            any: [any Predicate] = [],
            all: [any Predicate] = [],
            nodeLine nl: Int,
            xctLine xl: UInt = #line
        ) {
            let c = mbnComponents(of: b)

            assertMatchBlock(c.0, any: any, all: all, sutLine: nl, xctLine: xl)
            assertMWANode(c.1,
                          any: any,
                          all: all,
                          nodeLine: nl,
                          restLine: mwaLine,
                          xctLine: xl)
        }

        let l1 = #line; let m1 = matching(Q.a) { matching(Q.a) { mwaBlock } }
        let l2 = #line; let m2 = Matching(Q.a) { Matching(Q.a) { mwaBlock } }

        assertCompoundMWABlock(m1, all: [Q.a], nodeLine: l1)
        assertCompoundMWABlock(m2, all: [Q.a], nodeLine: l2)
    }

    func testCompoundMTABlocks() {
        func assertCompoundMTABlock(
            _ b: Internal.MTASentence,
            any: [any Predicate] = [],
            all: [any Predicate] = [],
            nodeLine nl: Int,
            xctLine xl: UInt = #line
        ) {
            let c = mbnComponents(of: b)

            assertMatchBlock(c.0, any: any, all: all, sutLine: nl, xctLine: xl)
            assertMTANode(c.1,
                          any: any,
                          all: all,
                          nodeLine: nl,
                          restLine: mtaLine,
                          xctLine: xl)
        }

        let l1 = #line; let m1 = matching(Q.a) { matching(Q.a) { mtaBlock } }
        let l2 = #line; let m2 = Matching(Q.a) { Matching(Q.a) { mtaBlock } }

        assertCompoundMTABlock(m1, all: [Q.a], nodeLine: l1)
        assertCompoundMTABlock(m2, all: [Q.a], nodeLine: l2)
    }
}

class ConditionBlockTests: BlockTests {
    func mbnComponents(of s: Sentence) -> (MatchBlockNode, MatchBlockNode) {
        let a1 = mbn(s.node)
        let a2 = mbn(a1.rest.first!)
        return (a1, a2)
    }

    func mbn(_ n: any Node<DefaultIO>) -> MatchBlockNode {
        n as! MatchBlockNode
    }

    func assertMWTANode(
        _ b: MatchBlockNode,
        expected: Bool,
        nodeLine nl: Int,
        restLine rl: Int,
        xctLine xl: UInt
    ) {
        assertMatchBlock(b, expected: expected, sutLine: nl, xctLine: xl)
        assertMWTAResult(b.rest, sutLine: rl, xctLine: xl)
    }

    func assertMWANode(
        _ b: MatchBlockNode,
        expected: Bool,
        nodeLine nl: Int,
        restLine rl: Int,
        xctLine xl: UInt
    ) {
        assertMatchBlock(b, expected: expected, sutLine: nl, xctLine: xl)
        assertMWAResult(b.rest, sutLine: rl, xctLine: xl)
    }

    func assertMTANode(
        _ b: MatchBlockNode,
        expected: Bool,
        nodeLine nl: Int,
        restLine rl: Int,
        xctLine xl: UInt
    ) {
        assertMatchBlock(b, expected: expected, sutLine: nl, xctLine: xl)
        assertMTAResult(b.rest, sutLine: rl, xctLine: xl)
    }

    func assertMatchBlock(
        _ b: MatchBlockNode,
        expected: Bool,
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) {
        assertNeverEmptyNode(b, caller: "condition", sutLine: sl, xctLine: xl)
        assertMatchNode(b, condition: expected, caller: "condition", sutLine: sl, xctLine: xl)
    }

    func testMWTABlocks() {
        func assertMWTABlock(
            _ b: Internal.MWTASentence,
            condition: Bool,
            nodeLine sl: Int,
            xctLine xl: UInt = #line
        ) {
            assertMWTANode(
                mbn(b.node),
                expected: condition,
                nodeLine: sl,
                restLine: mwtaLine,
                xctLine: xl
            )
        }

        let l1 = #line; let c1 = condition({ false }) { mwtaBlock }
        let l2 = #line; let c2 = Condition({ false }) { mwtaBlock }

        assertMWTABlock(c1, condition: false, nodeLine: l1)
        assertMWTABlock(c2, condition: false, nodeLine: l2)
    }

    func testMWABlocks() {
        func assertMWABlock(
            _ b: Internal.MWASentence,
            condition: Bool,
            nodeLine nl: Int,
            xctLine xl: UInt = #line
        ) {
            assertMWANode(mbn(b.node),
                          expected: condition,
                          nodeLine: nl,
                          restLine: mwaLine,
                          xctLine: xl)
        }

        let l1 = #line; let c1 = condition({ false }) { mwaBlock }
        let l2 = #line; let c2 = Condition({ false }) { mwaBlock }

        assertMWABlock(c1, condition: false, nodeLine: l1)
        assertMWABlock(c2, condition: false, nodeLine: l2)
    }

    func testMTABlocks() {
        func assertMTABlock(
            _ b: Internal.MTASentence,
            condition: Bool,
            nodeLine nl: Int,
            xctLine xl: UInt = #line
        ) {
            assertMTANode(mbn(b.node),
                          expected: condition,
                          nodeLine: nl,
                          restLine: mtaLine,
                          xctLine: xl)
        }

        let l1 = #line; let c1 = condition({ false }) { mtaBlock }
        let l2 = #line; let c2 = Condition({ false }) { mtaBlock }

        assertMTABlock(c1, condition: false, nodeLine: l1)
        assertMTABlock(c2, condition: false, nodeLine: l2)
    }

    func testCompoundMWTABlocks() {
        func assertCompoundMWTABlock(
            _ b: Internal.MWTASentence,
            condition: Bool,
            nodeLine nl: Int,
            xctLine xl: UInt = #line
        ) {
            let c = mbnComponents(of: b)

            assertMatchBlock(c.0, expected: condition, sutLine: nl, xctLine: xl)
            assertMWTANode(c.1,
                           expected: condition,
                           nodeLine: nl,
                           restLine: mwtaLine,
                           xctLine: xl)
        }

        let l1 = #line; let c1 = condition({ false }) { condition({ false }) { mwtaBlock } }
        let l2 = #line; let c2 = Condition({ false }) { Condition({ false }) { mwtaBlock } }

        assertCompoundMWTABlock(c1, condition: false, nodeLine: l1)
        assertCompoundMWTABlock(c2, condition: false, nodeLine: l2)
    }

    func testCompoundMWABlocks() {
        func assertCompoundMWABlock(
            _ b: Internal.MWASentence,
            condition: Bool,
            nodeLine nl: Int,
            xctLine xl: UInt = #line
        ) {
            let c = mbnComponents(of: b)

            assertMatchBlock(c.0, expected: condition, sutLine: nl, xctLine: xl)
            assertMWANode(c.1,
                          expected: condition,
                          nodeLine: nl,
                          restLine: mwaLine,
                          xctLine: xl)
        }

        let l1 = #line; let c1 = condition({ false }) { condition({ false }) { mwaBlock } }
        let l2 = #line; let c2 = Condition({ false }) { Condition({ false }) { mwaBlock } }

        assertCompoundMWABlock(c1, condition: false, nodeLine: l1)
        assertCompoundMWABlock(c2, condition: false, nodeLine: l2)
    }

    func testCompoundMTABlocks() {
        func assertCompoundMTABlock(
            _ b: Internal.MTASentence,
            condition: Bool,
            nodeLine nl: Int,
            xctLine xl: UInt = #line
        ) {
            let c = mbnComponents(of: b)

            assertMatchBlock(c.0, expected: condition, sutLine: nl, xctLine: xl)
            assertMTANode(c.1,
                          expected: condition,
                          nodeLine: nl,
                          restLine: mtaLine,
                          xctLine: xl)
        }

        let l1 = #line; let c1 = condition({ false }) { condition({ false }) { mtaBlock } }
        let l2 = #line; let c2 = Condition({ false }) { Condition({ false }) { mtaBlock } }

        assertCompoundMTABlock(c1, condition: false, nodeLine: l1)
        assertCompoundMTABlock(c2, condition: false, nodeLine: l2)
    }
}

class WhenBlockTests: BlockTests {
    func assert(
        _ b: Internal.MWTASentence,
        events: [Int] = [1, 2],
        nodeLine nl: Int,
        restLine rl: Int,
        xctLine xl: UInt = #line
    ) {
        let node = b.node as! WhenBlockNode
        assertWhenNode(node, events: events, sutLine: nl, xctLine: xl)
        assertMTAResult(node.rest, sutLine: rl, xctLine: xl)
    }

    func assert(
        _ b: Internal.MWASentence,
        expectedOutput eo: String = BlockTests.defaultOutput,
        events: [Int] = [1, 2],
        nodeLine nl: Int,
        restLine rl: Int,
        xctLine xl: UInt = #line
    ) {
        let node = b.node as! WhenBlockNode
        assertWhenNode(node, events: events, sutLine: nl, xctLine: xl)
        let actionsNode = node.rest.first as! ActionsNode
        assertActions(actionsNode.actions, expectedOutput: eo, xctLine: xl)
        let matchNode = actionsNode.rest.first as! MatchNode
        assertMatchNode(matchNode, all: [P.a], sutLine: rl, xctLine: xl)
    }

    func testWhenBlockWithMTA() {
        let l1 = #line; let w1 = when(1, or: 2) { mtaBlock }
        let l2 = #line; let w2 = When(1, or: 2) { mtaBlock }

        assert(w1, nodeLine: l1, restLine: mtaLine)
        assert(w2, nodeLine: l2, restLine: mtaLine)

        let l3 = #line; let w3 = when(1) { mtaBlock }
        let l4 = #line; let w4 = When(1) { mtaBlock }

        assert(w3, events: [1], nodeLine: l3, restLine: mtaLine)
        assert(w4, events: [1], nodeLine: l4, restLine: mtaLine)
    }

    func testWhenBlockWithMA() {
        let l1 = #line; let w1 = when(1, or: 2) { maBlockSync }
        let l2 = #line; let w2 = When(1, or: 2) { maBlockSync }

        assert(w1, nodeLine: l1, restLine: maLineSync)
        assert(w2, nodeLine: l2, restLine: maLineSync)

        let l3 = #line; let w3 = when(1) { maBlockSync }
        let l4 = #line; let w4 = When(1) { maBlockSync }

        assert(w3, events: [1], nodeLine: l3, restLine: maLineSync)
        assert(w4, events: [1], nodeLine: l4, restLine: maLineSync)

        let l5 = #line; let w5 = when(1, or: 2) { maBlockWithEventSync }
        let l6 = #line; let w6 = When(1, or: 2) { maBlockWithEventSync }

        assert(w5,
               expectedOutput: Self.defaultOutputWithEvent,
               nodeLine: l5,
               restLine: maLineWithEventSync)
        assert(w6,
               expectedOutput: Self.defaultOutputWithEvent,
               nodeLine: l6,
               restLine: maLineWithEventSync)

        let l7 = #line; let w7 = when(1) { maBlockWithEventSync }
        let l8 = #line; let w8 = When(1) { maBlockWithEventSync }

        assert(w7,
               expectedOutput: Self.defaultOutputWithEvent,
               events: [1],
               nodeLine: l7,
               restLine: maLineWithEventSync)
        assert(w8,
               expectedOutput: Self.defaultOutputWithEvent,
               events: [1],
               nodeLine: l8,
               restLine: maLineWithEventSync)
    }
}

class ThenBlockTests: BlockTests {
    func assert(
        _ b: Internal.MWTASentence,
        nodeLine nl: Int,
        restLine rl: Int,
        xctLine xl: UInt = #line
    ) {
        let node = b.node as! ThenBlockNode
        assertThenNode(node, state: 1, sutFile: #file, sutLine: nl, xctLine: xl)
        assertMWAResult(node.rest, sutLine: rl, xctLine: xl)
    }

    func assert(
        _ b: Internal.MTASentence,
        expectedOutput eo: String = BlockTests.defaultOutput,
        nodeLine nl: Int,
        restLine rl: Int,
        xctLine xl: UInt = #line
    ) {
        let node = b.node as! ThenBlockNode
        assertThenNode(node, state: 1, sutFile: #file, sutLine: nl, xctLine: xl)
        assertMAResult(node.rest, expectedOutput: eo, sutLine: rl, xctLine: xl)
    }

    func testThenBlockWithMTA() {
        let l1 = #line; let t1 = then(1) { mwaBlock }
        let l2 = #line; let t2 = Then(1) { mwaBlock }

        assert(t1, nodeLine: l1, restLine: mwaLine)
        assert(t2, nodeLine: l2, restLine: mwaLine)
    }

    func testThenBlockWithMA() {
        let l1 = #line; let w1 = then(1) { maBlockSync }
        let l2 = #line; let w2 = Then(1) { maBlockSync }

        assert(w1, nodeLine: l1, restLine: maLineSync)
        assert(w2, nodeLine: l2, restLine: maLineSync)

        let l3 = #line; let w3 = then(1) { maBlockAsync }
        let l4 = #line; let w4 = Then(1) { maBlockAsync }

        assert(w3, nodeLine: l3, restLine: maLineAsync)
        assert(w4, nodeLine: l4, restLine: maLineAsync)

        let l5 = #line; let w5 = then(1) { maBlockWithEventSync }
        let l6 = #line; let w6 = Then(1) { maBlockWithEventSync }

        assert(w5,
               expectedOutput: Self.defaultOutputWithEvent,
               nodeLine: l5,
               restLine: maLineWithEventSync)
        assert(w6,
               expectedOutput: Self.defaultOutputWithEvent,
               nodeLine: l6,
               restLine: maLineWithEventSync)

        let l7 = #line; let w7 = then(1) { maBlockWithEventAsync }
        let l8 = #line; let w8 = Then(1) { maBlockWithEventAsync }

        assert(w7,
               expectedOutput: Self.defaultOutputWithEvent,
               nodeLine: l7,
               restLine: maLineWithEventAsync)
        assert(w8,
               expectedOutput: Self.defaultOutputWithEvent,
               nodeLine: l8,
               restLine: maLineWithEventAsync)
    }
}

class OverrideBlockTests: BlockTests {
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
