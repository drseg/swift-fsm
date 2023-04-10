//
//  MatchNode.swift
//
//  Created by Daniel Segall on 14/03/2023.
//

import Foundation

class MatchNodeBase {
    let match: Match
    var rest: [any Node<DefaultIO>]
    
    init(match: Match, rest: [any Node<DefaultIO>] = []) {
        self.match = match
        self.rest = rest
    }
    
    func makeOutput(_ rest: [DefaultIO]) -> [DefaultIO] {
        rest.reduce(into: []) {
            $0.append(
                (match: $1.match.prepend(match),
                 event: $1.event,
                 state: $1.state,
                 actions: $1.actions)
            )
        }
    }
}

class MatchNode: MatchNodeBase, Node {
    func combinedWithRest(_ rest: [DefaultIO]) -> [DefaultIO] {
        makeOutput(rest) ??? makeDefaultIO(match: match)
    }
}

class MatchBlockNode: MatchNodeBase, NeverEmptyNode {
    let caller: String
    let file: String
    let line: Int
    
    init(
        match: Match,
        rest: [any Node<Input>] = [],
        caller: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        self.caller = caller
        self.file = file
        self.line = line
        
        super.init(match: match, rest: rest)
    }
    
    func combinedWithRest(_ rest: [DefaultIO]) -> [DefaultIO] {
        makeOutput(rest)
    }
}
