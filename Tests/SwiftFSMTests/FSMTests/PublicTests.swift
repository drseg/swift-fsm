import XCTest
@testable import SwiftFSM

@MainActor
final class PublicTests: XCTestCase, ExpandedSyntaxBuilder {
    typealias State = Int
    typealias Event = Int

    enum P: Predicate { case a, b }

    typealias BaseType = BaseFSM<Int, Int> & EventHandling

    class FSMSpy: BaseType {
        typealias Event = Int
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

        override func buildTable(
            file: String = #file,
            line: Int = #line, 
            _ block: () -> [Syntax.Define<Int, Int>]
        ) throws {
            log(args: [file, line, block()])
        }

        func reset() {
            log = []
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

    func testInitDefaultsToExecuteAlways() {
        let lazy = FSM<Int, Int>(type: .lazy, initialState: 1)
        let eager = FSM<Int, Int>(type: .eager, initialState: 1)

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

    func testHandleEvent() async {
        func assertHandleEvent(_ predicates: String..., function: String = "handleEvent") {
            XCTAssertTrue(spy.log[0].contains(function))
            for (i, p) in predicates.enumerated() {
                XCTAssertTrue(spy.log[i + 1].contains(p),
                              "\(spy.log[i + 1]) doesn't contain \(p)")
            }

            spy.reset()
        }

        fsm.handleEvent(1)
        assertHandleEvent()

        fsm.handleEvent(1, predicates: P.a)
        assertHandleEvent("a")

        fsm.handleEvent(1, predicates: P.a, P.b)
        assertHandleEvent("a", "b")

        await fsm.handleEventAsync(1)
        assertHandleEvent(function: "handleEventAsync")

        await fsm.handleEventAsync(1, predicates: P.a)
        assertHandleEvent("a", function: "handleEventAsync")

        await fsm.handleEventAsync(1, predicates: P.a, P.b)
        assertHandleEvent("a", "b", function: "handleEventAsync")
    }
}
