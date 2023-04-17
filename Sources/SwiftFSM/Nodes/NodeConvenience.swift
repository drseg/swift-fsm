//
//  NodeConvenience.swift
//  
//  Created by Daniel Segall on 14/03/2023.
//

import Foundation

typealias Action = () -> ()

protocol NeverEmptyNode: Node {
    var caller: String { get }
    var file: String { get }
    var line: Int { get }
}

extension NeverEmptyNode {
    func validate() -> [Error] {
        makeError(if: rest.isEmpty)
    }
    
    func makeError(if predicate: Bool) -> [Error] {
        predicate ? [EmptyBuilderError(caller: caller, file: file, line: line)] : []
    }
}

struct DefaultIO {
    let match: Match,
        event: AnyTraceable?,
        state: AnyTraceable?,
        actions: [Action]
    
    init(_ match: Match, _ event: AnyTraceable?, _ state: AnyTraceable?, _ actions: [Action]) {
        self.match = match
        self.event = event
        self.state = state
        self.actions = actions
    }
}

func makeDefaultIO(
    match: Match = Match(),
    event: AnyTraceable? = nil,
    state: AnyTraceable? = nil,
    actions: [Action] = []
) -> [DefaultIO] {
    [DefaultIO(match, event, state, actions)]
}

infix operator ???: AdditionPrecedence

func ???<T: Collection> (lhs: T, rhs: T) -> T {
    lhs.isEmpty ? rhs : lhs
}
