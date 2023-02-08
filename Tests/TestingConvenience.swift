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

func build<S: SP, E: EP>(
    @TableBuilder<S, E> _ content: () -> [any TableRowProtocol<S, E>]
) -> [Transition<S, E>] {
    content().map { $0.transitions }.flatten
}
