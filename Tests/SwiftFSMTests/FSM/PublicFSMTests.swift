import XCTest
@testable import SwiftFSM

protocol FSMSpyProtocol<State, Event>: AnyObject {
    associatedtype State: FSMHashable
    associatedtype Event: FSMHashable
    
    var log: [String] { get set }
}

extension FSMSpyProtocol {
    func log(_ caller: String = #function, args: [Any]) {
        log += [caller] + args.map(String.init(describing:))
    }
    
    func assertLog(
        contains entries: String...,
        at indices: Int...,
        line: UInt = #line
    ) {
        precondition(entries.count == indices.count)
        precondition(indices.max() ?? Int.max < log.count)
        
        for i in indices {
            let entryIndex = i % entries.count
            XCTAssertTrue(
                log[i].contains(entries[entryIndex]),
                log[i] + " at \(i)",
                line: line)
        }
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

final class PublicFSMTests: XCTestCase, ExpandedSyntaxBuilder {
    typealias State = Int
    typealias Event = Int

    enum P: Predicate { case a, b }

    class FSMSpy: BaseFSM<Int, Int>, FSMSpyProtocol, FSMProtocol {
        typealias State = Int
        typealias Event = Int

        var log = [String]()

        func handleEvent(
            _ event: Int,
            predicates: [any Predicate],
            isolation: isolated (any Actor)?
        ) async {
            log(args: predicates)
        }

        override func buildTable(
            file: String = #file,
            line: Int = #line,
            isolation: isolated (any Actor)? = #isolation,
            @TableBuilder<State, Event> _ block: () -> [Internal.Define<State, Event>]
        ) throws {
            log(args: [file, line, block()])
        }
    }

    var sut: FSM<Int, Int>!
    var spy: FSMSpy!
    
    override func setUp() async throws {
        sut = FSM(type: .eager, initialState: 1)
        spy = FSMSpy(initialState: 1)
        sut.fsm = spy
    }

    func testCanInitPublicEagerFSM() async {
        let sut = FSM<Int, Int>(type: .eager,
                                initialState: 1,
                                actionsPolicy: .executeAlways)
        let fsm = sut.fsm
        XCTAssertTrue(fsm is EagerFSM<Int, Int>)
        XCTAssertEqual(fsm.state, 1)
        XCTAssertEqual(fsm.stateActionsPolicy, .executeAlways)
    }

    func testCanInitPublicLazyFSM() async {
        let sut = FSM<Int, Int>(type: .lazy,
                                initialState: 1,
                                actionsPolicy: .executeAlways)
        let fsm = sut.fsm
        XCTAssertTrue(fsm is LazyFSM<Int, Int>)
        XCTAssertEqual(fsm.state, 1)
        XCTAssertEqual(fsm.stateActionsPolicy, .executeAlways)
    }

    func testIsEagerByDefault() async {
        let sut = FSM<Int, Int>(initialState: 1)
        let fsm = sut.fsm
        XCTAssertTrue(fsm is EagerFSM<Int, Int>)
    }

    func testExecutesOnChangeOnlyByDefault() async {
        let lazy = FSM<Int, Int>(type: .lazy, initialState: 1)
        let eager = FSM<Int, Int>(type: .eager, initialState: 1)

        let lazyFSM = lazy.fsm
        let eagerFSM = eager.fsm

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
        
        let lazyFSM = lazy.fsm
        let eagerFSM = eager.fsm

        XCTAssertEqual(lazyFSM.stateActionsPolicy, .executeAlways)
        XCTAssertEqual(eagerFSM.stateActionsPolicy, .executeAlways)
    }

    func testBuildTable() async throws {
        let line = #line; try sut.buildTable {
            define(1) {
                when(1) | then(1)
            }
        }

        spy.assertLog(
            contains: "buildTable", #file, String(line), "Define",
            at: 0, 1, 2, 3
        )
    }

    func testHandleEvent() async throws {
        func assertHandleEvent(
            _ predicates: String...,
            function: String = "handleEvent",
            line: UInt = #line
        ) {
            XCTAssertTrue(spy.log[0].contains(function), line: line)
            for (i, p) in predicates.enumerated() {
                XCTAssertTrue(
                    spy.log[i + 1].contains(p),
                    "\(spy.log[i + 1]) doesn't contain \(p)",
                    line: line
                )
            }

            spy.reset()
        }
        
        await sut.handleEvent(1)
        assertHandleEvent(function: "handleEvent")

        await sut.handleEvent(1, predicates: P.a)
        assertHandleEvent("a", function: "handleEvent")

        await sut.handleEvent(1, predicates: P.a, P.b)
        assertHandleEvent("a", "b", function: "handleEvent")
    }
    
    class LazyFSMSpy: LazyFSM<Int, Int>, FSMSpyProtocol {
        var log = [String]()
        
        override func _handleEvent(
            _ event: Int,
            predicates: [any Predicate],
            isolation: isolated (any Actor)?
        ) async -> TransitionStatus<Int> {
            log(args: [isolation as Any])
            return .notFound(1, [])
        }

        override func buildTable(
            file: String = #file,
            line: Int = #line,
            isolation: isolated (any Actor)? = #isolation,
            @TableBuilder<State, Event> _ block: () -> [Internal.Define<State, Event>]
        ) throws {
            log(args: [isolation as Any])
        }
    }
    
    class EagerFSMSpy: EagerFSM<Int, Int>, FSMSpyProtocol {
        var log = [String]()
        
        override func _handleEvent(
            _ event: Int,
            predicates: [any Predicate],
            isolation: isolated (any Actor)?
        ) async -> TransitionStatus<Int> {
            log(args: [isolation as Any])
            return .notFound(1, [])
        }

        override func buildTable(
            file: String = #file,
            line: Int = #line,
            isolation: isolated (any Actor)? = #isolation,
            @TableBuilder<State, Event> _ block: () -> [Internal.Define<State, Event>]
        ) throws {
            log(args: [isolation as Any])
        }
    }
    
    @MainActor
    func testPublicFSMPassesCallingActorIsolation_Eager() async throws {
        let eagerSpy = EagerFSMSpy(initialState: 1)
        sut.fsm = eagerSpy
        
        try sut.buildTable { }
        await sut.handleEvent(1)
        await sut.handleEvent(1, predicates: P.a)
        
        eagerSpy.assertLog(
            contains: "MainActor", "MainActor", "MainActor",
            at: 1, 3, 5
        )
    }
    
    @MainActor
    func testPublicFSMPassesCallingActorIsolation_Lazy() async throws {
        let lazySpy = LazyFSMSpy(initialState: 1)
        sut.fsm = lazySpy
        
        try sut.buildTable { }
        await sut.handleEvent(1)
        await sut.handleEvent(1, predicates: P.a)
        
        lazySpy.assertLog(
            contains: "MainActor", "MainActor", "MainActor",
            at: 1, 3, 5
        )
    }
    
    class FSMForwardingSpy: FSM<Int, Int>, FSMSpyProtocol {
        var log = [String]()
        
        typealias State = Int
        typealias Event = Int

        public override func buildTable(
            file: String = #file,
            line: Int = #line,
            isolation: isolated (any Actor)? = #isolation,
            @TableBuilder<State, Event> _ block: @isolated(any) () -> [Internal.Define<State, Event>]
        ) throws {
            log(args: [isolation!])
        }

        public override func handleEvent(
            _ event: Event,
            isolation: isolated (any Actor)? = #isolation
        ) async {
            log(args: [isolation!])
        }
        
        internal override func handleEvent(
            _ event: Event,
            predicates: [any Predicate],
            isolation: isolated (any Actor)? = #isolation
        ) async {
            log(args: [predicates, isolation!])
        }
    }
    
    @MainActor
    func testMainActorFSMMethodForwarding() async throws {
        let sut = MainActorFSM<Int, Int>(initialState: 1)
        let spy = FSMForwardingSpy(initialState: 1)
        sut.fsm = spy
        
        try sut.buildTable { }
        await sut.handleEvent(1)
        await sut.handleEvent(1, predicates: P.b)
        
        spy.assertLog(
            contains: "buildTable", "MainActor", "handleEvent", "MainActor", "handleEvent", "P.b", "MainActor",
            at: 0, 1, 2, 3, 4, 5, 6
        )
    }
}
