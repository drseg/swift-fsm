//
//  Combinations.swift
//
//  Created by Daniel Segall on 24/03/2023.
//

import Foundation

extension Collection where Element: Collection {
    typealias Output = [[Element.Element]]
    
    func combinations() -> Output {
        guard !isEmpty else { return [] }
        
        return reduce([[]], combinations)
    }
    
    private func combinations(_ c1: Output, _ c2: Element) -> Output {
        c1.reduce(into: []) { combinations, elem1 in
            c2.forEach { elem2 in
                combinations.append(elem1 + [elem2])
            }
        }
    }
}
