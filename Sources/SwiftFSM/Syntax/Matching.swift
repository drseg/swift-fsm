import Foundation

protocol Conditional {
    var node: MatchNode { get }
    var file: String { get }
    var line: Int { get }
    var name: String { get }
}

extension Conditional {
    static func |<E: Hashable> (lhs: Self, rhs: Syntax.When<E>) -> Internal.MatchingWhen {
        .init(node: rhs.node.appending(lhs.node))
    }
    
    static func |<E: Hashable> (lhs: Self, rhs: Syntax.When<E>) -> Internal.MatchingWhenActions {
        .init(node: ActionsNode(rest: [rhs.node.appending(lhs.node)]))
    }
    
    static func |<S: Hashable> (lhs: Self, rhs: Syntax.Then<S>) -> Internal.MatchingThen {
        .init(node: rhs.node.appending(lhs.node))
    }
    
    static func |<S: Hashable> (lhs: Self, rhs: Syntax.Then<S>) -> Internal.MatchingThenActions {
        .init(node: ActionsNode(rest: [rhs.node.appending(lhs.node)]))
    }
    
    static func | (lhs: Self, rhs: @escaping Action) -> Internal.MatchingActions {
        return .init(node: ActionsNode(actions: [rhs], rest: [lhs.node]))
    }
    
    var blockNode: MatchBlockNode {
        MatchBlockNode(match: node.match,
                       rest: node.rest,
                       caller: name,
                       file: file,
                       line: line)
    }
    
    func callAsFunction(
        @Internal.MWTABuilder _ block: () -> [MWTA]
    ) -> Internal.MWTASentence {
        .init(blockNode, block)
    }
    
    func callAsFunction(
        @Internal.MWABuilder _ block: () -> [MWA]
    ) -> Internal.MWASentence {
        .init(blockNode, block)
    }
    
    func callAsFunction(
        @Internal.MTABuilder _ block: () -> [MTA]
    ) -> Internal.MTASentence {
        .init(blockNode, block)
    }
}

extension Syntax.Expanded {
    struct Condition: Conditional {
        let node: MatchNode
        let file: String
        let line: Int
        
        let name = "condition"
        
        init(
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
    
    struct Matching: Conditional {
        let node: MatchNode
        let file: String
        let line: Int
        
        let name = "matching"
        
        init<P: Predicate>(
            _ first: P,
            or: P...,
            and: any Predicate...,
            file: String = #file,
            line: Int = #line
        ) {
            self.init(first, or: or, and: and, file: file, line: line)
        }
        
        init<P: Predicate>(
            _ first: P,
            or: [P],
            and: [any Predicate],
            file: String = #file,
            line: Int = #line
        ) {
            if or.isEmpty {
                self.init(any: [], all: [first] + and, file: file, line: line)
            } else {
                self.init(any: [first] + or, all: and, file: file, line: line)
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
