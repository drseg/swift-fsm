//
//  TestingConvenience.swift
//  FiniteStateMachineTests
//
//  Created by Daniel Segall on 06/02/2023.
//

import Foundation
@testable import FiniteStateMachine

extension String: StateProtocol, EventProtocol {}
extension Int: EventProtocol, StateProtocol {}
extension Bool: EventProtocol, StateProtocol {}

extension Transition {
    static func build(
        @FSMTableBuilder<S, E> _ content: () -> FSMTableRowCollection<S, E>
    ) -> FSMTableRowCollection<S, E> {
        content()
    }
}
