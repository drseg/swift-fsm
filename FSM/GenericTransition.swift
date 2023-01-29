//
//  SittingFSMInfix.swift
//  Sitting
//
//  Created by Daniel Segall on 28/01/2023.
//

import Foundation

struct Given<G> {
    let given: [G]
    
    init(_ given: G...) {
        self.given = given
    }
}

struct When<W> {
    let when: [W]
    
    init(_ when: W...) {
        self.when = when
    }
}

struct GivenWhen<G,W> {
    let given: G
    let when: W
}

struct Then<T> {
    let then: T
    
    init(_ then: T) {
        self.then = then
    }
}

struct GivenWhenThen<G, W> {
    let given: G
    let when: W
    let then: G
}

struct WhenThen<W,T> {
    let when: W
    let then: T
}

struct ThenAction<T> {
    let then: T
    let action: () -> Void
}

struct WhenThenAction<W,T> {
    let when: W
    let then: T
    let action: () -> Void
}

struct Action {
    let action: () -> Void
    
    init(_ action: @escaping () -> Void) {
        self.action = action
    }
}

struct Transition<G,W>: Equatable
where G: Hashable, W: Hashable {
    let givenState: G
    let event: W
    let nextState: G
    let action: () -> Void
    
    struct Key<G,W>: Hashable where G: Hashable, W: Hashable {
        let given: G
        let event: W
    }
    
    @resultBuilder
    struct Builder {
        static func buildBlock(
            _ transitions: [Transition]...
        ) -> [Key<G,W>: Transition] {
            transitions.flatMap {$0}.reduce(into: [Key<G,W>: Transition]()) {
                $0[Key(given: $1.givenState, event: $1.event)] = $1
            }
        }
        
        static func buildIf(
            _ values: [Key<G,W>: Transition]?
        ) -> [Transition] {
            if let values {
                return Array(values.values)
            } else {
                return [Transition<G,W>]()
            }
        }
        
        static func buildEither(
            first component: [Key<G,W>: Transition]
        ) -> [Transition] {
            Array(component.values)
        }
        
        static func buildEither(
            second component: [Key<G,W>: Transition]
        ) -> [Transition] {
            Array(component.values)
        }
    }
    
    static func build(
        @Transition.Builder _ content: () -> [Key<G,W>: Transition]
    ) -> [Key<G,W>: Transition] {
        content()
    }
    
    static func == (
        lhs: Transition<G,W>,
        rhs: Transition<G,W>
    ) -> Bool {
        lhs.givenState == rhs.givenState &&
        lhs.event == rhs.event &&
        lhs.nextState == rhs.nextState
    }
}

func |<G,W> (lhs: Given<G>, rhs: When<W>) -> [GivenWhen<G, W>] {
    lhs.given.reduce(into: [GivenWhen]()) { givenWhens, given in
        rhs.when.forEach {
            givenWhens.append(GivenWhen(given: given, when: $0))
        }
    }
}

func |<G,W> (
    lhs: Given<G>,
    rhs: [[WhenThen<W,G>]]
) -> [GivenWhenThen<G,W>] {
    lhs.given.reduce(into: [GivenWhenThen]()) { givenWhenThens, given in
        rhs.flatMap { $0 }.forEach {
            givenWhenThens.append(GivenWhenThen(given: given,
                                                when: $0.when,
                                                then: $0.then))
        }
    }
}

func |<G,W> (
    lhs: [GivenWhen<G, W>],
    rhs: Then<G>
) -> [GivenWhenThen<G,W>] {
    lhs.reduce(into: [GivenWhenThen]()) { givenWhenThens, givenWhen in
        givenWhenThens.append(GivenWhenThen(given: givenWhen.given,
                                            when: givenWhen.when,
                                            then: rhs.then))
    }
}

func |<G,W> (
    lhs: [GivenWhenThen<G,W>],
    rhs: Action
) -> [Transition<G,W>] {
    lhs.reduce(into: [Transition<G,W>]()) {
        $0.append(
            Transition(
                givenState: $1.given,
                event: $1.when,
                nextState: $1.then,
                action: rhs.action
            )
        )
    }
}

func |<W,T> (lhs: When<W>, rhs: Then<T>) -> [WhenThen<W,T>] {
    lhs.when.reduce(into: [WhenThen<W,T>]()) { whenThens, when in
        whenThens.append(WhenThen(when: when, then: rhs.then))
    }
}

func |<W,T> (
    lhs: [WhenThen<W,T>],
    rhs: Action
) -> [WhenThenAction<W,T>] {
    lhs.reduce(into: [WhenThenAction<W,T>]()) {
        $0.append(WhenThenAction(when: $1.when,
                                 then: $1.then,
                                 action: rhs.action))
    }
}

func |<W,T> (
    lhs: [[WhenThen<W,T>]],
    rhs: Action
) -> [WhenThenAction<W,T>] {
    lhs.flatMap { $0 }.reduce(into: [WhenThenAction<W,T>]()) {
        $0.append(WhenThenAction(when: $1.when,
                                 then: $1.then,
                                 action: rhs.action))
    }
}

func |<G,W> (
    lhs: Given<G>,
    rhs: [[WhenThenAction<W,G>]]
) -> [Transition<G,W>] {
    rhs.flatMap { $0 }.reduce(into: [Transition<G,W>]()) { ts, action in
        lhs.given.forEach { given in
            ts.append(
                Transition(
                    givenState: given,
                    event: action.when,
                    nextState: action.then,
                    action: action.action
                )
            )
        }
    }
}

infix operator |: AdditionPrecedence
