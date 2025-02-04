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

        func handleEvent(
            _ event: Int,
            predicates: [any Predicate],
            isolation: isolated (any Actor)?
        ) async {
            log(args: predicates)
        }

        func buildTable(
            file: String = #file,
            line: Int = #line,
            isolation: isolated (any Actor)? = #isolation,
            @TableBuilder<State, Event> _ block: () -> [Internal.Define<State, Event>]
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
    
    override func setUp() async throws {
        fsm = FSM(type: .eager, initialState: 1)
        spy = FSMSpy(initialState: 1)
        fsm.setFSM(spy)
    }

    func testCanInitPublicEagerFSM() async {
        let sut = FSM<Int, Int>(type: .eager,
                                initialState: 1,
                                actionsPolicy: .executeAlways)
        let fsm = sut.getFSM()
        XCTAssertTrue(fsm is EagerFSM<Int, Int>)
        XCTAssertEqual(fsm.state, 1)
        XCTAssertEqual(fsm.stateActionsPolicy, .executeAlways)
    }

    func testCanInitPublicLazyFSM() async {
        let sut = FSM<Int, Int>(type: .lazy,
                                initialState: 1,
                                actionsPolicy: .executeAlways)
        let fsm = sut.getFSM()
        XCTAssertTrue(fsm is LazyFSM<Int, Int>)
        XCTAssertEqual(fsm.state, 1)
        XCTAssertEqual(fsm.stateActionsPolicy, .executeAlways)
    }

    func testIsEagerByDefault() async {
        let sut = FSM<Int, Int>(initialState: 1)
        let fsm = sut.getFSM()
        XCTAssertTrue(fsm is EagerFSM<Int, Int>)
    }

    func testExecutesOnChangeOnlyByDefault() async {
        let lazy = FSM<Int, Int>(type: .lazy, initialState: 1)
        let eager = FSM<Int, Int>(type: .eager, initialState: 1)

        let lazyFSM = lazy.getFSM()
        let eagerFSM = eager.getFSM()

        XCTAssertEqual(lazyFSM.stateActionsPolicy, .executeOnChangeOnly)
        XCTAssertEqual(eagerFSM.stateActionsPolicy, .executeOnChangeOnly)
    }

    func testRespectsActionsPolicy() async {
        let lazy = FSM<Int, Int>(
            type: .lazy, initialState: 1, actionsPolicy: .executeAlways
        )
        let eager = FSM<Int, Int>(
            type: .eager, initialState: 1, actionsPolicy: .executeAlways
        )
        
        let lazyFSM = lazy.getFSM()
        let eagerFSM = eager.getFSM()

        XCTAssertEqual(lazyFSM.stateActionsPolicy, .executeAlways)
        XCTAssertEqual(eagerFSM.stateActionsPolicy, .executeAlways)
    }

    func testBuildTable() async throws {
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

    func testHandleEvent() async throws {
        func assertHandleEvent(_ predicates: String..., function: String = "handleEvent") {
            XCTAssertTrue(spy.log[0].contains(function))
            for (i, p) in predicates.enumerated() {
                XCTAssertTrue(spy.log[i + 1].contains(p),
                              "\(spy.log[i + 1]) doesn't contain \(p)")
            }

            spy.reset()
        }
        await fsm.handleEvent(1)
        assertHandleEvent(function: "handleEvent")

        await fsm.handleEvent(1, predicates: P.a)
        assertHandleEvent("a", function: "handleEvent")

        await fsm.handleEvent(1, predicates: P.a, P.b)
        assertHandleEvent("a", "b", function: "handleEvent")
    }
}

extension FSM {
    func getFSM() -> any FSMProtocol<State, Event> {
        self.fsm
    }
    func setFSM(_ fsm: any FSMProtocol<State, Event>) {
        self.fsm = fsm
    }
}
