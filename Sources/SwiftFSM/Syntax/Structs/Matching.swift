import Foundation

public protocol Conditional<State, Event> {
    associatedtype State: FSMHashable
    associatedtype Event: FSMHashable
}

extension Conditional {
    var node: MatchingNode { this.node }
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
        rhs: @escaping FSMSyncAction
    ) -> Internal.MatchingActions<Event> {
        .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
    }

    public static func | (
        lhs: Self,
        rhs: @escaping FSMAsyncAction
    ) -> Internal.MatchingActions<Event> {
        .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
    }

    public static func | (
        lhs: Self,
        rhs: @escaping FSMSyncActionWithEvent<Event>
    ) -> Internal.MatchingActions<Event> {
        .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
    }

    public static func | (
        lhs: Self,
        rhs: @escaping FSMAsyncActionWithEvent<Event>
    ) -> Internal.MatchingActions<Event> {
        .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
    }

    public static func | (
        lhs: Self,
        rhs: [AnyAction]
    ) -> Internal.MatchingActions<Event> {
        .init(node: ActionsNode(actions: rhs, rest: [lhs.node]))
    }
    
    var blockNode: MatchingBlockNode {
        MatchingBlockNode(
            descriptor: node.descriptor,
            rest: node.rest,
            caller: name,
            file: file,
            line: line
        )
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
    var node: MatchingNode { get }
    var file: String { get }
    var line: Int { get }
    var name: String { get }
}

public typealias ConditionProvider = @MainActor @Sendable () -> Bool

public extension Syntax.Expanded {
    struct Condition<State: FSMHashable, Event: FSMHashable>: _Conditional {
        let node: MatchingNode
        let file: String
        let line: Int

        var name: String { "condition" }
        
        init(
            _ condition: @escaping ConditionProvider,
            file: String = #file,
            line: Int = #line
        ) {
            let match = MatchDescriptorChain(
                condition: condition,
                file: file,
                line: line
            )
            self.node = MatchingNode(descriptor: match, rest: [])
            self.file = file
            self.line = line
        }
    }

    struct Matching<State: FSMHashable, Event: FSMHashable>: _Conditional {
        let node: MatchingNode
        let file: String
        let line: Int

        var name: String { "matching" }

        init<P: Predicate>(
            _ predicate: P,
            or: [P],
            and: [any Predicate],
            file: String = #file,
            line: Int = #line
        ) {
            if or.isEmpty {
                self.init(
                    any: [], all: [predicate] + and,
                    file: file,
                    line: line
                )
            } else {
                self.init(
                    any: [predicate] + or,
                    all: and,
                    file: file,
                    line: line
                )
            }
        }

        private init(
            any: [any Predicate],
            all: [any Predicate],
            file: String = #file,
            line: Int = #line
        ) {
            let match = MatchDescriptorChain(
                any: any.erased(),
                all: all.erased(),
                file: file,
                line: line
            )
            
            self.node = MatchingNode(descriptor: match, rest: [])
            self.file = file
            self.line = line
        }
    }
}
