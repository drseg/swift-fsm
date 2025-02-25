import XCTest
@testable import SwiftFSM

protocol FSMSpyProtocol: AnyObject {
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
        rest: [any SyntaxNode<OverrideSyntaxDTO>]
    ) -> any MatchResolvingNode {
        fatalError("never called")
    }
}

final class PublicFSMTests: XCTestCase, ExpandedSyntaxBuilder {
    typealias State = Int
    typealias Event = Int

    enum P: Predicate { case a, b }

    class FSMSpy: FSM<Int, Int>.Base, FSMSpyProtocol {
        typealias State = Int
        typealias Event = Int

        var log = [String]()

        @discardableResult
        override func handleEvent(
            _ event: Int,
            predicates: [any Predicate],
            isolation: isolated (any Actor)?
        ) async -> TransitionStatus {
            log(args: predicates)
            return .notFound(event, [])
        }

        override func buildTable(
            file: String = #file,
            line: Int = #line,
            isolation: isolated (any Actor)? = #isolation,
            @FSM<State, Event>.TableBuilder _ block: () -> [Syntax.Define<State, Event>]
        ) throws {
            log(args: [file, line, block()])
        }
    }

    var sut: FSM<Int, Int>!
    var spy: FSMSpy!
    
    override func setUp() async throws {
        sut = FSM(
            type: .eager,
            initialState: 1,
            enforceConcurrency: true
        )
        spy = FSMSpy(initialState: 1)
        sut.fsm = spy
    }

    func testCanInitPublicEagerFSM() async {
        let sut = FSM<Int, Int>(type: .eager,
                                initialState: 1,
                                actionsPolicy: .executeAlways)
        let fsm = sut.fsm
        XCTAssertTrue(fsm is FSM<State, Event>.Eager)
        XCTAssertEqual(fsm.state, 1)
        XCTAssertEqual(fsm.stateActionsPolicy, .executeAlways)
    }

    func testCanInitPublicLazyFSM() async {
        let sut = FSM<Int, Int>(type: .lazy,
                                initialState: 1,
                                actionsPolicy: .executeAlways)
        let fsm = sut.fsm
        XCTAssertTrue(fsm is FSM<State, Event>.Lazy)
        XCTAssertEqual(fsm.state, 1)
        XCTAssertEqual(fsm.stateActionsPolicy, .executeAlways)
    }

    func testIsEagerByDefault() async {
        let sut = FSM<Int, Int>(initialState: 1)
        let fsm = sut.fsm
        XCTAssertTrue(fsm is FSM<State, Event>.Eager)
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
    
    class LazyFSMSpy: FSM<State, Event>.Lazy, FSMSpyProtocol {
        var log = [String]()
        
        override func handleEvent(
            _ event: Int,
            predicates: [any Predicate],
            isolation: isolated (any Actor)?
        ) async -> TransitionStatus {
            log(args: [isolation as Any])
            return .notFound(1, [])
        }

        override func buildTable(
            file: String = #file,
            line: Int = #line,
            isolation: isolated (any Actor)? = #isolation,
            @FSM<State, Event>.TableBuilder _ block: () -> [Syntax.Define<State, Event>]
        ) throws {
            log(args: [isolation as Any])
        }
    }
    
    class EagerFSMSpy: FSM<State, Event>.Eager, FSMSpyProtocol {
        var log = [String]()
        
        override func handleEvent(
            _ event: Int,
            predicates: [any Predicate],
            isolation: isolated (any Actor)?
        ) async -> TransitionStatus {
            log(args: [isolation as Any])
            return .notFound(1, [])
        }

        override func buildTable(
            file: String = #file,
            line: Int = #line,
            isolation: isolated (any Actor)? = #isolation,
            @FSM<State, Event>.TableBuilder _ block: () -> [Syntax.Define<State, Event>]
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
            file: StaticString = #file,
            line: Int = #line,
            isolation: isolated (any Actor)? = #isolation,
            @TableBuilder _ block: @isolated(any) () -> [Syntax.Define<State, Event>]
        ) throws {
            log(args: [isolation!])
        }
        
        internal override func handleEvent(
            _ event: Event,
            predicates: [any Predicate],
            isolation: isolated (any Actor)? = #isolation,
            file: StaticString = #file,
            line: UInt = #line
        ) async {
            log(args: [predicates, isolation!])
        }
    }
    
    @MainActor
    func testMainActorFSMMethodForwarding() async throws {
        let sut = FSM<Int, Int>.OnMainActor(initialState: 1)
        let spy = FSMForwardingSpy(initialState: 1)
        sut.fsm = spy
        
        try sut.buildTable { }
        await sut.handleEvent(1)
        await sut.handleEvent(1, predicates: P.b)
        
        spy.assertLog(
            contains: "buildTable", "MainActor", "handleEvent", "[]", "MainActor", "handleEvent", "P.b", "MainActor",
            at: 0, 1, 2, 3, 4, 5, 6, 7
        )
    }
    
    func testFSMConcurrencyValidation() async throws {
        actor BadActor: Actor { }
        
        var preconditionLog = [Bool]()
        var messageLog = [String]()
        var fileLineLog = [String]()
        
        func preconditionSpy(
            _ condition: @autoclosure () -> Bool,
            _ message: @autoclosure () -> String,
            _ file: StaticString,
            _ line: UInt
        ) -> () {
            fileLineLog.append("\(file) \(line)")
            messageLog.append(message())
            preconditionLog.append(condition())
        }
        
        sut._precondition = preconditionSpy
        
        await sut.handleEvent(1)
        XCTAssertEqual(fileLineLog, [])
        XCTAssertEqual(preconditionLog, [])
        XCTAssertEqual(messageLog, [])
        
        let l1 = #line; try sut.buildTable {
            define(1) { when(1) | then() }
        }
        XCTAssertEqual(fileLineLog, ["\(#file) \(l1)"])
        XCTAssertEqual(preconditionLog, [true])
        XCTAssertEqual(
            messageLog,
            ["Concurrency violation: buildTable(file:line:isolation:_:) called by NonIsolated (expected NonIsolated)"]
        )
        
        sut.isolation = BadActor()
        
        let l2 = #line; await sut.handleEvent(1, predicates: P.a)
        XCTAssertEqual(fileLineLog, ["\(#file) \(l1)", "\(#file) \(l2)"])
        XCTAssertEqual(preconditionLog, [true, false])
        XCTAssertEqual(
            messageLog,
            ["Concurrency violation: buildTable(file:line:isolation:_:) called by NonIsolated (expected NonIsolated)",
             "Concurrency violation: handleEvent(_:predicates:isolation:file:line:) called by NonIsolated (expected BadActor)"]
        )
        
        sut.assertsIsolation = false
        XCTAssertEqual(fileLineLog.count, 2)
        XCTAssertEqual(preconditionLog.count, 2)
        XCTAssertEqual(messageLog.count, 2)
    }
}
