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
    
    func wtas<S: SP, E: EP>() -> [WTAP<S, E>] {
        map { ($0 as! (WTAPRow<S, E>)).wtap }.compactMap { $0 }
    }
}

extension Array where Element == () -> () {
    func executeAll() {
        forEach { $0() }
    }
}

extension Collection
where Element: Collection, Element: Hashable, Element.Element: Hashable {
    var asSets: Set<Set<Element.Element>> {
        Set(map(Set.init)).removeEmpties
    }
    
    var removeEmpties: Set<Element> {
        Set(filter { !$0.isEmpty })
    }
}
