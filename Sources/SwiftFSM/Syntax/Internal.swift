import Foundation

enum Syntax {
    enum Expanded { }
}

enum Internal {
    struct MatchingWhen {
        static func |<S: Hashable> (lhs: Self, rhs: Syntax.Then<S>) -> MatchingWhenThen {
            .init(node: rhs.node.appending(lhs.node))
        }
        
        static func | (lhs: Self, rhs: @escaping Action) -> MatchingWhenActions {
            .init(node: ActionsNode(actions: [rhs], rest: [lhs.node]))
        }
        
        static func |<S: Hashable> (lhs: Self, rhs: Syntax.Then<S>) -> MatchingWhenThenActions {
            .init(node: ActionsNode(rest: [rhs.node.appending(lhs.node)]))
        }
        
        let node: WhenNode
    }
    
    struct MatchingThen {
        static func | (lhs: Self, rhs: @escaping Action) -> MatchingThenActions {
            .init(node: ActionsNode(actions: [rhs], rest: [lhs.node]))
        }
        
        let node: ThenNode
    }
    
    class MatchingActions: MA { }
    class MatchingWhenActions: MWA { }
    class MatchingThenActions: MTA { }
    
    struct MatchingWhenThen {
        static func | (lhs: Self, rhs: @escaping Action) -> MatchingWhenThenActions {
            .init(node: ActionsNode(actions: [rhs], rest: [lhs.node]))
        }
        
        let node: ThenNode
    }
    
    class MatchingWhenThenActions: MWTA { }
    
    final class MWTASentence: MWTA, BlockSentence { }
    final class MWASentence:  MWA, BlockSentence  { }
    final class MTASentence:  MTA, BlockSentence  { }
    
    @resultBuilder
    struct MWTABuilder: ResultBuilder {
        typealias T = MWTA
    }
    
    @resultBuilder
    struct MWABuilder: ResultBuilder {
        typealias T = MWA
    }
    
    @resultBuilder
    struct MTABuilder: ResultBuilder {
        typealias T = MTA
    }
    
    @resultBuilder
    struct MABuilder: ResultBuilder {
        typealias T = MA
    }
}

protocol BlockSentence {
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
        _ actions: [Action],
        file: String = #file,
        line: Int = #line,
        _ block: () -> [Sentence]
    ) {
        self.init(node: ActionsBlockNode(actions: actions,
                                rest: block().nodes,
                                caller: "actions",
                                file: file,
                                line: line))
    }
}

class Sentence {
    let node: any Node<DefaultIO>
    
    init(node: any Node<DefaultIO>) {
        self.node = node
    }
}

class MWTA: Sentence { }
class MWA: Sentence { }
class MTA: Sentence { }
class MA: Sentence { }

extension Node {
    func appending<Other: Node>(_ other: Other) -> Self where Input == Other.Output {
        var this = self
        this.rest = [other]
        return this
    }
}

extension Array {
    var nodes: [any Node<DefaultIO>] {
        map { ($0 as! Sentence).node }
    }
}
