import Testing
@testable import SwiftFSM

private protocol FSMSpyProtocol: AnyObject {
    var log: [String] { get set }
}

extension FSMSpyProtocol {
    func log(_ caller: String = #function, args: [Any]) {
        log += [caller] + args.map(String.init(describing:))
    }
    
    func assertLog(
        contains entries: String...,
        at indices: Int...,
        location: SourceLocation = #_sourceLocation
    ) {
        precondition(entries.count == indices.count)
        precondition(indices.max() ?? Int.max < log.count)
        
        for i in indices {
            let entryIndex = i % entries.count
            #expect(
                log[i].contains(entries[entryIndex]),
                "\(log[i]) at \(i)",
                sourceLocation: location)
        }
    }
    
    func reset() {
        log = []
    }
    
    func makeMatchResolvingNode(
        rest: [any SyntaxNode<OverrideSyntaxDTO>]
    ) -> any MatchResolvingNode.Interface {
        fatalError("never called")
    }
}

final class PublicFSMTests: ExpandedSyntaxBuilder {
    typealias State = Int
    typealias Event = Int

    enum P: Predicate { case a, b }

    class FSMSpy: FSM<Int, Int>.Base, FSMSpyProtocol, @unchecked Sendable {
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
    
    init() {
        sut = FSM(
            type: .eager,
            initialState: 1,
            enforceConcurrency: true
        )
        spy = FSMSpy(initialState: 1)
        sut.fsm = spy
    }

    @Test func canInitPublicEagerFSM() async {
        let sut = FSM<Int, Int>(type: .eager,
                                initialState: 1,
                                actionsPolicy: .executeAlways)
        let fsm = sut.fsm
        #expect(fsm is FSM<State, Event>.Eager)
        #expect(fsm.state as! Int == 1)
        #expect(fsm.stateActionsPolicy == .executeAlways)
    }

    @Test func canInitPublicLazyFSM() async {
        let sut = FSM<Int, Int>(type: .lazy,
                                initialState: 1,
                                actionsPolicy: .executeAlways)
        let fsm = sut.fsm
        #expect(fsm is FSM<State, Event>.Lazy)
        #expect(fsm.state as! Int == 1)
        #expect(fsm.stateActionsPolicy == .executeAlways)
    }

    @Test func isEagerByDefault() async {
        let sut = FSM<Int, Int>(initialState: 1)
        let fsm = sut.fsm
        #expect(fsm is FSM<State, Event>.Eager)
    }

    @Test func executesOnChangeOnlyByDefault() async {
        let lazy = FSM<Int, Int>(type: .lazy, initialState: 1)
        let eager = FSM<Int, Int>(type: .eager, initialState: 1)

        let lazyFSM = lazy.fsm
        let eagerFSM = eager.fsm

        #expect(lazyFSM.stateActionsPolicy == .executeOnChangeOnly)
        #expect(eagerFSM.stateActionsPolicy == .executeOnChangeOnly)
    }

    @Test func respectsActionsPolicy() async {
        let lazy = FSM<Int, Int>(
            type: .lazy, initialState: 1, actionsPolicy: .executeAlways
        )
        let eager = FSM<Int, Int>(
            type: .eager, initialState: 1, actionsPolicy: .executeAlways
        )
        
        let lazyFSM = lazy.fsm
        let eagerFSM = eager.fsm

        #expect(lazyFSM.stateActionsPolicy == .executeAlways)
        #expect(eagerFSM.stateActionsPolicy == .executeAlways)
    }

    @Test func buildTable() async throws {
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

    @Test func handleEvent() async throws {
        func assertHandleEvent(
            _ predicates: String...,
            function: String = "handleEvent",
            location: SourceLocation = #_sourceLocation
        ) {
            #expect(spy.log[0].contains(function), sourceLocation: location)
            for (i, p) in predicates.enumerated() {
                #expect(
                    spy.log[i + 1].contains(p),
                    "\(spy.log[i + 1]) doesn't contain \(p)",
                    sourceLocation: location
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
    
    class LazyFSMSpy: FSM<State, Event>.Lazy, FSMSpyProtocol, @unchecked Sendable {
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
    
    class EagerFSMSpy: FSM<State, Event>.Eager, FSMSpyProtocol, @unchecked Sendable {
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
    
    typealias SUT = FSM<State, Event>.Base
    
    @MainActor @Test(arguments: [EagerFSMSpy(initialState: 1), LazyFSMSpy(initialState: 1)])
    func publicFSMPassesCallingActorIsolation(_ fsm: SUT) async throws {
        sut.fsm = fsm
        
        try sut.buildTable { }
        await sut.handleEvent(1)
        await sut.handleEvent(1, predicates: P.a)
        
        (fsm as! FSMSpyProtocol).assertLog(
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
            @TableBuilder _ block: () -> [Syntax.Define<State, Event>]
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
    @Test func mainActorFSMMethodForwarding() async throws {
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
    
    @Test func fsmConcurrencyValidation() async throws {
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
        #expect(fileLineLog == [])
        #expect(preconditionLog == [])
        #expect(messageLog == [])
        
        let l1 = #line; try sut.buildTable {
            define(1) { when(1) | then() }
        }
        #expect(fileLineLog == ["\(#file) \(l1)"])
        #expect(preconditionLog == [true])
        #expect(
            messageLog ==
            ["Concurrency violation: buildTable(file:line:isolation:_:) called by NonIsolated (expected NonIsolated)"]
        )
        
        sut.isolation = BadActor()
        
        let l2 = #line; await sut.handleEvent(1, predicates: P.a)
        #expect(fileLineLog == ["\(#file) \(l1)", "\(#file) \(l2)"])
        #expect(preconditionLog == [true, false])
        #expect(
            messageLog ==
            ["Concurrency violation: buildTable(file:line:isolation:_:) called by NonIsolated (expected NonIsolated)",
             "Concurrency violation: handleEvent(_:predicates:isolation:file:line:) called by NonIsolated (expected BadActor)"]
        )
        
        sut.assertsIsolation = false
        #expect(fileLineLog.count == 2)
        #expect(preconditionLog.count == 2)
        #expect(messageLog.count == 2)
    }
}
