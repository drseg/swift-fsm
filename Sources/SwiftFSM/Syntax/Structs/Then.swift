import Foundation

public extension Internal {
    struct Then<State: FSMHashable, Event: FSMHashable> {
        public static func | (
            lhs: Self,
            rhs: @escaping FSMSyncAction
        ) -> Internal.MatchingThenActions<Event> {
            .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
        }

        public static func | (
            lhs: Self,
            rhs: @escaping FSMAsyncAction
        ) -> Internal.MatchingThenActions<Event> {
            .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
        }

        public static func | (
            lhs: Self,
            rhs: @escaping FSMSyncActionWithEvent<Event>
        ) -> Internal.MatchingThenActions<Event> {
            .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
        }

        public static func | (
            lhs: Self,
            rhs: @escaping FSMAsyncActionWithEvent<Event>
        ) -> Internal.MatchingThenActions<Event> {
            .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
        }

        public static func | (
            lhs: Self,
            rhs: [AnyAction]
        ) -> Internal.MatchingThenActions<Event> {
            .init(node: ActionsNode(actions: rhs, rest: [lhs.node]))
        }

        let node: ThenNode
        let file: String
        let line: Int

        var blockNode: ThenBlockNode {
            ThenBlockNode(state: node.state,
                          rest: node.rest,
                          caller: "then",
                          file: file,
                          line: line)
        }

        init(_ state: State? = nil, file: String = #file, line: Int = #line) {
            let state = state != nil ? AnyTraceable(state,
                                                    file: file,
                                                    line: line) : nil
            node = ThenNode(state: state)
            self.file = file
            self.line = line
        }

        public func callAsFunction(
            @Internal.MWABuilder _ block: () -> [MWA]
        ) -> Internal.MWTASentence {
            .init(blockNode, block)
        }

        public func callAsFunction(
            @Internal.MABuilder _ block: () -> [MA]
        ) -> Internal.MTASentence {
            .init(blockNode, block)
        }
    }
}
