//
//  SittingFSMInfix.swift
//  Sitting
//
//  Created by Daniel Segall on 28/01/2023.
//

import Foundation

enum Generic {
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
                _ ts: [Transition]...
            ) -> [Key<G,W>: Transition] {
                ts.flatMap {$0}.reduce(into: [Key<G,W>: Transition]()) {
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
}


func |<G,W> (lhs: Generic.Given<G>, rhs: Generic.When<W>) -> [Generic.GivenWhen<G, W>] {
    lhs.given.reduce(into: [Generic.GivenWhen]()) { givenWhens, given in
        rhs.when.forEach {
            givenWhens.append(Generic.GivenWhen(given: given, when: $0))
        }
    }
}

func |<G,W> (
    lhs: Generic.Given<G>,
    rhs: [[Generic.WhenThen<W,G>]]
) -> [Generic.GivenWhenThen<G,W>] {
    lhs.given.reduce(into: [Generic.GivenWhenThen]()) { givenWhenThens, given in
        rhs.flatMap { $0 }.forEach {
            givenWhenThens.append(Generic.GivenWhenThen(given: given,
                                                when: $0.when,
                                                then: $0.then))
        }
    }
}

func |<G,W> (
    lhs: [Generic.GivenWhen<G, W>],
    rhs: Generic.Then<G>
) -> [Generic.GivenWhenThen<G,W>] {
    lhs.reduce(into: [Generic.GivenWhenThen]()) { givenWhenThens, givenWhen in
        givenWhenThens.append(Generic.GivenWhenThen(given: givenWhen.given,
                                            when: givenWhen.when,
                                            then: rhs.then))
    }
}

func |<G,W> (
    lhs: [Generic.GivenWhenThen<G,W>],
    rhs: Generic.Action
) -> [Generic.Transition<G,W>] {
    lhs.reduce(into: [Generic.Transition<G,W>]()) {
        $0.append(
            Generic.Transition(
                givenState: $1.given,
                event: $1.when,
                nextState: $1.then,
                action: rhs.action
            )
        )
    }
}

func |<W,T> (lhs: Generic.When<W>, rhs: Generic.Then<T>) -> [Generic.WhenThen<W,T>] {
    lhs.when.reduce(into: [Generic.WhenThen<W,T>]()) { whenThens, when in
        whenThens.append(Generic.WhenThen(when: when, then: rhs.then))
    }
}

func |<W,T> (
    lhs: [Generic.WhenThen<W,T>],
    rhs: Generic.Action
) -> [Generic.WhenThenAction<W,T>] {
    lhs.reduce(into: [Generic.WhenThenAction<W,T>]()) {
        $0.append(Generic.WhenThenAction(when: $1.when,
                                 then: $1.then,
                                 action: rhs.action))
    }
}

func |<W,T> (
    lhs: [[Generic.WhenThen<W,T>]],
    rhs: Generic.Action
) -> [Generic.WhenThenAction<W,T>] {
    lhs.flatMap { $0 }.reduce(into: [Generic.WhenThenAction<W,T>]()) {
        $0.append(Generic.WhenThenAction(when: $1.when,
                                 then: $1.then,
                                 action: rhs.action))
    }
}

func |<G,W> (
    lhs: Generic.Given<G>,
    rhs: [[Generic.WhenThenAction<W,G>]]
) -> [Generic.Transition<G,W>] {
    rhs.flatMap { $0 }.reduce(into: [Generic.Transition<G,W>]()) { ts, action in
        lhs.given.forEach { given in
            ts.append(
                Generic.Transition(
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
