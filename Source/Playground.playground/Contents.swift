import Cocoa

protocol StateProtocol: Hashable {
    associatedtype Event: EventProtocol
}

protocol EventProtocol: Hashable {
    associatedtype State: StateProtocol
}

enum S: StateProtocol {
    typealias Event = E
    
    case a, b, c
}

enum E: EventProtocol {
    typealias State = S
    
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

let a = TransitionBuilder.build {
    Transitions(transitions:
                    [Transition(givenState: S.a,
                                event: E.d,
                                nextState: S.b,
                                actions: [])]
    )
    
    Transitions(transitions:
                    [Transition(givenState: S.b,
                                event: E.d,
                                nextState: S.c,
                                actions: [])]
    )
    
    if false {
        Transitions(transitions:
                        [Transition(givenState: S.b,
                                    event: E.d,
                                    nextState: S.c,
                                    actions: [])]
        )
    }

    if true {
        Transitions(transitions:
                        [Transition(givenState: S.b,
                                    event: E.d,
                                    nextState: S.c,
                                    actions: [])]
        )
    } else {
        Transitions(transitions:
                        [Transition(givenState: S.b,
                                    event: E.d,
                                    nextState: S.c,
                                    actions: [])]
        )
    }
}

print(a)

@resultBuilder struct TransitionBuilder<S: StateProtocol, E: EventProtocol> {
    struct Output: TransitionGroup {
        typealias State = S
        typealias Event = E
        
        var transitions: [Transition<S, E>]
        
        init(_ transitions: [Transition<S, E>]) {
            self.transitions = transitions
        }
    }
    
    static func buildBlock(_ components: Output...) -> [Transition<S, E>] {
        Array(components.map(\.transitions).joined())
    }
    
    static func buildExpression(_ expression: [Transition<S, E>]) -> Output {
        Output(expression)
    }
    
    static func buildExpression<T: TransitionGroup>(_ expression: T) -> Output where T.State == S, T.Event == E {
        Output(expression.transitions)
    }
    
    static func buildIf(_ components: [Transition<S, E>]?) -> Output {
        Output(components ?? [])
    }
    
    static func buildEither(first component: [Transition<S, E>]) -> Output {
        Output(component)
    }
    
    static func buildEither(second component: [Transition<S, E>]) -> Output {
        Output(component)
    }
    
    static func build(@TransitionBuilder _ content: () -> ([Transition<S, E>])) -> [Transition<S, E>] {
        content()
    }
}
