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
    
    func combinedWithRest(_ rest: [IntermediateIO]) -> [IntermediateIO] {
        var duplicates = DuplicatesDictionary()
        var clashes = ClashesDictionary()
    
        var output = rest.reduce(into: [Output]()) { result, row in
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
            
            if let dupe = result.first(where: isDuplicate) {
                add(dupe, row: row, to: &duplicates)
            }
            
            else if let clash = result.first(where: isClash) {
                add(clash, row: row, to: &clashes)
            }
            
            result.append(row)
        }
        
        if !duplicates.isEmpty {
            errors.append(DuplicatesError(duplicates: duplicates))
        }
        
        if !clashes.isEmpty {
            errors.append(ClashError(clashes: clashes))
        }
        
        output = handleOverrides(in: output)
        return errors.isEmpty ? output : []
    }
    
    private func handleOverrides(in output: [IntermediateIO]) -> [IntermediateIO] {
        var reverseOutput = Array(output.reversed())
        let overrides = reverseOutput.filter(\.isOverride)
        guard !overrides.isEmpty else { return output }
        
        var alreadyOverridden = [IntermediateIO]()
        
        overrides.forEach { override in
            func isOverridden(_ candidate: IntermediateIO) -> Bool {
                candidate.state == override.state &&
                candidate.match == override.match &&
                candidate.event == override.event
            }
            
            func overridesAreInOrder() -> Bool {
                let prefix = Array(reverseOutput.prefix(upTo: indexAfterOverride - 1))
                return !prefix.contains(where: isOverridden)
            }
            
            func findSuffixFromOverride() -> [IntermediateIO]? {
                let suffix = Array(reverseOutput.suffix(from: indexAfterOverride))
                return suffix.contains(where: isOverridden) ? suffix : nil
            }
            
            guard !alreadyOverridden.contains(where: isOverridden) else { return }
            alreadyOverridden.append(override)
            
            let indexAfterOverride = reverseOutput.firstIndex { $0 == override }! + 1
            
            guard overridesAreInOrder() else {
                errors.append("TEMP: override before overridden"); return
            }
            
            guard var suffixFromOverride = findSuffixFromOverride() else {
                errors.append("TEMP: nothing to override"); return
            }
            
            suffixFromOverride.removeAll(where: isOverridden)
            reverseOutput.replaceSubrange(indexAfterOverride..., with: suffixFromOverride)
        }
        
        return reverseOutput.reversed()
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
