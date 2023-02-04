import Cocoa

protocol StateProtocol: Hashable {
    associatedtype Event: EventProtocol
}

protocol EventProtocol: Hashable {
    associatedtype State: StateProtocol
}

extension String: StateProtocol, EventProtocol {
    typealias State = Self
    typealias Event = Self
}

struct Transition<S: StateProtocol, E: EventProtocol> {
    let givenState: S
    let event: E
    let nextState: S
    let actions: [() -> ()]
}

extension StateProtocol {
    func callAsFunction() {
        print(self)
    }
    
    static func |(lhs: Self, rhs: Event) -> (Self, Event) {
        (lhs, rhs)
    }
    
    static func |(lhs: (Self, Event), rhs: Self) -> (Self, Event, Self) {
        (lhs.0, lhs.1, rhs)
    }
}

func |<S: StateProtocol, E: EventProtocol>(lhs: (S, E, S), rhs: [() -> ()]) -> Transition<S, E> {
    Transition(givenState: lhs.0,
               event: lhs.1,
               nextState: lhs.2,
               actions: rhs)
}

extension Array where Element: StateProtocol {
    typealias Event = Element.Event
    
    func callAsFunction() {
        forEach { $0() }
    }
    
    static func |(lhs: Self, rhs: Element.Event) -> [(Element, Element.Event)] {
        lhs.reduce(into: [(Element, Element.Event)]()) {
            $0.append($1 | rhs)
        }
    }
    
    static func |(lhs: [(Element, Element.Event)], rhs: Element) -> [(Element, Element.Event, Element)] {
        lhs.reduce(into: [(Element, Element.Event, Element)]()) {
            $0.append($1 | rhs)
        }
    }
}

extension Array where Element: EventProtocol, Element.State.Event == Element {
    typealias State = Element.State
    
    static func |(lhs: State, rhs: Self) -> [(State, Element)] {
        rhs.reduce(into: [(State, Element)]()) {
            $0.append(lhs | $1)
        }
    }
    
    static func |(lhs: [State], rhs: Self) -> [(State, Element)] {
        lhs.reduce(into: [(State, Element)]()) { eventStates, state in
            rhs.forEach {
                eventStates.append(state | $0)
            }
        }
    }
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

"Dog"()
["Dog", "Cat"]()

"Dog" | ["Cat", "Fish"] | "Bone" | [{}]
["Dog", "Bat"] | ["Cat", "Fish"] | "Bone" | [{}]

