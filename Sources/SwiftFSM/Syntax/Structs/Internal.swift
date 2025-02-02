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
    
    public final class MatchingActions<Event: FSMHashable>: MA { }
    public final class MatchingWhenActions<Event: FSMHashable>: MWA { }
    public final class MatchingThenActions<Event: FSMHashable>: MTA { }

    public final class MatchingWhenThenActions<Event>: MWTA { }

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

protocol BlockSentence {
    var node: any Node<DefaultIO> { get }

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
        _ actions: [AnyAction],
        file: String = #file,
        line: Int = #line,
        _ block: () -> [Sentence]
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
        compactMap { ($0 as? Sentence)?.node }
    }
}
