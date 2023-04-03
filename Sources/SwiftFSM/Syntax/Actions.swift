//
//  Actions.swift
//
//  Created by Daniel Segall on 07/03/2023.
//

import Foundation

extension Syntax {
    struct Actions {
        let actions: [Action]
        let file: String
        let line: Int
        
        init(_ actions: @escaping Action, file: String = #file, line: Int = #line) {
            self.init([actions], file: file, line: line)
        }
        
        init(_ actions: [Action], file: String = #file, line: Int = #line) {
            self.actions = actions
            self.file = file
            self.line = line
        }
        
        func callAsFunction(
            @Internal.MWTABuilder _ block: () -> [any MWTA]
        ) -> Internal.MWTASentence {
            .init(actions, file: file, line: line, block)
        }
        
        func callAsFunction(
            @Internal.MWABuilder _ block: () -> [any MWA]
        ) -> Internal.MWASentence {
            .init(actions, file: file, line: line, block)
        }
        
        func callAsFunction(
            @Internal.MTABuilder _ block: () -> [any MTA]
        ) -> Internal.MTASentence {
            .init(actions, file: file, line: line, block)
        }
    }
}
