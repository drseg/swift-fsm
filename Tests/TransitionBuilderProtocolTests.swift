//
//  TransitionBuilderProtocolTests.swift
//  FiniteStateMachineTests
//
//  Created by Daniel Segall on 12/02/2023.
//

import XCTest
@testable import FiniteStateMachine

enum TurnstileState: String, SP {
    case locked, unlocked, alarming
}

enum TurnstileEvent: String, EP {
    case reset, coin, pass
}

class TransitionBuilderProtocolTests: XCTestCase, TransitionBuilder {
    typealias State = TurnstileState
    typealias Event = TurnstileEvent
    
    func assertContains(
        _ e: Event,
        _ s: State,
        _ ss: SuperState<State, Event>,
        _ file: StaticString = #file,
        _ line: UInt = #line
    ) {
        XCTAssertTrue(
            ss.wtas.contains(
                WhenThenAction(when: e, then: s, actions: [])
            )
            , "\n(\(e), \(s)) not found in: \n\(ss.description)",
            file: file, line: line)
    }
    
    func assertContains(
        _ g: State,
        _ w: Event,
        _ t: State,
        _ tr: TableRow<State, Event>,
        _ file: StaticString = #file,
        _ line: UInt = #line
    ) {
        XCTAssertTrue(
            tr.transitions.contains(
                Transition(givenState: g,
                           event: w,
                           nextState: t,
                           actions: [])
            )
            , "\n(\(g), \(w), \(t)) not found in: \n\(tr.description)",
            file: file, line: line)
    }
    
    func testSuperState() {
        let s = SuperState {
            when(.reset, then: .unlocked, actions: [])
            when(.coin, then: .unlocked) { }
            when(.pass, then: .locked)
        }
        
        assertContains(.reset, .unlocked, s)
        assertContains(.coin, .unlocked, s)
        assertContains(.pass, .locked, s)
    }
    
    func testImplements() {
        let s = SuperState {
            when(.reset, then: .unlocked, actions: [])
            when(.coin, then: .unlocked) { }
            when(.pass, then: .locked)
        }
        
        let tr = define(.locked) {
            implements(s)
        }
        
        let trs = tr.modifiers.superStates.first!
        assertContains(.reset, .unlocked, trs)
        assertContains(.coin, .unlocked, trs)
        assertContains(.pass, .locked, trs)
    }
    
    func testEntryActions() {
        let actions = [{}, {}]
        
        let tr = define(.locked) {
            onEnter(actions)
        }
        
        XCTAssertEqual(2, tr.modifiers.entryActions.count)
    }
    
    func testExitActions() {
        let actions = [{}, {}]
        
        let tr = define(.locked) {
            onExit(actions)
        }
        
        XCTAssertEqual(2, tr.modifiers.exitActions.count)
    }
}

extension TableRow<TurnstileState, TurnstileEvent> {
    var description: String {
        transitions.map(\.description).reduce("", +)
    }
}

extension SuperState<TurnstileState, TurnstileEvent> {
    var description: String {
        wtas.map(\.description).reduce("", +)
    }
}

extension WhenThenAction<TurnstileState, TurnstileEvent> {
    var description: String {
        String("(\(when.rawValue), \(then.rawValue))\n")
    }
}

extension Transition<TurnstileState, TurnstileEvent> {
    var description: String {
        String("(\(givenState.rawValue), \(event.rawValue), \(nextState.rawValue))\n")
    }
}

