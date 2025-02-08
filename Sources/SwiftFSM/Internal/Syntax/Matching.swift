import Foundation

public typealias ConditionProvider = @Sendable () -> Bool

public extension Syntax {
    protocol Conditional<State, Event> {
        associatedtype State: FSMHashable
        associatedtype Event: FSMHashable
    }
    
    internal protocol _Conditional: Conditional {
        var node: MatchingNode { get }
        var file: String { get }
        var line: Int { get }
        var name: String { get }
    }
    
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

extension Syntax.Conditional {
    var node: MatchingNode { this.node }
    var file: String { this.file }
    var line: Int { this.line }
    var name: String { this.name }
    
    var this: any Syntax._Conditional { self as! any Syntax._Conditional }
    
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
        @Syntax.MWTABuilder _ block: () -> [Syntax.MWTA]
    ) -> Syntax.MWTABlock {
        .init(blockNode, block)
    }
    
    public func callAsFunction(
        @Syntax.MWABuilder _ block: () -> [Syntax.MWA]
    ) -> Syntax.MWABlock {
        .init(blockNode, block)
    }
    
    public func callAsFunction(
        @Syntax.MTABuilder _ block: () -> [Syntax.MTA]
    ) -> Syntax.MTABlock {
        .init(blockNode, block)
    }
}
