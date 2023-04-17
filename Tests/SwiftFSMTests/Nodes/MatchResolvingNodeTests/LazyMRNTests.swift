//
//  LazyMatchResolvingNodeTests.swift
//
//  Created by Daniel Segall on 16/04/2023.
//

import Foundation

import XCTest
@testable import SwiftFSM

class LazyMatchResolvingNodeTests: DefineConsumer {
    typealias SVN = SemanticValidationNode
    typealias EMRN = EagerMatchResolvingNode

    
    func sut(rest: [any Node<DefineNode.Output>]) -> EMRN {
        .init(rest: [SVN(rest: [ActionsResolvingNode(rest: rest)])])
    }
}
