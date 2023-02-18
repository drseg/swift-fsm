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
    func transitions<S: SP, E: EP>() -> [Transition<S, E>]
    where Element == TableRow<S, E> {
        map(\.transitions).flatten
    }
    
    func wtaps<S: SP, E: EP>() -> [WTAP<S, E>]
    where Element == WTAPRow<S, E> {
        map(\.wtap).compactMap { $0 }
    }
    
    func executeAll() where Element == () -> () {
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
