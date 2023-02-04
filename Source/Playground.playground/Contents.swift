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

@resultBuilder
struct Builder<S, E> where S: StateProtocol, E: EventProtocol {
    static func buildBlock(
        _ wts: (E, S, [() -> ()])...
    ) -> [(E, S, [() -> ()])]{
        wts
    }
}

extension StateProtocol {
//    static func |(lhs: Self, rhs: Event) -> (Self, Event) {
//        (lhs, rhs)
//    }
    
//    static func |(lhs: (Self, Event), rhs: Self) -> (Self, Event, Self) {
//        (lhs.0, lhs.1, rhs)
//    }
    
    func callAsFunction(
        @Builder<Self, Event> _ content: () -> [(Event, Self, [() -> ()])]
    ) -> [Transition<Self, Event>]  {
        content().reduce(into: [Transition<Self, Event>]()) {
            $0.append(Transition(givenState: self, event: $1.0, nextState: $1.1, actions: $1.2))
        }
    }
}

extension EventProtocol {
    static func |(lhs: Self, rhs: State) -> (Self, State) {
        (lhs, rhs)
    }
}

func |<S: StateProtocol, E: EventProtocol>(lhs: (E, S), rhs: [() -> ()]) -> (E, S, [() -> ()]) {
    (lhs.0, lhs.1, rhs)
}

//func |<S: StateProtocol, E: EventProtocol>(lhs: (S, E, S), rhs: [() -> ()]) -> Transition<S, E> {
//    Transition(givenState: lhs.0,
//               event: lhs.1,
//               nextState: lhs.2,
//               actions: rhs)
//}

//extension Array where Element: StateProtocol, Element.Event.State == Element {
//    typealias Event = Element.Event
//
//    static func |(lhs: [(Element, Event)], rhs: Element) -> [(Element, Event, Element)] {
//        lhs.reduce(into: [(Element, Element.Event, Element)]()) {
//            $0.append($1 | rhs)
//        }
//    }
//}

extension Array where Element: EventProtocol, Element.State.Event == Element {
    typealias State = Element.State
    
//    static func |(lhs: State, rhs: Self) -> [(State, Element)] {
//        rhs.reduce(into: [(State, Element)]()) {
//            $0.append(lhs | $1)
//        }
//    }
//
//    static func |(lhs: [State], rhs: Self) -> [(State, Element)] {
//        lhs.reduce(into: [(State, Element)]()) { eventStates, state in
//            rhs.forEach {
//                eventStates.append(state | $0)
//            }
//        }
//    }
}

func |<S: StateProtocol, E: EventProtocol>(lhs: [(S, E, S)], rhs: [() -> ()]) -> [Transition<S, E>] {
    lhs.reduce(into: [Transition<S, E>]()) {
        $0.append(
            Transition(givenState: $1.0,
                       event: $1.1,
                       nextState: $1.2,
                       actions: rhs)
        )
    }
}

let a = "Dog"() {
    1 | "Bone" | [{}]
}

let b = S.a {
    E.d | .a | [{}]
}

let f = E.d | .a

