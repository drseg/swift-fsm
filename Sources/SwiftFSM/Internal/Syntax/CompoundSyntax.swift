import Foundation

public enum Syntax {
    public class CompoundSyntax {
        let node: any SyntaxNode<RawSyntaxDTO>

        init(node: any SyntaxNode<RawSyntaxDTO>) {
            self.node = node
        }
    }
    
    protocol CompoundSyntaxGroup {
        var node: any SyntaxNode<RawSyntaxDTO> { get }
        
        init(node: any SyntaxNode<RawSyntaxDTO>)
    }
    
    public final class MatchingWhen<State: FSMHashable, Event: FSMHashable>: CompoundSyntax { }
    public final class MatchingThen<Event: FSMHashable>: CompoundSyntax { }
    public final class MatchingWhenThen<Event: FSMHashable>: CompoundSyntax { }
    
    public class MatchingActions: CompoundSyntax { }
    public class MatchingWhenActions: CompoundSyntax { }
    public class MatchingThenActions: CompoundSyntax { }
    public class MatchingWhenThenActions: CompoundSyntax { }

    public final class MWA_Group: MatchingWhenActions, CompoundSyntaxGroup { }
    public final class MTA_Group: MatchingThenActions, CompoundSyntaxGroup { }
    public final class MWTA_Group: MatchingWhenThenActions, CompoundSyntaxGroup { }

    @resultBuilder public struct MWTABuilder: ResultBuilder {
        public typealias T = MatchingWhenThenActions
    }
    
    @resultBuilder public struct MWABuilder: ResultBuilder {
        public typealias T = MatchingWhenActions
    }
    
    @resultBuilder public struct MTABuilder: ResultBuilder {
        public typealias T = MatchingThenActions
    }
    
    @resultBuilder public struct MABuilder: ResultBuilder {
        public typealias T = MatchingActions
    }
}

extension Syntax.CompoundSyntaxGroup {
    init<N: SyntaxNode<RawSyntaxDTO>>(
        _ n: N,
        _ group: () -> [Syntax.CompoundSyntax]
    ) where N.Input == N.Output {
        var n = n
        n.rest = group().nodes
        self.init(node: n)
    }

    init(
        _ actions: [AnyAction],
        file: String = #file,
        line: Int = #line,
        _ group: () -> [Syntax.CompoundSyntax]
    ) {
        self.init(
            node: ActionsBlockNode(
                actions: actions,
                rest: group().nodes,
                caller: "actions",
                file: file,
                line: line
            )
        )
    }
}
