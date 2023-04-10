//
//  ThenNode.swift
//  
//  Created by Daniel Segall on 14/03/2023.
//

import Foundation

class ThenNodeBase {
    let state: AnyTraceable?
    var rest: [any Node<DefaultIO>]
    
    init(state: AnyTraceable?, rest: [any Node<DefaultIO>] = []) {
        self.state = state
        self.rest = rest
    }
    
    func makeOutput(_ rest: [DefaultIO]) -> [DefaultIO] {
        rest.reduce(into: []) {
            $0.append((match: $1.match,
                       event: $1.event,
                       state: state,
                       actions: $1.actions))
        }
    }
}

class ThenNode: ThenNodeBase, Node {
    func combinedWithRest(_ rest: [DefaultIO]) -> [DefaultIO] {
        makeOutput(rest) ??? makeDefaultIO(state: state)
    }
}

class ThenBlockNode: ThenNodeBase, NeverEmptyNode {
    let caller: String
    let file: String
    let line: Int
    
    init(
        state: AnyTraceable?,
        rest: [any Node<Input>],
        caller: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        self.caller = caller
        self.file = file
        self.line = line
        
        super.init(state: state, rest: rest)
    }
    
    func combinedWithRest(_ rest: [DefaultIO]) -> [DefaultIO] {
        makeOutput(rest)
    }
}
