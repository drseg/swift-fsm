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

class FSMIntegrationTests: FSMTestsBase<TurnstileState, TurnstileEvent>, @unchecked Sendable {
    var actions = [String]()
    var actual = [String]()
    
    func alarmOn()  { actions.append("alarmOn")  }
    func alarmOff() { actions.append("alarmOff") }
    func lock()     { actions.append("lock")     }
    func unlock()   { actions.append("unlock")   }
    func thankyou() { actions.append("thankyou") }
    
    override var initialState: TurnstileState { .locked }
    
    override func makeSUT() -> any FSMProtocol<State, Event> {
        makeEager()
    }
}

class FSMIntegrationTests_Turnstile: FSMIntegrationTests, @unchecked Sendable {
    func assertEventAction(_ e: Event, _ a: String, line: UInt = #line) async {
        await assertEventAction(e, a.isEmpty ? [] : [a], line: line)
    }
    
    func assertEventAction(_ e: Event, _ a: [String], line: UInt = #line) async {
        actual += a
        await fsm.handleEvent(e)
        XCTAssertEqual(actions, actual, line: line)
    }
    
    func assertTurnstile() async {
        await assertEventAction(.coin,  "unlock")
        await assertEventAction(.pass,  "lock")
        await assertEventAction(.pass,  "alarmOn")
        await assertEventAction(.reset, ["alarmOff", "lock"])
        await assertEventAction(.coin,  "unlock")
        await assertEventAction(.coin,  "thankyou")
        await assertEventAction(.coin,  "thankyou")
        await assertEventAction(.reset, "lock")
    }
    
    func testTurnstile() async throws {
        try fsm.buildTable {
            let resetable = SuperState {
                when(.reset) | then(.locked)
            }

            define(.locked, adopts: resetable, onEntry: Array(lock)) {
                when(.coin) | then(.unlocked)
                when(.pass) | then(.alarming)
            }
            
            define(.unlocked, adopts: resetable, onEntry: Array(unlock)) {
                when(.coin) | then(.unlocked) | thankyou
                when(.pass) | then(.locked)
            }
            
            define(.alarming, adopts: resetable, onEntry: Array(alarmOn), onExit: Array(alarmOff))
        }
        
        await assertTurnstile()
    }
    
    func testConditionTurnstile() async throws {
        let bool = false
        
        try fsm.buildTable {
            let resetable = SuperState {
                condition { bool } | when(.reset) | then(.locked)
            }

            define(.locked, adopts: resetable, onEntry: Array(lock)) {
                condition { bool } | when(.coin) | then(.unlocked)
                condition { bool } | when(.pass) | then(.alarming)
            }

            define(.unlocked, adopts: resetable, onEntry: Array(unlock)) {
                condition { bool } | when(.coin) | then(.unlocked) | thankyou
                condition { bool } | when(.pass) | then(.locked)
            }

            define(.alarming, adopts: resetable, onEntry: Array(alarmOn), onExit: Array(alarmOff))
        }

        await assertEventAction(.coin,  "")
        await assertEventAction(.pass,  "")
        await assertEventAction(.reset,  "")

        fsm.state = AnyHashable(State.unlocked)

        await assertEventAction(.coin,  "")
        await assertEventAction(.pass,  "")
        await assertEventAction(.reset,  "")

        fsm.state = AnyHashable(State.alarming)

        await assertEventAction(.reset,  "")
    }
    
    func testOverrideTurnstile() async throws {
        try fsm.buildTable {
            let resetable = SuperState {
                when(.reset) | then(.locked)
            }

            define(.locked, adopts: resetable, onEntry: Array(lock)) {
                when(.coin) | then(.unlocked)
                when(.pass) | then(.alarming)
                
                overriding {
                    when(.reset) | then(.locked) | thankyou
                }
            }
            
            define(.unlocked, adopts: resetable, onEntry: Array(unlock)) {
                when(.coin) | then(.unlocked) | thankyou
                when(.pass) | then(.locked)
                
                overriding {
                    when(.reset) | then(.locked) | lock
                }
            }
            
            define(.alarming, adopts: resetable, onEntry: Array(alarmOn), onExit: Array(alarmOff))
        }
        
        await assertEventAction(.reset, "thankyou")
        
        fsm.state = AnyHashable(State.unlocked)
        await assertEventAction(.reset, ["lock", "lock"])
        
        fsm.state = AnyHashable(State.alarming)
        await assertEventAction(.reset, ["alarmOff", "lock"])
    }
    
    func fail() { XCTFail("should not have been called") }
    
    func testChainedOverrides() async throws {
        try fsm.buildTable {
            let s1 = SuperState { when(.coin) | then(.unlocked) | fail  }
            let s2 = SuperState(adopts: s1) { overriding { when(.coin) | then(.unlocked) | fail } }
            let s3 = SuperState(adopts: s2) { overriding { when(.coin) | then(.unlocked) | fail } }
            let s4 = SuperState(adopts: s3) { overriding { when(.coin) | then(.unlocked) | fail } }
            
            define(.locked, adopts: s4) {
                overriding { when(.coin) | then(.unlocked) | unlock }
            }
        }

        await assertEventAction(.coin, "unlock")
    }
}

final class LazyFSMIntegrationTests_Turnstile: FSMIntegrationTests_Turnstile, @unchecked Sendable {
    override func makeSUT() -> any FSMProtocol<State, Event> {
        makeLazy()
    }
}

class FSMIntegrationTests_PredicateTurnstile: FSMIntegrationTests, @unchecked Sendable {
    enum Enforcement: Predicate { case strong, weak }
    enum Reward: Predicate { case punishing, rewarding }
    
    func idiot() { actions.append("idiot") }
    
    func assertEventAction(_ e: Event, _ a: String, line: UInt = #line) async {
        await assertEventAction(e, [a], line: line)
    }
    
    func assertEventAction(_ e: Event, _ a: [String], line: UInt = #line) async {
        if !(a.first?.isEmpty ?? false) {
            actual += a
        }
        await fsm.handleEvent(e, predicates: [Enforcement.weak, Reward.punishing])
        XCTAssertEqual(actions, actual, line: line)
    }
    
    func assertTable() async {
        await assertEventAction(.coin,  "unlock")
        await assertEventAction(.pass,  "lock")
        await assertEventAction(.pass,  "")
        await assertEventAction(.reset, "")
        await assertEventAction(.coin,  "unlock")
        await assertEventAction(.coin,  "idiot")
        await assertEventAction(.coin,  "idiot")
        await assertEventAction(.reset, "lock")
    }
    
    func testPredicateTurnstile() async throws {
        try fsm.buildTable {
            let resetable = SuperState {
                when(.reset) | then(.locked)
            }
            
            define(.locked, adopts: resetable, onEntry: Array(lock)) {
                matching(Enforcement.weak)   | when(.pass) | then(.locked)
                matching(Enforcement.strong) | when(.pass) | then(.alarming)
                
                when(.coin) | then(.unlocked)
            }
            
            define(.unlocked, adopts: resetable, onEntry: Array(unlock)) {
                matching(Reward.rewarding) | when(.coin) | then(.unlocked) | thankyou
                matching(Reward.punishing) | when(.coin) | then(.unlocked) | idiot
                
                when(.pass) | then(.locked)
            }
            
            define(.alarming, adopts: resetable, onEntry: Array(alarmOn), onExit: Array(alarmOff))
        }
        
        await assertTable()
    }
    
    func testDeduplicatedPredicateTurnstile() async throws {
        try fsm.buildTable {
            let resetable = SuperState {
                when(.reset) | then(.locked)
            }
            
            define(.locked, adopts: resetable, onEntry: Array(lock)) {
                when(.pass) {
                    matching(Enforcement.weak)   | then(.locked)
                    matching(Enforcement.strong) | then(.alarming)
                }
                
                when(.coin) | then(.unlocked)
            }
            
            define(.unlocked, adopts: resetable, onEntry: Array(unlock)) {
                when(.coin) {
                    then(.unlocked) {
                        matching(Reward.rewarding) | thankyou
                        matching(Reward.punishing) | idiot
                    }
                }
                
                when(.pass) | then(.locked)
            }
            
            define(.alarming, adopts: resetable, onEntry: Array(alarmOn), onExit: Array(alarmOff))
        }
        
        await assertTable()
    }
    
    func testActionsBlockTurnstile() async throws {
        try fsm.buildTable {
            let resetable = SuperState {
                when(.reset) | then(.locked)
            }
            
            define(.locked, adopts: resetable, onEntry: Array(lock)) {
                when(.pass) {
                    matching(Enforcement.weak)   | then(.locked)
                    matching(Enforcement.strong) | then(.alarming)
                }
                
                when(.coin) | then(.unlocked)
            }
            
            define(.unlocked, adopts: resetable, onEntry: Array(unlock)) {
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
            
            define(.alarming, adopts: resetable, onEntry: Array(alarmOn), onExit: Array(alarmOff))
        }
        
        await assertTable()
    }
}

class LazyFSMIntegrationTests_PredicateTurnstile: FSMIntegrationTests_PredicateTurnstile, @unchecked Sendable {
    override func makeSUT() -> any FSMProtocol<State, Event> {
        makeLazy()
    }
}

class FSMIntegrationTests_NestedBlocks: FSMIntegrationTests, @unchecked Sendable {
    func testMultiplePredicateBlocks() async throws {
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
        
        await fsm.handleEvent(.coin, predicates: P.a, Q.a, R.a, S.a, T.a, U.a, V.a)
        XCTAssertEqual(["thankyou"], actions)
        
        await fsm.handleEvent(.coin, predicates: P.b, Q.a, R.a, S.a, T.a, U.a, V.a)
        XCTAssertEqual(["thankyou", "thankyou"], actions)
        
        actions = []
        await fsm.handleEvent(.coin, predicates: P.c, Q.a, R.a, S.a, T.a, U.a, V.a)
        XCTAssertEqual([], actions)
        
        actions = []
        await fsm.handleEvent(.coin, predicates: P.a, Q.b, R.b, S.b, T.b, U.b, V.b)
        XCTAssertEqual(["unlock"], actions)
    }
    
    func testMultiplActionsBlocks() async throws {
        try fsm.buildTable {
            define(.locked) {
                actions(thankyou) {
                    actions(lock) {
                        matching(P.a) | when(.coin) | then(.locked) | unlock
                    }
                }
            }
        }
        
        await fsm.handleEvent(.coin, predicates: P.a)
        XCTAssertEqual(["thankyou", "lock", "unlock"], actions)
    }
}


class LazyFSMIntegrationTests_NestedBlocks: FSMIntegrationTests_NestedBlocks, @unchecked Sendable {
    override func makeSUT() -> any FSMProtocol<State, Event> {
        makeLazy()
    }
}

class FSMIntegrationTests_Errors: FSMIntegrationTests, @unchecked Sendable {
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
                    $0.descriptor.isEqual(MatchDescriptorChain(all: P.a, file: #file, line: 2)) &&
                    $0.event.isEqual(AnyTraceable(Event.coin, file: #file, line: 3)) &&
                    $0.nextState.isEqual(AnyTraceable(State.unlocked, file: #file, line: 4))
                }, "\(duplicates)"
            )
            
            XCTAssert(
                clashes.allSatisfy {
                    $0.state.isEqual(AnyTraceable(State.locked, file: #file, line: 1)) &&
                    $0.descriptor.isEqual(MatchDescriptorChain(all: P.a, file: #file, line: 2)) &&
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
                $0.descriptor.isEqual(MatchDescriptorChain(all: P.a, file: "1", line: 1))
            } ?? false, "\(String(describing: clash))")
            
            XCTAssert(clash?.contains {
                $0.state.isEqual(AnyTraceable(State.locked, file: "1", line: 1)) &&
                $0.event.isEqual(AnyTraceable(Event.coin, file: "2", line: 2)) &&
                $0.descriptor.isEqual(MatchDescriptorChain(all: Q.a, file: "2", line: 2))
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
                    overriding { when(.coin) | then(.unlocked) }
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
                    overriding { when(.coin) | then(.unlocked) }
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

class LazyFSMIntegrationTests_Errors: FSMIntegrationTests_Errors, @unchecked Sendable {
    override func makeSUT() -> any FSMProtocol<State, Event> {
        makeLazy()
    }
}

enum ComplexEvent: EventWithValues {    
    case didSetOtherValue(FSMValue<String>)
    case null

    var stringValue: String? {
        switch self {
        case let .didSetOtherValue(value): value.wrappedValue
        default: nil
        }
    }
}

class FSMEventPassingIntegrationTests: FSMTestsBase<TurnstileState, ComplexEvent>, @unchecked Sendable {
    override func makeSUT() -> any FSMProtocol<State, Event> {
        makeEager()
    }

    override var initialState: TurnstileState { .locked }
    var event = ComplexEvent.null

    func setEvent(_ e: ComplexEvent) {
        event = e
    }

    func assertEventPassing(
        cat: ComplexEvent,
        fish: ComplexEvent,
        dog: ComplexEvent,
        any: ComplexEvent
    ) async {
        func assertValue(_ expectedValue: ComplexEvent) {
            XCTAssertEqual(expectedValue.stringValue, event.stringValue)
            event = .null
        }

        try! fsm.buildTable {
            define(.locked) {
                when(cat)  | then() | setEvent
                when(fish) | then() | setEvent
            }

            define(.unlocked) {
                when(any) | then() | setEvent
            }
        }

        await fsm.handleEvent(cat)
        assertValue(cat)

        await fsm.handleEvent(fish)
        assertValue(fish)

        await fsm.handleEvent(dog)
        XCTAssertEqual(event, .null)

        fsm.state = AnyHashable(State.unlocked)
        await fsm.handleEvent(cat)
        assertValue(cat)

        await fsm.handleEvent(fish)
        assertValue(fish)
    }

    func testEventPassingUsingValueEnum() async {
        await assertEventPassing(cat: .didSetOtherValue(.some("cat")),
                                 fish: .didSetOtherValue(.some("fish")),
                                 dog: .didSetOtherValue(.some("dog")),
                                 any: .didSetOtherValue(.any))
    }

    func testDuplicatesDetectedAsExpectedUsingStruct() {
        XCTAssertThrowsError(
            try fsm.buildTable {
                define(.locked) {
                    when(.didSetOtherValue(.some("cat"))) | then() | setEvent
                    when(.didSetOtherValue(.any))         | then() | setEvent
                }
            }
        )
    }
}

final class LazyFSMEventPassingIntegrationTests: FSMEventPassingIntegrationTests, @unchecked Sendable {
    override func makeSUT() -> any FSMProtocol<State, Event> {
        makeLazy()
    }
}

private extension MatchDescriptorChain {
    func isEqual(_ other: MatchDescriptorChain) -> Bool {
        self == other && file == other.file && line == other.line
    }
}

private extension AnyTraceable {
    func isEqual(_ other: AnyTraceable) -> Bool {
        self == other && file == other.file && line == other.line
    }
}
