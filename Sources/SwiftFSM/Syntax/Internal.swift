//
//  Internal.swift
//
//  Created by Daniel Segall on 07/03/2023.
//

import Foundation

enum Syntax { }

enum Internal {
    struct MatchingWhen {
        static func |<S: Hashable> (lhs: Self, rhs: Syntax.Then<S>) -> MatchingWhenThen {
            .init(node: rhs.node.appending(lhs.node))
        }
        
        static func | (lhs: Self, rhs: @escaping () -> ()) -> MatchingWhenActions {
            .init(node: ActionsNode(actions: [rhs], rest: [lhs.node]))
        }
        
        static func |<S: Hashable> (lhs: Self, rhs: Syntax.Then<S>) -> MatchingWhenThenActions {
            .init(node: ActionsNode(rest: [rhs.node.appending(lhs.node)]))
        }
        
        let node: WhenNode
    }
    
    struct MatchingThen {
        static func | (lhs: Self, rhs: @escaping () -> ()) -> MatchingThenActions {
            .init(node: ActionsNode(actions: [rhs], rest: [lhs.node]))
        }
        
        let node: ThenNode
    }
    
    struct MatchingActions: MA {
        let node: any Node<DefaultIO>
    }
    
    struct MatchingWhenActions: MWA {
        let node: any Node<DefaultIO>
    }
    
    struct MatchingThenActions: MTA {
        let node: any Node<DefaultIO>
    }
    
    struct MatchingWhenThen {
        static func | (lhs: Self, rhs: @escaping () -> ()) -> MatchingWhenThenActions {
            .init(node: ActionsNode(actions: [rhs], rest: [lhs.node]))
        }
        
        let node: ThenNode
    }
    
    struct MatchingWhenThenActions: MWTA {
        let node: any Node<DefaultIO>
    }
    
    class BlockSentence {
        let node: any Node<DefaultIO>

        init<N: Node>(_ n: N, _ block: () -> [any Sentence])
        where N.Input == DefaultIO, N.Input == N.Output {
            var n = n
            n.rest = block().nodes
            node = n
        }
        
        init(
            _ actions: [() -> ()],
            file: String = #file,
            line: Int = #line,
            _ block: () -> [any Sentence]
        ) {
            node = ActionsBlockNode(actions: actions,
                                    rest: block().nodes,
                                    caller: "actions",
                                    file: file,
                                    line: line)
        }
    }
    
    final class MWTASentence: BlockSentence, MWTA { }
    final class MWASentence:  BlockSentence, MWA  { }
    final class MTASentence:  BlockSentence, MTA  { }
    
    @resultBuilder
    struct MWTABuilder: ResultBuilder {
        typealias T = any MWTA
    }
    
    @resultBuilder
    struct MWABuilder: ResultBuilder {
        typealias T = any MWA
    }
    
    @resultBuilder
    struct MTABuilder: ResultBuilder {
        typealias T = any MTA
    }
    
    @resultBuilder
    struct MABuilder: ResultBuilder {
        typealias T = any MA
    }
}

protocol Sentence {
    var node: any Node<DefaultIO> { get }
}

protocol MWTA: Sentence { }
protocol MWA: Sentence { }
protocol MTA: Sentence { }
protocol MA: Sentence { }

extension Node {
    func appending<Other: Node>(_ other: Other) -> Self where Input == Other.Output {
        var this = self
        this.rest = [other]
        return this
    }
}

extension Array {
    var nodes: [any Node<DefaultIO>] {
        map { ($0 as! any Sentence).node }
    }
}
