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
