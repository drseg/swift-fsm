import Foundation


public extension Syntax.Expanded {
    class _Conditional {
        var node: MatchNode!
        var file: String!
        var line: Int!
        
        var name: String { "TILT" }
        
        fileprivate init() { }
        
        public static func |<E: Hashable> (lhs: _Conditional, rhs: Syntax.When<E>) -> Internal.MatchingWhen {
            .init(node: rhs.node.appending(lhs.node))
        }
        
        public static func |<E: Hashable> (lhs: _Conditional, rhs: Syntax.When<E>) -> Internal.MatchingWhenActions {
            .init(node: ActionsNode(rest: [rhs.node.appending(lhs.node)]))
        }
        
        public static func |<S: Hashable> (lhs: _Conditional, rhs: Syntax.Then<S>) -> Internal.MatchingThen {
            .init(node: rhs.node.appending(lhs.node))
        }
        
        public static func |<S: Hashable> (lhs: _Conditional, rhs: Syntax.Then<S>) -> Internal.MatchingThenActions {
            .init(node: ActionsNode(rest: [rhs.node.appending(lhs.node)]))
        }
        
        public static func | (lhs: _Conditional, rhs: @escaping Action) -> Internal.MatchingActions {
            return .init(node: ActionsNode(actions: [rhs], rest: [lhs.node]))
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
    
    final class Condition: _Conditional {
        override var name: String { "condition" }
        
        public init(
            _ condition: @escaping () -> Bool,
            file: String = #file,
            line: Int = #line
        ) {
            super.init()
            let match = Match(condition: condition,
                              file: file,
                              line: line)
            self.node = MatchNode(match: match, rest: [])
            self.file = file
            self.line = line
        }
    }
    
    final class Matching: _Conditional {
        override var name: String { "matching" }
        
        public convenience init<P: Predicate>(
            _ predicate: P,
            file: String = #file,
            line: Int = #line
        ) {
            self.init(predicate, or: [], and: [], file: file, line: line)
        }
        
        public convenience init<P: Predicate>(
            _ predicate: P,
            or: P...,
            file: String = #file,
            line: Int = #line
        ) {
            self.init(predicate, or: or, and: [], file: file, line: line)
        }
        
        public convenience init<P: Predicate>(
            _ predicate: P,
            and: any Predicate...,
            file: String = #file,
            line: Int = #line
        ) {
            self.init(predicate, or: [], and: and, file: file, line: line)
        }
        
        public convenience init<P: Predicate>(
            _ predicate: P,
            or: P...,
            and: any Predicate...,
            file: String = #file,
            line: Int = #line
        ) {
            self.init(predicate, or: or, and: and, file: file, line: line)
        }
        
        public convenience init<P: Predicate>(
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
            super.init()
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
