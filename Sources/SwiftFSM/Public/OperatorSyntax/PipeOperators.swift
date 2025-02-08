import Foundation

public extension Syntax.MatchingWhen {
    static func | (
        lhs: Syntax.MatchingWhen<State, Event>,
        rhs: Syntax.Then<State, Event>
    ) -> Syntax.MatchingWhenThen<Event> {
        .init(node: rhs.node.appending(lhs.node))
    }

    static func | (
        lhs: Syntax.MatchingWhen<State, Event>,
        rhs: @escaping FSMAction
    ) -> Syntax.MatchingWhenActions<Event> {
        .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
    }

    static func | (
        lhs: Syntax.MatchingWhen<State, Event>,
        rhs: @escaping FSMActionWithEvent<Event>
    ) -> Syntax.MatchingWhenActions<Event> {
        .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
    }

    static func | (
        lhs: Syntax.MatchingWhen<State, Event>,
        rhs: [AnyAction]
    ) -> Syntax.MatchingWhenActions<Event> {
        .init(node: ActionsNode(actions: rhs, rest: [lhs.node]))
    }

    static func | (
        lhs: Syntax.MatchingWhen<State, Event>,
        rhs: Syntax.Then<State, Event>
    ) -> Syntax.MatchingWhenThenActions<Event> {
        .init(node: ActionsNode(rest: [rhs.node.appending(lhs.node)]))
    }
}

public extension Syntax.MatchingThen {
    static func | (
        lhs: Syntax.MatchingThen<Event>,
        rhs: @escaping FSMAction
    ) -> Syntax.MatchingThenActions<Event> {
        .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
    }

    static func | (
        lhs: Syntax.MatchingThen<Event>,
        rhs: @escaping FSMActionWithEvent<Event>
    ) -> Syntax.MatchingThenActions<Event> {
        .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
    }

    static func | (
        lhs: Syntax.MatchingThen<Event>,
        rhs: [AnyAction]
    ) -> Syntax.MatchingThenActions<Event> {
        .init(node: ActionsNode(actions: rhs, rest: [lhs.node]))
    }
}

public extension Syntax.MatchingWhenThen {
    static func | (
        lhs: Syntax.MatchingWhenThen<Event>,
        rhs: @escaping FSMAction
    ) -> Syntax.MatchingWhenThenActions<Event> {
        .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
    }

    static func | (
        lhs: Syntax.MatchingWhenThen<Event>,
        rhs: @escaping FSMActionWithEvent<Event>
    ) -> Syntax.MatchingWhenThenActions<Event> {
        .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
    }

    static func | (
        lhs: Syntax.MatchingWhenThen<Event>,
        rhs: [AnyAction]
    ) -> Syntax.MatchingWhenThenActions<Event> {
        .init(node: ActionsNode(actions: rhs, rest: [lhs.node]))
    }
}

public extension Syntax.Conditional {
    static func | (
        lhs: Self,
        rhs: Syntax.When<State, Event>
    ) -> Syntax.MatchingWhen<State, Event> {
        .init(node: rhs.node.appending(lhs.node))
    }

    static func | (
        lhs: Self,
        rhs: Syntax.When<State, Event>
    ) -> Syntax.MatchingWhenActions<Event> {
        .init(node: ActionsNode(rest: [rhs.node.appending(lhs.node)]))
    }

    static func | (
        lhs: Self,
        rhs: Syntax.Then<State, Event>
    ) -> Syntax.MatchingThen<Event> {
        .init(node: rhs.node.appending(lhs.node))
    }

    static func | (
        lhs: Self,
        rhs: Syntax.Then<State, Event>
    ) -> Syntax.MatchingThenActions<Event> {
        .init(node: ActionsNode(rest: [rhs.node.appending(lhs.node)]))
    }

    static func | (
        lhs: Self,
        rhs: @escaping FSMAction
    ) -> Syntax.MatchingActions<Event> {
        .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
    }

    static func | (
        lhs: Self,
        rhs: @escaping FSMActionWithEvent<Event>
    ) -> Syntax.MatchingActions<Event> {
        .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
    }

    static func | (
        lhs: Self,
        rhs: [AnyAction]
    ) -> Syntax.MatchingActions<Event> {
        .init(node: ActionsNode(actions: rhs, rest: [lhs.node]))
    }

}
