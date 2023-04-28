import Foundation

protocol SVNKey: Hashable {
    init(_ input: SemanticValidationNode.Input)
}

class SemanticValidationNode: Node {
    struct DuplicatesError: Error {
        let duplicates: DuplicatesDictionary
    }
    
    struct ClashError: Error {
        let clashes: ClashesDictionary
    }
    
    struct DuplicatesKey: SVNKey {
        let state: AnyTraceable,
            match: Match,
            event: AnyTraceable,
            nextState: AnyTraceable
        
        init(_ input: Input) {
            state = input.state
            match = input.match
            event = input.event
            nextState = input.nextState
        }
    }
    
    struct ClashesKey: SVNKey {
        let state: AnyTraceable,
            match: Match,
            event: AnyTraceable
        
        init(_ input: Input) {
            state = input.state
            match = input.match
            event = input.event
        }
    }
    
    typealias DuplicatesDictionary = [DuplicatesKey: [Input]]
    typealias ClashesDictionary = [ClashesKey: [Input]]
    
    var rest: [any Node<Input>]
    var errors: [Error] = []
    
    init(rest: [any Node<Input>]) {
        self.rest = rest
    }
    
    func combinedWithRest(_ rest: [IntermediateIO], ignoreErrors: Bool) -> [IntermediateIO] {
        if !ignoreErrors {
            validateInput(rest)
        }
        return errors.isEmpty ? rest : []
    }
    
    private func validateInput(_ input: [IntermediateIO]) {
        var duplicates = DuplicatesDictionary()
        var clashes = ClashesDictionary()
    
        _ = input.reduce(into: [Output]()) { validated, row in
            func isDuplicate(_ lhs: Input) -> Bool {
                isError(lhs, keyType: DuplicatesKey.self)
            }
            
            func isClash(_ lhs: Input) -> Bool {
                isError(lhs, keyType: ClashesKey.self)
            }
            
            func isError<T: SVNKey>(_ lhs: Input, keyType: T.Type) -> Bool {
                let haveClashingValues = T.init(lhs) == T.init(row)
                let haveNoOverrides = !lhs.isOverride && !row.isOverride
                let haveOverrides = lhs.isOverride || row.isOverride
                let areSameGroup = lhs.groupID == row.groupID
                
                return haveClashingValues && (haveNoOverrides || haveOverrides && areSameGroup)
            }
            
            func add<T: SVNKey>(_ existing: Output, row: Output, to dict: inout [T: [Input]]) {
                let key = T(row)
                dict[key] = (dict[key] ?? [existing]) + [row]
            }
            
            if let dupe = validated.first(where: isDuplicate) {
                add(dupe, row: row, to: &duplicates)
            }
            
            else if let clash = validated.first(where: isClash) {
                add(clash, row: row, to: &clashes)
            }
            
            validated.append(row)
        }
        
        if !duplicates.isEmpty {
            errors.append(DuplicatesError(duplicates: duplicates))
        }
        
        if !clashes.isEmpty {
            errors.append(ClashError(clashes: clashes))
        }
    }
    
    func validate() -> [Error] {
        errors
    }
}

extension IntermediateIO: Equatable {
    static func == (lhs: IntermediateIO, rhs: IntermediateIO) -> Bool {
        lhs.state == rhs.state &&
        lhs.match == rhs.match &&
        lhs.event == rhs.event &&
        lhs.nextState == rhs.nextState &&
        lhs.groupID == rhs.groupID &&
        lhs.isOverride == rhs.isOverride
    }
}
