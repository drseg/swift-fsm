//
//  SuperState.swift
//
//  Created by Daniel Segall on 07/03/2023.
//

import Foundation

struct SuperState {
    var nodes: [any Node<DefaultIO>]
    var onEntry: [() -> ()]
    var onExit: [() -> ()]

    init(
        superStates: SuperState,
        _ rest: SuperState...,
        onEntry: [() -> ()] = [],
        onExit: [() -> ()] = []
    ) {
        self.init(superStates: [superStates] + rest, onEntry: onEntry, onExit: onExit)
    }
    
    init(
        superStates: SuperState...,
        onEntry: [() -> ()] = [],
        onExit: [() -> ()] = [],
        @Internal.MWTABuilder _ block: () -> [any MWTA]
    ) {
        self.init(nodes: block().nodes,
                  superStates: superStates,
                  onEntry: onEntry,
                  onExit: onExit)
    }
    
    private init(
        nodes: [any Node<DefaultIO>] = [],
        superStates: [SuperState],
        onEntry: [() -> ()],
        onExit: [() -> ()]
    ) {
        self.nodes = nodes + superStates.map(\.nodes).flattened
        self.onEntry = onEntry + superStates.map(\.onEntry).flattened
        self.onExit = onExit + superStates.map(\.onExit).flattened
    }
}
