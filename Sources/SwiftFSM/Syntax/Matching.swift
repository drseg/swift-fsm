import Foundation

public protocol Conditional<State, Event> {
    associatedtype Event: Hashable
    associatedtype State: Hashable
}

extension Conditional {
    var node: MatchNode { this.node }
    var file: String { this.file }
    var line: Int { this.line }
    var name: String { this.name }

    var this: any _Conditional { self as! any _Conditional }

    public static func | (
        lhs: Self,
        rhs: Syntax.When<State, Event>
    ) -> Internal.MatchingWhen<State, Event> {
        .init(node: rhs.node.appending(lhs.node))
    }

    public static func | (
        lhs: Self,
        rhs: Syntax.When<State, Event>
    ) -> Internal.MatchingWhenActions<Event> {
        .init(node: ActionsNode(rest: [rhs.node.appending(lhs.node)]))
    }

    public static func | (
        lhs: Self,
        rhs: Syntax.Then<State, Event>
    ) -> Internal.MatchingThen<Event> {
        .init(node: rhs.node.appending(lhs.node))
    }

    public static func | (
        lhs: Self,
        rhs: Syntax.Then<State, Event>
    ) -> Internal.MatchingThenActions<Event> {
        .init(node: ActionsNode(rest: [rhs.node.appending(lhs.node)]))
    }

    public static func | (
        lhs: Self,
        rhs: @escaping FSMAction
    ) -> Internal.MatchingActions<Event> {
        .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
    }

    public static func | (
        lhs: Self,
        rhs: @escaping FSMActionWithEvent<Event>
    ) -> Internal.MatchingActions<Event> {
        .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
    }

    var blockNode: MatchBlockNode {
        MatchBlockNode(match: node.match,
                       rest: node.rest,
                       caller: name,
                       file: file,
                       line: line)
    }

    public func callAsFunction(
        @Internal.MWTABuilder _ block: () -> [MWTA]
    ) -> Internal.MWTASentence {
        .init(blockNode, block)
    }

    public func callAsFunction(
        @Internal.MWABuilder _ block: () -> [MWA]
    ) -> Internal.MWASentence {
        .init(blockNode, block)
    }

    public func callAsFunction(
        @Internal.MTABuilder _ block: () -> [MTA]
    ) -> Internal.MTASentence {
        .init(blockNode, block)
    }
}

protocol _Conditional: Conditional {
    var node: MatchNode { get }
    var file: String { get }
    var line: Int { get }
    var name: String { get }
}

public extension Syntax.Expanded {
    struct Condition<State: Hashable, Event: Hashable>: _Conditional {
        let node: MatchNode
        let file: String
        let line: Int

        var name: String { "condition" }

        public init(
            _ condition: @escaping () -> Bool,
            file: String = #file,
            line: Int = #line
        ) {
            let match = Match(condition: condition,
                              file: file,
                              line: line)
            self.node = MatchNode(match: match, rest: [])
            self.file = file
            self.line = line
        }
    }

    struct Matching<State: Hashable, Event: Hashable>: _Conditional {
        let node: MatchNode
        let file: String
        let line: Int

        var name: String { "matching" }

        public init<P: Predicate>(
            _ predicate: P,
            file: String = #file,
            line: Int = #line
        ) {
            self.init(predicate, or: [], and: [], file: file, line: line)
        }

        public init<P: Predicate>(
            _ predicate: P,
            or: P...,
            file: String = #file,
            line: Int = #line
        ) {
            self.init(predicate, or: or, and: [], file: file, line: line)
        }

        public init<P: Predicate>(
            _ predicate: P,
            and: any Predicate...,
            file: String = #file,
            line: Int = #line
        ) {
            self.init(predicate, or: [], and: and, file: file, line: line)
        }

        public init<P: Predicate>(
            _ predicate: P,
            or: P...,
            and: any Predicate...,
            file: String = #file,
            line: Int = #line
        ) {
            self.init(predicate, or: or, and: and, file: file, line: line)
        }

        public init<P: Predicate>(
            _ predicate: P,
            or: [P],
            and: [any Predicate],
            file: String = #file,
            line: Int = #line
        ) {
            if or.isEmpty {
                self.init(any: [], all: [predicate] + and, file: file, line: line)
            } else {
                self.init(any: [predicate] + or, all: and, file: file, line: line)
            }
        }

        private init(
            any: [any Predicate],
            all: [any Predicate],
            file: String = #file,
            line: Int = #line
        ) {
            let match = Match(any: any.erased(),
                              all: all.erased(),
                              file: file,
                              line: line)

            self.node = MatchNode(match: match, rest: [])
            self.file = file
            self.line = line
        }
    }
}
