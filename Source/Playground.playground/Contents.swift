import Cocoa

protocol StateProtocol: Hashable {}
protocol EventProtocol: Hashable {}

enum S: StateProtocol {
    case a, b, c
}

enum E: EventProtocol {
    case d, e, f
}

extension String: StateProtocol {
    typealias Event = Int
}

extension Int: EventProtocol {
    typealias State = String
}

struct Transition<S: StateProtocol, E: EventProtocol> {
    let givenState: S
    let event: E
    let nextState: S
    let actions: [() -> ()]
}

struct Transitions<S: StateProtocol, E: EventProtocol>: TransitionGroup {
    static var empty: some TransitionGroup {
        Self.init(transitions: [])
    }
    
    var transitions: [Transition<S, E>]
    
    typealias State = S
    typealias Event = E
}

protocol TransitionGroup {
    associatedtype State: StateProtocol
    associatedtype Event: EventProtocol
    
    var transitions: [Transition<State, Event>] { get set }
}

//let a = TransitionBuilder.build {
//    Transitions(transitions:
//                    [Transition(givenState: S.a,
//                                event: E.d,
//                                nextState: S.b,
//                                actions: [])]
//    )
//
//    Transitions(transitions:
//                    [Transition(givenState: S.b,
//                                event: E.d,
//                                nextState: S.c,
//                                actions: [])]
//    )
//
//    if false {
//        Transitions(transitions:
//                        [Transition(givenState: S.b,
//                                    event: E.d,
//                                    nextState: S.c,
//                                    actions: [])]
//        )
//    }
//
//    if true {
//        Transitions(transitions:
//                        [Transition(givenState: S.b,
//                                    event: E.d,
//                                    nextState: S.c,
//                                    actions: [])]
//        )
//    } else {
//        Transitions(transitions:
//                        [Transition(givenState: S.b,
//                                    event: E.d,
//                                    nextState: S.c,
//                                    actions: [])]
//        )
//    }
//}
//
//print(a)

@resultBuilder struct TransitionBuilder {
    struct Output<S: StateProtocol, E: EventProtocol>: TransitionGroup {
        typealias State = S
        typealias Event = E
        
        var transitions: [Transition<S, E>]
        
        init(_ transitions: [Transition<S, E>]) {
            self.transitions = transitions
        }
    }
    
    static func buildBlock<T: TransitionGroup>(_ components: T...) -> [Transition<T.State, T.Event>] {
        Array(components.map(\.transitions).joined())
    }
    
    static func buildExpression<S, E>(_ expression: [Transition<S, E>]) -> some TransitionGroup {
        Output(expression)
    }
    
    static func buildExpression<T: TransitionGroup>(_ expression: T) -> some TransitionGroup {
        Output(expression.transitions)
    }
    
    static func buildIf<S, E>(_ components: [Transition<S, E>]?) -> some TransitionGroup {
        Output(components ?? [])
    }
    
    static func buildEither<S, E>(first component: [Transition<S, E>]) -> some TransitionGroup {
        Output(component)
    }
    
    static func buildEither<S, E>(second component: [Transition<S, E>]) -> some TransitionGroup {
        Output(component)
    }
    
    static func build<S: StateProtocol, E: EventProtocol>(@TransitionBuilder _ content: () -> ([Transition<S, E>])) -> [Transition<S, E>] {
        content()
    }
}
