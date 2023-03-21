//
//  AnyTraceable.swift
//  
//  Created by Daniel Segall on 21/03/2023.
//

import Foundation

struct AnyTraceable {
    let base: AnyHashable
    let file: String
    let line: Int
    
    init<H: Hashable>(base: H?, file: String, line: Int) {
        self.base = base!
        self.file = file
        self.line = line
    }
}

extension AnyTraceable: Hashable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.base == rhs.base
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(base)
    }
}
