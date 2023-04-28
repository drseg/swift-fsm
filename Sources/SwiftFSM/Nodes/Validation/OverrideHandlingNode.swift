import Foundation

class OverrideHandlingNode: Node {
    class OverrideError: Error {
        let override: IntermediateIO
        
        init(_ override: IntermediateIO) {
            self.override = override
        }
    }
    
    final class OverrideOutOfOrder: OverrideError {
        let outOfOrder: [IntermediateIO]
        
        init(_ override: IntermediateIO, _ outOfOrder: [IntermediateIO]) {
            self.outOfOrder = outOfOrder
            super.init(override)
        }
    }
    
    final class NothingToOverride: OverrideError { }
    
    var rest: [any Node<Input>]
    var errors: [Error] = []
    
    init(rest: [any Node<Input>]) {
        self.rest = rest
    }
    
    func combinedWithRest(_ rest: [IntermediateIO], ignoreErrors: Bool) -> [IntermediateIO] {
        var reverseOutput = Array(rest.reversed())
        let overrides = reverseOutput.filter(\.isOverride)
        guard !overrides.isEmpty else { return rest }
        
        var alreadyOverridden = [IntermediateIO]()
        
        overrides.forEach { override in
            func isOverridden(_ candidate: IntermediateIO) -> Bool {
                candidate.state == override.state &&
                candidate.match == override.match &&
                candidate.event == override.event
            }
            
            func handleOverrides() {
                func findOutOfPlaceOverrides() -> [IntermediateIO]? {
                    let prefix = Array(reverseOutput.prefix(upTo: indexAfterOverride - 1))
                    let outOfPlaceOverrides = prefix.filter(isOverridden)
                    return outOfPlaceOverrides.isEmpty ? nil : outOfPlaceOverrides
                }
                
                func findSuffixFromOverride() -> [IntermediateIO]? {
                    let suffix = Array(reverseOutput.suffix(from: indexAfterOverride))
                    return suffix.contains(where: isOverridden) ? suffix : nil
                }
                
                let indexAfterOverride = reverseOutput.firstIndex { $0 == override }! + 1
                
                if let outOfPlaceOverrides = findOutOfPlaceOverrides() {
                    errors.append(OverrideOutOfOrder(override, outOfPlaceOverrides)); return
                }
                
                guard var suffixFromOverride = findSuffixFromOverride() else {
                    errors.append(NothingToOverride(override)); return
                }
                
                suffixFromOverride.removeAll(where: isOverridden)
                reverseOutput.replaceSubrange(indexAfterOverride..., with: suffixFromOverride)
            }
            
            guard !alreadyOverridden.contains(where: isOverridden) else { return }
            alreadyOverridden.append(override)
            handleOverrides()
        }
        
        return errors.isEmpty ? reverseOutput.reversed() : []
    }
    
    func validate() -> [Error] {
        errors
    }
}
