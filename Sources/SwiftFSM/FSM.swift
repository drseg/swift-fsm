//
//  FSM.swift
//  
//  Created by Daniel Segall on 03/03/2023.
//

import Foundation
import ReflectiveEquality

class FSM<State: Hashable, Event: Hashable> {
    private (set) var state: AnyHashable
    
    init(initialState: State) throws {
        if State.self == Event.self && State.self != AnyHashable.self  {
            throw StateEventClash()
        }
        
        state = initialState
    }
}

struct StateEventClash: Error {}
