//
//  SuperState.swift
//
//  Created by Daniel Segall on 07/03/2023.
//

import Foundation

struct SuperState {
    var nodes: [any Node<DefaultIO>]
    
    #warning("should take vararg SuperState")
    #warning("should take entry/exit actions?")
    init(@Internal.MWTABuilder _ block: () -> [any MWTA]) {
        nodes = block().nodes
    }
}
