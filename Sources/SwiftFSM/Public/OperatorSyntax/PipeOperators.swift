import Foundation

public extension Internal.MatchingWhen {
    static func | (
        lhs: Internal.MatchingWhen<State, Event>,
        rhs: Internal.Then<State, Event>
    ) -> Internal.MatchingWhenThen<Event> {
        .init(node: rhs.node.appending(lhs.node))
    }

    static func | (
        lhs: Internal.MatchingWhen<State, Event>,
        rhs: @escaping FSMAction
    ) -> Internal.MatchingWhenActions<Event> {
        .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
    }

    static func | (
        lhs: Internal.MatchingWhen<State, Event>,
        rhs: @escaping FSMActionWithEvent<Event>
    ) -> Internal.MatchingWhenActions<Event> {
        .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
    }

    static func | (
        lhs: Internal.MatchingWhen<State, Event>,
        rhs: [AnyAction]
    ) -> Internal.MatchingWhenActions<Event> {
        .init(node: ActionsNode(actions: rhs, rest: [lhs.node]))
    }

    static func | (
        lhs: Internal.MatchingWhen<State, Event>,
        rhs: Internal.Then<State, Event>
    ) -> Internal.MatchingWhenThenActions<Event> {
        .init(node: ActionsNode(rest: [rhs.node.appending(lhs.node)]))
    }
}

public extension Internal.MatchingThen {
    static func | (
        lhs: Internal.MatchingThen<Event>,
        rhs: @escaping FSMAction
    ) -> Internal.MatchingThenActions<Event> {
        .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
    }

    static func | (
        lhs: Internal.MatchingThen<Event>,
        rhs: @escaping FSMActionWithEvent<Event>
    ) -> Internal.MatchingThenActions<Event> {
        .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
    }

    static func | (
        lhs: Internal.MatchingThen<Event>,
        rhs: [AnyAction]
    ) -> Internal.MatchingThenActions<Event> {
        .init(node: ActionsNode(actions: rhs, rest: [lhs.node]))
    }
}

public extension Internal.MatchingWhenThen {
    static func | (
        lhs: Internal.MatchingWhenThen<Event>,
        rhs: @escaping FSMAction
    ) -> Internal.MatchingWhenThenActions<Event> {
        .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
    }

    static func | (
        lhs: Internal.MatchingWhenThen<Event>,
        rhs: @escaping FSMActionWithEvent<Event>
    ) -> Internal.MatchingWhenThenActions<Event> {
        .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
    }

    static func | (
        lhs: Internal.MatchingWhenThen<Event>,
        rhs: [AnyAction]
    ) -> Internal.MatchingWhenThenActions<Event> {
        .init(node: ActionsNode(actions: rhs, rest: [lhs.node]))
    }
}

public extension Internal.Conditional {
    static func | (
        lhs: Self,
        rhs: Internal.When<State, Event>
    ) -> Internal.MatchingWhen<State, Event> {
        .init(node: rhs.node.appending(lhs.node))
    }

    static func | (
        lhs: Self,
        rhs: Internal.When<State, Event>
    ) -> Internal.MatchingWhenActions<Event> {
        .init(node: ActionsNode(rest: [rhs.node.appending(lhs.node)]))
    }

    static func | (
        lhs: Self,
        rhs: Internal.Then<State, Event>
    ) -> Internal.MatchingThen<Event> {
        .init(node: rhs.node.appending(lhs.node))
    }

    static func | (
        lhs: Self,
        rhs: Internal.Then<State, Event>
    ) -> Internal.MatchingThenActions<Event> {
        .init(node: ActionsNode(rest: [rhs.node.appending(lhs.node)]))
    }

    static func | (
        lhs: Self,
        rhs: @escaping FSMAction
    ) -> Internal.MatchingActions<Event> {
        .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
    }

    static func | (
        lhs: Self,
        rhs: @escaping FSMActionWithEvent<Event>
    ) -> Internal.MatchingActions<Event> {
        .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
    }

    static func | (
        lhs: Self,
        rhs: [AnyAction]
    ) -> Internal.MatchingActions<Event> {
        .init(node: ActionsNode(actions: rhs, rest: [lhs.node]))
    }

}
