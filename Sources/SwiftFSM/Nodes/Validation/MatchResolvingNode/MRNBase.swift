import Foundation

class MRNBase: Node {
    var rest: [any Node<IntermediateIO>]
    var errors: [Error] = []
    
    required init(rest: [any Node<IntermediateIO>] = []) {
        self.rest = rest
    }
    
    func validate() -> [Error] {
        errors
    }
    
    func combinedWithRest(_ rest: [IntermediateIO], ignoreErrors: Bool) -> [Transition] {
        fatalError("subclasses must implement")
    }
}
