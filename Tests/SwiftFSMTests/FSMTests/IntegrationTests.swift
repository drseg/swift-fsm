import Foundation
import XCTest
@testable import SwiftFSM

enum TurnstileState: String, CustomStringConvertible {
    case locked, unlocked, alarming
    var description: String { rawValue  }
}

enum TurnstileEvent: String, CustomStringConvertible {
    case reset, coin, pass
    var description: String { rawValue }
}

class FSMIntegrationTests: FSMTestsBase<TurnstileState, TurnstileEvent> {
    var actions = [String]()
    var actual = [String]()
    
    func alarmOn()  { actions.append("alarmOn")  }
    func alarmOff() { actions.append("alarmOff") }
    func lock()     { actions.append("lock")     }
    func unlock()   { actions.append("unlock")   }
    func thankyou() { actions.append("thankyou") }
    
    override var initialState: TurnstileState { .locked }
    
    override func makeSUT<_State: Hashable, _Event: Hashable>(
        initialState: _State,
        actionsPolicy: _FSMBase<_State, _Event>.StateActionsPolicy = .executeOnChangeOnly
    ) -> _FSMBase<_State, _Event> {
        FSM<_State, _Event>(initialState: initialState, actionsPolicy: actionsPolicy)
    }
}

final class LazyFSMIntegrationTests_Turnstile: FSMIntegrationTests_Turnstile {
    override func makeSUT<_State: Hashable, _Event: Hashable>(
        initialState: _State,
        actionsPolicy: _FSMBase<_State, _Event>.StateActionsPolicy = .executeOnChangeOnly
    ) -> _FSMBase<_State, _Event> {
        LazyFSM<_State, _Event>(initialState: initialState, actionsPolicy: actionsPolicy)
    }
}

class FSMIntegrationTests_Turnstile: FSMIntegrationTests {
    func assertEventAction(_ e: Event, _ a: String, line: UInt = #line) {
        assertEventAction(e, a.isEmpty ? [] : [a], line: line)
    }
    
    func assertEventAction(_ e: Event, _ a: [String], line: UInt = #line) {
        actual += a
        fsm.handleEvent(e)
        XCTAssertEqual(actions, actual, line: line)
    }
    
    func assertTurnstile() {
        assertEventAction(.coin,  "unlock")
        assertEventAction(.pass,  "lock")
        assertEventAction(.pass,  "alarmOn")
        assertEventAction(.reset, ["alarmOff", "lock"])
        assertEventAction(.coin,  "unlock")
        assertEventAction(.coin,  "thankyou")
        assertEventAction(.coin,  "thankyou")
        assertEventAction(.reset, "lock")
    }
    
    func testTurnstile() throws {
        try fsm.buildTable {
            let resetable = SuperState {
                when(.reset) | then(.locked)
            }

            define(.locked, adopts: resetable, onEntry: [lock]) {
                when(.coin) | then(.unlocked)
                when(.pass) | then(.alarming)
            }
            
            define(.unlocked, adopts: resetable, onEntry: [unlock]) {
                when(.coin) | then(.unlocked) | thankyou
                when(.pass) | then(.locked)
            }
            
            define(.alarming, adopts: resetable, onEntry: [alarmOn], onExit: [alarmOff])
        }
        
        assertTurnstile()
    }
    
    func testConditionTurnstile() throws {
        var bool = false
        
        try fsm.buildTable {
            let resetable = SuperState {
                condition { bool } | when(.reset) | then(.locked)
            }
            
            define(.locked, adopts: resetable, onEntry: [lock]) {
                condition { bool } | when(.coin) | then(.unlocked)
                condition { bool } | when(.pass) | then(.alarming)
            }
            
            define(.unlocked, adopts: resetable, onEntry: [unlock]) {
                condition { bool } | when(.coin) | then(.unlocked) | thankyou
                condition { bool } | when(.pass) | then(.locked)
            }
            
            define(.alarming, adopts: resetable, onEntry: [alarmOn], onExit: [alarmOff])
        }
        
        assertEventAction(.coin,  "")
        assertEventAction(.pass,  "")
        assertEventAction(.reset,  "")

        fsm.state = AnyHashable(State.unlocked)
        
        assertEventAction(.coin,  "")
        assertEventAction(.pass,  "")
        assertEventAction(.reset,  "")
        
        fsm.state = AnyHashable(State.alarming)
        
        assertEventAction(.reset,  "")

        fsm.state = AnyHashable(State.locked)
        bool = true
        
        assertTurnstile()
    }
    
    func testOverrideTurnstile() throws {
        try fsm.buildTable {
            let resetable = SuperState {
                when(.reset) | then(.locked)
            }

            define(.locked, adopts: resetable, onEntry: [lock]) {
                when(.coin) | then(.unlocked)
                when(.pass) | then(.alarming)
                
                override {
                    when(.reset) | then(.locked) | thankyou
                }
            }
            
            define(.unlocked, adopts: resetable, onEntry: [unlock]) {
                when(.coin) | then(.unlocked) | thankyou
                when(.pass) | then(.locked)
                
                override {
                    when(.reset) | then(.locked) | lock
                }
            }
            
            define(.alarming, adopts: resetable, onEntry: [alarmOn], onExit: [alarmOff])
        }
        
        assertEventAction(.reset, "thankyou")
        
        fsm.state = AnyHashable(State.unlocked)
        assertEventAction(.reset, ["lock", "lock"])
        
        fsm.state = AnyHashable(State.alarming)
        assertEventAction(.reset, ["alarmOff", "lock"])
    }
    
    func testChainedOverrides() throws {
        func fail() { XCTFail("should not have been called") }
        
        try fsm.buildTable {
            let s1 = SuperState { when(.coin) | then(.unlocked) | fail  }
            let s2 = SuperState(adopts: s1) { override { when(.coin) | then(.unlocked) | fail } }
            let s3 = SuperState(adopts: s2) { override { when(.coin) | then(.unlocked) | fail } }
            let s4 = SuperState(adopts: s3) { override { when(.coin) | then(.unlocked) | fail } }
            
            define(.locked, adopts: s4) {
                override { when(.coin) | then(.unlocked) | unlock }
            }
        }

        assertEventAction(.coin, "unlock")
    }
}

class LazyFSMIntegrationTests_PredicateTurnstile: FSMIntegrationTests_PredicateTurnstile {
    override func makeSUT<_State: Hashable, _Event: Hashable>(
        initialState: _State,
        actionsPolicy: _FSMBase<_State, _Event>.StateActionsPolicy = .executeOnChangeOnly
    ) -> _FSMBase<_State, _Event> {
        LazyFSM<_State, _Event>(initialState: initialState, actionsPolicy: actionsPolicy)
    }
}

class FSMIntegrationTests_PredicateTurnstile: FSMIntegrationTests {
    enum Enforcement: Predicate { case strong, weak }
    enum Reward: Predicate { case punishing, rewarding }
    
    func idiot() { actions.append("idiot") }
    
    func assertEventAction(_ e: Event, _ a: String, line: UInt = #line) {
        assertEventAction(e, [a], line: line)
    }
    
    func assertEventAction(_ e: Event, _ a: [String], line: UInt = #line) {
        if !(a.first?.isEmpty ?? false) {
            actual += a
        }
        fsm.handleEvent(e, predicates: [Enforcement.weak, Reward.punishing])
        XCTAssertEqual(actions, actual, line: line)
    }
    
    func assertTable() {
        assertEventAction(.coin,  "unlock")
        assertEventAction(.pass,  "lock")
        assertEventAction(.pass,  "")
        assertEventAction(.reset, "")
        assertEventAction(.coin,  "unlock")
        assertEventAction(.coin,  "idiot")
        assertEventAction(.coin,  "idiot")
        assertEventAction(.reset, "lock")
    }
    
    func testPredicateTurnstile() throws {
        try fsm.buildTable {
            let resetable = SuperState {
                when(.reset) | then(.locked)
            }
            
            define(.locked, adopts: resetable, onEntry: [lock]) {
                matching(Enforcement.weak)   | when(.pass) | then(.locked)
                matching(Enforcement.strong) | when(.pass) | then(.alarming)
                
                when(.coin) | then(.unlocked)
            }
            
            define(.unlocked, adopts: resetable, onEntry: [unlock]) {
                matching(Reward.rewarding) | when(.coin) | then(.unlocked) | thankyou
                matching(Reward.punishing) | when(.coin) | then(.unlocked) | idiot
                
                when(.pass) | then(.locked)
            }
            
            define(.alarming, adopts: resetable, onEntry: [alarmOn], onExit: [alarmOff])
        }
        
        assertTable()
    }
    
    func testDeduplicatedPredicateTurnstile() throws {
        try fsm.buildTable {
            let resetable = SuperState {
                when(.reset) | then(.locked)
            }
            
            define(.locked, adopts: resetable, onEntry: [lock]) {
                when(.pass) {
                    matching(Enforcement.weak)   | then(.locked)
                    matching(Enforcement.strong) | then(.alarming)
                }
                
                when(.coin) | then(.unlocked)
            }
            
            define(.unlocked, adopts: resetable, onEntry: [unlock]) {
                when(.coin) {
                    then(.unlocked) {
                        matching(Reward.rewarding) | thankyou
                        matching(Reward.punishing) | idiot
                    }
                }
                
                when(.pass) | then(.locked)
            }
            
            define(.alarming, adopts: resetable, onEntry: [alarmOn], onExit: [alarmOff])
        }
        
        assertTable()
    }
    
    func testTypealiasSyntaxTurnstile() throws {
        typealias S = Syntax.Define<State>
        typealias E = Syntax.When<State, Event>
        typealias NS = Syntax.Then<State, Event>
        typealias If = Syntax.Expanded.Matching<State, Event>
        
        try fsm.buildTable {
            let resetable = SuperState {
                E(.reset) | NS(.locked)
            }
            
            S(.locked, adopts: resetable, onEntry: [lock]) {
                E(.pass) {
                    If(Enforcement.weak)   | NS(.locked)
                    If(Enforcement.strong) | NS(.alarming)
                }
                
                E(.coin) | NS(.unlocked)
            }
            
            S(.unlocked, adopts: resetable, onEntry: [unlock]) {
                NS(.unlocked) {
                    If(Reward.rewarding) | E(.coin) | thankyou
                    If(Reward.punishing) | E(.coin) | idiot
                }
                
                E(.pass) | NS(.locked)
            }
            
            S(.alarming, adopts: resetable, onEntry: [alarmOn], onExit: [alarmOff])
        }
        
        assertTable()
    }
    
    func testActionsBlockTurnstile() throws {
        try fsm.buildTable {
            let resetable = SuperState {
                when(.reset) | then(.locked)
            }
            
            define(.locked, adopts: resetable, onEntry: [lock]) {
                when(.pass) {
                    matching(Enforcement.weak)   | then(.locked)
                    matching(Enforcement.strong) | then(.alarming)
                }
                
                when(.coin) | then(.unlocked)
            }
            
            define(.unlocked, adopts: resetable, onEntry: [unlock]) {
                then(.unlocked) {
                    actions(thankyou) {
                        matching(Reward.rewarding) | when(.coin)
                    }
                    
                    actions(idiot) {
                        matching(Reward.punishing) | when(.coin)
                    }
                }
                
                when(.pass) | then(.locked)
            }
            
            define(.alarming, adopts: resetable, onEntry: [alarmOn], onExit: [alarmOff])
        }
        
        assertTable()
    }
}

class LazyFSMIntegrationTests_NestedBlocks: FSMIntegrationTests_NestedBlocks {
    override func makeSUT<_State: Hashable, _Event: Hashable>(
        initialState: _State,
        actionsPolicy: _FSMBase<_State, _Event>.StateActionsPolicy = .executeOnChangeOnly
    ) -> _FSMBase<_State, _Event> {
        LazyFSM<_State, _Event>(initialState: initialState, actionsPolicy: actionsPolicy)
    }
}

class FSMIntegrationTests_NestedBlocks: FSMIntegrationTests {
    func testMultiplePredicateBlocks() throws {
        try fsm.buildTable {
            define(.locked) {
                matching(P.a, or: P.b) {
                    matching(Q.a) {
                        matching(R.a, and: S.a) {
                            matching(T.a, and: U.a) {
                                matching(V.a) | when(.coin) | then() | thankyou
                            }
                        }
                    }
                }
                
                matching(P.a) {
                    when(.coin) | then() | unlock
                }
            }
        }
        
        fsm.handleEvent(.coin, predicates: P.a, Q.a, R.a, S.a, T.a, U.a, V.a)
        XCTAssertEqual(["thankyou"], actions)
        
        fsm.handleEvent(.coin, predicates: P.b, Q.a, R.a, S.a, T.a, U.a, V.a)
        XCTAssertEqual(["thankyou", "thankyou"], actions)
        
        actions = []
        fsm.handleEvent(.coin, predicates: P.c, Q.a, R.a, S.a, T.a, U.a, V.a)
        XCTAssertEqual([], actions)
        
        actions = []
        fsm.handleEvent(.coin, predicates: P.a, Q.b, R.b, S.b, T.b, U.b, V.b)
        XCTAssertEqual(["unlock"], actions)
    }
    
    func testMultiplActionsBlocks() throws {
        try fsm.buildTable {
            define(.locked) {
                actions(thankyou) {
                    actions(lock) {
                        matching(P.a) | when(.coin) | then(.locked) | unlock
                    }
                }
            }
        }
        
        fsm.handleEvent(.coin, predicates: P.a)
        XCTAssertEqual(["thankyou", "lock", "unlock"], actions)
    }
}

class LazyFSMIntegrationTests_Errors: FSMIntegrationTests_Errors {
    override func makeSUT<_State: Hashable, _Event: Hashable>(
        initialState: _State,
        actionsPolicy: _FSMBase<_State, _Event>.StateActionsPolicy = .executeOnChangeOnly
    ) -> _FSMBase<_State, _Event> {
        LazyFSM<_State, _Event>(initialState: initialState, actionsPolicy: actionsPolicy)
    }
}

class FSMIntegrationTests_Errors: FSMIntegrationTests {
    func assertEmptyError(_ e: EmptyBuilderError?,
                     expectedCaller: String,
                     expectedLine: Int,
                     line: UInt = #line
    ) {
        XCTAssertEqual(expectedCaller, e?.caller, line: line)
        XCTAssertEqual("file", e?.file, line: line)
        XCTAssertEqual(expectedLine, e?.line, line: line)
    }
    
    func testEmptyBlockThrowsError() {
        XCTAssertThrowsError (
            try fsm.buildTable {
                define(.locked, file: "file", line: 1 ) { }
            }
        ) {
            let errors = ($0 as? SwiftFSMError)?.errors
            XCTAssertEqual(1, errors?.count)
            let error = errors?.first as? EmptyBuilderError
            
            assertEmptyError(error, expectedCaller: "define", expectedLine: 1)
        }
    }
    
    func testEmptyBlocksThrowErrors() {
        XCTAssertThrowsError (
            try fsm.buildTable {
                define(.locked) {
                    matching(P.a, file: "file", line: 1) {}
                    then(.locked, file: "file", line: 2) {}
                    when(.pass,   file: "file", line: 3) {}
                }
            }
        ) {
            let errors = ($0 as? SwiftFSMError)?.errors
            XCTAssertEqual(3, errors?.count)
            
            let e1 = errors?(0) as? EmptyBuilderError
            assertEmptyError(e1, expectedCaller: "matching", expectedLine: 1)
            
            let e2 = errors?(1) as? EmptyBuilderError
            assertEmptyError(e2, expectedCaller: "then", expectedLine: 2)
            
            let e3 = errors?(2) as? EmptyBuilderError
            assertEmptyError(e3, expectedCaller: "when", expectedLine: 3)
        }
    }
    
    func testDuplicatesAndClashesThrowErrors() {
        typealias DE = SemanticValidationNode.DuplicatesError
        typealias CE = SemanticValidationNode.ClashError
        
        XCTAssertThrowsError (
            try fsm.buildTable {
                define(.locked, line: 1) {
                    matching(P.a, line: 2) | when(.coin, line: 3) | then(.unlocked, line: 4)
                    matching(P.a, line: 2) | when(.coin, line: 3) | then(.unlocked, line: 4)
                    matching(P.a, line: 2) | when(.coin, line: 3) | then(.locked, line: 4)
                }
            }
        ) {
            let errors = ($0 as? SwiftFSMError)?.errors
            XCTAssertEqual(2, errors?.count)
            
            let e1 = errors?.compactMap { $0 as? DE }.first?.duplicates.values
            let e2 = errors?.compactMap { $0 as? CE }.first?.clashes.values

            XCTAssertEqual(1, e1?.count)
            XCTAssertEqual(1, e2?.count)
            
            let duplicates = e1?.first ?? []
            let clashes = e2?.first ?? []
            
            XCTAssertEqual(2, duplicates.count)
            XCTAssertEqual(2, clashes.count)
            
            XCTAssert(
                duplicates.allSatisfy {
                    $0.state.isEqual(AnyTraceable(State.locked, file: #file, line: 1)) &&
                    $0.match.isEqual(Match(all: P.a, file: #file, line: 2)) &&
                    $0.event.isEqual(AnyTraceable(Event.coin, file: #file, line: 3)) &&
                    $0.nextState.isEqual(AnyTraceable(State.unlocked, file: #file, line: 4))
                }, "\(duplicates)"
            )
            
            XCTAssert(
                clashes.allSatisfy {
                    $0.state.isEqual(AnyTraceable(State.locked, file: #file, line: 1)) &&
                    $0.match.isEqual(Match(all: P.a, file: #file, line: 2)) &&
                    $0.event.isEqual(AnyTraceable(Event.coin, file: #file, line: 3))
                }, "\(clashes)"
            )
            
            XCTAssert(clashes.contains { $0.nextState.base == AnyHashable(State.locked) })
            XCTAssert(clashes.contains { $0.nextState.base == AnyHashable(State.unlocked) })
        }
    }
    
    func testImplicitMatchClashesThrowErrors() {
        XCTAssertThrowsError (
            try fsm.buildTable {
                define(.locked, file: "1", line: 1) {
                    matching(P.a, file: "1", line: 1)
                    | when(.coin, file: "1", line: 1)
                    | then(.unlocked, file: "1", line: 1)
                    
                    matching(Q.a, file: "2", line: 2)
                    | when(.coin, file: "2", line: 2)
                    | then(.locked, file: "2", line: 2)
                }
            }
        ) {
            let errors = ($0 as? SwiftFSMError)?.errors
            XCTAssertEqual(1, errors?.count)
            
            let error = errors?.first as? EagerMatchResolvingNode.ImplicitClashesError
            let clashes = error?.clashes.values
            XCTAssertEqual(1, clashes?.count)
            
            let clash = clashes?.first
            XCTAssertEqual(2, clash?.count)
            
            XCTAssert(clash?.contains {
                $0.state.isEqual(AnyTraceable(State.locked, file: "1", line: 1)) &&
                $0.event.isEqual(AnyTraceable(Event.coin, file: "1", line: 1)) &&
                $0.match.isEqual(Match(all: P.a, file: "1", line: 1))
            } ?? false, "\(String(describing: clash))")
            
            XCTAssert(clash?.contains {
                $0.state.isEqual(AnyTraceable(State.locked, file: "1", line: 1)) &&
                $0.event.isEqual(AnyTraceable(Event.coin, file: "2", line: 2)) &&
                $0.match.isEqual(Match(all: Q.a, file: "2", line: 2))
            } ?? false, "\(String(describing: clash))")
            
            XCTAssertEqual(AnyHashable(State.unlocked), clash?.first?.nextState.base)
            XCTAssertEqual(AnyHashable(State.locked), clash?.last?.nextState.base)
        }
    }
    
    func testMatchesThrowErrors() {
        XCTAssertThrowsError (
            try fsm.buildTable {
                define(.locked) {
                    matching(P.a, or: P.a, file: "1", line: 1)  | when(.coin) | then(.unlocked)
                    matching(P.a, and: P.a, file: "2", line: 2) | when(.coin) | then(.locked)
                }
            }
        ) {
            func assertError(
                _ e: MatchError?,
                expectedFile: String,
                expectedLine: Int,
                line: UInt = #line
            ) {
                XCTAssertEqual([expectedFile], e?.files, line: line)
                XCTAssertEqual([expectedLine], e?.lines, line: line)
                XCTAssert(e?.description.contains("P.a, P.a") ?? false, line: line)
            }
            
            let errors = ($0 as? SwiftFSMError)?.errors
            XCTAssertEqual(2, errors?.count)
            
            assertError(errors?.first as? MatchError, expectedFile: "1", expectedLine: 1)
            assertError(errors?.last as? MatchError, expectedFile: "2", expectedLine: 2)
        }
    }
    
    func testNothingToOverrideThrowsErrors() {
        XCTAssertThrowsError (
            try fsm.buildTable {
                define(.locked) {
                    override { when(.coin) | then(.unlocked) }
                }
            }
        ) {
            let errors = ($0 as? SwiftFSMError)?.errors
            XCTAssertEqual(1, errors?.count)
            XCTAssert(errors?.first is SemanticValidationNode.NothingToOverride)
        }
    }
    
    func testOutOfOrderOverridesThrowErrors() {
        XCTAssertThrowsError (
            try fsm.buildTable {
                let s = SuperState {
                    override { when(.coin) | then(.unlocked) }
                }
                
                define(.locked, adopts: s) {
                    when(.coin) | then(.unlocked)
                }
            }
        ) {
            let errors = ($0 as? SwiftFSMError)?.errors
            XCTAssertEqual(1, errors?.count)
            XCTAssert(errors?.first is SemanticValidationNode.OverrideOutOfOrder)
        }
    }
}

enum Value<T: Hashable>: Hashable {
    case some(T), any

    var value: T? {
        if case let .some(value) = self {
            return value
        }
        return nil
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.isSome, rhs.isSome else { return true }

        if case let .some(lhsValue) = lhs, case let .some(rhsValue) = rhs {
            return lhsValue == rhsValue
        }

        return false
    }

    private var isSome: Bool {
        return if case .some(_) = self {
            true
        } else {
            false
        }
    }

    private var isAny: Bool {
        return if case .any = self {
            true
        } else {
            false
        }
    }
}

enum ComplexEvent: EventWithValues {
    case didSetValue(Animal)
    case didSetOtherValue(Value<String>)
    case null
}

enum Animal: EventValue {
    case cat, dog, fish, any
}

protocol EventWithValues: Hashable { }
extension EventWithValues {
    func hash(into hasher: inout Hasher) {
        hasher.combine(String.caseName(self))
    }
}

protocol EventValue: Hashable, CaseIterable {
    static var any: Self { get }
}


extension EventValue {
    static func == (lhs: Self, rhs: Self) -> Bool {
        guard
            lhs.caseName != Self.any.caseName,
            rhs.caseName != Self.any.caseName
        else {
            return true
        }

        return lhs.caseName == rhs.caseName
    }

    var caseName: String {
        String.caseName(self)
    }
}

extension String {
    static func caseName(_ enumInstance: Any) -> String {
        String(String(describing: enumInstance).split(separator: "(").first!)
    }
}

final class LazyFSMEventPassingIntegrationTests: FSMEventPassingIntegrationTests {
    override func makeSUT<_State, _Event>(
        initialState: _State,
        actionsPolicy: _FSMBase<_State, _Event>.StateActionsPolicy = .executeOnChangeOnly
    ) -> _FSMBase<_State, _Event> where _State : Hashable, _Event : Hashable {
        LazyFSM(initialState: initialState, actionsPolicy: actionsPolicy)
    }
}

class FSMEventPassingIntegrationTests: FSMTestsBase<TurnstileState, ComplexEvent> {
    override func makeSUT<_State, _Event>(
        initialState: _State,
        actionsPolicy: _FSMBase<_State, _Event>.StateActionsPolicy = .executeOnChangeOnly
    ) -> _FSMBase<_State, _Event> where _State : Hashable, _Event : Hashable {
        FSM(initialState: initialState, actionsPolicy: actionsPolicy)
    }

    override var initialState: TurnstileState { .locked }

    func testEventPassing() {
        var event = ComplexEvent.null

        func assertValue(_ expectedValue: Animal, line: UInt = #line) {
            if case let .didSetValue(actualValue) = event {
                XCTAssertEqual(expectedValue, actualValue, line: line)
            } else {
                XCTFail(line: line)
            }

            event = .null
        }

        func setEvent(_ e: ComplexEvent) {
            event = e
        }

        try! fsm.buildTable {
            define(.locked) {
                when(.didSetValue(.cat))  | then() | setEvent
                when(.didSetValue(.fish)) | then() | setEvent
            }

            define(.unlocked) {
                when(.didSetValue(.any)) | then() | setEvent
            }
        }

        fsm.handleEvent(.didSetValue(.cat))
        assertValue(.cat)

        fsm.handleEvent(.didSetValue(.fish))
        assertValue(.fish)

        fsm.handleEvent(.didSetValue(.dog))
        XCTAssertEqual(event, .null)

        fsm.state = AnyHashable(State.unlocked)
        fsm.handleEvent(.didSetValue(.cat))
        assertValue(.cat)

        fsm.handleEvent(.didSetValue(.fish))
        assertValue(.fish)
    }

    func testEventPassingWithValue() {
        var event = ComplexEvent.null

        func assertValue(_ expectedValue: String, line: UInt = #line) {
            if case let .didSetOtherValue(actualValue) = event {
                XCTAssertEqual(expectedValue, actualValue.value, line: line)
            } else {
                XCTFail(line: line)
            }

            event = .null
        }

        func setEvent(_ e: ComplexEvent) {
            event = e
        }

        try! fsm.buildTable {
            define(.locked) {
                when(.didSetOtherValue(.some("cat"))) | then() | setEvent
                when(.didSetOtherValue(.some("fish"))) | then() | setEvent
            }

            define(.unlocked) {
                when(.didSetOtherValue(.any)) | then() | setEvent
            }
        }

        fsm.handleEvent(.didSetOtherValue(.some("cat")))
        assertValue("cat")

        fsm.handleEvent(.didSetOtherValue(.some("fish")))
        assertValue("fish")

        fsm.handleEvent(.didSetOtherValue(.some("dog")))
        XCTAssertEqual(event, .null)

        fsm.state = AnyHashable(State.unlocked)
        fsm.handleEvent(.didSetOtherValue(.some("cat")))
        assertValue("cat")

        fsm.handleEvent(.didSetOtherValue(.some("fish")))
        assertValue("fish")
    }
}

private extension Match {
    func isEqual(_ other: Match) -> Bool {
        self == other && file == other.file && line == other.line
    }
}

private extension AnyTraceable {
    func isEqual(_ other: AnyTraceable) -> Bool {
        self == other && file == other.file && line == other.line
    }
}
