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
    struct Group: TransitionGroup {
        var transitions: [Transition<S, E>]
        
        typealias State = S
        typealias Event = E
    }
    
    static func buildExpression<T: TransitionGroup>(_ expression: T) -> Group where T.State == S, T.Event == E {
        Group(transitions: expression.transitions)
    }
    
    static func buildBlock(_ components: Group...) -> Group {
        var first = components.first!
        components.dropFirst().forEach {
            first.transitions.append(contentsOf: $0.transitions)
        }
        return first
    }
    
    static func buildIf(_ components: Group?) -> Group {
        components ?? Group(transitions: [])
    }
    
    static func buildEither(first component: Group) -> Group {
        component
    }
    
    static func buildEither(second component: Group) -> Group {
        component
    }
    
    static func build(@TransitionBuilder _ content: () -> (Group)) -> [Transition<S, E>] {
        content().transitions
    }
}
