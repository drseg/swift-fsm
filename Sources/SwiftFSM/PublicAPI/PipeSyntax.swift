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
        rhs: @escaping FSMSyncAction
    ) -> Internal.MatchingWhenActions<Event> {
        .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
    }

    static func | (
        lhs: Internal.MatchingWhen<State, Event>,
        rhs: @escaping FSMAsyncAction
    ) -> Internal.MatchingWhenActions<Event> {
        .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
    }

    static func | (
        lhs: Internal.MatchingWhen<State, Event>,
        rhs: @escaping FSMSyncActionWithEvent<Event>
    ) -> Internal.MatchingWhenActions<Event> {
        .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
    }

    static func | (
        lhs: Internal.MatchingWhen<State, Event>,
        rhs: @escaping FSMAsyncActionWithEvent<Event>
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
        rhs: @escaping FSMSyncAction
    ) -> Internal.MatchingThenActions<Event> {
        .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
    }

    static func | (
        lhs: Internal.MatchingThen<Event>,
        rhs: @escaping FSMAsyncAction
    ) -> Internal.MatchingThenActions<Event> {
        .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
    }

    static func | (
        lhs: Internal.MatchingThen<Event>,
        rhs: @escaping FSMSyncActionWithEvent<Event>
    ) -> Internal.MatchingThenActions<Event> {
        .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
    }

    static func | (
        lhs: Internal.MatchingThen<Event>,
        rhs: @escaping FSMAsyncActionWithEvent<Event>
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
        rhs: @escaping FSMSyncAction
    ) -> Internal.MatchingWhenThenActions<Event> {
        .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
    }

    static func | (
        lhs: Internal.MatchingWhenThen<Event>,
        rhs: @escaping FSMAsyncAction
    ) -> Internal.MatchingWhenThenActions<Event> {
        .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
    }

    static func | (
        lhs: Internal.MatchingWhenThen<Event>,
        rhs: @escaping FSMSyncActionWithEvent<Event>
    ) -> Internal.MatchingWhenThenActions<Event> {
        .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
    }

    static func | (
        lhs: Internal.MatchingWhenThen<Event>,
        rhs: @escaping FSMAsyncActionWithEvent<Event>
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
        rhs: @escaping FSMSyncAction
    ) -> Internal.MatchingActions<Event> {
        .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
    }

    static func | (
        lhs: Self,
        rhs: @escaping FSMAsyncAction
    ) -> Internal.MatchingActions<Event> {
        .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
    }

    static func | (
        lhs: Self,
        rhs: @escaping FSMSyncActionWithEvent<Event>
    ) -> Internal.MatchingActions<Event> {
        .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
    }

    static func | (
        lhs: Self,
        rhs: @escaping FSMAsyncActionWithEvent<Event>
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
