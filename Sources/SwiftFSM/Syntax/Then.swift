import Foundation

public extension Syntax {
    struct Then<State: Hashable> {
        public static func | (lhs: Self, rhs: @escaping Action) -> Internal.MatchingThenActions {
            .init(node: ActionsNode(actions: [rhs], rest: [lhs.node]))
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

        public init(_ state: State? = nil, file: String = #file, line: Int = #line) {
            node = ThenNode(
                state: state != nil ? AnyTraceable(state,
                                                   file: file,
                                                   line: line) : nil
            )
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
