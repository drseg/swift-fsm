//
//  NodeConvenience.swift
//  
//  Created by Daniel Segall on 14/03/2023.
//

import Foundation

typealias Action = () -> ()

struct AnyTraceable {
    let base: AnyHashable
    let file: String
    let line: Int
    
    init<H: Hashable>(base: H, file: String, line: Int) {
        #warning("How can I test this?")
        assert(!String(describing: base).contains("Optional"))
        
        self.base = base
        self.file = file
        self.line = line
    }
}

extension AnyTraceable: Hashable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.base == rhs.base
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(base)
    }
}

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

typealias DefaultIO = (match: Match,
                       event: AnyTraceable?,
                       state: AnyTraceable?,
                       actions: [Action])

func defaultIOOutput(
    match: Match = Match(),
    event: AnyTraceable? = nil,
    state: AnyTraceable? = nil,
    actions: [() -> ()] = []
) -> [DefaultIO] {
    [(match: match, event: event, state: state, actions: actions)]
}

infix operator ???: AdditionPrecedence

func ???<T: Collection> (lhs: T, rhs: T) -> T {
    lhs.isEmpty ? rhs : lhs
}
