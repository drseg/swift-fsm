import Foundation
import Testing
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
    
    class override var initialState: TurnstileState { .locked }
}

class FSMIntegrationTests_Turnstile: FSMIntegrationTests {
    func assertEventAction(
        _ e: Event,
        _ a: String,
        fsm: SUT,
        location: SourceLocation = #_sourceLocation
    ) async {
        await assertEventAction(e, a.isEmpty ? [] : [a], fsm: fsm, location: location)
    }
    
    func assertEventAction(
        _ e: Event,
        _ a: [String],
        fsm: SUT,
        location: SourceLocation = #_sourceLocation
    ) async {
        actual += a
        await fsm.handleEvent(e)
        #expect(actions == actual, sourceLocation: location)
    }
    
    func assertTurnstile(fsm: SUT) async {
        await assertEventAction(.coin,  "unlock", fsm: fsm)
        await assertEventAction(.pass,  "lock", fsm: fsm)
        await assertEventAction(.pass,  "alarmOn", fsm: fsm)
        await assertEventAction(.reset, ["alarmOff", "lock"], fsm: fsm)
        await assertEventAction(.coin,  "unlock", fsm: fsm)
        await assertEventAction(.coin,  "thankyou", fsm: fsm)
        await assertEventAction(.coin,  "thankyou", fsm: fsm)
        await assertEventAction(.reset, "lock", fsm: fsm)
    }
    
    @Test(arguments: eagerAndLazy)
    func turnstile(_ fsm: SUT) async throws {
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
        
        await assertTurnstile(fsm: fsm)
    }
    
    @Test(arguments: eagerAndLazy)
    func conditionTurnstile(_ fsm: SUT) async throws {
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

        await assertEventAction(.coin,  "", fsm: fsm)
        await assertEventAction(.pass,  "", fsm: fsm)
        await assertEventAction(.reset,  "", fsm: fsm)

        fsm.state = AnyHashable(State.unlocked)

        await assertEventAction(.coin,  "", fsm: fsm)
        await assertEventAction(.pass,  "", fsm: fsm)
        await assertEventAction(.reset,  "", fsm: fsm)

        fsm.state = AnyHashable(State.alarming)

        await assertEventAction(.reset,  "", fsm: fsm)
    }
    
    @Test(arguments: eagerAndLazy)
    func overrideTurnstile(_ fsm: SUT) async throws {
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
        
        await assertEventAction(.reset, "thankyou", fsm: fsm)
        
        fsm.state = AnyHashable(State.unlocked)
        await assertEventAction(.reset, ["lock", "lock"], fsm: fsm)
        
        fsm.state = AnyHashable(State.alarming)
        await assertEventAction(.reset, ["alarmOff", "lock"], fsm: fsm)
    }
    
    func fail() { Issue.record("should not have been called") }
    
    @Test(arguments: eagerAndLazy)
    func chainedOverrides(_ fsm: SUT) async throws {
        try fsm.buildTable {
            let s1 = SuperState { when(.coin) | then(.unlocked) | fail  }
            let s2 = SuperState(adopts: s1) { overriding { when(.coin) | then(.unlocked) | fail } }
            let s3 = SuperState(adopts: s2) { overriding { when(.coin) | then(.unlocked) | fail } }
            let s4 = SuperState(adopts: s3) { overriding { when(.coin) | then(.unlocked) | fail } }
            
            define(.locked, adopts: s4) {
                overriding { when(.coin) | then(.unlocked) | unlock }
            }
        }

        await assertEventAction(.coin, "unlock", fsm: fsm)
    }
}

class FSMIntegrationTests_PredicateTurnstile: FSMIntegrationTests {
    enum Enforcement: Predicate { case strong, weak }
    enum Reward: Predicate { case punishing, rewarding }
    
    func idiot() { actions.append("idiot") }
    
    func assertEventAction(
        _ e: Event,
        _ a: String,
        fsm: SUT,
        location: SourceLocation = #_sourceLocation
    ) async {
        await assertEventAction(e, [a], fsm: fsm, location: location)
    }
    
    func assertEventAction(
        _ e: Event,
        _ a: [String],
        fsm: SUT,
        location: SourceLocation = #_sourceLocation
    ) async {
        if !(a.first?.isEmpty ?? false) {
            actual += a
        }
        await fsm.handleEvent(e, predicates: [Enforcement.weak, Reward.punishing], isolation: nil)
        #expect(actions == actual, sourceLocation: location)
    }
    
    func assertTable(fsm: SUT) async {
        await assertEventAction(.coin,  "unlock", fsm: fsm)
        await assertEventAction(.pass,  "lock", fsm: fsm)
        await assertEventAction(.pass,  "", fsm: fsm)
        await assertEventAction(.reset, "", fsm: fsm)
        await assertEventAction(.coin,  "unlock", fsm: fsm)
        await assertEventAction(.coin,  "idiot", fsm: fsm)
        await assertEventAction(.coin,  "idiot", fsm: fsm)
        await assertEventAction(.reset, "lock", fsm: fsm)
    }
    
    @Test(arguments: eagerAndLazy)
    func predicateTurnstile(_ fsm: SUT) async throws {
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
        
        await assertTable(fsm: fsm)
    }
    
    @Test(arguments: eagerAndLazy)
    func deduplicatedPredicateTurnstile(_ fsm: SUT) async throws {
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
        
        await assertTable(fsm: fsm)
    }
    
    @Test(arguments: eagerAndLazy)
    func actionsBlockTurnstile(_ fsm: SUT) async throws {
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
        
        await assertTable(fsm: fsm)
    }
}

class FSMIntegrationTests_NestedBlocks: FSMIntegrationTests {
    @Test(arguments: eagerAndLazy)
    func multiplePredicateBlocks(_ fsm: SUT) async throws {
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
        #expect(["thankyou"] == actions)
        
        await fsm.handleEvent(.coin, predicates: P.b, Q.a, R.a, S.a, T.a, U.a, V.a)
        #expect(["thankyou", "thankyou"] == actions)
        
        actions = []
        await fsm.handleEvent(.coin, predicates: P.c, Q.a, R.a, S.a, T.a, U.a, V.a)
        #expect([] == actions)
        
        actions = []
        await fsm.handleEvent(.coin, predicates: P.a, Q.b, R.b, S.b, T.b, U.b, V.b)
        #expect(["unlock"] == actions)
    }
    
    @Test(arguments: eagerAndLazy)
    func multipleActionsBlocks(_ fsm: SUT) async throws {
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
        #expect(["thankyou", "lock", "unlock"] == actions)
    }
}

class FSMIntegrationTests_Errors: FSMIntegrationTests {
    func assertEmptyError(
        _ e: EmptyBuilderError?,
        expectedCaller: String,
        expectedLine: Int,
        location: SourceLocation = #_sourceLocation
    ) {
        #expect(expectedCaller == e?.caller, sourceLocation: location)
        #expect("file" == e?.file, sourceLocation: location)
        #expect(expectedLine == e?.line, sourceLocation: location)
    }
    
    @Test(arguments: eagerAndLazy)
    func emptyBlockThrowsError(_ fsm: SUT) {
        #expect(performing: {
            try fsm.buildTable {
                define(.locked, file: "file", line: 1 ) { }
            }
        }, throws: {
            let errors = ($0 as? SwiftFSMError)?.errors
            #expect(1 == errors?.count)
            let error = errors?.first as? EmptyBuilderError
            
            assertEmptyError(error, expectedCaller: "define", expectedLine: 1)
            return true
        })
    }
    
    @Test(arguments: eagerAndLazy)
    func emptyBlocksThrowErrors(_ fsm: SUT) {
        #expect(performing: {
            try fsm.buildTable {
                define(.locked) {
                    matching(P.a, file: "file", line: 1) {}
                    then(.locked, file: "file", line: 2) {}
                    when(.pass,   file: "file", line: 3) {}
                }
            }
        }, throws: {
            let errors = ($0 as? SwiftFSMError)?.errors
            #expect(3 == errors?.count)
            
            let e1 = errors?(0) as? EmptyBuilderError
            assertEmptyError(e1, expectedCaller: "matching", expectedLine: 1)
            
            let e2 = errors?(1) as? EmptyBuilderError
            assertEmptyError(e2, expectedCaller: "then", expectedLine: 2)
            
            let e3 = errors?(2) as? EmptyBuilderError
            assertEmptyError(e3, expectedCaller: "when", expectedLine: 3)
            
            return true
        })
    }
    
    @Test(arguments: eagerAndLazy)
    func duplicatesAndClashesThrowErrors(_ fsm: SUT) {
        typealias DE = SemanticValidationNode.DuplicatesError
        typealias CE = SemanticValidationNode.ClashError
        
        #expect(performing: {
            try fsm.buildTable {
                define(.locked, line: 1) {
                    matching(P.a, line: 2) | when(.coin, line: 3) | then(.unlocked, line: 4)
                    matching(P.a, line: 2) | when(.coin, line: 3) | then(.unlocked, line: 4)
                    matching(P.a, line: 2) | when(.coin, line: 3) | then(.locked, line: 4)
                }
            }
        }, throws: {
            let errors = ($0 as? SwiftFSMError)?.errors
            #expect(2 == errors?.count, "\(String(describing: errors))")
            
            let e1 = errors?.compactMap { $0 as? DE }.first?.duplicates.values
            let e2 = errors?.compactMap { $0 as? CE }.first?.clashes.values

            #expect(1 == e1?.count)
            #expect(1 == e2?.count)
            
            let duplicates = e1?.first ?? []
            let clashes = e2?.first ?? []
            
            #expect(2 == duplicates.count)
            #expect(2 == clashes.count)
            
            #expect(
                duplicates.allSatisfy {
                    $0.state.isEqual(AnyTraceable(State.locked, file: #file, line: 1)) &&
                    $0.descriptor.isEqual(MatchDescriptorChain(all: P.a, file: #file, line: 2)) &&
                    $0.event.isEqual(AnyTraceable(Event.coin, file: #file, line: 3)) &&
                    $0.nextState.isEqual(AnyTraceable(State.unlocked, file: #file, line: 4))
                }, "\(duplicates)"
            )
            
            #expect(
                clashes.allSatisfy {
                    $0.state.isEqual(AnyTraceable(State.locked, file: #file, line: 1)) &&
                    $0.descriptor.isEqual(MatchDescriptorChain(all: P.a, file: #file, line: 2)) &&
                    $0.event.isEqual(AnyTraceable(Event.coin, file: #file, line: 3))
                }, "\(clashes)"
            )
            
            #expect(clashes.contains { $0.nextState.base == AnyHashable(State.locked) })
            #expect(clashes.contains { $0.nextState.base == AnyHashable(State.unlocked) })
            
            return true
        })
    }
    
    @Test(arguments: eagerAndLazy)
    func implicitMatchClashesThrowErrors(_ fsm: SUT) {
        #expect(performing: {
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
        }, throws: {
            let errors = ($0 as? SwiftFSMError)?.errors
            #expect(1 == errors?.count)
            
            let error = errors?.first as? MatchResolvingNode.Eager.ImplicitClashesError
            let clashes = error?.clashes.values
            #expect(1 == clashes?.count)
            
            let clash = clashes?.first
            #expect(2 == clash?.count)
            
            #expect(clash?.contains {
                $0.state.isEqual(AnyTraceable(State.locked, file: "1", line: 1)) &&
                $0.event.isEqual(AnyTraceable(Event.coin, file: "1", line: 1)) &&
                $0.descriptor.isEqual(MatchDescriptorChain(all: P.a, file: "1", line: 1))
            } ?? false, "\(String(describing: clash))")
            
            #expect(clash?.contains {
                $0.state.isEqual(AnyTraceable(State.locked, file: "1", line: 1)) &&
                $0.event.isEqual(AnyTraceable(Event.coin, file: "2", line: 2)) &&
                $0.descriptor.isEqual(MatchDescriptorChain(all: Q.a, file: "2", line: 2))
            } ?? false, "\(String(describing: clash))")
            
            #expect(AnyHashable(State.unlocked) == clash?.first?.nextState.base)
            #expect(AnyHashable(State.locked) == clash?.last?.nextState.base)
            
            return true
        })
    }
    
    @Test(arguments: eagerAndLazy)
    func matchesThrowErrors(_ fsm: SUT) {
        #expect(performing: {
            try fsm.buildTable {
                define(.locked) {
                    matching(P.a, or: P.a, file: "1", line: 1)  | when(.coin) | then(.unlocked)
                    matching(P.a, and: P.a, file: "2", line: 2) | when(.coin) | then(.locked)
                }
            }
        }, throws: {
            func assertError(
                _ e: MatchError?,
                expectedFile: String,
                expectedLine: Int,
                location: SourceLocation = #_sourceLocation
            ) {
                #expect([expectedFile] == e?.files, sourceLocation: location)
                #expect([expectedLine] == e?.lines, sourceLocation: location)
                #expect(e?.description.contains("P.a, P.a") ?? false, sourceLocation: location)
            }
            
            let errors = ($0 as? SwiftFSMError)?.errors
            #expect(2 == errors?.count)
            
            assertError(errors?.first as? MatchError, expectedFile: "1", expectedLine: 1)
            assertError(errors?.last as? MatchError, expectedFile: "2", expectedLine: 2)
            
            return true
        })
    }
    
    @Test(arguments: eagerAndLazy)
    func nothingToOverrideThrowsErrors(_ fsm: SUT) {
        #expect(performing: {
            try fsm.buildTable {
                define(.locked) {
                    overriding { when(.coin) | then(.unlocked) }
                }
            }
        }, throws: {
            let errors = ($0 as? SwiftFSMError)?.errors
            #expect(1 == errors?.count)
            #expect(errors?.first is SemanticValidationNode.NothingToOverride)
            return true
        })
    }
    
    @Test(arguments: eagerAndLazy)
    func outOfOrderOverridesThrowErrors(_ fsm: SUT) {
        #expect(performing: {
            let s = SuperState {
                overriding { when(.coin) | then(.unlocked) }
            }
            try fsm.buildTable {
                define(.locked, adopts: s) {
                    when(.coin) | then(.unlocked)
                }
            }
        }, throws: {
            let errors = ($0 as? SwiftFSMError)?.errors
            #expect(1 == errors?.count)
            #expect(errors?.first is SemanticValidationNode.OverrideOutOfOrder)
            return true
        })
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

class FSMEventPassingIntegrationTests: FSMTestsBase<TurnstileState, ComplexEvent> {
    override class var initialState: TurnstileState { .locked }
    
    var event = ComplexEvent.null

    func setEvent(_ e: ComplexEvent) {
        event = e
    }

    func assertEventPassing(
        cat: ComplexEvent,
        fish: ComplexEvent,
        dog: ComplexEvent,
        any: ComplexEvent,
        fsm: SUT
    ) async {
        func assertValue(_ expectedValue: ComplexEvent) {
            #expect(expectedValue.stringValue == event.stringValue)
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
        #expect(event == .null)

        fsm.state = AnyHashable(State.unlocked)
        await fsm.handleEvent(cat)
        assertValue(cat)

        await fsm.handleEvent(fish)
        assertValue(fish)
    }

    @Test(arguments: eagerAndLazy)
    func EventPassingUsingValueEnum(_ fsm: SUT) async {
        await assertEventPassing(
            cat: .didSetOtherValue(.some("cat")),
            fish: .didSetOtherValue(.some("fish")),
            dog: .didSetOtherValue(.some("dog")),
            any: .didSetOtherValue(.any),
            fsm: fsm
        )
    }

    @Test(arguments: eagerAndLazy)
    func DuplicatesDetectedAsExpectedUsingStruct(_ fsm: SUT) {
        #expect(performing: {
            try fsm.buildTable {
                define(.locked) {
                    when(.didSetOtherValue(.some("cat"))) | then() | setEvent
                    when(.didSetOtherValue(.any))         | then() | setEvent
                }
            }
        }, throws: { _ in true })
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
