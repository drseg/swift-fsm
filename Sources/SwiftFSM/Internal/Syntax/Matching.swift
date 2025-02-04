import Foundation

public typealias ConditionProvider = @isolated(any) @Sendable () -> Bool

public extension Internal {
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

extension Internal.Conditional {
    var node: MatchingNode { this.node }
    var file: String { this.file }
    var line: Int { this.line }
    var name: String { this.name }
    
    var this: any Internal._Conditional { self as! any Internal._Conditional }
    
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
        @Internal.MWTABuilder _ block: @Sendable () -> [Internal.MWTA]
    ) -> Internal.MWTABlock {
        .init(blockNode, block)
    }
    
    public func callAsFunction(
        @Internal.MWABuilder _ block: @Sendable () -> [Internal.MWA]
    ) -> Internal.MWABlock {
        .init(blockNode, block)
    }
    
    public func callAsFunction(
        @Internal.MTABuilder _ block: @Sendable () -> [Internal.MTA]
    ) -> Internal.MTABlock {
        .init(blockNode, block)
    }
}
