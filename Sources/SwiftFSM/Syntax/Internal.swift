import Foundation

public enum Syntax {
    public enum Expanded { }
}

public enum Internal {
    public struct MatchingWhen {
        public static func |<S: Hashable> (lhs: Self, rhs: Syntax.Then<S>) -> MatchingWhenThen {
            .init(node: rhs.node.appending(lhs.node))
        }
        
        public static func | (lhs: Self, rhs: @escaping Action) -> MatchingWhenActions {
            .init(node: ActionsNode(actions: [rhs], rest: [lhs.node]))
        }
        
        public static func |<S: Hashable> (lhs: Self, rhs: Syntax.Then<S>) -> MatchingWhenThenActions {
            .init(node: ActionsNode(rest: [rhs.node.appending(lhs.node)]))
        }
        
        let node: WhenNode
    }
    
    public struct MatchingThen {
        public static func | (lhs: Self, rhs: @escaping Action) -> MatchingThenActions {
            .init(node: ActionsNode(actions: [rhs], rest: [lhs.node]))
        }
        
        let node: ThenNode
    }
    
    public final class MatchingActions: MA { }
    public final class MatchingWhenActions: MWA { }
    public final class MatchingThenActions: MTA { }
    
    public struct MatchingWhenThen {
        public static func | (lhs: Self, rhs: @escaping Action) -> MatchingWhenThenActions {
            .init(node: ActionsNode(actions: [rhs], rest: [lhs.node]))
        }
        
        let node: ThenNode
    }
    
    public final class MatchingWhenThenActions: MWTA { }
    
    public final class MWTASentence: MWTA, BlockSentence { }
    public final class MWASentence:  MWA, BlockSentence  { }
    public final class MTASentence:  MTA, BlockSentence  { }
    
    @resultBuilder
    public struct MWTABuilder: ResultBuilder {
        public typealias T = MWTA
    }
    
    @resultBuilder
    public struct MWABuilder: ResultBuilder {
        public typealias T = MWA
    }
    
    @resultBuilder
    public struct MTABuilder: ResultBuilder {
        public typealias T = MTA
    }
    
    @resultBuilder
    public struct MABuilder: ResultBuilder {
        public typealias T = MA
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

public class Sentence {
    let node: any Node<DefaultIO>
    
    init(node: any Node<DefaultIO>) {
        self.node = node
    }
}

public class MWTA: Sentence { }
public class MWA: Sentence { }
public class MTA: Sentence { }
public class MA: Sentence { }

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
