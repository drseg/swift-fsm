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

struct GivenWhenThen<G, W, T> {
    let given: G
    let when: W
    let then: T
}

struct WhenThen<W, T> {
    let when: W
    let then: T
}

struct ThenAction<T, A> {
    let then: T
    let action: (A) -> Void
}

struct WhenThenAction<W, T, A> {
    let when: W
    let then: T
    let action: (A) -> Void
}

struct Action<A> {
    let action: (A) -> Void
    
    init(_ action: @escaping (A) -> Void) {
        self.action = action
    }
}

struct Transition<G,W,T,A>: Equatable
where G: Hashable, W: Hashable, T: Hashable {
    let givenState: G
    let event: W
    let nextState: T
    let action: (A) -> Void
    
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
                return [Transition<G,W,T,A>]()
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
        lhs: Transition<G, W, T, A>,
        rhs: Transition<G, W, T, A>
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

func |<G,W,T> (
    lhs: Given<G>,
    rhs: [[WhenThen<W,T>]]
) -> [GivenWhenThen<G, W, T>] {
    lhs.given.reduce(into: [GivenWhenThen]()) { givenWhenThens, given in
        rhs.flatMap { $0 }.forEach {
            givenWhenThens.append(GivenWhenThen(given: given,
                                                when: $0.when,
                                                then: $0.then))
        }
    }
}

func |<G,W,T> (
    lhs: [GivenWhen<G, W>],
    rhs: Then<T>
) -> [GivenWhenThen<G,W,T>] {
    lhs.reduce(into: [GivenWhenThen]()) { givenWhenThens, givenWhen in
        givenWhenThens.append(GivenWhenThen(given: givenWhen.given,
                                            when: givenWhen.when,
                                            then: rhs.then))
    }
}

func |<G,W,T,A> (
    lhs: [GivenWhenThen<G,W,T>],
    rhs: Action<A>
) -> [Transition<G,W,T,A>] {
    lhs.reduce(into: [Transition<G,W,T,A>]()) {
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

func |<W,T,A> (
    lhs: [WhenThen<W,T>],
    rhs: Action<A>
) -> [WhenThenAction<W,T,A>] {
    lhs.reduce(into: [WhenThenAction<W,T,A>]()) {
        $0.append(WhenThenAction(when: $1.when,
                                 then: $1.then,
                                 action: rhs.action))
    }
}

func |<W,T,A> (
    lhs: [[WhenThen<W,T>]],
    rhs: Action<A>
) -> [WhenThenAction<W,T,A>] {
    lhs.flatMap { $0 }.reduce(into: [WhenThenAction<W,T,A>]()) {
        $0.append(WhenThenAction(when: $1.when,
                                 then: $1.then,
                                 action: rhs.action))
    }
}

func |<G,W,T,A> (
    lhs: Given<G>,
    rhs: [[WhenThenAction<W,T,A>]]
) -> [Transition<G,W,T,A>] {
    rhs.flatMap { $0 }.reduce(into: [Transition<G,W,T,A>]()) { ts, action in
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
