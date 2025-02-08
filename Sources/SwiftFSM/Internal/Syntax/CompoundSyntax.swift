import Foundation

public enum Syntax {
    public class CompoundSyntax {
        let node: any Node<DefaultIO>

        init(node: any Node<DefaultIO>) {
            self.node = node
        }
    }
    
    public final class MatchingWhen<State: FSMHashable, Event: FSMHashable>: CompoundSyntax { }
    public final class MatchingThen<Event: FSMHashable>: CompoundSyntax { }
    public final class MatchingWhenThen<Event: FSMHashable>: CompoundSyntax { }
    
    public class MA: CompoundSyntax { }
    public class MWA: CompoundSyntax { }
    public class MTA: CompoundSyntax { }
    public class MWTA: CompoundSyntax { }
    
    public final class MatchingActions: MA { }
    public final class MatchingWhenActions: MWA { }
    public final class MatchingThenActions: MTA { }
    public final class MatchingWhenThenActions: MWTA { }

    protocol CompoundBlockSyntax {
        var node: any Node<DefaultIO> { get }
        
        init(node: any Node<DefaultIO>)
    }
    
    public final class MWTABlock: MWTA, CompoundBlockSyntax { }
    public final class MWABlock: MWA, CompoundBlockSyntax { }
    public final class MTABlock: MTA, CompoundBlockSyntax { }

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

extension Syntax.CompoundBlockSyntax {
    init<N: Node<DefaultIO>>(
        _ n: N,
        _ block: () -> [Syntax.CompoundSyntax]
    ) where N.Input == N.Output {
        var n = n
        n.rest = block().nodes
        self.init(node: n)
    }

    init(
        _ actions: [AnyAction],
        file: String = #file,
        line: Int = #line,
        _ block: () -> [Syntax.CompoundSyntax]
    ) {
        self.init(
            node: ActionsBlockNode(
                actions: actions,
                rest: block().nodes,
                caller: "actions",
                file: file,
                line: line
            )
        )
    }
}
