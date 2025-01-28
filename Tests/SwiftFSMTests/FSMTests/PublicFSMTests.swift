import XCTest
@testable import SwiftFSM

final class PublicFSMTests: XCTestCase, ExpandedSyntaxBuilder {
    typealias State = Int
    typealias Event = Int

    enum P: Predicate { case a, b }

    typealias BaseType = BaseFSM<Int, Int> & FSMProtocol

    class FSMSpy: BaseType {
        typealias Event = Int
        typealias State = Int

        var log = [String]()

        private func log(_ caller: String = #function, args: [Any]) {
            log += [caller] + args.map(String.init(describing:))
        }

        func handleEventAsync(_ event: Int, predicates: [any Predicate]) async {
            log(args: predicates)
        }

        func handleEvent(_ event: Int, predicates: [any Predicate]) {
            log(args: predicates)
        }

        func buildTable(
            file: String = #file,
            line: Int = #line,
            _ block: () -> [Syntax.Define<Int, Int>]
        ) throws {
            log(args: [file, line, block()])
        }

        func reset() {
            log = []
        }

        func makeMatchResolvingNode(
            rest: [any Node<IntermediateIO>]
        ) -> any MatchResolvingNode {
            fatalError("never called")
        }
    }

    var fsm: FSM<Int, Int>!
    var spy: FSMSpy!

    override func setUp() {
        fsm = FSM(type: .eager, initialState: 1)
        spy = FSMSpy(initialState: 1)
        fsm.fsm = spy
    }

    func testCanInitPublicEagerFSM() {
        let fsm = FSM<Int, Int>(type: .eager,
                                initialState: 1,
                                actionsPolicy: .executeAlways)
        XCTAssertTrue(fsm.fsm is EagerFSM<Int, Int>)
        XCTAssertEqual(fsm.fsm.state, 1)
        XCTAssertEqual(fsm.fsm.stateActionsPolicy, .executeAlways)
    }

    func testCanInitPublicLazyFSM() {
        let fsm = FSM<Int, Int>(type: .lazy,
                                initialState: 1,
                                actionsPolicy: .executeAlways)
        XCTAssertTrue(fsm.fsm is LazyFSM<Int, Int>)
        XCTAssertEqual(fsm.fsm.state, 1)
        XCTAssertEqual(fsm.fsm.stateActionsPolicy, .executeAlways)
    }

    func testIsEagerByDefault() {
        let fsm = FSM<Int, Int>(initialState: 1)
        XCTAssertTrue(fsm.fsm is EagerFSM<Int, Int>)
    }

    func testExecutesOnChangeOnlyByDefault() {
        let lazy = FSM<Int, Int>(type: .lazy, initialState: 1)
        let eager = FSM<Int, Int>(type: .eager, initialState: 1)

        XCTAssertEqual(lazy.fsm.stateActionsPolicy, .executeOnChangeOnly)
        XCTAssertEqual(eager.fsm.stateActionsPolicy, .executeOnChangeOnly)
    }

    func testRespectsActionsPolicy() {
        let lazy = FSM<Int, Int>(
            type: .lazy, initialState: 1, actionsPolicy: .executeAlways
        )
        let eager = FSM<Int, Int>(
            type: .eager, initialState: 1, actionsPolicy: .executeAlways
        )

        XCTAssertEqual(lazy.fsm.stateActionsPolicy, .executeAlways)
        XCTAssertEqual(eager.fsm.stateActionsPolicy, .executeAlways)
    }

    func testBuildTable() throws {
        let line = #line; try fsm.buildTable {
            define(1) {
                when(1) | then(1)
            }
        }

        XCTAssertTrue(spy.log[0].contains("buildTable"))
        XCTAssertTrue(spy.log[1].contains(#file))
        XCTAssertTrue(spy.log[2].contains(String(line)))
        XCTAssertTrue(spy.log[3].contains("Define"))
    }

    @MainActor
    func testHandleEvent() async throws {
        func assertHandleEvent(_ predicates: String..., function: String = "handleEvent") {
            XCTAssertTrue(spy.log[0].contains(function))
            for (i, p) in predicates.enumerated() {
                XCTAssertTrue(spy.log[i + 1].contains(p),
                              "\(spy.log[i + 1]) doesn't contain \(p)")
            }

            spy.reset()
        }

        try fsm.handleEvent(1)
        assertHandleEvent()

        try fsm.handleEvent(1, predicates: P.a)
        assertHandleEvent("a")

        try fsm.handleEvent(1, predicates: P.a, P.b)
        assertHandleEvent("a", "b")

        await fsm.handleEventAsync(1)
        assertHandleEvent(function: "handleEventAsync")

        await fsm.handleEventAsync(1, predicates: P.a)
        assertHandleEvent("a", function: "handleEventAsync")

        await fsm.handleEventAsync(1, predicates: P.a, P.b)
        assertHandleEvent("a", "b", function: "handleEventAsync")
    }
}
