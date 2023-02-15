//
//  Array+FSM.swift
//  FiniteStateMachine
//
//  Created by Daniel Segall on 06/02/2023.
//

import Foundation

extension Array where Element: Collection {
    var flatten: [Element.Element] {
        flatMap { $0 }
    }
}

extension Array where Element: Hashable {
    var uniqueValues: Self {
        Array(Set(self))
    }
}

extension Array {
    func transitions<S: SP, E: EP>() -> [Transition<S, E>] {
        map { ($0 as! (TableRow<S, E>)).transitions }.flatten
    }
    
    func wtas<S: SP, E: EP>() -> [WhensThenActions<S, E>] {
        map { ($0 as! (WTARow<S, E>)).wta }.compactMap { $0 }
    }
}

extension Array where Element == () -> () {
    func executeAll() {
        forEach { $0() }
    }
}
