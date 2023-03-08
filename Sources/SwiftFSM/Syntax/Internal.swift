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
    
    struct MatchingWhenActions: MWAProtocol {
        let node: any Node<DefaultIO>
    }
    
    struct MatchingThenActions: MTAProtocol {
        let node: any Node<DefaultIO>
    }
    
    struct MatchingWhenThen {
        static func | (lhs: Self, rhs: @escaping () -> ()) -> MatchingWhenThenActions {
            .init(node: ActionsNode(actions: [rhs], rest: [lhs.node]))
        }
        
        let node: ThenNode
    }
    
    struct MatchingWhenThenActions: MWTAProtocol {
        let node: any Node<DefaultIO>
    }
    
    struct MWTASentence: MWTAProtocol {
        let node: any Node<DefaultIO>
        
        init(
            _ actions: [() -> ()],
            file: String = #file,
            line: Int = #line,
            _ block: () -> ([any MWTAProtocol])
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
    
    struct MWASentence: MWAProtocol {
        let node: any Node<DefaultIO>
        
        init(
            _ actions: [() -> ()],
            file: String = #file,
            line: Int = #line,
            _ block: () -> ([any MWAProtocol])
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
    
    struct MTASentence: MTAProtocol {
        let node: any Node<DefaultIO>
        
        init(
            _ actions: [() -> ()],
            file: String = #file,
            line: Int = #line,
            _ block: () -> ([any MTAProtocol])
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
    struct MWTABuilder: ResultBuilder {
        typealias T = any MWTAProtocol
    }
    
    @resultBuilder
    struct MWABuilder: ResultBuilder {
        typealias T = any MWAProtocol
    }
    
    @resultBuilder
    struct MTABuilder: ResultBuilder {
        typealias T = any MTAProtocol
    }
}

protocol Sentence {
    var node: any Node<DefaultIO> { get }
}

protocol MWTAProtocol: Sentence { }
protocol MWAProtocol: Sentence { }
protocol MTAProtocol: Sentence { }

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
