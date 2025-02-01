import Foundation

@MainActor
public enum Syntax {
    @MainActor
    public enum Expanded { }
}

public enum Internal {
    public struct MatchingWhen<State: FSMHashable, Event: FSMHashable> {
        public static func | (
            lhs: Self,
            rhs: Syntax.Then<State, Event>
        ) -> MatchingWhenThen<Event> {
            .init(node: rhs.node.appending(lhs.node))
        }

        public static func | (
            lhs: Self,
            rhs: @escaping FSMSyncAction
        ) -> MatchingWhenActions<Event> {
            .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
        }

        public static func | (
            lhs: Self,
            rhs: @escaping FSMAsyncAction
        ) -> MatchingWhenActions<Event> {
            .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
        }

        public static func | (
            lhs: Self,
            rhs: @escaping FSMSyncActionWithEvent<Event>
        ) -> MatchingWhenActions<Event> {
            .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
        }

        public static func | (
            lhs: Self,
            rhs: @escaping FSMAsyncActionWithEvent<Event>
        ) -> MatchingWhenActions<Event> {
            .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
        }

        public static func | (
            lhs: Self,
            rhs: [AnyAction]
        ) -> MatchingWhenActions<Event> {
            .init(node: ActionsNode(actions: rhs, rest: [lhs.node]))
        }

        public static func | (
            lhs: Self,
            rhs: Syntax.Then<State, Event>
        ) -> MatchingWhenThenActions<Event> {
            .init(node: ActionsNode(rest: [rhs.node.appending(lhs.node)]))
        }

        let node: WhenNode
    }

    public struct MatchingThen<Event: FSMHashable> {
        public static func | (
            lhs: Self,
            rhs: @escaping FSMSyncAction
        ) -> MatchingThenActions<Event> {
            .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
        }

        public static func | (
            lhs: Self,
            rhs: @escaping FSMAsyncAction
        ) -> MatchingThenActions<Event> {
            .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
        }

        public static func | (
            lhs: Self,
            rhs: @escaping FSMSyncActionWithEvent<Event>
        ) -> MatchingThenActions<Event> {
            .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
        }

        public static func | (
            lhs: Self,
            rhs: @escaping FSMAsyncActionWithEvent<Event>
        ) -> MatchingThenActions<Event> {
            .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
        }

        public static func | (
            lhs: Self,
            rhs: [AnyAction]
        ) -> MatchingThenActions<Event> {
            .init(node: ActionsNode(actions: rhs, rest: [lhs.node]))
        }

        let node: ThenNode
    }

    public final class MatchingActions<Event: FSMHashable>: MA { }
    public final class MatchingWhenActions<Event: FSMHashable>: MWA { }
    public final class MatchingThenActions<Event: FSMHashable>: MTA { }

    public struct MatchingWhenThen<Event: FSMHashable> {
        public static func | (
            lhs: Self,
            rhs: @escaping FSMSyncAction
        ) -> MatchingWhenThenActions<Event> {
            .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
        }

        public static func | (
            lhs: Self,
            rhs: @escaping FSMAsyncAction
        ) -> MatchingWhenThenActions<Event> {
            .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
        }

        public static func | (
            lhs: Self,
            rhs: @escaping FSMSyncActionWithEvent<Event>
        ) -> MatchingWhenThenActions<Event> {
            .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
        }

        public static func | (
            lhs: Self,
            rhs: @escaping FSMAsyncActionWithEvent<Event>
        ) -> MatchingWhenThenActions<Event> {
            .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
        }

        public static func | (
            lhs: Self,
            rhs: [AnyAction]
        ) -> MatchingWhenThenActions<Event> {
            .init(node: ActionsNode(actions: rhs, rest: [lhs.node]))
        }

        let node: ThenNode
    }

    public final class MatchingWhenThenActions<Event>: MWTA { }

    public final class MWTASentence: MWTA, BlockSentence { }
    public final class MWASentence: MWA, BlockSentence { }
    public final class MTASentence: MTA, BlockSentence { }

    @resultBuilder
    public struct MWTABuilder: ResultBuilder {
        public typealias T = MWTA
    }

    @resultBuilder
    public struct MWABuilder: ResultBuilder {
        public typealias T = MWA
    }

    @resultBuilder
    public struct MTABuilder: ResultBuilder {
        public typealias T = MTA
    }

    @resultBuilder
    public struct MABuilder: ResultBuilder {
        public typealias T = MA
    }
}

protocol BlockSentence {
    var node: any Node<DefaultIO> { get }

    init(node: any Node<DefaultIO>)
}

extension BlockSentence {
    init<N: Node>(_ n: N, _ block: () -> [Sentence])
    where N.Input == DefaultIO, N.Input == N.Output {
        var n = n
        n.rest = block().nodes
        self.init(node: n)
    }

    init(
        _ actions: [AnyAction],
        file: String = #file,
        line: Int = #line,
        _ block: () -> [Sentence]
    ) {
        self.init(
            node: ActionsBlockNode(
                actions: actions,
                rest: block().nodes,
                caller: "actions",
                file: file,
                line: line
            )
        )
    }
}

public class Sentence {
    let node: any Node<DefaultIO>

    init(node: any Node<DefaultIO>) {
        self.node = node
    }
}

public class MWTA: Sentence { }
public class MWA: Sentence { }
public class MTA: Sentence { }
public class MA: Sentence { }

extension Node {
    func appending<Other: Node>(_ other: Other) -> Self where Input == Other.Output {
        var this = self
        this.rest = [other]
        return this
    }
}

extension Array {
    var nodes: [any Node<DefaultIO>] {
        compactMap { ($0 as? Sentence)?.node }
    }
}
