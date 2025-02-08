import Foundation

public extension Syntax {
    struct Then<State: FSMHashable, Event: FSMHashable> {
        public static func | (
            lhs: Self,
            rhs: @escaping FSMAction
        ) -> MatchingThenActions<Event> {
            .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
        }

        public static func | (
            lhs: Self,
            rhs: @escaping FSMActionWithEvent<Event>
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
            @MWABuilder _ block: () -> [MWA]
        ) -> MWTABlock {
            .init(blockNode, block)
        }

        public func callAsFunction(
            @MABuilder _ block: () -> [MA]
        ) -> MTABlock {
            .init(blockNode, block)
        }
    }
}
