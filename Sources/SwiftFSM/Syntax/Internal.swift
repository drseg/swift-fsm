//
//  Internal.swift
//
//  Created by Daniel Segall on 07/03/2023.
//

import Foundation

enum Syntax { }

enum Internal {
    struct ThenActions {
        let node: ActionsNode
    }
    
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
    
    struct MatchingWhenActions {
        let node: ActionsNode
    }
    
    struct MatchingThenActions {
        let node: ActionsNode
    }
    
    struct MatchingWhenThen {
        static func | (lhs: Self, rhs: @escaping () -> ()) -> MatchingWhenThenActions {
            .init(node: ActionsNode(actions: [rhs], rest: [lhs.node]))
        }
        
        let node: ThenNode
    }
    
    struct MatchingWhenThenActions: Sentence {
        let node: ActionsNode
    }
    
    struct ActionsSentence: Sentence {
        let node: ActionsBlockNode
        
        init(
            _ actions: [() -> ()],
            file: String = #file,
            line: Int = #line,
            @SentenceBuilder _ block: () -> ([any Sentence])
        ) {
            node = ActionsBlockNode(
                actions: actions,
                rest: block().nodes,
                caller: "actions",
                file: file,
                line: line
            )
        }
    }
    
    struct MWASentence {
        let node: ActionsBlockNode
        
        init(
            _ actions: [() -> ()],
            file: String = #file,
            line: Int = #line,
            @MWABuilder _ block: () -> ([MatchingWhenActions])
        ) {
            node = ActionsBlockNode(
                actions: actions,
                rest: block().nodes,
                caller: "actions",
                file: file,
                line: line
            )
        }
    }
    
    struct MTASentence {
        let node: ActionsBlockNode
        
        init(
            _ actions: [() -> ()],
            file: String = #file,
            line: Int = #line,
            @MWABuilder _ block: () -> ([MatchingThenActions])
        ) {
            node = ActionsBlockNode(
                actions: actions,
                rest: block().nodes,
                caller: "actions",
                file: file,
                line: line
            )
        }
    }
    
    @resultBuilder
    struct SentenceBuilder: ResultBuilder {
        typealias T = any Sentence
    }
    
    @resultBuilder
    struct MWABuilder: ResultBuilder {
        typealias T = MatchingWhenActions
    }
    
    @resultBuilder
    struct MTABuilder: ResultBuilder {
        typealias T = MatchingThenActions
    }
}

protocol Sentence {
    associatedtype N: Node<DefaultIO>
    var node: N { get }
}

extension Node {
    func appending<Other: Node>(_ other: Other) -> Self where Input == Other.Output {
        var this = self
        this.rest = [other]
        return this
    }
}

extension [Sentence] {
    var nodes: [any Node<DefaultIO>] {
        map { $0.node as! any Node<DefaultIO> }
    }
}

extension [Internal.MatchingWhenActions] {
    var nodes: [any Node<DefaultIO>] {
        map { $0.node }
    }
}

extension [Internal.MatchingThenActions] {
    var nodes: [any Node<DefaultIO>] {
        map { $0.node }
    }
}
