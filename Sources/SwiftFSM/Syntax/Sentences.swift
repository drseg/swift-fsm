import Foundation

public enum Internal {
    public struct MatchingWhen<State: FSMHashable, Event: FSMHashable> {
        let node: WhenNode
    }

    public struct MatchingThen<Event: FSMHashable> {
        let node: ThenNode
    }

    public struct MatchingWhenThen<Event: FSMHashable> {
        let node: ThenNode
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
    
    public final class MatchingActions<Event: FSMHashable>: MA { }
    public final class MatchingWhenActions<Event: FSMHashable>: MWA { }
    public final class MatchingThenActions<Event: FSMHashable>: MTA { }

    public final class MatchingWhenThenActions<Event>: MWTA { }

    protocol BlockSentence {
        var node: any Node<DefaultIO> { get }
        
        init(node: any Node<DefaultIO>)
    }
    
    public final class MWTASentence: MWTA, BlockSentence { }
    public final class MWASentence: MWA, BlockSentence { }
    public final class MTASentence: MTA, BlockSentence { }

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

extension Internal.BlockSentence {
    init<N: Node<DefaultIO>>(
        _ n: N,
        _ block: () -> [Internal.Sentence]
    ) where N.Input == N.Output {
        var n = n
        n.rest = block().nodes
        self.init(node: n)
    }

    init(
        _ actions: [AnyAction],
        file: String = #file,
        line: Int = #line,
        _ block: () -> [Internal.Sentence]
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
