//
//  SuperState.swift
//
//  Created by Daniel Segall on 07/03/2023.
//

import Foundation

struct SuperState {
    var nodes: [any Node<DefaultIO>]
    
    init(@Internal.MWTABuilder _ block: () -> [any MWTA]) {
        nodes = block().nodes
    }
}
