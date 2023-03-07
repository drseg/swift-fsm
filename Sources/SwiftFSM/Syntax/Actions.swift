//
//  Actions.swift
//
//  Created by Daniel Segall on 07/03/2023.
//

import Foundation

extension Syntax {
    struct Actions {
        let actions: [() -> ()]
        let file: String
        let line: Int
        
        init(_ actions: @escaping () -> (), file: String = #file, line: Int = #line) {
            self.init([actions], file: file, line: line)
        }
        
        init(_ actions: [() -> ()], file: String = #file, line: Int = #line) {
            self.actions = actions
            self.file = file
            self.line = line
        }
        
        func callAsFunction(
            @Internal.SentenceBuilder _ block: () -> ([any Sentence])
        ) -> Internal.ActionsSentence {
            .init(actions, file: file, line: line, block)
        }
        
        func callAsFunction(
            @Internal.MWABuilder _ block: () -> ([Internal.MatchingWhenActions])
        ) -> Internal.MWASentence {
            .init(actions, file: file, line: line, block)
        }
        
        func callAsFunction(
            @Internal.MTABuilder _ block: () -> ([Internal.MatchingThenActions])
        ) -> Internal.MTASentence {
            .init(actions, file: file, line: line, block)
        }
    }
}
